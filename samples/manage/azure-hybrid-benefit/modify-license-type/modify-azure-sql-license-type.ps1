<#
.SYNOPSIS
    Updates the license type for Azure SQL resources (SQL DBs, Elastic Pools, Managed Instances, Instance Pools, SQL VMs)
    to a specified model ("LicenseIncluded" or "BasePrice"). 

.DESCRIPTION
    The script updates Azure SQL License types across subscriptions by modifying the license settings for a variety of SQL resources. It supports processing resources in one of the following ways:
    The script processes several types of Azure SQL resources including:

    SQL Virtual Machines (SQL VMs)
    SQL Managed Instances
    SQL Databases
    Elastic Pools
    SQL Instance Pools
    DataFactory SSIS Integration Runtimes

.VERSION
    1.0.0 - Initial version.
    1.0.2 - Modified to fix errors and to remove the auto-start of the offline resources.
    1.0.3 - Added transcript.
    1.0.4 - Fixed RG filter for SQL DB

.PARAMETER SubId
    A single subscription ID or a CSV file name containing a list of subscriptions.

.PARAMETER ResourceGroup
    Optional. Limit the scope to a specific resource group.

.PARAMETER LicenseType
    Optional. License type to set. Allowed values: "LicenseIncluded" (default) or "BasePrice".

.PARAMETER ExclusionTags
    Optional. If specified, excludes the resources that have this tag assigned.

.PARAMETER TenantId
    Optional. If specified, this tenant id to log in both PowerShell and CLI. Otherwise, the current login context is used.

.PARAMETER ReportOnly
    Optional. If true, generates a csv file with the list of resources that are to be modified, but doesn't make the actual change.

.PARAMETER UseManagedIdentity
    Optional. If true, logs in both PowerShell and CLI using managed identity. Required to run the script as a runbook.

.PARAMETER ResourceName
    Optional. If specified, only updates resources related to this name:
    - For SQL Server: Updates all databases under the specified server
    - For SQL Managed Instance: Updates the specified instance
    - For SQL VM: Updates the specified VM
#>

param (
    [Parameter(Mandatory = $false)]
    [string] $SubId,
    
    [Parameter(Mandatory = $false)]
    [string] $ResourceGroup,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("LicenseIncluded", "BasePrice", IgnoreCase = $false)]
    [string] $LicenseType = "LicenseIncluded",
    
    [Parameter (Mandatory= $false)]
    [object] $ExclusionTags,

    [Parameter (Mandatory= $false)]
    [string] $TenantId,

    [Parameter (Mandatory= $false)]
    [switch] $ReportOnly,

    [Parameter (Mandatory= $false)]
    [switch] $UseManagedIdentity,
    
    [Parameter (Mandatory= $false)]
    [string] $ResourceName
)


Start-Transcript -Path "$env:TEMP\modify-azure-sql-license-type.log"
$scriptStartTime = Get-Date
Write-Output "Script execution started at: $($scriptStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# Suppress unnecessary logging output
$VerbosePreference      = "SilentlyContinue"
$DebugPreference        = "SilentlyContinue"
$ProgressPreference     = "SilentlyContinue"
$InformationPreference  = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"

function Connect-Azure {
    [CmdletBinding()]
    param(
         [Parameter (Mandatory= $true)]
         [string] $TenantId,

         [Parameter (Mandatory= $false)]
         [switch]$UseManagedIdentity
    )

    # 1) Detect environment
    $envType = "Local"
    if ($env:AZUREPS_HOST_ENVIRONMENT -and $env:AZUREPS_HOST_ENVIRONMENT -like 'cloud-shell*') {
        $envType = "CloudShell"
    }
    elseif (($env:AZUREPS_HOST_ENVIRONMENT -and $env:AZUREPS_HOST_ENVIRONMENT -like 'AzureAutomation*') -or $PSPrivateMetadata.JobId) {
        $envType = "AzureAutomation"
        $UseManagedIdentity=$true
    }
    Write-Verbose "Environment detected: $envType"

    # 2) Ensure Az.PowerShell context
    Write-Output "Not connected to Azure PowerShell. Running Connect-AzAccount..."
    if ($UseManagedIdentity -or $envType -eq 'AzureAutomation') {
        $ctx = Connect-AzAccount -Tenant $TenantId -Identity -ErrorAction Stop | Out-Null
    }
    else {
        $ctx = Connect-AzAccount -Tenant $TenantId -ErrorAction Stop | Out-Null
    }
    Write-Output "Connected to Azure PowerShell as: $($ctx.Account)"

    # 3) Sync Azure CLI if available
    if (Get-Command az -ErrorAction SilentlyContinue) {
        Write-Output "Running az login..."
        if ($UseManagedIdentity -or $envType -eq 'AzureAutomation') {
            az login --tenant $TenantId --identity | Out-Null
        }
        else {
            az login --tenant $TenantId | Out-Null
        }
        $acct = az account show --output json | ConvertFrom-Json
    }
    Write-Output "Azure CLI logged in as: $($acct.user.name)"        
}


