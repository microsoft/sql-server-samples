<#
.SYNOPSIS
    Schedules or executes pay-transition operations for Azure and/or Arc.

.DESCRIPTION
    This script is fully self-contained: the Azure SQL, Arc SQL, and Azure Automation
    runbook-registration logic are embedded directly in this file (no external
    downloads are required to run it). Depending on parameters, this script either:
      - Executes the Azure and/or Arc pay-transition logic once, or
      - Registers a scheduled Azure Automation runbook to invoke itself
        on a recurring basis.

.PARAMETER Target
    Which environment(s) to process:
      - Arc
      - Azure
      - Both (default)

.PARAMETER RunMode
    Whether to run immediately or schedule recurring runs:
      - Single     (default) : Run once, then exit.
      - Scheduled             : Create or update the scheduled Automation runbook calling this
                                logic daily.

.PARAMETER TargetLicenseType
    The license type to transition resources to:
      - PAYG  (default) : Pay-as-you-go / consumption-based licensing.
      - AHUB             : Azure Hybrid Benefit / License-only (bring-your-own-license).

.PARAMETER TenantId
    Azure AD tenant to operate against. If omitted, the tenant of the current
    Az PowerShell context ((Get-AzContext).Tenant.Id) is used. Specify this
    explicitly to avoid accidentally running against whichever tenant happens
    to be selected in the current session.

.PARAMETER ReportOnly
    Perform a read-only dry run: discover and report the resources that would be
    changed, without modifying any license types.

.PARAMETER AutomationAccResourceGroupName
    Required only when -RunMode is 'Scheduled'. Resource group for the Azure
    Automation Account that will host the recurring runbook. Not needed/used for
    -RunMode Single.

.PARAMETER Location
    Required only when -RunMode is 'Scheduled'. Azure region for the Automation
    Account/resource group. Not needed/used for -RunMode Single.

.EXAMPLE
    # Run immediately for both Azure and Arc, transitioning to PAYG (all defaults)
    .\manage-payg-transition.ps1

.EXAMPLE
    # Run immediately for both Azure and Arc, transitioning to PAYG (explicit)
    .\manage-payg-transition.ps1 -Target Both -RunMode Single

.EXAMPLE
    # Run immediately for both Azure and Arc, transitioning back to AHUB
    .\manage-payg-transition.ps1 -Target Both -RunMode Single -TargetLicenseType AHUB

.EXAMPLE
    # Dry run against a specific tenant - reports what would change, modifies nothing
    .\manage-payg-transition.ps1 -TenantId 'd1623670-9777-4399-aaf6-01d87b84ef1d' -ReportOnly

.EXAMPLE
    # Schedule daily runs for Azure only (AutomationAccResourceGroupName/Location required in this mode)
    .\manage-payg-transition.ps1 -Target Azure -RunMode Scheduled -AutomationAccResourceGroupName myRG -Location eastus
#>

param(
    [Parameter(Mandatory = $false, Position=0)]
    [ValidateSet("Arc","Azure","Both")]
    [string]$Target="Both",

    [Parameter(Mandatory = $false, Position=1)]
    [ValidateSet("Single","Scheduled")]
    [string]$RunMode="Single",

    [Parameter(Mandatory = $false, Position=2)]
    [bool]$cleanDownloads=$false,

    [Parameter (Mandatory= $false)]
    [ValidateSet("PAYG","AHUB", IgnoreCase=$false)]
    [string] $TargetLicenseType="PAYG",

    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $UsePcoreLicense="No",

    [Parameter(Mandatory=$false)]
    [string]$targetResourceGroup=$null,

    [Parameter(Mandatory=$false)]
    [string]$targetSubscription=$null,

    [Parameter(Mandatory=$false)]
    [string]$TenantId=$null,

    [Parameter(Mandatory=$false)]
    [switch]$ReportOnly,

    [Parameter(Mandatory=$false)]
    [string]$AutomationAccResourceGroupName=$null,

    [Parameter(Mandatory=$false)]
    [string]$AutomationAccountName="aaccAzureArcSQLLicenseType",

    [Parameter(Mandatory=$false)]
    [string]$Location=$null
)

# -AutomationAccResourceGroupName and -Location are only actually used by the
# Azure Automation setup path (RunMode Scheduled). Only require them in that mode,
# so a one-time -RunMode Single run doesn't need an Automation Account at all.
if ($RunMode -eq "Scheduled") {
    if ([string]::IsNullOrWhiteSpace($AutomationAccResourceGroupName)) {
        throw "-AutomationAccResourceGroupName is required when -RunMode is 'Scheduled'."
    }
    if ([string]::IsNullOrWhiteSpace($Location)) {
        throw "-Location is required when -RunMode is 'Scheduled'."
    }
}

# Translate the simplified -TargetLicenseType switch into the vocabulary each
# embedded script expects:
#   - modify-azure-sql-license-type.ps1 expects "LicenseIncluded" (PAYG) or "BasePrice" (AHUB).
#   - modify-arc-sql-license-type.ps1 expects "PAYG" or "LicenseOnly" (AHUB-equivalent for Arc).
$azureLicenseType = if ($TargetLicenseType -eq "PAYG") { "LicenseIncluded" } else { "BasePrice" }
$arcLicenseType    = if ($TargetLicenseType -eq "PAYG") { "PAYG" } else { "LicenseOnly" }

# === Embedded dependency scripts (materialized to disk at runtime; nothing is downloaded) ===
$EmbeddedScripts = @{}
$EmbeddedScripts['Azure'] = @'
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


