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

.PARAMETER WaitForCompletion
    Optional. If specified, waits for each update to reach a terminal state before continuing
    and reports the confirmed outcome ("Updated"). By default the script submits updates with
    --no-wait and reports "RequestSubmitted", meaning the service accepted the request rather
    than that the change has been applied.

    Note: Set-AzDataFactoryV2IntegrationRuntime provides no asynchronous option, so SSIS
    integration runtimes always wait regardless of this switch and always report "Updated".
    SQL virtual machines are submitted asynchronously through a direct ARM request because
    'az sql vm update' has no --no-wait option; see Invoke-SqlVmLicenseUpdate.
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
    [switch] $WaitForCompletion,
    
    [Parameter (Mandatory= $false)]
    [string] $ResourceName,

    [Parameter (Mandatory= $false)]
    [switch] $NoSummary
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

    By default updates are submitted with --no-wait so a large estate is not
    processed serially; the caller then records "RequestSubmitted" rather than
    "Updated", because the service has only accepted the request at that point.
    Passing -WaitForCompletion to the script omits --no-wait, making the CLI poll
    the operation to a terminal state so the outcome is confirmed.
.PARAMETER SupportsNoWait
    Set for commands that accept --no-wait. 'az sql vm update' does not; SQL VMs are
    submitted asynchronously through Invoke-SqlVmLicenseUpdate instead.
#>
function Invoke-AzCliLicenseUpdate {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description,
        [switch]$SupportsNoWait
    )

    $effectiveArgs = @($Arguments)
    $submittedOnly = $false
    if ($SupportsNoWait -and -not $WaitForCompletion) {
        $effectiveArgs += '--no-wait'
        $submittedOnly = $true
    }

    $output = & az @effectiveArgs 2>&1

    if ($LASTEXITCODE -ne 0) {
        $message = ($output | Out-String).Trim()
        Write-Warning "Failed to update $Description`: $message"
        return [PSCustomObject]@{ Success = $false; Result = $null; ErrorMessage = $message; Submitted = $submittedOnly }
    }

    # --no-wait produces no output, so only attempt to parse when something came back.
    $parsed = $null
    $raw = ($output | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        try { $parsed = $raw | ConvertFrom-Json } catch { $parsed = $raw }
    }

    # Note: this function must not write to the success stream. Anything emitted there
    # would be merged into the return value, turning it into an array and hiding the
    # message from the caller. Callers log their own success line.
    return [PSCustomObject]@{ Success = $true; Result = $parsed; ErrorMessage = ""; Submitted = $submittedOnly }
}


<#
.SYNOPSIS
    Runs a read-only Azure CLI query and reports failures instead of silently returning nothing.
.DESCRIPTION
    Discovery calls used to be piped straight into ConvertFrom-Json. The Azure CLI signals
    failure through $LASTEXITCODE rather than by throwing, so a failed query produced $null,
    which every caller then treated as "no resources found". A transient error therefore looked
    exactly like an empty result and the affected resources were skipped without any indication
    that they had not actually been examined.

    This wrapper checks the exit code, surfaces the real service error as a warning, and returns
    the parsed value normalised to an array so callers can use .Count safely.
#>
function Invoke-AzCliQuery {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $output = & az @Arguments 2>&1

    if ($LASTEXITCODE -ne 0) {
        $message = ($output | Out-String).Trim()
        Write-Warning "Unable to query $Description`: $message"
        return [PSCustomObject]@{ Success = $false; Value = @(); ErrorMessage = $message }
    }

    $raw = ($output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [PSCustomObject]@{ Success = $true; Value = @(); ErrorMessage = "" }
    }

    try { $parsed = $raw | ConvertFrom-Json }
    catch {
        Write-Warning "Unable to parse the response for $Description`: $($_.Exception.Message)"
        return [PSCustomObject]@{ Success = $false; Value = @(); ErrorMessage = $_.Exception.Message }
    }

    # Normalise to an array so .Count is meaningful for both single objects and empty results.
    return [PSCustomObject]@{ Success = $true; Value = @($parsed); ErrorMessage = "" }
}