# Initialize final status and report counters.
$finalStatus = @()

# Convert to hashtable explicitly
$tagTable = @{}
if($ExclusionTags){
    if($ExclusionTags.GetType().Name -eq "Hashtable"){
        $tagTable = $ExclusionTags    
    }else{
        ($ExclusionTags | ConvertFrom-Json).PSObject.Properties | ForEach-Object {
            $tagTable[$_.Name] = $_.Value
        }
    }
}

if (-not $TenantId) {
    $TenantId =  (Get-AzContext).Tenant.Id
    Write-Output "No TenantId provided. Using current context TenantId: $TenantId"
} else {
    Write-Output "Using provided TenantId: $TenantId"
}
# Ensure connection with both PowerShell and CLI.
if ($UseManagedIdentity) {
    Connect-Azure ($TenantId, $UseManagedIdentity)
}else{
    Connect-Azure ($TenantId)
}

# Ensure the required modules are imported

# Ensure NuGet provider is available
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force
}

# Check if Az module is installed
$installedModule = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue

if (-not $installedModule) {
    Write-Output "Az module not found. Installing latest version..."
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
} else {
    # Get the latest version available in the PSGallery
    $latestVersion = (Find-Module -Name Az -Repository PSGallery).Version
    if ($installedModule.Version -lt $latestVersion) {
        Write-Output "Az module is outdated. Updating to latest version..."
        Update-Module -Name Az -Force
    } else {
        Write-Output "Az module is already up to date. No action needed."
    }
}

# Import Az.Accounts with minimum version requirement
try {
    Import-Module Az.Accounts -MinimumVersion 4.2.0 -Force
    Write-Output "Az.Accounts module imported successfully."
} catch {
    Write-Error "Failed to import Az.Accounts: $_"
    return
}

# Ensure Az.DataFactory is available and import it
try {
    if (-not (Get-Module -ListAvailable -Name Az.DataFactory)) {
        Write-Output "Az.DataFactory module not found. Installing..."
        Install-Module -Name Az.DataFactory -Scope CurrentUser -Force
    } else {
        Write-Output "Az.DataFactory module is already installed."
    }
    Import-Module Az.DataFactory -Force
} catch {
    Write-Error "Can't import module Az.DataFactory: $_"
}

# Map License Types for SQL VMs: LicenseIncluded -> PAYG, BasePrice -> AHUB.
$SqlVmLicenseType = if ($LicenseType -eq "LicenseIncluded") { "PAYG" } else { "AHUB" }

# Modified resources array
$modifiedResources = @()

# Determine the subscriptions to process: CSV file, single subscription, or all accessible subscriptions.
if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne "") {
    Write-Output "Passed Subscription $($SubId)"
    $subscriptions = Get-AzSubscription -SubscriptionId $SubId
}else {
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }
}

# Build resource group filter if specified.
$rgFilter = if ($ResourceGroup) { "resourceGroup=='$ResourceGroup'" } else { "" }
$scriptStartTime = Get-Date
Write-Output "Our adventure begins at: $scriptStartTime`n"
$tagsFilter = $null
if($tagTable.Keys.Count -gt 0) {
    $tagsFilter += " && "
    $tagcount = $tagTable.Keys.Count
    foreach ($tag in $tagTable.Keys) {
        $tagcount--
        $tagsFilter += " tags.$($tag) != '$($tagTable[$tag])' "
        if($tagcount -gt 0) {
            $tagsFilter += " && "
        }
    }
}