# Transcription is not available in every host (for example Azure Automation
# runbooks) and can also fail if the log path is not writable. Track whether it
# actually started so the matching Stop-Transcript at the end of the script does
# not throw "The host is not currently transcribing".
$transcriptStarted = $false
try {
    Start-Transcript -Path "$env:TEMP\modify-azure-sql-license-type.log" -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
} catch {
    Write-Warning "Unable to start transcript logging: $($_.Exception.Message) Continuing without a transcript."
}
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

    # 2) Ensure Az.PowerShell context - reuse an existing, already-authenticated context for the
    #    requested tenant instead of forcing a fresh interactive/managed-identity login every run.
    $currentCtx = Get-AzContext -ErrorAction SilentlyContinue
    if ($currentCtx -and $currentCtx.Account -and $currentCtx.Tenant.Id -eq $TenantId) {
        Write-Output "Already connected to Azure PowerShell as: $($currentCtx.Account) (tenant $TenantId). Reusing existing context."
    }
    else {
        Write-Output "Not connected to Azure PowerShell for tenant $TenantId. Running Connect-AzAccount..."
        if ($UseManagedIdentity -or $envType -eq 'AzureAutomation') {
            $ctx = Connect-AzAccount -Tenant $TenantId -Identity -ErrorAction Stop
        }
        else {
            $ctx = Connect-AzAccount -Tenant $TenantId -ErrorAction Stop
        }
        Write-Output "Connected to Azure PowerShell as: $($ctx.Context.Account)"
    }

    # 3) Sync Azure CLI if available - reuse an existing az CLI session for the same tenant when possible.
    if (Get-Command az -ErrorAction SilentlyContinue) {
        $acct = az account show --output json 2>$null | ConvertFrom-Json
        if ($acct -and $acct.tenantId -eq $TenantId) {
            Write-Output "Azure CLI already logged in as: $($acct.user.name) (tenant $TenantId). Reusing existing session."
        }
        else {
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
}

<#
.SYNOPSIS
    Runs an 'az ... update' command and reports whether it actually succeeded.
.DESCRIPTION
    The Azure CLI signals failure through its exit code, not through a thrown
    exception, so piping its output straight into ConvertFrom-Json silently
    swallows errors and makes a failed update indistinguishable from a
    successful one. This wrapper checks $LASTEXITCODE and returns a result
    object used to populate the UpdateResult/UpdateError columns of the report.
#>
function Invoke-AzCliLicenseUpdate {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $output = & az @Arguments 2>&1

    if ($LASTEXITCODE -ne 0) {
        $message = ($output | Out-String).Trim()
        Write-Warning "Failed to update $Description`: $message"
        return [PSCustomObject]@{ Success = $false; Result = $null; ErrorMessage = $message }
    }

    $parsed = $null
    try { $parsed = $output | ConvertFrom-Json } catch { $parsed = $output }
    # Note: this function must not write to the success stream. Anything emitted there
    # would be merged into the return value, turning it into an array and hiding the
    # message from the caller. Callers log their own success line.
    return [PSCustomObject]@{ Success = $true; Result = $parsed; ErrorMessage = "" }
}


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

# Ensure connection with both PowerShell and CLI. Use V1 login.
Update-AzConfig -LoginExperienceV2 Off
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

# Check if the required Az.Accounts module (at the minimum version this script needs) is already
# available. Checking Get-InstalledModule -Name "Az" only detects the "Az" meta-package and false
# -positives as "not found" when the individual Az.* modules were installed some other way (e.g.
# preinstalled on the machine, installed individually, or via a package manager). That mismatch
# triggered an unnecessary "Install-Module -Name Az -Force", which fails/hangs when the modules are
# already loaded/in use. Instead, check directly for the module/version this script actually needs.
$requiredAzAccountsVersion = [version]"4.2.0"
$azAccountsAvailable = Get-Module -ListAvailable -Name Az.Accounts |
    Where-Object { $_.Version -ge $requiredAzAccountsVersion } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $azAccountsAvailable) {
    Write-Output "Az.Accounts module (>= $requiredAzAccountsVersion) not found. Installing latest version..."
    Install-Module -Name Az.Accounts -MinimumVersion $requiredAzAccountsVersion -Scope CurrentUser -Repository PSGallery -Force
} else {
    Write-Output "Az.Accounts module $($azAccountsAvailable.Version) already satisfies the minimum required version ($requiredAzAccountsVersion). No action needed."
}