<#
.SYNOPSIS
    Updates the license type of a SQL virtual machine, asynchronously by default.
.DESCRIPTION
    'az sql vm update' has no --no-wait option and blocks until the operation reaches a
    terminal state, which for a SQL VM is typically around two minutes per resource.
    Update-AzSqlVM advertises -NoWait and -AsJob but both are broken in
    Az.SqlVirtualMachine 2.4.0 (-NoWait forwards the bound parameter into Get-AzSqlVM,
    which rejects it; -AsJob throws a NullReferenceException).

    To honour the script's async-by-default contract this function talks to ARM directly:
    it reads the resource, changes only sqlServerLicenseType and writes it back. ARM
    accepts the request and returns an Azure-AsyncOperation header without waiting for the
    provisioning to finish, so the call returns in seconds instead of minutes.

    When -WaitForCompletion is passed, or if the ARM round trip fails for any reason, the
    original synchronous 'az sql vm update' path is used so behaviour degrades safely.
#>
function Invoke-SqlVmLicenseUpdate {
    param(
        [Parameter(Mandatory = $true)][string]$ResourceId,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$LicenseType
    )

    $cliArguments = @('sql','vm','update','-n',$Name,'-g',$ResourceGroup,'--license-type',$LicenseType,'-o','json')

    if ($WaitForCompletion) {
        return Invoke-AzCliLicenseUpdate -Description "SQL VM '$Name'" -Arguments $cliArguments
    }

    $apiVersion = '2023-10-01'
    $path = "$ResourceId`?api-version=$apiVersion"

    try {
        $get = Invoke-AzRestMethod -Path $path -Method GET -ErrorAction Stop
        if ($get.StatusCode -ne 200) {
            throw "GET returned HTTP $($get.StatusCode): $($get.Content)"
        }

        # Read-modify-write: the payload is the body ARM just returned with a single
        # property changed, so no unrelated settings are dropped by the PUT.
        $resource = $get.Content | ConvertFrom-Json
        $resource.properties.sqlServerLicenseType = $LicenseType

        $put = Invoke-AzRestMethod -Path $path -Method PUT -Payload ($resource | ConvertTo-Json -Depth 30) -ErrorAction Stop
        if ($put.StatusCode -ge 400) {
            throw "PUT returned HTTP $($put.StatusCode): $($put.Content)"
        }

        $parsed = $null
        if (-not [string]::IsNullOrWhiteSpace($put.Content)) {
            try { $parsed = $put.Content | ConvertFrom-Json } catch { $parsed = $put.Content }
        }

        return [PSCustomObject]@{ Success = $true; Result = $parsed; ErrorMessage = ""; Submitted = $true }
    }
    catch {
        Write-Warning "Asynchronous update of SQL VM '$Name' failed ($($_.Exception.Message)). Falling back to the synchronous 'az sql vm update' path."
        return Invoke-AzCliLicenseUpdate -Description "SQL VM '$Name'" -Arguments $cliArguments
    }
}