# Process each subscription.
foreach ($sub in $subscriptions) {
    try {
        Write-Output "===== Entering Subscription: $($sub.name) ====="
        Write-Output "Switching context to subscription: $($sub.name)"
        <#if($SqlVmLicenseType -eq "LicenseIncluded") {
            Write-Output "SQL VM License Type: PAYG"
            $ArcSQLServerExtensionDeployment = az tag list --resource-id "/subscriptions/$sub.id" --query "properties.tags.ArcSQLServerExtensionDeployment" -o json | ConvertFrom-Json
            if ($ArcSQLServerExtensionDeployment -ne "LicenseIncluded") {
                Write-Output "SQL VM License Type: PAYG"
                az tag update --resource-id /"/subscriptions/$sub.id" --operation merge --tags ArcSQLServerExtensionDeployment=PAYG | Out-Null
            }
        } else {
            Write-Output "SQL VM License Type: AHUB"
        }#>

        Write-Output "License Type: $LicenseType"
        az account set --subscription $sub.id

        # --- Section: Update SQL Virtual Machines ---
        try {
            Write-Output "Seeking SQL Virtual Machines that require a license update to $SqlVmLicenseType..."
            
            # Build SQL VM query
            $sqlVmQuery = "[?sqlServerLicenseType!='${SqlVmLicenseType}' && sqlServerLicenseType!= 'DR'"
            
            # Add resource group filter if specified
            if ($rgFilter) {
                $sqlVmQuery += " && $rgFilter"
            }
            
            # Add name filter if ResourceName specified
            if ($ResourceName) {
                $sqlVmQuery += " && name=='$ResourceName'"
            }
            
            # Add tags filter if specified
            if ($tagsFilter) {
                $sqlVmQuery += " $tagsFilter"
            }
            
            $sqlVmQuery += "].{name:name, resourceGroup:resourceGroup, sqlServerLicenseType:sqlServerLicenseType, type:type, id:id, Location:location}"

            Write-Output "Seeking SQL Virtual Machines with filter $sqlVmQuery..."
            $sqlVMs = az sql vm list --query $sqlVmQuery -o json | ConvertFrom-Json
            $sqlVmsToUpdate = [System.Collections.ArrayList]::new()
            if($sqlVMs.Count -eq 0) {
                Write-Output "No SQL VMs found that require a license update."
            } else {
                Write-Output "Found $($sqlVMs.Count) SQL VMs that require a license update."
            }
            foreach ($sqlvm in $sqlVMs) {

                if($null -ne (az vm list --query "[?name=='$($sqlvm.name)' && resourceGroup=='$($sqlvm.resourceGroup)' $tagsFilter]"))
                {
                    $vmStatus = az vm get-instance-view --resource-group $sqlvm.resourceGroup --name $sqlvm.name --query "{Name:name, ResourceGroup:resourceGroup, PowerState:instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]}" -o json | ConvertFrom-Json
                    if ($vmStatus.PowerState -eq "VM running") {
                        
                        # Collect data before modification
                        $modifiedResources += [PSCustomObject]@{
                            TenantID            = $TenantId
                            SubID               = ($sqlvm.id -split '/')[2]
                            ResourceName        = $sqlvm.name
                            ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                            Status              = $vmStatus.PowerState
                            OriginalLicenseType = $sqlvm.sqlServerLicenseType
                            ResourceGroup       = $sqlvm.resourceGroup
                            Location            = $sqlvm.Location
                            # Cores             <To be added>
                        }

        
                        if (-not $ReportOnly) {
                            Write-Output "Updating SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' to license type '$SqlVmLicenseType'..."
                            $result = az sql vm update -n $sqlvm.name -g $sqlvm.resourceGroup --license-type $SqlVmLicenseType -o json | ConvertFrom-Json
                            $finalStatus += $result
                        }
                    }
                }
                else {
                    Write-Output "SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' Skipping because of tags..."
                }
            }
            if($sqlVmsToUpdate.Count -eq 0) {
                Write-Output "No SQL VMs found to start that require a license update."
            } else {
                Write-Output "Found $($sqlVmsToUpdate.Count) to Start SQL VMs that require a license update."
            }
        }
        catch {
            Write-Error "An error occurred while updating SQL VMs: $_"
        }

        # --- Section: Update SQL Managed Instances (Stopped then Ready) "hybridSecondaryUsage": "Passive"---
        $sqlMIsToUpdate = [System.Collections.ArrayList]::new()
        try {
            
            Write-Output "Processing SQL Managed Instances that are running to $LicenseType..."
            
            # Build Managed Instance query
            $miRunningQuery = "[?licenseType!='${LicenseType}' && hybridSecondaryUsage!='Passive' && state=='Ready'"

            # Add resource group filter if specified
            if ($rgFilter) {
                $miRunningQuery += " && $rgFilter"
            }
            
            # Add name filter if ResourceName specified
            if ($ResourceName) {
                $miRunningQuery += " && name=='$ResourceName'"
            }
            
            # Add tags filter if specified
            if ($tagsFilter) {
                $miRunningQuery += " $tagsFilter"
            }

            $miRunningQuery += "].{name:name, state:state, resourceGroup:resourceGroup, licenseType:licenseType, location:location, id:id, ResourceType:type}"

            Write-Output "Processing SQL Managed Instances that are running with filter $miRunningQuery..."
            $runningMIs = az sql mi list --query $miRunningQuery -o json | ConvertFrom-Json
            if($runningMIs.Count -eq 0) {
                Write-Output "No SQL Managed Instances found that require a license update."
            } else {
                Write-Output "Found $($runningMIs.Count) SQL Managed Instances that require a license update."
            }
            foreach ($mi in $runningMIs) {
                        
                # Collect data before modification
                $modifiedResources += [PSCustomObject]@{
                    TenantID            = $TenantId
                    SubID               = ($mi.id -split '/')[2]
                    ResourceName        = $mi.name
                    ResourceType        = $mi.ResourceType
                    Status              = $mi.state
                    OriginalLicenseType = $mi.licenseType
                    ResourceGroup       = $mi.resourceGroup
                    Location            = $mi.location
                }
                
                if (-not $ReportOnly) {
                    Write-Output "Updating SQL Managed Instance '$($mi.name)' in RG '$($mi.resourceGroup)' to license type '$LicenseType'..."
                    $result = az sql mi update --name $mi.name --resource-group $mi.resourceGroup --license-type $LicenseType -o json | ConvertFrom-Json
                    $finalStatus += $result
                }
            }
        }
        catch {
            Write-Error "An error occurred while updating SQL Managed Instances: $_"
        }

        # --- Section: Update SQL Databases and Elastic Pools ---
       
        try {
             Write-Output   "Querying SQL Servers within this subscription..."
            
            # First, let's verify we're in the right subscription context
            $currentSubContext = az account show --query id -o tsv
             Write-Output   "Currently in subscription context: $currentSubContext"
            
            if ($currentSubContext -ne $sub.id) {
                 Write-Output   "Subscription context mismatch! Re-setting context..."
                az account set --subscription $sub.id
            }
            
            # Build SQL Server query with proper JMESPath syntax
            $serverQuery = ""
            $filterAdded = $false
            
            # Start with an empty filter array
            if ($rgFilter -or $ResourceName -or $tagsFilter) {
                $serverQuery = "["
                
                # Add resource group filter if specified
                if ($rgFilter) {
                    $serverQuery += "?$rgFilter"
                    $filterAdded = $true
                }
                
                # Add name filter if ResourceName is provided
                if ($ResourceName) {
                    if ($filterAdded) {
                        $serverQuery += " && name=='$ResourceName'"
                    } else {
                        $serverQuery += "?name=='$ResourceName'"
                        $filterAdded = $true
                    }
                }
                
                # Add tag filter if specified
                if ($tagsFilter -and $filterAdded) {
                    $serverQuery += "$tagsFilter"
                } elseif ($tagsFilter) {
                    $serverQuery += "?type=='Microsoft.Sql/servers'$tagsFilter" # A trick to make the tags filter work when it's the only filter
                }
                
                $serverQuery += "]"
            } else {
                # No filters, get all servers
                $serverQuery = "[]"
            }
            
            # Output the query for debugging
             Write-Output   "SQL Server query: $serverQuery"
            
            # Get all servers first as a fallback in case the query fails
            $allServers = az sql server list -o json | ConvertFrom-Json
             Write-Output   "Found a total of $($allServers.Count) SQL Servers in subscription"
            
            # Now try the filtered query
            $servers = az sql server list --query "$serverQuery" -o json | ConvertFrom-Json
            
            # Verify if we got any results
            if ($null -eq $servers -or $servers.Count -eq 0) {
                 Write-Output   "WARNING: No SQL Servers found with the specified filters."
                 Write-Output   "Available SQL Servers in subscription:"
                $allServers | ForEach-Object {
                     Write-Output   "  - $($_.name) (Resource Group: $($_.resourceGroup))"
                }
                
                # Use all servers if no specific resource name was provided
                if (-not $ResourceName) {
                     Write-Output   "Proceeding with all SQL Servers since no specific ResourceName was provided."
                    $servers = $allServers
                }
            } else {
                 Write-Output   "Found $($servers.Count) SQL Servers matching the criteria."
                $servers | ForEach-Object {
                     Write-Output   "  - $($_.name) (Resource Group: $($_.resourceGroup))"
                }
            }

            # Process each server
            foreach ($server in $servers) {
                # Update SQL Databases
                 Write-Output   "Scanning SQL Databases on server '$($server.name)' in resource group '$($server.resourceGroup)'..."
                
                # First get all databases to check if any exist
                $allDbs = az sql db list --resource-group $server.resourceGroup --server $server.name -o json | ConvertFrom-Json
                 Write-Output   "Found a total of $($allDbs.Count) databases on server '$($server.name)'"
                
                # Build database query with better error handling
                $dbQuery = "[?licenseType!=null && licenseType!='$($LicenseType)'"
                
                # Add tags filter if specified
                if ($tagsFilter) {
                    $dbQuery += "$tagsFilter"
                }
                if ($rgFilter) {
                    $dbQuery += " && $rgFilter"
                }
                
                $dbQuery += "].{name:name, licenseType:licenseType, location:location, resourceGroup:resourceGroup, id:id, ResourceType:type, State:status}"
                
                 Write-Output   "Database query: $dbQuery"
                
                # Get databases with error handling
                try {
                    $dbs = az sql db list --resource-group $server.resourceGroup --server $server.name --query "$dbQuery" -o json | ConvertFrom-Json
                    
                    if ($null -eq $dbs) {
                         Write-Output   "No SQL Databases found on Server $($server.name) that require a license update."
                    } elseif ($dbs.Count -eq 0) {
                         Write-Output   "No SQL Databases found on Server $($server.name) that require a license update."
                    } else {
                         Write-Output   "Found $($dbs.Count) SQL Databases on Server $($server.name) that require a license update:"
                        $dbs | ForEach-Object {
                             Write-Output   "  - $($_.name) (Current license: $($_.licenseType))"
                        }
                        
                        foreach ($db in $dbs) {
                            # Collect data before modification
                            $modifiedResources += [PSCustomObject]@{
                                TenantID            = $TenantId
                                SubID               = ($db.id -split '/')[2]
                                ResourceName        = $db.name
                                ResourceType        = $db.ResourceType
                                Status              = $db.State
                                OriginalLicenseType = $db.licenseType
                                ResourceGroup       = $db.resourceGroup
                                Location            = $db.location
                            }
                            
                            if (-not $ReportOnly) {
                                 Write-Output   "Updating SQL Database '$($db.name)' on server '$($server.name)' to license type '$LicenseType'..."
                                try {
                                    $result = az sql db update --name $db.name --server $server.name --resource-group $server.resourceGroup --set licenseType=$LicenseType -o json | ConvertFrom-Json
                                    if ($result) {
                                         Write-Output   "Successfully updated database '$($db.name)' license to '$LicenseType'"
                                        $finalStatus += $result
                                    } else {
                                         Write-Output   "Failed to update database '$($db.name)' license. No result returned."
                                    }
                                } catch {
                                     Write-Output   "Error updating database '$($db.name)': $_"
                                }
                            }
                        }
                    }
                } catch {
                     Write-Output   "Error querying databases on server '$($server.name)': $_"
                }

                # Update Elastic Pools with similar improved error handling
                try {
                     Write-Output   "Scanning Elastic Pools on server '$($server.name)'..."
                    
                    # First check if there are any elastic pools
                    $allPools = az sql elastic-pool list --resource-group $server.resourceGroup --server $server.name --only-show-errors -o json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
                    
                    if ($null -eq $allPools -or $allPools.Count -eq 0) {
                         Write-Output   "No Elastic Pools found on server '$($server.name)'."
                    } else {
                         Write-Output   "Found $($allPools.Count) total Elastic Pools on server '$($server.name)'."
                        
                        # Build elastic pool query with better formatting
                        $elasticPoolQuery = "[?licenseType!=null && licenseType!='$($LicenseType)'"
                        
                        # Add tags filter if specified
                        if ($tagsFilter) {
                            $elasticPoolQuery += " $tagsFilter"
                        }
                        
                        $elasticPoolQuery += "].{name:name, licenseType:licenseType, location:location, resourceGroup:resourceGroup, id:id, ResourceType:type, State:state}"
                        
                         Write-Output   "Elastic Pool query: $elasticPoolQuery"
                        
                        $elasticPools = az sql elastic-pool list --resource-group $server.resourceGroup --server $server.name --query "$elasticPoolQuery" --only-show-errors -o json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
                        
                        if ($null -eq $elasticPools -or $elasticPools.Count -eq 0) {
                             Write-Output   "No Elastic Pools found on Server $($server.name) that require a license update."
                        } else {
                             Write-Output   "Found $($elasticPools.Count) Elastic Pools on Server $($server.name) that require a license update:"
                            $elasticPools | ForEach-Object {
                                 Write-Output   "  - $($_.name) (Current license: $($_.licenseType))"
                            }
                            
                            foreach ($pool in $elasticPools) {
                                # Collect data before modification
                                $modifiedResources += [PSCustomObject]@{
                                    TenantID            = $TenantId
                                    SubID               = ($pool.id -split '/')[2]
                                    ResourceName        = $pool.name
                                    ResourceType        = $pool.ResourceType
                                    Status              = $pool.State
                                    OriginalLicenseType = $pool.licenseType
                                    ResourceGroup       = $pool.resourceGroup
                                    Location            = $pool.location
                                }
                                
                                if (-not $ReportOnly) {
                                     Write-Output   "Updating Elastic Pool '$($pool.name)' on server '$($server.name)' to license type '$LicenseType'..."
                                    try {
                                        $result = az sql elastic-pool update --name $pool.name --server $server.name --resource-group $server.resourceGroup --set licenseType=$LicenseType --only-show-errors -o json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
                                        if ($result) {
                                             Write-Output   "Successfully updated elastic pool '$($pool.name)' license to '$LicenseType'"
                                            $finalStatus += $result
                                        } else {
                                             Write-Output   "Failed to update elastic pool '$($pool.name)' license. No result returned."
                                        }
                                    } catch {
                                         Write-Output   "Error updating elastic pool '$($pool.name)': $_"
                                    }
                                }
                            }
                        }
                    }
                } catch {
                     Write-Output   "Error processing Elastic Pools on server '$($server.name)': $_"
                }
            }
        } catch {
             Write-Output   "An error occurred while processing SQL Databases or Elastic Pools: $_"
        }

        # --- Section: Update SQL Instance Pools ---
        try {
            Write-Output "Searching for SQL Instance Pools that require a license update..."
            
            # Build instance pool query
            $instancePoolsQuery = "[?licenseType!='${LicenseType}'"
            
            # Add resource group filter if specified
            if ($rgFilter) {
                $instancePoolsQuery += " && $rgFilter"
            }
            
            # Add name filter if ResourceName specified
            if ($ResourceName) {
                $instancePoolsQuery += " && name=='$ResourceName'"
            }
            
            # Add tags filter if specified
            if ($tagsFilter) {
                $instancePoolsQuery += " $tagsFilter"
            }
            
            $instancePoolsQuery += "].{name:name, licenseType:licenseType, location:location, resourceGroup:resourceGroup, id:id, ResourceType:type, State:status}"
            
            $instancePools = az sql instance-pool list --query $instancePoolsQuery -o json 2>$null | ConvertFrom-Json 
            $poolsToUpdate = $instancePools | Where-Object { $_.licenseType -ne $LicenseType }
            if($poolsToUpdate.Count -eq 0) {
                Write-Output "No SQL Instance Pools found that require a license update."
            } else {
                Write-Output "Found $($poolsToUpdate.Count) SQL Instance Pools that require a license update."
            }
            foreach ($pool in $poolsToUpdate) {
                
                # Collect data before modification
                $modifiedResources += [PSCustomObject]@{
                    TenantID            = $TenantId
                    SubID               = ($pool.id -split '/')[2]
                    ResourceName        = $pool.name
                    ResourceType        = $pool.ResourceType
                    Status              = $pool.State
                    OriginalLicenseType = $pool.licenseType
                    ResourceGroup       = $pool.resourceGroup
                    Location            = $pool.location
                }
                if (-not $ReportOnly) {
                    Write-Output "Updating SQL Instance Pool '$($pool.name)' in RG '$($pool.resourceGroup)' to license type '$LicenseType'..."
                    $result = az sql instance-pool update --name $pool.name --resource-group $pool.resourceGroup --license-type $LicenseType -o json | ConvertFrom-Json
                    $finalStatus += $result
                }
            }
        }
        catch {
            Write-Error "An error occurred while updating SQL Instance Pools: $_"
        }

        # --- Section: Update DataFactory SSIS Integration Runtimes ---
        try {
            Write-Output "Processing DataFactory SSIS Integration Runtime resources..."
            Set-AzContext -Subscription $sub.id | Out-Null
            Get-AzDataFactoryV2 | 
            Where-Object { 
                $_.ProvisioningState -eq "Succeeded" -and
                ([string]::IsNullOrEmpty($ResourceGroup) -or $_.ResourceGroupName -eq $ResourceGroup)
            } | 
            ForEach-Object {
                $df = $_
                $IRs = Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $df.ResourceGroupName -DataFactoryName $df.DataFactoryName | 
                Where-Object { 
                    $_.Type -eq "Managed" -and 
                    $_.State -ne "Starting" -and 
                    $_.LicenseType -ne $LicenseType -and
                    ([string]::IsNullOrEmpty($ResourceName) -or $_.Name -eq $ResourceName)
                }

                if ($IRs.Count -eq 0) {
                    Write-Output "No matching integration runtimes found."
                } else {
                    $IRs | ForEach-Object {
                        $modifiedResources += [PSCustomObject]@{
                            TenantID            = $TenantId
                            SubID               = ($_.Id -split '/')[2]
                            ResourceName        = $_.Name
                            ResourceType        = "Microsoft.DataFactory/factories/integrationRuntimes"
                            Status              = $_.State
                            OriginalLicenseType = $_.LicenseType
                            ResourceGroup       = $df.ResourceGroupName
                            Location            = $df.Location
                        }

                        if (-not $ReportOnly) {
                            if (-not [string]::IsNullOrEmpty($ResourceName) -and $_.State -ne "Stopped") {
                                Write-Output "ADF Integration Service '$($_.Name)' is not in stopped state"
                            } else {
                                $result = Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $df.ResourceGroupName -DataFactoryName $df.DataFactoryName -Name $_.Name -LicenseType $LicenseType -Force
                                $finalStatus += $result
                                Write-Output "-- DataFactory '$($df.DataFactoryName)' integration runtime updated to license type $LicenseType"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "An error occurred while updating DataFactory SSIS Integration Runtimes: $_"
        }

    }
    catch {
        Write-Error "An error occurred while processing subscription '$($sub.name)': $_"
    }
}

$scriptEndTime = Get-Date
$totalDuration = $scriptEndTime - $scriptStartTime

# --- Final Report ---
Write-Output "`n===== Final Report ====="
Write-Output "Script started at: $scriptStartTime"
Write-Output "Script ended at:   $scriptEndTime"
Write-Output "Total duration:    $($totalDuration.ToString())"

# Export modified resource data to CSV
if ($modifiedResources.Count -gt 0) {
    $csvPath = "ModifiedResources_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $modifiedResources | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "CSV report saved to: $csvPath"
} else {
    Write-Output "No resources were marked for modification. No CSV generated."
}

Write-Output "Azure SQL Update Script completed"

$scriptEndTime = Get-Date
$executionDuration = $scriptEndTime - $scriptStartTime
Write-Output "Script execution ended at: $($scriptEndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "Total execution time: $($executionDuration.ToString('hh\:mm\:ss'))"
Stop-Transcript