# Import Az.Accounts with minimum version requirement
try {
    Import-Module Az.Accounts -MinimumVersion $requiredAzAccountsVersion -Force
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
            $sqlVmQuery = "[?sqlServerLicenseType!='${SqlVmLicenseType}' && sqlServerLicenseType!='DR'"
            
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
                    if (($vmStatus.PowerState -eq "VM running") -and ($sqlvm.sqlServerLicenseType -ne "DR")) {

                        $vmResult = "NotAttempted"
                        $vmError = ""

                        if ($ReportOnly) {
                            Write-Output "ReportOnly mode enabled. Skipping modification for SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' (would change '$($sqlvm.sqlServerLicenseType)' -> '$SqlVmLicenseType')."
                        } else {
                            Write-Output "Updating SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' to license type '$SqlVmLicenseType'..."
                            $update = Invoke-AzCliLicenseUpdate -Description "SQL VM '$($sqlvm.name)'" -Arguments @(
                                'sql','vm','update','-n',$sqlvm.name,'-g',$sqlvm.resourceGroup,'--license-type',$SqlVmLicenseType,'-o','json')
                            if ($update.Success) { $finalStatus += $update.Result; $vmResult = "Updated"; Write-Output "-- SQL VM '$($sqlvm.name)' updated to license type '$SqlVmLicenseType'" }
                            else { $vmResult = "Failed"; $vmError = $update.ErrorMessage }
                        }

                        # Collect data after the attempt so the recorded outcome is accurate
                        $modifiedResources += [PSCustomObject]@{
                            TenantID            = $TenantId
                            SubID               = ($sqlvm.id -split '/')[2]
                            ResourceName        = $sqlvm.name
                            ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                            Status              = $vmStatus.PowerState
                            OriginalLicenseType = $sqlvm.sqlServerLicenseType
                            ResourceGroup       = $sqlvm.resourceGroup
                            Location            = $sqlvm.Location
                            UpdateResult        = $vmResult
                            UpdateError         = $vmError
                            # Cores             <To be added>
                        }
                    }
                }
                else {
                    Write-Output "SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' Skipping because of tags..."
                }
            }
            if($sqlVmsToUpdate.Count -eq 0) {
                Write-Output "No stopped SQL VMs needed to be started for a license update."
            } else {
                Write-Output "Found $($sqlVmsToUpdate.Count) to Start SQL VMs that require a license update."
            }
        }
        catch {
            Write-Error "An error occurred while updating SQL VMs: $_"
        }

        # --- Section: Update SQL Managed Instances (Stopped then Ready) "
        $sqlMIsToUpdate = [System.Collections.ArrayList]::new()
        try {
            
          
            # Build Managed Instance query
            $miRunningQuery = "[?licenseType!='${LicenseType}' && state=='Ready'"

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

                $miResult = "NotAttempted"
                $miError = ""

                if (-not $ReportOnly) {
                    Write-Output "Updating SQL Managed Instance '$($mi.name)' in RG '$($mi.resourceGroup)' to license type '$LicenseType'..."
                    $update = Invoke-AzCliLicenseUpdate -Description "SQL Managed Instance '$($mi.name)'" -Arguments @(
                        'sql','mi','update','--name',$mi.name,'--resource-group',$mi.resourceGroup,'--license-type',$LicenseType,'-o','json')
                    if ($update.Success) { $finalStatus += $update.Result; $miResult = "Updated"; Write-Output "-- SQL Managed Instance '$($mi.name)' updated to license type '$LicenseType'" }
                    else { $miResult = "Failed"; $miError = $update.ErrorMessage }
                }

                # Collect data after the attempt so the recorded outcome is accurate
                $modifiedResources += [PSCustomObject]@{
                    TenantID            = $TenantId
                    SubID               = ($mi.id -split '/')[2]
                    ResourceName        = $mi.name
                    ResourceType        = $mi.ResourceType
                    Status              = $mi.state
                    OriginalLicenseType = $mi.licenseType
                    ResourceGroup       = $mi.resourceGroup
                    Location            = $mi.location
                    UpdateResult        = $miResult
                    UpdateError         = $miError
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

                # Only fall back to scanning every server in the subscription when the
                # caller did not restrict the scope. Falling back while -ResourceGroup
                # (or -ResourceName) was supplied would silently widen the blast radius
                # far beyond what was asked for: the elastic pool query below is not
                # resource-group filtered, so pools on out-of-scope servers would be
                # modified.
                if (-not $ResourceName -and -not $ResourceGroup) {
                     Write-Output   "Proceeding with all SQL Servers since no specific ResourceName or ResourceGroup was provided."
                    $servers = $allServers
                } else {
                     Write-Output   "Scope was explicitly restricted; not falling back to all SQL Servers. Skipping SQL Database and Elastic Pool processing."
                    $servers = @()
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

                            $dbResult = "NotAttempted"
                            $dbError = ""

                            if (-not $ReportOnly) {
                                 Write-Output   "Updating SQL Database '$($db.name)' on server '$($server.name)' to license type '$LicenseType'..."
                                $update = Invoke-AzCliLicenseUpdate -Description "SQL Database '$($db.name)' on server '$($server.name)'" -Arguments @(
                                    'sql','db','update','--name',$db.name,'--server',$server.name,'--resource-group',$server.resourceGroup,'--set',"licenseType=$LicenseType",'-o','json')
                                if ($update.Success) { $finalStatus += $update.Result; $dbResult = "Updated"; Write-Output "-- SQL Database '$($db.name)' updated to license type '$LicenseType'" }
                                else { $dbResult = "Failed"; $dbError = $update.ErrorMessage }
                            }

                            # Collect data after the attempt so the recorded outcome is accurate
                            $modifiedResources += [PSCustomObject]@{
                                TenantID            = $TenantId
                                SubID               = ($db.id -split '/')[2]
                                ResourceName        = $db.name
                                ResourceType        = $db.ResourceType
                                Status              = $db.State
                                OriginalLicenseType = $db.licenseType
                                ResourceGroup       = $db.resourceGroup
                                Location            = $db.location
                                UpdateResult        = $dbResult
                                UpdateError         = $dbError
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

                                $poolResult = "NotAttempted"
                                $poolError = ""

                                if (-not $ReportOnly) {
                                     Write-Output   "Updating Elastic Pool '$($pool.name)' on server '$($server.name)' to license type '$LicenseType'..."
                                    $update = Invoke-AzCliLicenseUpdate -Description "Elastic Pool '$($pool.name)' on server '$($server.name)'" -Arguments @(
                                        'sql','elastic-pool','update','--name',$pool.name,'--server',$server.name,'--resource-group',$server.resourceGroup,'--set',"licenseType=$LicenseType",'--only-show-errors','-o','json')
                                    if ($update.Success) { $finalStatus += $update.Result; $poolResult = "Updated"; Write-Output "-- Elastic Pool '$($pool.name)' updated to license type '$LicenseType'" }
                                    else { $poolResult = "Failed"; $poolError = $update.ErrorMessage }
                                }

                                # Collect data after the attempt so the recorded outcome is accurate
                                $modifiedResources += [PSCustomObject]@{
                                    TenantID            = $TenantId
                                    SubID               = ($pool.id -split '/')[2]
                                    ResourceName        = $pool.name
                                    ResourceType        = $pool.ResourceType
                                    Status              = $pool.State
                                    OriginalLicenseType = $pool.licenseType
                                    ResourceGroup       = $pool.resourceGroup
                                    Location            = $pool.location
                                    UpdateResult        = $poolResult
                                    UpdateError         = $poolError
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
            
            # Build instance pool query (skip the passive replicas)
            $instancePoolsQuery = "[?licenseType!='${LicenseType}' && state=='Ready'"
            
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

                $ipResult = "NotAttempted"
                $ipError = ""

                if (-not $ReportOnly) {
                    Write-Output "Updating SQL Instance Pool '$($pool.name)' in RG '$($pool.resourceGroup)' to license type '$LicenseType'..."
                    $update = Invoke-AzCliLicenseUpdate -Description "SQL Instance Pool '$($pool.name)'" -Arguments @(
                        'sql','instance-pool','update','--name',$pool.name,'--resource-group',$pool.resourceGroup,'--license-type',$LicenseType,'-o','json')
                    if ($update.Success) { $finalStatus += $update.Result; $ipResult = "Updated"; Write-Output "-- SQL Instance Pool '$($pool.name)' updated to license type '$LicenseType'" }
                    else { $ipResult = "Failed"; $ipError = $update.ErrorMessage }
                }

                # Collect data after the attempt so the recorded outcome is accurate
                $modifiedResources += [PSCustomObject]@{
                    TenantID            = $TenantId
                    SubID               = ($pool.id -split '/')[2]
                    ResourceName        = $pool.name
                    ResourceType        = $pool.ResourceType
                    Status              = $pool.State
                    OriginalLicenseType = $pool.licenseType
                    ResourceGroup       = $pool.resourceGroup
                    Location            = $pool.location
                    UpdateResult        = $ipResult
                    UpdateError         = $ipError
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
                    # Only SSIS integration runtimes carry a LicenseType. The default
                    # 'AutoResolveIntegrationRuntime' is also Type 'Managed' but has a null
                    # LicenseType; without this check it passes the filter below (since
                    # $null -ne $LicenseType) and the update fails with
                    # 'DataFactoryPropertyUpdateNotSupported: Updating property managedVirtualNetwork'.
                    (-not [string]::IsNullOrEmpty($_.LicenseType)) -and
                    $_.LicenseType -ne $LicenseType -and
                    ([string]::IsNullOrEmpty($ResourceName) -or $_.Name -eq $ResourceName)
                }

                if ($null -eq $IRs -or @($IRs).Count -eq 0) {
                    Write-Output "No SSIS integration runtimes found on DataFactory '$($df.DataFactoryName)' that require a license update."
                } else {
                    $IRs | ForEach-Object {
                        $ir = $_
                        $irResult = "NotAttempted"
                        $irError = ""

                        if (-not $ReportOnly) {
                            if (-not [string]::IsNullOrEmpty($ResourceName) -and $ir.State -ne "Stopped") {
                                Write-Output "ADF Integration Service '$($ir.Name)' is not in stopped state"
                                $irResult = "SkippedNotStopped"
                            } else {
                                Write-Output "Updating DataFactory '$($df.DataFactoryName)' integration runtime '$($ir.Name)' to license type $LicenseType..."
                                try {
                                    $result = Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $df.ResourceGroupName -DataFactoryName $df.DataFactoryName -Name $ir.Name -LicenseType $LicenseType -Force -ErrorAction Stop
                                    $finalStatus += $result
                                    $irResult = "Updated"
                                    Write-Output "-- DataFactory '$($df.DataFactoryName)' integration runtime '$($ir.Name)' updated to license type $LicenseType"
                                }
                                catch {
                                    $irResult = "Failed"
                                    $irError = $_.Exception.Message
                                    Write-Warning "Failed to update integration runtime '$($ir.Name)' on DataFactory '$($df.DataFactoryName)': $irError"
                                }
                            }
                        }

                        $modifiedResources += [PSCustomObject]@{
                            TenantID            = $TenantId
                            SubID               = ($ir.Id -split '/')[2]
                            ResourceName        = $ir.Name
                            ResourceType        = "Microsoft.DataFactory/factories/integrationRuntimes"
                            Status              = $ir.State
                            OriginalLicenseType = $ir.LicenseType
                            ResourceGroup       = $df.ResourceGroupName
                            Location            = $df.Location
                            UpdateResult        = $irResult
                            UpdateError         = $irError
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
    # Export-Csv derives its header from the first object only, so rows built by
    # different sections (some of which carry UpdateResult/UpdateError) are projected
    # onto one consistent schema to avoid silently dropping columns.
    $csvColumns = @('TenantID','SubID','ResourceName','ResourceType','Status',
                    'OriginalLicenseType','ResourceGroup','Location','UpdateResult','UpdateError')
    $modifiedResources |
        Select-Object -Property $csvColumns |
        Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "CSV report saved to: $csvPath"
} else {
    Write-Output "No resources were marked for modification. No CSV generated."
}

Write-Output "Azure SQL Update Script completed"

$scriptEndTime = Get-Date
$executionDuration = $scriptEndTime - $scriptStartTime
Write-Output "Script execution ended at: $($scriptEndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "Total execution time: $($executionDuration.ToString('hh\:mm\:ss'))"
if ($transcriptStarted) {
    try { Stop-Transcript | Out-Null } catch { Write-Warning "Unable to stop transcript logging: $($_.Exception.Message)" }
}
'@

$EmbeddedScripts['Arc'] = @'

<#
.SYNOPSIS
    Updates the license type for Azure Arc SQL resources to a specified license and license related options.  

.DESCRIPTION
    The script updates the license related settings of the SQL extension resources in a specified Entra ID tenant. You can specify a particular subscription, resource group or an individual connected machine. 
    You can also provide a list of subscriptions as a .CSV file. 
    By default, all subscriptions in your current tenant id are scanned.

.VERSION
    3.0.5 - Initial version.

.PARAMETER SubId
    A single subscription ID or a CSV file name containing a list of subscriptions.

.PARAMETER ResourceGroup
    Optional. Limit the scope to a specific resource group.

.PARAMETER MachineName 
    Optional. A single machine name or a CSV file name containing a list of machine names.

.PARAMETER LicenseType
    Optional. License type to set. Allowed values: "PAYG", "Paid" or "LicenseOnly"

.PARAMETER ConsentToRecurringPAYG 
    Optional. Consents to enabling the recurring PAYG billing. LicenseType must be "PAYG". Applies to CSP subscriptions only.

.PARAMETER UsePcoreLicense
    Optional. Opts in to use unlimited virtualization license if the value is "Yes", or opts out if the value is "No". To opt in, the license type must be "Paid" or "PAYG"

.PARAMETER EnableESU
    Optional. Enables the ESU policy if the value is "Yes" or disables it if the value is "No". To enable, the license type must be "Paid" or "PAYG"

.PARAMETER Force
    Optional. Forces the change of the license type to the specified value on all installed extensions. If not forced, the changes will apply only to the extensions where the license type is undefined.    

.PARAMETER ExclusionTags
    Optional. If specified, excludes the resources that have this tag assigned.

.PARAMETER TenantId
    Optional. If specified, this tenant id to log in both PowerShell and CLI. Otherwise, the current login context is used.

.PARAMETER ReportOnly
    Optional. If true, generates a csv file with the list of resources that are to be modified, but doesn't make the actual change.

.PARAMETER UseManagedIdentity
    Optional. If true, logs in both PowerShell and CLI using managed identity. Required to run the script as a runbook.

#>

param (
    [Parameter (Mandatory=$false)]
    [string] $SubId,

    [Parameter (Mandatory= $false)]
    [string] $ResourceGroup,

    [Parameter (Mandatory= $false)]
    [string] $MachineName,

    [Parameter (Mandatory= $false)]
    [ValidateSet("PAYG","Paid","LicenseOnly", IgnoreCase=$false)]
    [string] $LicenseType,

    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $ConsentToRecurringPAYG,
    
    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $UsePcoreLicense,

    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $EnableESU,

    [Parameter (Mandatory= $false)]
    [switch] $Force,

    [Parameter (Mandatory= $false)]
    [object] $ExclusionTags,

    [Parameter (Mandatory= $false)]
    [string] $TenantId,

    [Parameter (Mandatory= $false)]
    [switch] $ReportOnly,
   
    [Parameter (Mandatory= $false)]
    [switch] $UseManagedIdentity,
    [Parameter (Mandatory= $false)]
    [int] $batchSize = 500
)

# Transcription is not available in every host (for example Azure Automation
# runbooks) and can also fail if the log path is not writable. Track whether it
# actually started so the matching Stop-Transcript at the end of the script does
# not throw "The host is not currently transcribing".
$transcriptStarted = $false
try {
    Start-Transcript -Path ".\modify-arc-sql-license-type.log" -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
} catch {
    Write-Warning "Unable to start transcript logging: $($_.Exception.Message) Continuing without a transcript."
}
$scriptStartTime = Get-Date
Write-Output "Script execution started at: $($scriptStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"


function Connect-Azure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $TenantId = $null,

        [Parameter(Mandatory=$false)]
        [switch] $UseManagedIdentity
    )

    # 1) Detect host environment
    $envType = 'Local'
    if ($env:AZUREPS_HOST_ENVIRONMENT -like 'cloud-shell*') {
        $envType = 'CloudShell'
    }
    elseif (($env:AZUREPS_HOST_ENVIRONMENT -like 'AzureAutomation*') -or $PSPrivateMetadata.JobId) {
        $envType = 'AzureAutomation'
        $UseManagedIdentity = $true
    }
    Write-Output "Environment detected: $envType"

    # 2) Ensure Az.PowerShell context. Use login V1
    Update-AzConfig -LoginExperienceV2 Off
    $currentCtx = Get-AzContext -ErrorAction SilentlyContinue
    if ($currentCtx -and $currentCtx.Account) {
        if ($TenantId) {
            if ($currentCtx.Tenant.Id -eq $TenantId) {
                Write-Output "Already in Az tenant $TenantId"
            }
            else {
                Write-Output "Switching Az context to tenant $TenantId without re-authentication"
                $newContext = Set-AzContext -Tenant $TenantId -ErrorAction SilentlyContinue
                if($null -eq $newContext -or $newContext.TenantId -ne $TenantId)
                {
                  Connect-AzAccount -Tenant $TenantId  | Out-Null
                }
            } 
        }
        else {
            Write-Output "Using existing Az context: Tenant $($currentCtx.Tenant.Id)"
        }
    }
    else {
        Write-Output "Not connected to Azure PowerShell. Running Connect-AzAccount..."
        if ($UseManagedIdentity) {
            if ($TenantId) {
                Connect-AzAccount -Identity -Tenant $TenantId  | Out-Null
            }
            else {
                Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
            }
        }
        else {
            if ($TenantId) {
                Connect-AzAccount -Tenant $TenantId | Out-Null
            }
            else {
                Connect-AzAccount | Out-Null
            }
        }
        $ctx = Get-AzContext
        Write-Output "Connected to Az PowerShell as: $($ctx.Account) in tenant $($ctx.Tenant.Id)"
    }
}


# Convert to hashtable explicitly
$tagTable = @{}
if($null -ne $ExclusionTags){
    if($ExclusionTags.GetType().Name -eq "Hashtable"){
        $tagTable = $ExclusionTags    
    }else{
        ($ExclusionTags | ConvertFrom-Json).PSObject.Properties | ForEach-Object {
            $tagTable[$_.Name] = $_.Value
        }
    }
}
# Ensure connection with both PowerShell and CLI.
if($UseManagedIdentity -or $envType -eq 'AzureAutomation') {
    if ($TenantId) {
        Connect-Azure -TenantId $TenantId -UseManagedIdentity $UseManagedIdentity
    } else {
        Connect-Azure -UseManagedIdentity $UseManagedIdentity
    }
} else {
    if ($TenantId) {
        Connect-Azure -TenantId $TenantId
    } else {
        Connect-Azure
    }
}

$context = Get-AzContext -ErrorAction SilentlyContinue
Write-Output "Connected to Azure as: $($context.Account)"

if (-not $TenantId) {
    $TenantId = $context.Tenant.Id
    Write-Output "No TenantId provided. Using current context TenantId: $TenantId"
} else {
    Write-Output "Using provided TenantId: $TenantId"
}


# Ensure the required modules are imported

try{
    Import-Module Az.Accounts
}catch{
    Write-Output "Can't import module Az.Accounts"
}
try{
    Import-Module Az.ConnectedMachine
}
catch{
    Write-Output "Can't import module Az.ConnectedMachine"
}
try{
    Import-Module Az.ResourceGraph
}
catch{
    Write-Output "Can't import module Az.ResourceGraph"
}

$modifiedResources = @()

if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne "") {
    Write-Output "Passed Subscription $($SubId)"
    $subscriptions = Get-AzSubscription -SubscriptionId $SubId
}else {
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }
}

# Handle MachineName input (single or CSV)
$machineNames = @()
if ($MachineName) {
    if ($MachineName -like "*.csv") {
        try {
            $machines = Import-Csv $MachineName
            foreach ($m in $machines) {
                if ($m.MachineName) {
                    $machineNames += $m.MachineName
                }
            }
            Write-Output "Loaded $($machineNames.Count) machine names from CSV."
        } catch {
            Write-Error "Failed to import machine names from CSV: $_"
            exit 1
        }
    } else {
        $machineNames += $MachineName
    }
}

Write-Host ([Environment]::NewLine + "-- Scanning subscriptions --")

foreach ($sub in $subscriptions) {
    if ($sub.State -ne "Enabled") {continue}

    try {
        Set-AzContext -SubscriptionId $sub.Id #Removed TenantID by Sunil
    }catch {
        write-host "Invalid subscription: $($sub.Id)"
        {continue}
    }

    Write-Output "Collecting list of resources to update"

    $query = "
    resources
    | where subscriptionId =~ '$($sub.Id)'
    | where type == 'microsoft.hybridcompute/machines'
    | where properties.detectedProperties.mssqldiscovered == 'true'"
    if ($ResourceGroup) {
        $query += "
    | where resourceGroup =~ '$ResourceGroup'"
    }

    if ($machineNames.Count -gt 0) {
        $machineFilter = ($machineNames | ForEach-Object { "'$_'" }) -join ", "
        $query += "| where name in~ ($machineFilter)"
    }

    $query += "
    | extend machineId = tolower(tostring(id))
    | project machineId, machineName = tolower(name)
    | join kind= inner (
        resources
        | where subscriptionId =~ '$($sub.Id)'
        | where type == 'microsoft.hybridcompute/machines/extensions'
        | where properties.publisher =~ 'Microsoft.AzureData'
        | where properties.provisioningState == 'Succeeded'
        | where properties.settings.LicenseType!='$LicenseType'
        | extend extensionName = name
        | extend extensionPublisher = properties.publisher
        | extend extensionType = properties.type
        | parse id with '/subscriptions/' subscriptionId '/resourceGroups/' resourceGroup '/providers/Microsoft.HybridCompute/machines/' machineNameRaw '/extensions/' extensionName
        | extend machineName = tolower(machineNameRaw)
        ) on `$left.machineName == `$right.machineName
    | project machineName, extensionName, resourceGroup, location, subscriptionId, extensionPublisher, extensionType
    | order by machineName asc"
   
    $skipToken = $null

    Write-Output $query

    $allResults = [System.Collections.Generic.List[PSObject]]::new()
    do{
        $resources = Search-AzGraph -Query "$($query)" -First $batchSize -SkipToken $skipToken
        $allResults.AddRange($resources)
        $skipToken = $resources.SkipToken
    }while($skipToken)

    Write-Output "Found $($allResults.Count) resource(s) to update"


    $count = $allResults.Count

    
    while($count -gt 0) {
        $count-=1
        $setID = @{
            MachineName = $allResults[$count].MachineName
            Name = $allResults[$count].extensionName
            ResourceGroup = $allResults[$count].resourceGroup
            Location = $allResults[$count].location
            SubscriptionId = $allResults[$count].subscriptionId
            Publisher = $allResults[$count].extensionPublisher
            ExtensionType = $allResults[$count].extensionType
        }

        write-Output "   MachineName - $($setID.MachineName)"
        write-Output "   ResourceGroup - $($setID.ResourceGroup)"
        write-Output "   Location - $($setID.Location)"
        write-Output "   SubscriptionId - $($setID.SubscriptionId)"
        write-Output "   ExtensionType - $($setID.ExtensionType)"
        
        # Get connected machine info
        $sqlvm = Get-AzConnectedMachine -Name $setID.MachineName -ResourceGroup $setID.ResourceGroup | Select-Object Name, Tags, Status

        
        $excludedByTags = $false
        foreach ($tag in $tagTable.Keys){
            if($sqlvm.Tags.ContainsKey($tag))
            {
                if($sqlvm.Tags[$tag] -eq $tagTable[$tag]){
                    $excludedByTags=$true
                    $value = $tagTable[$tag]
                    write-Output "Exclusion tag $($tag):$value. Skipping..."
                    Break;
                }
            }
        }
        if(!$excludedByTags){
           
        
        $WriteSettings = $false
        $ext = Get-AzConnectedMachineExtension -Name $setID.Name -ResourceGroupName $setID.ResourceGroup -MachineName $setID.MachineName

        # Collect data before modification. UpdateResult/UpdateError are populated
        # after the actual Set-AzConnectedMachineExtension call below (or left as
        # "NotAttempted" if the resource was skipped) so the CSV/console output
        # reflects what actually happened, not just what was intended.
        $resourceRecord = [PSCustomObject]@{
            TenantID            = $TenantId
            SubID               = $setID.SubscriptionId
            ResourceName        = $setID.MachineName
            ResourceType        = $setID.ExtensionType
            Status              = $sqlvm.Status
            OriginalLicenseType = $ext.Setting["LicenseType"]
            ResourceGroup       = $setID.ResourceGroup
            Location            = $setID.Location
            UpdateResult        = "NotAttempted"
            UpdateError         = ""
            # Cores             <To be added>
        }
        $modifiedResources += $resourceRecord

        if($ext.ProvisioningState -ne "Succeeded") {
            write-Output "Extension is not in a valid state. Skipping..."
            {continue}
        } else {
            $LO_Allowed = (!$ext.Setting["enableExtendedSecurityUpdates"] -and !$EnableESU) -or  ($EnableESU -eq "No")
            
            if ($LicenseType) {
                if (($LicenseType -eq "LicenseOnly") -and !$LO_Allowed) {
                    write-Output "ESU must be disabled before license type can be set to $($LicenseType)"
                } else {
                    if ($ext.Setting["LicenseType"]) {
                        if ($Force) {
                            $ext.Setting["LicenseType"] = $LicenseType
                            $WriteSettings = $true
                        }
                    } else {
                        $ext.Setting["LicenseType"] = $LicenseType
                        $WriteSettings = $true
                    }
                }
            }
            
            if ($EnableESU) {
                if (($ext.Setting["LicenseType"] -in ("Paid","PAYG")) -or  ($EnableESU -eq "No")) {
                    $ext.Setting["enableExtendedSecurityUpdates"] = ($EnableESU -eq "Yes")
                    $ext.Setting["esuLastUpdatedTimestamp"] = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    $WriteSettings = $true
                } else {
                    write-Output "The configured license type does not support ESUs" 
                }
            }
            
            if ($UsePcoreLicense) {
                if (($ext.Setting["LicenseType"] -in ("Paid","PAYG")) -or  ($UsePcoreLicense -eq "No")) {
                    $ext.Setting["UsePhysicalCoreLicense"] = @{
                        "IsApplied" = ($UsePcoreLicense -eq "Yes");
                        "LastUpdatedTimestamp" = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    }
                    $WriteSettings = $true
                } else {
                    write-Output "The configured license type does not support ESUs" 
                }
            }
            
            # Add or update ConsentToRecurringPAYG setting if applicable
            if ($ConsentToRecurringPAYG -eq "Yes") {
                $isPayg = ($LicenseType -eq "PAYG") -or ($ext.Setting["LicenseType"] -eq "PAYG")
                if ($isPayg) {
                    if (-not $ext.Setting.ContainsKey("ConsentToRecurringPAYG") -or -not $ext.Setting["ConsentToRecurringPAYG"]["Consented"]) {
                        $ext.Setting["ConsentToRecurringPAYG"] = @{
                            "Consented" = $true;
                            "ConsentTimestamp" = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
                        }
                        $WriteSettings = $true
                    }
                }
            }

            write-Output "   Write Settings - $($WriteSettings)"

            if (-not $ReportOnly) {
                If ($WriteSettings) {
                    try {
                        $settings = @{}
                        foreach ($h in $ext.Setting.Keys) {
                           $settings[$h]=$($ext.Setting[$h])
                        }
                        # -ErrorAction Stop is required here: Set-AzConnectedMachineExtension
                        # can emit a non-terminating error (e.g. "An extension of type ... is
                        # still processing. Only one instance of an extension may be in
                        # progress at a time...") which, combined with -NoWait, would otherwise
                        # be printed to the console and then fall through to the "Updated"
                        # success message below without ever entering the catch block.
                        Set-AzConnectedMachineExtension -Name $setID.Name -ResourceGroupName $setID.ResourceGroup -Location $setID.Location -MachineName $setID.MachineName -Publisher $setID.Publisher -ExtensionType $setID.ExtensionType -Setting $settings -NoWait -ErrorAction Stop
                        Write-Output "Updated -- Resource group: [$($setID.ResourceGroup)], Connected machine: [$($setID.MachineName)]"
                        $resourceRecord.UpdateResult = "RequestSubmitted"
                    } catch {
                        $errorMessage = $_.Exception.Message
                        Write-Output "The request to modify the extension object for [$($setID.MachineName)] failed with the following error: $errorMessage"
                        $resourceRecord.UpdateResult = "Failed"
                        $resourceRecord.UpdateError = $errorMessage
                        continue
                    }
                }
            } else {
                Write-Output "ReportOnly mode enabled. Skipping modification for: $($setID.MachineName)"
            }
        }
        
    }
    }
}

# Export modified resource data to CSV
if ($modifiedResources.Count -gt 0) {
    $csvPath = "ModifiedResources_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $modifiedResources | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "CSV report saved to: $csvPath"
} else {
    Write-Output "No resources were marked for modification. No CSV generated."
}

write-Output "Arc SQL Update Script completed"

$scriptEndTime = Get-Date
$executionDuration = $scriptEndTime - $scriptStartTime
Write-Output "Script execution ended at: $($scriptEndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "Total execution time: $($executionDuration.ToString('hh\:mm\:ss'))"
if ($transcriptStarted) {
    try { Stop-Transcript | Out-Null } catch { Write-Warning "Unable to stop transcript logging: $($_.Exception.Message)" }
}

'@

$EmbeddedScripts['General'] = @'
<#
.SYNOPSIS
    Creates or uses an Azure Automation account and imports a runbook.

.DESCRIPTION
    This script:
      - Connects to Azure (PowerShell + CLI).
      - Creates the resource group if it doesn't exist.
      - Creates the Automation account (with system identity) if it doesn't exist.
      - Assigns a set of built‑in roles to that managed identity.
      - Imports or updates the specified runbook, publishes it.
      - Creates a daily schedule (if missing) and links it to the runbook.
      - Starts a one‑off job of the runbook.

.PARAMETER ResourceGroupName
    The resource group in which to create/use the Automation account.

.PARAMETER AutomationAccountName
    The Automation account name.

.PARAMETER Location
    Azure region for the RG and account (e.g. "EastUS").

.PARAMETER RunbookName
    The name under which to import/publish the runbook.

.PARAMETER RunbookPath
    Full path to the local .ps1 runbook file.

.PARAMETER RunbookType
    Runbook type: "PowerShell", "PowerShell72", "PowerShellWorkflow", "Graph", "Python2", or "Python3".
    Default: "PowerShell72".

.PARAMETER targetResourceGroup
    (Optional) Resource group passed into the runbook as a parameter.

.PARAMETER targetSubscription
    (Optional) Subscription ID passed into the runbook as a parameter.
#>

param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AutomationAccountName,
    [Parameter(Mandatory)][string]$Location,
    [Parameter(Mandatory)][string]$RunbookName,
    [Parameter(Mandatory)][string]$RunbookPath,
    [Parameter()][Hashtable]$RunbookArg,
    [ValidateSet("PowerShell","PowerShell72","PowerShellWorkflow","Graph","Python2","Python3")]
    [string]$RunbookType = "PowerShell72",
    [string]$targetResourceGroup,
    [string]$targetSubscription
)
# Suppress unnecessary logging output
$VerbosePreference      = "SilentlyContinue"
$DebugPreference        = "SilentlyContinue"
$ProgressPreference     = "SilentlyContinue"
$InformationPreference  = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"
$context = $null
# Define role assignments to apply
$roleAssignments = @(
    @{ RoleName = "SQL DB Contributor"; Description = "For Azure SQL Databases and Azure SQL Elastic Pools" },
    @{ RoleName = "SQL Managed Instance Contributor"; Description = "For Azure SQL Managed Instances and Azure SQL Instance Pools" },
    @{ RoleName = "Data Factory Contributor"; Description = "For Azure Data Factory SSIS Integration Runtimes" },
    @{ RoleName = "Virtual Machine Contributor"; Description = "For SQL Servers in Azure Virtual Machines" },
    @{RoleName = "SQL Server Contributor"; Description = "For Elastic-Pools in Azure Virtual Machines"},
    @{RoleName = "Azure Connected Machine Resource Administrator"; Description = "For SQL Servers in Arc Virtual Machines"},
    @{RoleName = "Reader"; Description = "For read resources in the subscription"}
)
function Connect-Azure {
        try {
            Write-Output "Testing if it is connected to Azure."
            # Attempt to retrieve the current Azure context
            $context = Get-AzContext -ErrorAction SilentlyContinue
    
            if ($null -eq $context -or $null -eq $context.Account) {
                Write-Output "Not connected to Azure. Executing Connect-AzAccount..."
                if($UseManageIdentity){
                    Connect-AzAccount -Identity -ErrorAction Stop  | Out-Null
                } else {
                    Connect-AzAccount -ErrorAction Stop  | Out-Null
                }
                $context = Get-AzContext
                Write-Output "Connected to Azure as: $($context.Account)"
            }
            else {
                Write-Output "Already connected to Azure as: $($context.Account)"
            }
        }
        catch {
            Write-Error "An error occurred while testing the Azure connection: $_"
        }
        # Ensure the user is logged in to Azure
        try {
            $account = az account show 2>$null | ConvertFrom-Json
            if ($account) {
                Write-Output "Logged in as: $($account.user.name)"
            }
        } catch {
            Write-Output "Not logged in. Run 'az login'."
            if($UseManageIdentity){
                az login --Identity  | Out-Null
            } else {    
                az login  | Out-Null
            }
        }
    }
    function LoadAzModules {
        param(
            [Parameter(Mandatory)][string]$SubscriptionId,
            [Parameter(Mandatory)][string]$ResourceGroupName,
            [Parameter(Mandatory)][string]$AutomationAccountName
        )
        
        
        # List of modules to import from PSGallery
        $modules = @(
            'AzureAD',
            'Az.Accounts',
            'Az.ConnectedMachine',
            'Az.ResourceGraph'
        )
        try {
            $existing = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                -AutomationAccountName $AutomationAccountName -Name $mod -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Output "Removing existing Automation module '$mod'..." -ForegroundColor Magenta
                Remove-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName -Name $mod -Force
                    Write-Output "  → Removed '$mod'." -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Could not check/remove existing module '$mod': $_"
        }

        foreach ($mod in $modules) {
            # Remove existing module from Automation account, if present
            try {
                $existing = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName -Name $mod -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Output "Removing existing Automation module '$mod'..." -ForegroundColor Magenta
                    Remove-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                        -AutomationAccountName $AutomationAccountName -Name $mod -Force
                        Write-Output "  → Removed '$mod'." -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Could not check/remove existing module '$mod': $_"
            }
            Write-Output "Resolving latest version for module '$mod' from PowerShell Gallery..." -ForegroundColor Yellow
            try {
                $info = Find-Module -Name $mod -Repository PSGallery -ErrorAction Stop
                $version = $info.Version.ToString()
                $contentUri = "https://www.powershellgallery.com/api/v2/package/$mod/$version"
                Write-Output "Importing '$mod' version $version into Automation account..." -ForegroundColor Cyan
                Import-AzAutomationModule `
                    -ResourceGroupName     $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName `
                    -Name                  $mod `
                    -ContentLinkUri        $contentUri `
                    -RuntimeVersion    5.1 `
                    -ErrorAction Stop | Out-Null
                    
                    Import-AzAutomationModule `
                    -ResourceGroupName     $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName `
                    -Name                  $mod `
                    -ContentLinkUri        $contentUri `
                    -RuntimeVersion    7.2 `
                    -ErrorAction Stop | Out-Null
        
                Write-Output "  → Queued '$mod' v$version for import." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to import module '$mod': $_"
            }
        }
        
        Write-Output "All specified modules have been queued for import. Check the Automation account in the portal for status." -ForegroundColor Cyan
        }
# Connect to Azure.
Write-Output "Connecting to Azure..."
Connect-Azure
$context = Get-AzContext -ErrorAction Stop
if ($null -ne $targetSubscription -and $targetSubscription -ne $context.Subscription.Id -and $targetSubscription -ne "") {
    $context = Set-AzContext -Subscription  $targetSubscription -ErrorAction Stop
}

# Check if the resource group exists; if not, create it.
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating Resource Group '$ResourceGroupName' in region '$Location'..."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location  | Out-Null
}
else {
    Write-Output "Resource Group '$ResourceGroupName' already exists."
}

# Check if the Automation Account exists; if not, create it.
$automationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -ErrorAction SilentlyContinue
if ($null -eq $automationAccount) {
    Write-Output "Automation Account '$AutomationAccountName' not found. Creating it..."
    $automationAccount = New-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName -Location $Location -AssignSystemIdentity 
} else {
    Write-Output "Automation Account '$AutomationAccountName' already exists."
}
if (-not (Get-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name 'Az.ResourceGraph')) {
    Import-AzAutomationModule `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Name 'Az.ResourceGraph' `
    -ContentLinkUri "https://www.powershellgallery.com/packages/Az.ResourceGraph/1.2.0"
    -ErrorAction Stop
}
LoadAzModules -SubscriptionId $context.Subscription.Id -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
# Assign roles to the Automation Account's system-assigned managed identity.
$principalId = $automationAccount.Identity.PrincipalId
$Scope = "/subscriptions/$($context.Subscription.Id)"
Write-Output $principalId 
if ($null -eq $principalId) {
    Write-Output "The Automation Account does not have a system-assigned managed identity enabled." -ForegroundColor Yellow
    exit
} else {
    Write-Output "Automation Account Object ID (PrincipalId): $principalId" -ForegroundColor Green
    foreach ($assignment in $roleAssignments) {
        $roleName = $assignment.RoleName
        
        try {
            if($null -eq (Get-AzRoleAssignment -ObjectId $principalId -RoleDefinitionName $roleName  -Scope $Scope)) {
                Write-Output "Assigning role '$roleName' to Managed Identity '$AutomationAccountName' at scope '$Scope'..." -ForegroundColor Yellow
                New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionName $roleName -Scope "/subscriptions/$($context.Subscription.Id)"   -ErrorAction Stop  | Out-Null
                Write-Output "Role '$roleName' assigned successfully." -ForegroundColor Green
                continue
            }
            
        }
        catch {
            Write-Error "Failed to assign role '$roleName': $_"
        }
    }
}
$downloadFolder = './manage-payg-transition/'
# Import the runbook into the Automation Account.
if ((Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -ErrorAction SilentlyContinue)) {
    Write-Output "Removing old Runbook '$RunbookName' from Automation Account '$AutomationAccountName'..."
    Remove-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name $RunbookName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue | Out-Null
}
if (-not (Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -ErrorAction SilentlyContinue)) {
    Write-Output "Importing Runbook '$RunbookName' from file '$RunbookPath' into Automation Account '$AutomationAccountName'..."
    Import-AzAutomationRunbook -AutomationAccountName $AutomationAccountName `
        -Name $RunbookName `
        -ResourceGroupName $ResourceGroupName `
        -Path "$($downloadFolder)$($RunbookPath)" `
        -Type $RunbookType `
        -Force `
        -Published `
        -LogProgress $True   | Out-Null
    }


# Create a daily schedule for the runbook (if it doesn't exist).
$ScheduleName = "$($RunbookName)_defaultschedule"
if (-not (Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ErrorAction SilentlyContinue)) {
    Remove-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ErrorAction SilentlyContinue -Force | Out-Null
}
if (-not (Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating schedule '$ScheduleName'..."
    # Set the schedule to start 5 minutes from now and expire in one year, with daily frequency.
    New-AzAutomationSchedule `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Name $ScheduleName `
        -StartTime (Get-Date).AddDays(1)`
        -WeekInterval 1 `
        -DaysOfWeek @([System.DayOfWeek]::Monday..[System.DayOfWeek]::Sunday) `
        -TimeZone 'UTC' `
        -Description 'Default schedule for runbook'   | Out-Null
} 


# Link the schedule to the runbook, including the sample parameters.
Write-Output "Assigning schedule '$ScheduleName' to runbook '$RunbookName' with sample parameters..."
Register-AzAutomationScheduledRunbook `
    -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $ResourceGroupName `
    -RunbookName $RunbookName `
    -ScheduleName $ScheduleName `
    -Parameters $RunbookArg  | Out-Null

Start-AzAutomationRunbook `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Name $RunbookName `
    -Parameters $RunbookArg `
    -ErrorAction SilentlyContinue | Out-Null

Write-Output "Runbook '$RunbookName' has been imported and published successfully."

'@

# === Configuration ===
# NOTE: The Azure SQL, Arc SQL, and Automation-runbook logic below is embedded directly
# (see the $EmbeddedScripts hashtable above) - nothing is downloaded from the internet.
$scriptFiles = @{
    General = @{
        FileName = "set-azurerunbook.ps1"
    }
    Azure = @{
        FileName = "modify-azure-sql-license-type.ps1"
        Args = @{
            LicenseType = $azureLicenseType
            SubId = [string]$targetSubscription
            ResourceGroup = [string]$targetResourceGroup
            TenantId = [string]$TenantId
            ReportOnly = [bool]$ReportOnly
        }
    }
    Arc   = @{
        FileName = "modify-arc-sql-license-type.ps1"
        Args =@{
            LicenseType= $arcLicenseType
            Force = $true
            UsePcoreLicense=[string]$UsePcoreLicense
            SubId = [string]$targetSubscription
            ResourceGroup = [string]$targetResourceGroup
            TenantId = [string]$TenantId
            ReportOnly = [bool]$ReportOnly
        }
   }
}
# Define a dedicated work folder for materializing the embedded scripts to disk.
# (Azure Automation runbook import and local invocation both require an actual file
# on disk; they cannot consume an in-memory string/function directly.)
$downloadFolder = './manage-payg-transition/'
# Ensure destination folder exists
if (-not (Test-Path $downloadFolder)) {
    Write-Host "Creating folder: $downloadFolder"
    New-Item -Path $downloadFolder -ItemType Directory -Force | Out-Null
}

# Writes the embedded script content for the given key (Arc/Azure/General) to a
# local file and returns its path. Replaces the old "download from GitHub" step.
function Write-EmbeddedScript {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Arc","Azure","General")]
        [string]$Key
    )
    $fileName = $scriptFiles[$Key].FileName
    $dest     = Join-Path $downloadFolder $fileName
    Write-Host "Writing embedded script '$fileName' to $dest..."
    Set-Content -Path $dest -Value $EmbeddedScripts[$Key] -Encoding UTF8
    return $dest
}

# Helper to materialize the General runbook script and invoke it (Scheduled mode)
function Invoke-RemoteScript {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Arc","Azure","Both")]
        [string]$Target,
        [Parameter(Mandatory)]
        [ValidateSet("Single","Scheduled")]
        [string]$RunMode
    )
    $dest = Write-EmbeddedScript -Key General

    $scriptname = $dest
    $wrapper = @()
    $wrapper += @"
    `$ResourceGroupName= '$($AutomationAccResourceGroupName)'
    `$AutomationAccountName= '$AutomationAccountName' 
    `$Location= '$Location'
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "`$targetResourceGroup= '$targetResourceGroup'" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "`$targetSubscription= '$targetSubscription'" })
"@
    if($Target -eq "Both" -or $Target -eq "Arc") {

        $null = Write-EmbeddedScript -Key Arc
        $null = Write-EmbeddedScript -Key Azure

        $nextline = if(($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") -or ($null -ne $targetSubscription -and $targetSubscription -ne "")) {"`` "}
        $nextline2 = if(($null -ne $targetSubscription -and $targetSubscription -ne "")){"`` "}
        $wrapper += @"
`$RunbookArg =@{
LicenseType= '$arcLicenseType'
Force = `$true
$(if ($null -ne $UsePcoreLicense) { "UsePcoreLicense='$UsePcoreLicense'" } else { "" })
$(if ($null -ne $TenantId -and $TenantId -ne "") { "TenantId='$TenantId'" })
$(if ($ReportOnly) { "ReportOnly=`$true" })
$(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "SubId='$targetSubscription'" })
$(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "ResourceGroup='$targetResourceGroup'" })
}

    $scriptname -ResourceGroupName `$ResourceGroupName -AutomationAccountName `$AutomationAccountName -Location `$Location -RunbookName 'ModifyLicenseTypeArc' ``
    -RunbookPath '$($scriptFiles.Arc.FileName)' ``
    -RunbookArg `$RunbookArg $($nextline)
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "-targetResourceGroup `$targetResourceGroup $nextline2" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "-targetSubscription `$targetSubscription" })
"@

    }

    if($Target -eq "Both" -or $Target -eq "Azure") {

        $null = Write-EmbeddedScript -Key Azure

        $nextline = if(($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") -or ($null -ne $targetSubscription -and $targetSubscription -ne "")) {"`` "}
        $nextline2 = if(($null -ne $targetSubscription -and $targetSubscription -ne "")){"`` "}
        $wrapper += @"
`$RunbookArg =@{
    LicenseType= '$azureLicenseType'
    $(if ($null -ne $TenantId -and $TenantId -ne "") { "TenantId= '$TenantId'" })
    $(if ($ReportOnly) { "ReportOnly= `$true" })
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "ResourceGroup= '$targetResourceGroup'" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "SubId= '$targetSubscription'" })

}