function Format-ExecutionOutcomeSummary {
    param(
        [Parameter(Mandatory = $false)]
        [array]$TrackedResources = @(),
        [Parameter(Mandatory = $false)]
        [bool]$IsReportOnly = $false
    )

    Write-Output "`n========================================================================"
    Write-Output "                       EXECUTION OUTCOME SUMMARY                        "
    Write-Output "========================================================================"

    if ($TrackedResources.Count -eq 0) {
        Write-Output "No resources qualified for license transition or modification."
        Write-Output "========================================================================`n"
        return
    }

    $friendlyTypes = [ordered]@{
        "Microsoft.Sql/virtualMachines"                       = "SQL Virtual Machines"
        "Microsoft.Sql/servers/databases"                     = "SQL Databases"
        "Microsoft.Sql/servers/elasticPools"                  = "SQL Elastic Pools"
        "Microsoft.Sql/managedInstances"                      = "SQL Managed Instances"
        "Microsoft.Sql/instancePools"                         = "SQL Instance Pools"
        "Microsoft.DataFactory/factories/integrationRuntimes" = "SSIS Integration Runtimes"
        "Microsoft.AzureArcData/SqlServerInstances"           = "Arc SQL Server Instances"
        "Microsoft.HybridCompute/machines/extensions"         = "Arc SQL Server (HybridCompute)"
        "WindowsAgent.SqlServer"                              = "Arc SQL Server Extension (Windows)"
        "LinuxAgent.SqlServer"                                = "Arc SQL Server Extension (Linux)"
    }

    $grouped = $TrackedResources | Group-Object -Property ResourceType

    $summaryRows = @()
    foreach ($grp in $grouped) {
        $rType = $grp.Name
        $friendlyName = if ($friendlyTypes.Contains($rType)) { $friendlyTypes[$rType] } else { $rType }
        
        $totalQualified = $grp.Count
        $updatedCount = @($grp.Group | Where-Object { $_.UpdateResult -in @("Updated", "RequestSubmitted", "Succeeded", "SubmittedAsync", "ReportOnly") }).Count
        $failedCount = @($grp.Group | Where-Object { $_.UpdateResult -in @("Failed", "TimedOut") }).Count
        $skippedCount = @($grp.Group | Where-Object { $_.UpdateResult -like "Skipped*" -or $_.UpdateResult -eq "NotAttempted" }).Count

        $summaryRows += [PSCustomObject]@{
            "ResourceType"                = $friendlyName
            "Qualified"                   = $totalQualified
            "Updated or RequestSubmitted" = if ($IsReportOnly) { "$updatedCount (ReportOnly)" } else { $updatedCount }
            "Failed"                      = $failedCount
            "Skipped"                     = $skippedCount
        }
    }

    $summaryRows = $summaryRows | Sort-Object -Property ResourceType

    $summaryRows | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() } | Write-Output

    # Check for failures and skips
    $issues = $TrackedResources | Where-Object { $_.UpdateResult -in @("Failed", "TimedOut") -or $_.UpdateResult -like "Skipped*" }

    Write-Output "------------------------------------------------------------------------"
    Write-Output "                      FAILURE & SKIP ROOT CAUSES                        "
    Write-Output "------------------------------------------------------------------------"

    if ($issues.Count -eq 0) {
        Write-Output "No failures or skipped resources encountered."
    } else {
        $issueRows = @()
        foreach ($item in $issues) {
            $rType = $item.ResourceType
            $friendlyName = if ($friendlyTypes.Contains($rType)) { $friendlyTypes[$rType] } else { $rType }
            $cause = if (-not [string]::IsNullOrWhiteSpace($item.UpdateError)) {
                $item.UpdateError
            } elseif ($item.UpdateResult -eq "SkippedNotRunning") {
                "Underlying VM is deallocated / stopped. Azure requires the VM to be running to update license type."
            } elseif ($item.UpdateResult -eq "SkippedDR") {
                "Resource has Disaster Recovery (DR) license configured."
            } elseif ($item.UpdateResult -eq "SkippedTags") {
                "Resource matched exclusion tags."
            } elseif ($item.UpdateResult -eq "SkippedNotStopped") {
                "Integration Runtime is not in stopped state."
            } else {
                "Unknown reason ($($item.UpdateResult))"
            }

            $issueRows += [PSCustomObject]@{
                "Resource Name"  = $item.ResourceName
                "Resource Group" = $item.ResourceGroup
                "ResourceType"   = $friendlyName
                "Outcome"        = $item.UpdateResult
                "Root Cause"     = $cause
            }
        }
        $issueRows = $issueRows | Sort-Object -Property ResourceType, "Resource Name"
        $issueRows | Format-Table -AutoSize -Wrap | Out-String | ForEach-Object { $_.TrimEnd() } | Write-Output
    }
    Write-Output "========================================================================`n"
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
        if ($LASTEXITCODE -ne 0) {
            # Every az call below is scoped by the CLI's active subscription. If the switch
            # fails they would all silently run against whichever subscription was previously
            # selected, so resources in the wrong subscription could be updated.
            Write-Warning "Skipping subscription '$($sub.name)' ($($sub.id)): the Azure CLI context could not be switched to it."
            continue
        }

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
            $sqlVmQueryResult = Invoke-AzCliQuery -Description "SQL virtual machines" -Arguments @('sql','vm','list','--query',$sqlVmQuery,'-o','json')
            if (-not $sqlVmQueryResult.Success) {
                Write-Warning "SQL virtual machines could not be listed, so none were assessed in this subscription. Re-run to retry."
            }
            $sqlVMs = $sqlVmQueryResult.Value
            $sqlVmsToUpdate = [System.Collections.ArrayList]::new()
            if($sqlVMs.Count -eq 0) {
                Write-Output "No SQL VMs found that require a license update."
            } else {
                Write-Output "Found $($sqlVMs.Count) SQL VMs that require a license update."
            }
            foreach ($sqlvm in $sqlVMs) {

                if($null -ne (az vm list --query "[?name=='$($sqlvm.name)' && resourceGroup=='$($sqlvm.resourceGroup)' $tagsFilter]"))
                {
                    $vmStatusQuery = Invoke-AzCliQuery -Description "power state of VM '$($sqlvm.name)'" -Arguments @(
                        'vm','get-instance-view','--resource-group',$sqlvm.resourceGroup,'--name',$sqlvm.name,
                        '--query',"{Name:name, ResourceGroup:resourceGroup, PowerState:instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]}",'-o','json')
                    if (-not $vmStatusQuery.Success) {
                        # Without a power state the VM would silently fail the "VM running" test
                        # below and be skipped as though it were switched off.
                        Write-Warning "Skipping SQL VM '$($sqlvm.name)': its power state could not be read, so it was not assessed. Re-run to retry."
                        $modifiedResources += [PSCustomObject]@{
                            TenantID            = $TenantId
                            SubID               = ($sqlvm.id -split '/')[2]
                            ResourceName        = $sqlvm.name
                            ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                            Status              = "UnknownPowerState"
                            OriginalLicenseType = $sqlvm.sqlServerLicenseType
                            ResourceGroup       = $sqlvm.resourceGroup
                            Location            = $sqlvm.Location
                            UpdateResult        = "Failed"
                            UpdateError         = "Power state could not be read"
                        }
                        continue
                    }
                    $vmStatus = $vmStatusQuery.Value | Select-Object -First 1
                    if (($vmStatus.PowerState -eq "VM running") -and ($sqlvm.sqlServerLicenseType -ne "DR")) {

                        $vmResult = "NotAttempted"
                        $vmError = ""

                        if ($ReportOnly) {
                            $vmResult = "ReportOnly"
                            Write-Output "ReportOnly mode enabled. Skipping modification for SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' (would change '$($sqlvm.sqlServerLicenseType)' -> '$SqlVmLicenseType')."
                        } else {
                            Write-Output "Updating SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' to license type '$SqlVmLicenseType'..."
                            $update = Invoke-SqlVmLicenseUpdate -ResourceId $sqlvm.id -Name $sqlvm.name -ResourceGroup $sqlvm.resourceGroup -LicenseType $SqlVmLicenseType
                            if ($update.Success) {
                                $finalStatus += $update.Result
                                $vmResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                                Write-Output "-- SQL VM '$($sqlvm.name)': $vmResult (license type '$SqlVmLicenseType')"
                            }
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
                    elseif ($vmStatus.PowerState -ne "VM running") {
                        Write-Output "SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' is in '$($vmStatus.PowerState)' state (not running). Skipping update..."
                        $modifiedResources += [PSCustomObject]@{
                            TenantID            = $TenantId
                            SubID               = ($sqlvm.id -split '/')[2]
                            ResourceName        = $sqlvm.name
                            ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                            Status              = $vmStatus.PowerState
                            OriginalLicenseType = $sqlvm.sqlServerLicenseType
                            ResourceGroup       = $sqlvm.resourceGroup
                            Location            = $sqlvm.Location
                            UpdateResult        = "SkippedNotRunning"
                            UpdateError         = "Underlying VM is in '$($vmStatus.PowerState)' state (must be running to update license)"
                        }
                    }
                    elseif ($sqlvm.sqlServerLicenseType -eq "DR") {
                        Write-Output "SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' has license type 'DR'. Skipping update..."
                        $modifiedResources += [PSCustomObject]@{
                            TenantID            = $TenantId
                            SubID               = ($sqlvm.id -split '/')[2]
                            ResourceName        = $sqlvm.name
                            ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                            Status              = $vmStatus.PowerState
                            OriginalLicenseType = $sqlvm.sqlServerLicenseType
                            ResourceGroup       = $sqlvm.resourceGroup
                            Location            = $sqlvm.Location
                            UpdateResult        = "SkippedDR"
                            UpdateError         = "SQL VM has Disaster Recovery ('DR') license type"
                        }
                    }
                }
                else {
                    Write-Output "SQL VM '$($sqlvm.name)' in RG '$($sqlvm.resourceGroup)' Skipping because of tags..."
                    $modifiedResources += [PSCustomObject]@{
                        TenantID            = $TenantId
                        SubID               = ($sqlvm.id -split '/')[2]
                        ResourceName        = $sqlvm.name
                        ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                        Status              = "SkippedTags"
                        OriginalLicenseType = $sqlvm.sqlServerLicenseType
                        ResourceGroup       = $sqlvm.resourceGroup
                        Location            = $sqlvm.Location
                        UpdateResult        = "SkippedTags"
                        UpdateError         = "Excluded by tags filter"
                    }
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
            $miQueryResult = Invoke-AzCliQuery -Description "SQL Managed Instances" -Arguments @('sql','mi','list','--query',$miRunningQuery,'-o','json')
            if (-not $miQueryResult.Success) {
                Write-Warning "SQL Managed Instances could not be listed, so none were assessed in this subscription. Re-run to retry."
            }
            $runningMIs = $miQueryResult.Value
            if($runningMIs.Count -eq 0) {
                Write-Output "No SQL Managed Instances found that require a license update."
            } else {
                Write-Output "Found $($runningMIs.Count) SQL Managed Instances that require a license update."
            }
            foreach ($mi in $runningMIs) {

                $miResult = "NotAttempted"
                $miError = ""

                if ($ReportOnly) {
                    $miResult = "ReportOnly"
                    Write-Output "ReportOnly mode enabled. Skipping modification for SQL Managed Instance '$($mi.name)' in RG '$($mi.resourceGroup)' (would change '$($mi.licenseType)' -> '$LicenseType')."
                } else {
                    Write-Output "Updating SQL Managed Instance '$($mi.name)' in RG '$($mi.resourceGroup)' to license type '$LicenseType'..."
                    $update = Invoke-AzCliLicenseUpdate -Description "SQL Managed Instance '$($mi.name)'" -SupportsNoWait -Arguments @(
                        'sql','mi','update','--name',$mi.name,'--resource-group',$mi.resourceGroup,'--license-type',$LicenseType,'-o','json')
                    if ($update.Success) {
                        $finalStatus += $update.Result
                        $miResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                        Write-Output "-- SQL Managed Instance '$($mi.name)': $miResult (license type '$LicenseType')"
                    }
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
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Could not re-select subscription '$($sub.id)'; skipping SQL Server, database and elastic pool processing to avoid querying the wrong subscription."
                    throw "Subscription context could not be set to '$($sub.id)'."
                }
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
            $allServersQuery = Invoke-AzCliQuery -Description "SQL Servers in the subscription" -Arguments @('sql','server','list','-o','json')
            $allServers = $allServersQuery.Value
             Write-Output   "Found a total of $($allServers.Count) SQL Servers in subscription"
            
            # Now try the filtered query
            $serversQuery = Invoke-AzCliQuery -Description "SQL Servers matching the specified filters" -Arguments @('sql','server','list','--query',"$serverQuery",'-o','json')
            if (-not $serversQuery.Success) {
                # Distinguish a failed lookup from a genuinely empty one: falling through here
                # would print "No SQL Servers found" and skip every database and elastic pool
                # in the subscription as though there were nothing to do.
                Write-Warning "SQL Servers could not be listed, so no databases or elastic pools were assessed in this subscription. Re-run to retry."
                $servers = @()
            } else {
                $servers = $serversQuery.Value
            }
            
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
                $allDbsQuery = Invoke-AzCliQuery -Description "databases on server '$($server.name)'" -Arguments @(
                    'sql','db','list','--resource-group',$server.resourceGroup,'--server',$server.name,'-o','json')
                if (-not $allDbsQuery.Success) {
                    Write-Warning "Skipping server '$($server.name)': its databases could not be listed, so they cannot be assessed. Re-run to retry."
                    continue
                }
                $allDbs = $allDbsQuery.Value
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
                    $dbsQuery = Invoke-AzCliQuery -Description "databases requiring an update on server '$($server.name)'" -Arguments @(
                        'sql','db','list','--resource-group',$server.resourceGroup,'--server',$server.name,'--query',"$dbQuery",'-o','json')
                    if (-not $dbsQuery.Success) {
                        Write-Warning "Skipping server '$($server.name)': its databases could not be assessed for a license update. Re-run to retry."
                        continue
                    }
                    $dbs = $dbsQuery.Value
                    
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

                            if ($ReportOnly) {
                                $dbResult = "ReportOnly"
                                Write-Output "ReportOnly mode enabled. Skipping modification for SQL Database '$($db.name)' on server '$($server.name)' (would change '$($db.licenseType)' -> '$LicenseType')."
                            } else {
                                 Write-Output   "Updating SQL Database '$($db.name)' on server '$($server.name)' to license type '$LicenseType'..."
                                $update = Invoke-AzCliLicenseUpdate -Description "SQL Database '$($db.name)' on server '$($server.name)'" -SupportsNoWait -Arguments @(
                                    'sql','db','update','--name',$db.name,'--server',$server.name,'--resource-group',$server.resourceGroup,'--set',"licenseType=$LicenseType",'-o','json')
                                if ($update.Success) {
                                    $finalStatus += $update.Result
                                    $dbResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                                    Write-Output "-- SQL Database '$($db.name)': $dbResult (license type '$LicenseType')"
                                }
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
                    $allPoolsQuery = Invoke-AzCliQuery -Description "elastic pools on server '$($server.name)'" -Arguments @(
                        'sql','elastic-pool','list','--resource-group',$server.resourceGroup,'--server',$server.name,'--only-show-errors','-o','json')
                    if (-not $allPoolsQuery.Success) {
                        Write-Warning "Elastic pools on server '$($server.name)' could not be listed and were not assessed. Re-run to retry."
                        $allPools = @()
                    } else {
                        $allPools = $allPoolsQuery.Value
                    }
                    
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
                        
                        $elasticPoolsQueryResult = Invoke-AzCliQuery -Description "elastic pools requiring an update on server '$($server.name)'" -Arguments @(
                            'sql','elastic-pool','list','--resource-group',$server.resourceGroup,'--server',$server.name,'--query',"$elasticPoolQuery",'--only-show-errors','-o','json')
                        if (-not $elasticPoolsQueryResult.Success) {
                            Write-Warning "Elastic pools on server '$($server.name)' could not be assessed for a license update. Re-run to retry."
                        }
                        $elasticPools = $elasticPoolsQueryResult.Value
                        
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

                                if ($ReportOnly) {
                                    $poolResult = "ReportOnly"
                                    Write-Output "ReportOnly mode enabled. Skipping modification for Elastic Pool '$($pool.name)' on server '$($server.name)' (would change '$($pool.licenseType)' -> '$LicenseType')."
                                } else {
                                     Write-Output   "Updating Elastic Pool '$($pool.name)' on server '$($server.name)' to license type '$LicenseType'..."
                                    $update = Invoke-AzCliLicenseUpdate -Description "Elastic Pool '$($pool.name)' on server '$($server.name)'" -SupportsNoWait -Arguments @(
                                        'sql','elastic-pool','update','--name',$pool.name,'--server',$server.name,'--resource-group',$server.resourceGroup,'--set',"licenseType=$LicenseType",'--only-show-errors','-o','json')
                                    if ($update.Success) {
                                        $finalStatus += $update.Result
                                        $poolResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                                        Write-Output "-- Elastic Pool '$($pool.name)': $poolResult (license type '$LicenseType')"
                                    }
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
            
            $instancePoolsQueryResult = Invoke-AzCliQuery -Description "SQL instance pools" -Arguments @('sql','instance-pool','list','--query',$instancePoolsQuery,'-o','json')
            if (-not $instancePoolsQueryResult.Success) {
                Write-Warning "SQL instance pools could not be listed, so none were assessed in this subscription. Re-run to retry."
            }
            $instancePools = $instancePoolsQueryResult.Value
            $poolsToUpdate = $instancePools | Where-Object { $_.licenseType -ne $LicenseType }
            if($poolsToUpdate.Count -eq 0) {
                Write-Output "No SQL Instance Pools found that require a license update."
            } else {
                Write-Output "Found $($poolsToUpdate.Count) SQL Instance Pools that require a license update."
            }
            foreach ($pool in $poolsToUpdate) {

                $ipResult = "NotAttempted"
                $ipError = ""

                if ($ReportOnly) {
                    $ipResult = "ReportOnly"
                    Write-Output "ReportOnly mode enabled. Skipping modification for SQL Instance Pool '$($pool.name)' in RG '$($pool.resourceGroup)' (would change '$($pool.licenseType)' -> '$LicenseType')."
                } else {
                    Write-Output "Updating SQL Instance Pool '$($pool.name)' in RG '$($pool.resourceGroup)' to license type '$LicenseType'..."
                    $update = Invoke-AzCliLicenseUpdate -Description "SQL Instance Pool '$($pool.name)'" -SupportsNoWait -Arguments @(
                        'sql','instance-pool','update','--name',$pool.name,'--resource-group',$pool.resourceGroup,'--license-type',$LicenseType,'-o','json')
                    if ($update.Success) {
                        $finalStatus += $update.Result
                        $ipResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                        Write-Output "-- SQL Instance Pool '$($pool.name)': $ipResult (license type '$LicenseType')"
                    }
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

                        if ($ReportOnly) {
                            $irResult = "ReportOnly"
                            Write-Output "ReportOnly mode enabled. Skipping modification for DataFactory '$($df.DataFactoryName)' integration runtime '$($ir.Name)' (would change '$($ir.LicenseType)' -> '$LicenseType')."
                        } else {
                            if (-not [string]::IsNullOrEmpty($ResourceName) -and $ir.State -ne "Stopped") {
                                Write-Output "ADF Integration Service '$($ir.Name)' is not in stopped state"
                                $irResult = "SkippedNotStopped"
                                $irError = "Integration runtime is not in stopped state (must be stopped to update license)"
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

# Export tracked resources for orchestrator if running in orchestrated mode
if (Test-Path variable:global:PaygTrackedResources) {
    $global:PaygTrackedResources += $modifiedResources
}
$trackedOutPath = Join-Path (Get-Location) "manage-payg-transition\tracked_azure.json"
if ($modifiedResources.Count -gt 0) {
    try {
        $parentDir = Split-Path $trackedOutPath -Parent
        if (Test-Path $parentDir) {
            $modifiedResources | ConvertTo-Json -Depth 5 | Set-Content -Path $trackedOutPath -Encoding UTF8
        }
    } catch {}
} else {
    try {
        if (Test-Path $trackedOutPath) {
            Remove-Item -Path $trackedOutPath -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

if (-not $NoSummary) {
    # Print execution outcome summary and failure/skip root causes
    Format-ExecutionOutcomeSummary -TrackedResources $modifiedResources -IsReportOnly ([bool]$ReportOnly)
}

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