$scriptname     -ResourceGroupName `$ResourceGroupName -AutomationAccountName `$AutomationAccountName -Location `$Location -RunbookName 'ModifyLicenseTypeAzure' ``
    -RunbookPath '$($scriptFiles.Azure.FileName)' ``
    -RunbookArg `$RunbookArg $($nextline)
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "-targetResourceGroup `$targetResourceGroup $nextline2" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "-targetSubscription `$targetSubscription" })
        
"@

    }
    $wrapper | Out-File -FilePath './runnow.ps1' -Encoding UTF8
    .\runnow.ps1
}

# === Single run: materialize & invoke the appropriate script(s) ===
if($RunMode -eq "Single") {
    $wrapper = @()
    if ($Target -eq "Both" -or $Target -eq "Arc") {
        $dest = Write-EmbeddedScript -Key Arc

        $lines = @("$dest")
        foreach ($arg in $scriptFiles.Arc.Args.Keys) {
            $val = $scriptFiles.Arc.Args[$arg]
            if ($val -is [bool]) {
                # Switch parameters (e.g. -Force) take no value; PowerShell would
                # otherwise bind a literal 'True'/'False' token to the next
                # positional parameter instead of the switch.
                if ($val) { $lines += "-$($arg)" }
            } elseif ("" -ne $val) {
                $lines += "-$($arg) '$($val)'"
            }
        }
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -lt $lines.Count - 1) {
                $wrapper += "$($lines[$i]) ``"
            } else {
                $wrapper += $lines[$i]
            }
        }
    }

    if ($Target -eq "Both" -or $Target -eq "Azure") {
        $dest = Write-EmbeddedScript -Key Azure

        $lines = @("$dest")
        foreach ($arg in $scriptFiles.Azure.Args.Keys) {
            $val = $scriptFiles.Azure.Args[$arg]
            if ($val -is [bool]) {
                if ($val) { $lines += "-$($arg)" }
            } elseif ("" -ne $val) {
                $lines += "-$($arg) '$($val)'"
            }
        }
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -lt $lines.Count - 1) {
                $wrapper += "$($lines[$i]) ``"
            } else {
                $wrapper += $lines[$i]
            }
        }
    }

    $wrapper | Out-File -FilePath './runnow.ps1' -Encoding UTF8 
    .\runnow.ps1

    Write-Host "Single run completed."
}else{
    Write-Host "Run 'Scheduled'."
    Invoke-RemoteScript -Target $Target -RunMode $RunMode
}
# === Cleanup materialized files & folder ===
if($cleanDownloads -eq $true) {
    if (Test-Path $downloadFolder) {
        Write-Host "Cleaning up materialized scripts in $downloadFolder..."
        try {
            Remove-Item -Path $downloadFolder -Recurse -Force
            Write-Host "Cleanup successful: removed $downloadFolder"
        }
        catch {
            Write-Warning "Cleanup failed: $_"
        }
    }
}
