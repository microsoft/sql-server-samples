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
      - AHUB             : Azure Hybrid Benefit (bring-your-own-license with Software Assurance).

.PARAMETER TenantId
    Azure AD tenant to operate against. If omitted, the tenant of the current
    Az PowerShell context ((Get-AzContext).Tenant.Id) is used. Specify this
    explicitly to avoid accidentally running against whichever tenant happens
    to be selected in the current session.

.PARAMETER ReportOnly
    Perform a read-only dry run: discover and report the resources that would be
    changed, without modifying any license types.

.PARAMETER WaitForCompletion
    Wait for each license change to reach a terminal state and report the confirmed
    outcome. By default updates are submitted asynchronously and the report records
    'RequestSubmitted', meaning the service accepted the request rather than that the
    change has been applied.

    Exception: SQL virtual machine updates are always synchronous, because Update-AzSqlVM
    must not be run asynchronously for SQL VMs (see Invoke-SqlVmLicenseUpdate). Using this
    switch makes runs substantially slower on large estates.

.PARAMETER AutomationAccResourceGroupName
    Required only when -RunMode is 'Scheduled'. Resource group for the Azure
    Automation Account that will host the recurring runbook. Not needed/used for
    -RunMode Single.

.PARAMETER Location
    Required only when -RunMode is 'Scheduled'. Azure region for the Automation
    Account/resource group. Not needed/used for -RunMode Single.

.PARAMETER Force
    Skip interactive confirmation prompts: install missing Az PowerShell modules and
    proceed with the currently connected Azure account/tenant without asking first.
    Required when running non-interactively (e.g. scheduled/unattended), since the
    script will otherwise stop and ask for confirmation.

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
    [switch]$WaitForCompletion,

    [Parameter(Mandatory=$false)]
    [string]$AutomationAccResourceGroupName=$null,

    [Parameter(Mandatory=$false)]
    [string]$AutomationAccountName="aaccAzureArcSQLLicenseType",

    [Parameter(Mandatory=$false)]
    [string]$Location=$null,

    [Parameter(Mandatory=$false)]
    [switch]$Force
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

# Heuristic for "is a human watching this run right now". A real interactive console has
# UserInteractive = $true and an attached (non-redirected) console input stream; scheduled/
# Automation/CI contexts typically fail at least one of these checks.
function Test-IsInteractiveSession {
    try {
        return [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
    } catch {
        return $false
    }
}

# Translate the simplified -TargetLicenseType switch into the vocabulary each
# embedded script expects:
#   - modify-azure-sql-license-type.ps1 expects "LicenseIncluded" (PAYG) or "BasePrice" (AHUB).
#   - modify-arc-sql-license-type.ps1 expects "PAYG" or "Paid" (AHUB/SA for Arc).
$azureLicenseType = if ($TargetLicenseType -eq "PAYG") { "LicenseIncluded" } else { "BasePrice" }
$arcLicenseType    = if ($TargetLicenseType -eq "PAYG") { "PAYG" } else { "Paid" }

# === Connect once here instead of letting each embedded script redundantly re-authenticate.
#     Az PowerShell's context is process-wide, so authenticating once means each embedded
#     script's own Connect-Azure call finds an already-valid context and skips straight past
#     its own login, instead of repeating that work.
if ($RunMode -eq "Single") {
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        if (-not $Force) {
            if (Test-IsInteractiveSession) {
                $response = Read-Host "The Az.Accounts PowerShell module is required but not installed. Install it now? (Y/N)"
                if ($response -notmatch '^(y|yes)$') {
                    throw "Az.Accounts module is required to continue. Install it manually, or re-run with -Force to install it automatically."
                }
            } else {
                throw "Az.Accounts module is required but not installed, and this session is not interactive. Re-run with -Force to install it automatically."
            }
        }
        Write-Output "Az.Accounts module not found. Installing..."
        Install-Module -Name Az.Accounts -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    }
    Import-Module Az.Accounts -Force

    $currentCtx = Get-AzContext -ErrorAction SilentlyContinue
    if ($currentCtx -and $currentCtx.Account -and ([string]::IsNullOrWhiteSpace($TenantId) -or $currentCtx.Tenant.Id -eq $TenantId)) {
        Write-Output "Reusing this session ($($currentCtx.Account), tenant $($currentCtx.Tenant.Id))."
        if (-not $Force) {
            if (Test-IsInteractiveSession) {
                $response = Read-Host "Continue using this account/tenant? (Y/N)"
                if ($response -notmatch '^(y|yes)$') {
                    throw "Aborted by user. Sign in as a different account/tenant, or re-run with -Force to skip this confirmation."
                }
            } else {
                throw "Currently connected as $($currentCtx.Account) (tenant $($currentCtx.Tenant.Id)). Re-run with -Force to proceed non-interactively, or run interactively to confirm."
            }
        }
    }
    else {
        Write-Output "Connecting to Azure..."
        if ($TenantId) { Connect-AzAccount -Tenant $TenantId -ErrorAction Stop | Out-Null }
        else { Connect-AzAccount -ErrorAction Stop | Out-Null }
        $currentCtx = Get-AzContext
    }
    if ([string]::IsNullOrWhiteSpace($TenantId)) { $TenantId = $currentCtx.Tenant.Id }

    # Signal to the embedded scripts (which run in this same process) that the
    # connection for this tenant has already been established/validated, so their
    # own Connect-Azure calls can skip repeating the work.
    $env:PAYG_PRECONNECTED_TENANT = $TenantId
}

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

.VERSION
    1.0.0 - Initial version.
    1.0.2 - Modified to fix errors and to remove the auto-start of the offline resources.
    1.0.3 - Added transcript.
    1.0.4 - Fixed resource group filter for SQL DB

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
    -AsJob and reports "RequestSubmitted", meaning the service accepted the request rather
    than that the change has been applied.

    Note: SQL virtual machines are always updated synchronously via Update-AzSqlVM (no
    -AsJob/-NoWait) regardless of this switch, because SQL VM license updates must not be
    submitted asynchronously; see Invoke-SqlVmLicenseUpdate.
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
}

# Matches transient network failures observed in practice (e.g. Windows ephemeral
# port exhaustion - WinError 10048 - and generic HttpRequestExceptions/connection
# resets from Az PowerShell). These are environment/network blips, not problems with
# the request itself, so a short retry resolves most of them instead of permanently
# marking an otherwise-valid resource update as "Failed".
$script:TransientErrorPattern = 'socket|10048|underlying connection|connection was closed|forcibly closed|timed? ?out|temporarily unavailable|An error occurred while sending the request|could not be resolved|(?<!\d)(429|5\d\d)(?!\d)'

<#
.SYNOPSIS
    Runs an Az PowerShell cmdlet (via scriptblock) and retries it on transient network errors.
.DESCRIPTION
    Companion to Invoke-AzCliArgsWithRetry for Az PowerShell cmdlets, which signal failure by
    throwing rather than through $LASTEXITCODE. Callers should pass -ErrorAction Stop inside the
    scriptblock so failures are terminating and therefore retryable/catchable here; otherwise a
    transient error is written as a non-terminating error and silently treated as an empty result
    by the caller (exactly the failure mode this script's other helpers were written to avoid).
#>
function Invoke-AzCmdletWithRetry {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $true)][string]$Description,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 5
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return & $ScriptBlock
        }
        catch {
            $isTransient = $_.Exception.Message -match $script:TransientErrorPattern
            if (-not $isTransient -or $attempt -eq $MaxAttempts) {
                throw
            }
            Write-Warning "Transient network error on attempt $attempt/$MaxAttempts for $Description`: $($_.Exception.Message). Retrying in $DelaySeconds s..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

<#
.SYNOPSIS
    Runs an Az PowerShell 'Set-AzSql*' license-type update cmdlet (via scriptblock) and reports
    whether it actually succeeded.
.DESCRIPTION
    Replaces the previous Azure-CLI-based updater. The caller's scriptblock invokes the
    appropriate Set-AzSql* cmdlet with -ErrorAction Stop (so failures are terminating and
    retried/caught here) and, when -SupportsAsJob is set and -WaitForCompletion was not passed
    to the script, with -AsJob so a large estate is not processed serially. In that case the
    caller records "RequestSubmitted" rather than "Updated", because the service has only
    accepted the request at that point; passing -WaitForCompletion to the script omits -AsJob,
    so the cmdlet blocks until the operation reaches a terminal state and the outcome is
    confirmed before returning.
.PARAMETER SupportsAsJob
    Set for cmdlets whose scriptblock conditionally passes -AsJob. Update-AzSqlVM does not use
    this switch at all; SQL VMs are always updated synchronously (see Invoke-SqlVmLicenseUpdate).
#>
function Invoke-AzLicenseUpdate {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $true)][string]$Description,
        [switch]$SupportsAsJob
    )

    $submittedOnly = [bool]($SupportsAsJob -and -not $WaitForCompletion)

    try {
        $result = Invoke-AzCmdletWithRetry -Description $Description -ScriptBlock $ScriptBlock
        return [PSCustomObject]@{ Success = $true; Result = $result; ErrorMessage = ""; Submitted = $submittedOnly }
    }
    catch {
        Write-Warning "Failed to update $Description`: $($_.Exception.Message)"
        return [PSCustomObject]@{ Success = $false; Result = $null; ErrorMessage = $_.Exception.Message; Submitted = $false }
    }
}

<#
.SYNOPSIS
    Updates the license type of a SQL virtual machine, always synchronously.
.DESCRIPTION
    Update-AzSqlVM advertises -NoWait and -AsJob, but SQL VM license updates must not be
    submitted asynchronously: VMs cannot reliably run this operation in the background (the
    -NoWait/-AsJob switches are also broken in Az.SqlVirtualMachine 2.4.0 - -NoWait forwards the
    bound parameter into Get-AzSqlVM, which rejects it, and -AsJob throws a
    NullReferenceException), so this function always calls Update-AzSqlVM synchronously and
    waits for it to reach a terminal state, regardless of -WaitForCompletion.
#>
function Invoke-SqlVmLicenseUpdate {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$LicenseType
    )

    try {
        $result = Invoke-AzCmdletWithRetry -Description "SQL VM '$Name'" -ScriptBlock {
            Update-AzSqlVM -Name $Name -ResourceGroupName $ResourceGroup -LicenseType $LicenseType -ErrorAction Stop
        }
        return [PSCustomObject]@{ Success = $true; Result = $result; ErrorMessage = ""; Submitted = $false }
    }
    catch {
        Write-Warning "Failed to update SQL VM '$Name': $($_.Exception.Message)"
        return [PSCustomObject]@{ Success = $false; Result = $null; ErrorMessage = $_.Exception.Message; Submitted = $false }
    }
}

<#
.SYNOPSIS
    Tests whether a resource's tags match any of the -ExclusionTags key/value pairs.
.DESCRIPTION
    Replaces the JMESPath 'tags.<key> != <value>' clauses previously embedded in each Azure
    CLI --query. $Tags may be a [hashtable] (Az.Sql database/elastic-pool/instance/instance-pool
    model objects) or an IDictionary of a single tag (the SQL VM model's singular .Tag property);
    either shape is handled the same way. A resource is excluded when ANY exclusion tag key is
    present with a matching value, mirroring the previous CLI filter's semantics.
#>
function Test-ExcludedByTags {
    param(
        [Parameter(Mandatory = $false)]$Tags,
        [Parameter(Mandatory = $true)][hashtable]$ExclusionTagTable
    )

    if ($ExclusionTagTable.Keys.Count -eq 0 -or $null -eq $Tags) {
        return $false
    }

    foreach ($key in $ExclusionTagTable.Keys) {
        if ($Tags.Contains($key) -and $Tags[$key] -eq $ExclusionTagTable[$key]) {
            return $true
        }
    }
    return $false
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

# Whether Set-AzSql* license updates below are submitted with -AsJob (fire-and-forget, reported
# as "RequestSubmitted") or run synchronously to a terminal state (reported as "Updated"). SQL
# VMs never use this - see Invoke-SqlVmLicenseUpdate.
$submitAsync = -not $WaitForCompletion

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

# Ensure Az.Sql is available and import it (Get-/Set-AzSqlDatabase, Get-/Set-AzSqlInstance,
# Get-/Set-AzSqlElasticPool, Get-/Set-AzSqlInstancePool, Get-/Set-AzSqlServer all live here)
try {
    if (-not (Get-Module -ListAvailable -Name Az.Sql)) {
        Write-Output "Az.Sql module not found. Installing..."
        Install-Module -Name Az.Sql -Scope CurrentUser -Repository PSGallery -Force
    } else {
        Write-Output "Az.Sql module is already installed."
    }
    Import-Module Az.Sql -Force
} catch {
    Write-Error "Can't import module Az.Sql: $_"
}

# Ensure Az.SqlVirtualMachine is available and import it (Get-/Update-AzSqlVM)
try {
    if (-not (Get-Module -ListAvailable -Name Az.SqlVirtualMachine)) {
        Write-Output "Az.SqlVirtualMachine module not found. Installing..."
        Install-Module -Name Az.SqlVirtualMachine -Scope CurrentUser -Repository PSGallery -Force
    } else {
        Write-Output "Az.SqlVirtualMachine module is already installed."
    }
    Import-Module Az.SqlVirtualMachine -Force
} catch {
    Write-Error "Can't import module Az.SqlVirtualMachine: $_"
}

# Map License Types for SQL VMs: LicenseIncluded -> PAYG, BasePrice -> AHUB.
$SqlVmLicenseType = if ($LicenseType -eq "LicenseIncluded") { "PAYG" } else { "AHUB" }

# Modified resources array
$modifiedResources = @()

# Determine the subscriptions to process: CSV file, single subscription, or all accessible subscriptions.
# Get-AzSubscription occasionally fails with a transient HttpRequestException (e.g. network
# blips outside the usual dev environment). Previously this was a non-terminating error that
# left $subscriptions empty, so the script silently "completed" having scanned zero
# subscriptions instead of surfacing the failure. Retry a few times with increasing backoff
# (observed blips clear up within ~20-30s), then fail loudly.
$subRetryDelays = @(5, 10, 20, 30, 30)
if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne "") {
    Write-Output "Passed Subscription $($SubId)"
    $subscriptions = $null
    for ($subAttempt = 1; $subAttempt -le $subRetryDelays.Count; $subAttempt++) {
        # -TenantId scopes resolution to the requested tenant only. Without it, Get-AzSubscription
        # fans out and tries to acquire a token for *every* tenant the signed-in account belongs
        # to (including unrelated guest tenants requiring MFA/conditional access), which is why
        # unrelated 'Authentication failed against tenant ...' warnings were showing up even
        # though a specific -TenantId was passed to the script.
        try { $subscriptions = Get-AzSubscription -SubscriptionId $SubId -TenantId $TenantId -ErrorAction Stop; break }
        catch {
            if ($subAttempt -eq $subRetryDelays.Count) { Write-Error "Failed to resolve subscription '$SubId' after $subAttempt attempts: $($_.Exception.Message)"; exit 1 }
            $delay = $subRetryDelays[$subAttempt - 1]
            Write-Warning "Transient error resolving subscription '$SubId' (attempt $subAttempt/$($subRetryDelays.Count)): $($_.Exception.Message). Retrying in ${delay}s..."
            Start-Sleep -Seconds $delay
        }
    }
}else {
    $subscriptions = $null
    for ($subAttempt = 1; $subAttempt -le $subRetryDelays.Count; $subAttempt++) {
        try { $subscriptions = Get-AzSubscription -TenantId $TenantId -ErrorAction Stop; break }
        catch {
            if ($subAttempt -eq $subRetryDelays.Count) { Write-Error "Failed to list subscriptions for tenant '$tenantId' after $subAttempt attempts: $($_.Exception.Message)"; exit 1 }
            $delay = $subRetryDelays[$subAttempt - 1]
            Write-Warning "Transient error listing subscriptions for tenant '$tenantId' (attempt $subAttempt/$($subRetryDelays.Count)): $($_.Exception.Message). Retrying in ${delay}s..."
            Start-Sleep -Seconds $delay
        }
    }
}

if (-not $subscriptions -or @($subscriptions).Count -eq 0) {
    Write-Error "No subscriptions resolved (SubId='$SubId', TenantId='$tenantId'). Aborting instead of proceeding with zero subscriptions, which would otherwise look like a clean 'nothing to update' run."
    exit 1
}

# Resource group and tag-based exclusion filtering are applied per resource type via
# Where-Object/Test-ExcludedByTags below instead of a shared JMESPath fragment.
$scriptStartTime = Get-Date
Write-Output "Our adventure begins at: $scriptStartTime`n"

# Process each subscription.
foreach ($sub in $subscriptions) {
    try {
        Write-Output "===== Entering Subscription: $($sub.name) ====="
        Write-Output "Switching context to subscription: $($sub.name)"

        Write-Output "License Type: $LicenseType"
        try {
            Invoke-AzCmdletWithRetry -Description "Set-AzContext for subscription $($sub.id)" -ScriptBlock {
                Set-AzContext -Subscription $sub.id -ErrorAction Stop | Out-Null
            }
        }
        catch {
            # Every cmdlet below is scoped by the current Az PowerShell context. If the switch
            # fails they would all silently run against whichever subscription was previously
            # selected, so resources in the wrong subscription could be updated.
            Write-Warning "Skipping subscription '$($sub.name)' ($($sub.id)): the Az PowerShell context could not be switched to it: $($_.Exception.Message)"
            continue
        }

        # --- Section: Update SQL Virtual Machines ---
        try {
            Write-Output "Seeking SQL Virtual Machines that require a license update to $SqlVmLicenseType..."

            $sqlVMs = @(Invoke-AzCmdletWithRetry -Description "SQL virtual machines in subscription $($sub.id)" -ScriptBlock {
                Get-AzSqlVM -ErrorAction Stop
            })

            # License mismatch, exclude 'DR' (Disaster Recovery secondary replicas, which are
            # licensed separately and must not be overwritten), and the optional
            # resource-group/name scope.
            $sqlVMs = @($sqlVMs | Where-Object { $_.SqlServerLicenseType -ne $SqlVmLicenseType -and $_.SqlServerLicenseType -ne 'DR' })
            if ($ResourceGroup) {
                $sqlVMs = @($sqlVMs | Where-Object { ($_.Id -split '/')[4] -eq $ResourceGroup })
            }
            if ($ResourceName) {
                $sqlVMs = @($sqlVMs | Where-Object { $_.Name -eq $ResourceName })
            }

            if ($sqlVMs.Count -eq 0) {
                Write-Output "No SQL VMs found that require a license update."
            } else {
                Write-Output "Found $($sqlVMs.Count) SQL VMs that require a license update."
            }

            foreach ($sqlvm in $sqlVMs) {
                $vmResourceGroup = ($sqlvm.Id -split '/')[4]
                $vmName = $sqlvm.Name

                if (Test-ExcludedByTags -Tags $sqlvm.Tag -ExclusionTagTable $tagTable) {
                    Write-Output "SQL VM '$vmName' in resource group '$vmResourceGroup' Skipping because of tags..."
                    $modifiedResources += [PSCustomObject]@{
                        TenantID            = $TenantId
                        SubID               = ($sqlvm.Id -split '/')[2]
                        ResourceName        = $vmName
                        ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                        Status              = "SkippedTags"
                        OriginalLicenseType = $sqlvm.SqlServerLicenseType
                        ResourceGroup       = $vmResourceGroup
                        Location            = $sqlvm.Location
                        UpdateResult        = "SkippedTags"
                        UpdateError         = "Excluded by tags filter"
                    }
                    continue
                }

                $vmPowerState = $null
                try {
                    $vmPowerState = Invoke-AzCmdletWithRetry -Description "power state of VM '$vmName'" -ScriptBlock {
                        (Get-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -Status -ErrorAction Stop).Statuses |
                            Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -First 1 -ExpandProperty DisplayStatus
                    }
                }
                catch {
                    # Without a power state the VM would silently fail the "VM running" test
                    # below and be skipped as though it were switched off.
                    Write-Warning "Skipping SQL VM '$vmName': its power state could not be read, so it was not assessed. Re-run to retry."
                    $modifiedResources += [PSCustomObject]@{
                        TenantID            = $TenantId
                        SubID               = ($sqlvm.Id -split '/')[2]
                        ResourceName        = $vmName
                        ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                        Status              = "UnknownPowerState"
                        OriginalLicenseType = $sqlvm.SqlServerLicenseType
                        ResourceGroup       = $vmResourceGroup
                        Location            = $sqlvm.Location
                        UpdateResult        = "Failed"
                        UpdateError         = "Power state could not be read"
                    }
                    continue
                }

                if ($vmPowerState -eq "VM running") {

                    $vmResult = "NotAttempted"
                    $vmError = ""

                    if ($ReportOnly) {
                        $vmResult = "ReportOnly"
                        Write-Output "ReportOnly mode enabled. Skipping modification for SQL VM '$vmName' in resource group '$vmResourceGroup' (would change '$($sqlvm.SqlServerLicenseType)' -> '$SqlVmLicenseType')."
                    } else {
                        Write-Output "Updating SQL VM '$vmName' in resource group '$vmResourceGroup' to license type '$SqlVmLicenseType'..."
                        # Always synchronous - SQL VM license updates must not be submitted via
                        # -AsJob/-NoWait (see Invoke-SqlVmLicenseUpdate), so this call blocks
                        # until the update completes regardless of -WaitForCompletion.
                        $update = Invoke-SqlVmLicenseUpdate -Name $vmName -ResourceGroup $vmResourceGroup -LicenseType $SqlVmLicenseType
                        if ($update.Success) {
                            $finalStatus += $update.Result
                            $vmResult = "Updated"
                            Write-Output "-- SQL VM '$vmName': $vmResult (license type '$SqlVmLicenseType')"
                        }
                        else { $vmResult = "Failed"; $vmError = $update.ErrorMessage }
                    }

                    # Collect data after the attempt so the recorded outcome is accurate
                    $modifiedResources += [PSCustomObject]@{
                        TenantID            = $TenantId
                        SubID               = ($sqlvm.Id -split '/')[2]
                        ResourceName        = $vmName
                        ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                        Status              = $vmPowerState
                        OriginalLicenseType = $sqlvm.SqlServerLicenseType
                        ResourceGroup       = $vmResourceGroup
                        Location            = $sqlvm.Location
                        UpdateResult        = $vmResult
                        UpdateError         = $vmError
                        # Cores             <To be added>
                    }
                }
                else {
                    Write-Output "SQL VM '$vmName' in resource group '$vmResourceGroup' is in '$vmPowerState' state (not running). Skipping update..."
                    $modifiedResources += [PSCustomObject]@{
                        TenantID            = $TenantId
                        SubID               = ($sqlvm.Id -split '/')[2]
                        ResourceName        = $vmName
                        ResourceType        = "Microsoft.SqlVirtualMachine/sqlVirtualMachines"
                        Status              = $vmPowerState
                        OriginalLicenseType = $sqlvm.SqlServerLicenseType
                        ResourceGroup       = $vmResourceGroup
                        Location            = $sqlvm.Location
                        UpdateResult        = "SkippedNotRunning"
                        UpdateError         = "Underlying VM is in '$vmPowerState' state (must be running to update license)"
                    }
                }
            }
        }
        catch {
            Write-Error "An error occurred while updating SQL VMs: $_"
        }

        # --- Section: Update SQL Managed Instances ---
        try {
            $runningMIs = @(Invoke-AzCmdletWithRetry -Description "SQL Managed Instances in subscription $($sub.id)" -ScriptBlock {
                Get-AzSqlInstance -ErrorAction Stop
            })

            # Excludes running instances already at the target license type, plus the optional
            # resource-group/name scope and tag exclusion. The 'state==Ready' pre-filter is not
            # reproduced here: the Az.Sql module's managed-instance model does not expose a
            # state/provisioning-state property to check it against, so a managed instance that
            # is not actually ready is instead caught by Set-AzSqlInstance failing and being
            # recorded as "Failed" below.
            $runningMIs = @($runningMIs | Where-Object { $_.LicenseType -ne $LicenseType })
            if ($ResourceGroup) {
                $runningMIs = @($runningMIs | Where-Object { $_.ResourceGroupName -eq $ResourceGroup })
            }
            if ($ResourceName) {
                $runningMIs = @($runningMIs | Where-Object { $_.ManagedInstanceName -eq $ResourceName })
            }
            $runningMIs = @($runningMIs | Where-Object { -not (Test-ExcludedByTags -Tags $_.Tags -ExclusionTagTable $tagTable) })

            Write-Output "Processing SQL Managed Instances that require a license update..."
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
                    Write-Output "ReportOnly mode enabled. Skipping modification for SQL Managed Instance '$($mi.ManagedInstanceName)' in resource group '$($mi.ResourceGroupName)' (would change '$($mi.LicenseType)' -> '$LicenseType')."
                } else {
                    Write-Output "Updating SQL Managed Instance '$($mi.ManagedInstanceName)' in resource group '$($mi.ResourceGroupName)' to license type '$LicenseType'..."
                    $update = Invoke-AzLicenseUpdate -Description "SQL Managed Instance '$($mi.ManagedInstanceName)'" -SupportsAsJob -ScriptBlock {
                        Set-AzSqlInstance -Name $mi.ManagedInstanceName -ResourceGroupName $mi.ResourceGroupName -LicenseType $LicenseType -AsJob:$submitAsync -Force -ErrorAction Stop
                    }
                    if ($update.Success) {
                        $finalStatus += $update.Result
                        $miResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                        Write-Output "-- SQL Managed Instance '$($mi.ManagedInstanceName)': $miResult (license type '$LicenseType')"
                    }
                    else { $miResult = "Failed"; $miError = $update.ErrorMessage }
                }

                # Collect data after the attempt so the recorded outcome is accurate
                $modifiedResources += [PSCustomObject]@{
                    TenantID            = $TenantId
                    SubID               = ($mi.Id -split '/')[2]
                    ResourceName        = $mi.ManagedInstanceName
                    ResourceType        = "Microsoft.Sql/managedInstances"
                    Status              = ""
                    OriginalLicenseType = $mi.LicenseType
                    ResourceGroup       = $mi.ResourceGroupName
                    Location            = $mi.Location
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
            Write-Output "Querying SQL servers within this subscription..."

            $allServers = @(Invoke-AzCmdletWithRetry -Description "SQL servers in the subscription" -ScriptBlock {
                Get-AzSqlServer -ErrorAction Stop
            })
            Write-Output "Found a total of $($allServers.Count) SQL servers in subscription"

            $servers = $allServers
            if ($ResourceGroup) {
                $servers = @($servers | Where-Object { $_.ResourceGroupName -eq $ResourceGroup })
            }
            if ($ResourceName) {
                $servers = @($servers | Where-Object { $_.ServerName -eq $ResourceName })
            }
            $servers = @($servers | Where-Object { -not (Test-ExcludedByTags -Tags $_.Tags -ExclusionTagTable $tagTable) })

            # Verify if we got any results
            if ($servers.Count -eq 0) {
                Write-Output "WARNING: No SQL servers found with the specified filters."
                Write-Output "Available SQL servers in subscription:"
                $allServers | ForEach-Object {
                    Write-Output "  - $($_.ServerName) (Resource Group: $($_.ResourceGroupName))"
                }

                # Only fall back to scanning every server in the subscription when the
                # caller did not restrict the scope. Falling back while -ResourceGroup
                # (or -ResourceName) was supplied would silently widen the blast radius
                # far beyond what was asked for: the elastic pool query below is not
                # resource-group filtered, so pools on out-of-scope servers would be
                # modified.
                if (-not $ResourceName -and -not $ResourceGroup) {
                    Write-Output "Proceeding with all SQL servers since no specific ResourceName or ResourceGroup was provided."
                    $servers = $allServers
                } else {
                    Write-Output "Scope was explicitly restricted; not falling back to all SQL servers. Skipping SQL Database and Elastic Pool processing."
                    $servers = @()
                }
            } else {
                Write-Output "Found $($servers.Count) SQL servers matching the criteria."
                $servers | ForEach-Object {
                    Write-Output "  - $($_.ServerName) (Resource Group: $($_.ResourceGroupName))"
                }
            }

            # Process each server
            foreach ($server in $servers) {
                # Update SQL Databases
                Write-Output "Scanning SQL Databases on server '$($server.ServerName)' in resource group '$($server.ResourceGroupName)'..."

                try {
                    $allDbs = @(Invoke-AzCmdletWithRetry -Description "databases on server '$($server.ServerName)'" -ScriptBlock {
                        Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -ErrorAction Stop
                    })
                    Write-Output "Found a total of $($allDbs.Count) databases on server '$($server.ServerName)'"

                    $dbs = @($allDbs | Where-Object { $null -ne $_.LicenseType -and $_.LicenseType -ne $LicenseType })
                    $dbs = @($dbs | Where-Object { -not (Test-ExcludedByTags -Tags $_.Tags -ExclusionTagTable $tagTable) })

                    if ($dbs.Count -eq 0) {
                        Write-Output "No SQL Databases found on Server $($server.ServerName) that require a license update."
                    } else {
                        Write-Output "Found $($dbs.Count) SQL Databases on Server $($server.ServerName) that require a license update:"
                        $dbs | ForEach-Object {
                            Write-Output "  - $($_.DatabaseName) (Current license: $($_.LicenseType))"
                        }

                        foreach ($db in $dbs) {

                            $dbResult = "NotAttempted"
                            $dbError = ""

                            if ($ReportOnly) {
                                $dbResult = "ReportOnly"
                                Write-Output "ReportOnly mode enabled. Skipping modification for SQL Database '$($db.DatabaseName)' on server '$($server.ServerName)' (would change '$($db.LicenseType)' -> '$LicenseType')."
                            } else {
                                Write-Output "Updating SQL Database '$($db.DatabaseName)' on server '$($server.ServerName)' to license type '$LicenseType'..."
                                $update = Invoke-AzLicenseUpdate -Description "SQL Database '$($db.DatabaseName)' on server '$($server.ServerName)'" -SupportsAsJob -ScriptBlock {
                                    Set-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -DatabaseName $db.DatabaseName -LicenseType $LicenseType -AsJob:$submitAsync -ErrorAction Stop
                                }
                                if ($update.Success) {
                                    $finalStatus += $update.Result
                                    $dbResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                                    Write-Output "-- SQL Database '$($db.DatabaseName)': $dbResult (license type '$LicenseType')"
                                }
                                else { $dbResult = "Failed"; $dbError = $update.ErrorMessage }
                            }

                            # Collect data after the attempt so the recorded outcome is accurate
                            $modifiedResources += [PSCustomObject]@{
                                TenantID            = $TenantId
                                SubID               = $sub.id
                                ResourceName        = $db.DatabaseName
                                ResourceType        = "Microsoft.Sql/servers/databases"
                                Status              = $db.Status
                                OriginalLicenseType = $db.LicenseType
                                ResourceGroup       = $db.ResourceGroupName
                                Location            = $db.Location
                                UpdateResult        = $dbResult
                                UpdateError         = $dbError
                            }
                        }
                    }
                } catch {
                    Write-Warning "Error querying databases on server '$($server.ServerName)': $_"
                }

                # Update Elastic Pools
                try {
                    Write-Output "Scanning Elastic Pools on server '$($server.ServerName)'..."

                    $allPools = @(Invoke-AzCmdletWithRetry -Description "elastic pools on server '$($server.ServerName)'" -ScriptBlock {
                        Get-AzSqlElasticPool -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -ErrorAction Stop
                    })

                    if ($allPools.Count -eq 0) {
                        Write-Output "No Elastic Pools found on server '$($server.ServerName)'."
                    } else {
                        Write-Output "Found $($allPools.Count) total Elastic Pools on server '$($server.ServerName)'."

                        $elasticPools = @($allPools | Where-Object { $null -ne $_.LicenseType -and $_.LicenseType -ne $LicenseType })
                        $elasticPools = @($elasticPools | Where-Object { -not (Test-ExcludedByTags -Tags $_.Tags -ExclusionTagTable $tagTable) })

                        if ($elasticPools.Count -eq 0) {
                            Write-Output "No Elastic Pools found on Server $($server.ServerName) that require a license update."
                        } else {
                            Write-Output "Found $($elasticPools.Count) Elastic Pools on Server $($server.ServerName) that require a license update:"
                            $elasticPools | ForEach-Object {
                                Write-Output "  - $($_.ElasticPoolName) (Current license: $($_.LicenseType))"
                            }

                            foreach ($pool in $elasticPools) {

                                $poolResult = "NotAttempted"
                                $poolError = ""

                                if ($ReportOnly) {
                                    $poolResult = "ReportOnly"
                                    Write-Output "ReportOnly mode enabled. Skipping modification for Elastic Pool '$($pool.ElasticPoolName)' on server '$($server.ServerName)' (would change '$($pool.LicenseType)' -> '$LicenseType')."
                                } else {
                                    Write-Output "Updating Elastic Pool '$($pool.ElasticPoolName)' on server '$($server.ServerName)' to license type '$LicenseType'..."
                                    $update = Invoke-AzLicenseUpdate -Description "Elastic Pool '$($pool.ElasticPoolName)' on server '$($server.ServerName)'" -SupportsAsJob -ScriptBlock {
                                        Set-AzSqlElasticPool -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -ElasticPoolName $pool.ElasticPoolName -LicenseType $LicenseType -AsJob:$submitAsync -ErrorAction Stop
                                    }
                                    if ($update.Success) {
                                        $finalStatus += $update.Result
                                        $poolResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                                        Write-Output "-- Elastic Pool '$($pool.ElasticPoolName)': $poolResult (license type '$LicenseType')"
                                    }
                                    else { $poolResult = "Failed"; $poolError = $update.ErrorMessage }
                                }

                                # Collect data after the attempt so the recorded outcome is accurate
                                $modifiedResources += [PSCustomObject]@{
                                    TenantID            = $TenantId
                                    SubID               = $sub.id
                                    ResourceName        = $pool.ElasticPoolName
                                    ResourceType        = "Microsoft.Sql/servers/elasticPools"
                                    Status              = $pool.State
                                    OriginalLicenseType = $pool.LicenseType
                                    ResourceGroup       = $pool.ResourceGroupName
                                    Location            = $pool.Location
                                    UpdateResult        = $poolResult
                                    UpdateError         = $poolError
                                }
                            }
                        }
                    }
                } catch {
                    Write-Warning "Error processing Elastic Pools on server '$($server.ServerName)': $_"
                }
            }
        } catch {
            Write-Error "An error occurred while processing SQL Databases or Elastic Pools: $_"
        }

        # --- Section: Update SQL Instance Pools ---
        try {
            Write-Output "Searching for SQL Instance Pools that require a license update..."

            $instancePools = @(Invoke-AzCmdletWithRetry -Description "SQL instance pools in subscription $($sub.id)" -ScriptBlock {
                Get-AzSqlInstancePool -ErrorAction Stop
            })

            # Excludes pools already at the target license type, plus the optional
            # resource-group/name scope and tag exclusion. The 'state==Ready' pre-filter is not
            # reproduced here: the Az.Sql module's instance-pool model does not expose a
            # state/provisioning-state property to check it against, so an instance pool that is
            # not actually ready is instead caught by Set-AzSqlInstancePool failing and being
            # recorded as "Failed" below.
            $poolsToUpdate = @($instancePools | Where-Object { $_.LicenseType -ne $LicenseType })
            if ($ResourceGroup) {
                $poolsToUpdate = @($poolsToUpdate | Where-Object { $_.ResourceGroupName -eq $ResourceGroup })
            }
            if ($ResourceName) {
                $poolsToUpdate = @($poolsToUpdate | Where-Object { $_.Name -eq $ResourceName })
            }
            $poolsToUpdate = @($poolsToUpdate | Where-Object { -not (Test-ExcludedByTags -Tags $_.Tags -ExclusionTagTable $tagTable) })

            if ($poolsToUpdate.Count -eq 0) {
                Write-Output "No SQL Instance Pools found that require a license update."
            } else {
                Write-Output "Found $($poolsToUpdate.Count) SQL Instance Pools that require a license update."
            }
            foreach ($pool in $poolsToUpdate) {

                $ipResult = "NotAttempted"
                $ipError = ""

                if ($ReportOnly) {
                    $ipResult = "ReportOnly"
                    Write-Output "ReportOnly mode enabled. Skipping modification for SQL Instance Pool '$($pool.Name)' in resource group '$($pool.ResourceGroupName)' (would change '$($pool.LicenseType)' -> '$LicenseType')."
                } else {
                    Write-Output "Updating SQL Instance Pool '$($pool.Name)' in resource group '$($pool.ResourceGroupName)' to license type '$LicenseType'..."
                    $update = Invoke-AzLicenseUpdate -Description "SQL Instance Pool '$($pool.Name)'" -SupportsAsJob -ScriptBlock {
                        Set-AzSqlInstancePool -Name $pool.Name -ResourceGroupName $pool.ResourceGroupName -LicenseType $LicenseType -AsJob:$submitAsync -ErrorAction Stop
                    }
                    if ($update.Success) {
                        $finalStatus += $update.Result
                        $ipResult = if ($update.Submitted) { "RequestSubmitted" } else { "Updated" }
                        Write-Output "-- SQL Instance Pool '$($pool.Name)': $ipResult (license type '$LicenseType')"
                    }
                    else { $ipResult = "Failed"; $ipError = $update.ErrorMessage }
                }

                # Collect data after the attempt so the recorded outcome is accurate
                $modifiedResources += [PSCustomObject]@{
                    TenantID            = $TenantId
                    SubID               = $sub.id
                    ResourceName        = $pool.Name
                    ResourceType        = "Microsoft.Sql/instancePools"
                    Status              = ""
                    OriginalLicenseType = $pool.LicenseType
                    ResourceGroup       = $pool.ResourceGroupName
                    Location            = $pool.Location
                    UpdateResult        = $ipResult
                    UpdateError         = $ipError
                }
            }
        }
        catch {
            Write-Error "An error occurred while updating SQL Instance Pools: $_"
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

.PARAMETER WaitForCompletion
    Optional. If specified, waits for each submitted extension update to reach a terminal
    provisioning state and reports the confirmed outcome, instead of returning as soon as the
    request is accepted. Extension updates are normally submitted with -NoWait, so by default
    the report records "RequestSubmitted", which means the service accepted the request - not
    that the Arc agent has applied it. Use this switch when you need confirmed results;
    it makes the run substantially slower because each machine is polled individually.

.PARAMETER WaitTimeoutSeconds
    Optional. Maximum number of seconds to wait per resource when -WaitForCompletion is used.
    Defaults to 300. Reaching the timeout is not treated as a failure: the outcome is recorded
    as "TimedOut" because the update may still be applied by the agent afterwards.

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
    [switch] $WaitForCompletion,

    [Parameter (Mandatory= $false)]
    [int] $WaitTimeoutSeconds = 300,

    [Parameter (Mandatory= $false)]
    [int] $batchSize = 500,

    [Parameter (Mandatory= $false)]
    [switch] $NoSummary
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

<#
.SYNOPSIS
    Polls an Arc machine extension until its provisioning state is terminal.
.DESCRIPTION
    Extension updates are submitted with -NoWait, so the service accepting the request says
    nothing about whether the Arc agent applied it. When -WaitForCompletion is used this
    polls the extension and reports the confirmed outcome.

    A timeout is deliberately NOT reported as a failure: the agent may still apply the
    setting after the script gives up, so the run is recorded as inconclusive rather than
    unsuccessful.
#>
function Wait-ArcExtensionProvisioning {
    param(
        [Parameter(Mandatory = $true)][string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][string]$MachineName,
        [Parameter(Mandatory = $true)][string]$ExtensionName,
        [Parameter(Mandatory = $true)][string]$ExpectedLicenseType,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    $terminalStates = @('Succeeded', 'Failed', 'Canceled')
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $delay = 5
    $lastState = 'Unknown'
    $mismatch = $null

    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $delay
        try {
            $current = Get-AzConnectedMachineExtension -ResourceGroupName $ResourceGroupName `
                -MachineName $MachineName -Name $ExtensionName -ErrorAction Stop
        } catch {
            return [PSCustomObject]@{ Result = 'Failed'; ErrorMessage = $_.Exception.Message; State = 'Unknown' }
        }

        $lastState = "$($current.ProvisioningState)"

        if ($terminalStates -contains $lastState) {
            if ($lastState -ne 'Succeeded') {
                return [PSCustomObject]@{ Result = 'Failed'; ErrorMessage = "Extension provisioning state is '$lastState'."; State = $lastState }
            }

            # A 'Succeeded' provisioning state only means the extension settings were written.
            # Confirm the value actually reflects the requested license type.
            $applied = $null
            if ($null -ne $current.Setting) {
                try { $applied = "$($current.Setting['LicenseType'])" } catch { $applied = $null }
            }

            if ([string]::IsNullOrEmpty($applied)) {
                return [PSCustomObject]@{ Result = 'Succeeded'; ErrorMessage = ''; State = $lastState }
            }
            if ($applied -eq $ExpectedLicenseType) {
                return [PSCustomObject]@{ Result = 'Succeeded'; ErrorMessage = ''; State = $lastState }
            }

            # 'Succeeded' with the wrong license type is ambiguous: the update was submitted
            # with -NoWait, so this may still be the *previous* operation's terminal state read
            # before the new one started. Keep polling rather than failing on that race; the
            # mismatch is only reported if it survives to the deadline.
            $mismatch = "Extension reported '$lastState' but LicenseType is '$applied' instead of '$ExpectedLicenseType'."
        }

        # Back off gradually to avoid hammering the API on slow agents.
        if ($delay -lt 30) { $delay = [Math]::Min(30, $delay * 2) }
    }

    if ($mismatch) {
        return [PSCustomObject]@{ Result = 'Failed'; ErrorMessage = $mismatch; State = $lastState }
    }

    return [PSCustomObject]@{
        Result       = 'TimedOut'
        ErrorMessage = "Did not reach a terminal provisioning state within $TimeoutSeconds seconds (last state: '$lastState'). The update may still be applied by the agent."
        State        = $lastState
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
            } elseif ($item.UpdateResult -eq "SkippedTags") {
                "Resource matched exclusion tags."
            } elseif ($item.UpdateResult -eq "SkippedInvalidState") {
                "Extension is not in a valid/Succeeded state."
            } elseif ($item.UpdateResult -eq "SkippedNoChangeNeeded") {
                "No changes were needed or -Force was not specified to overwrite existing license type."
            } else {
                "Outcome: $($item.UpdateResult)"
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


# Ensure the required modules are installed and imported. These are hard
# dependencies (Search-AzGraph / Get-AzConnectedMachine are used later), so a
# missing module must install itself on demand and any failure must stop the
# script here with an actionable message instead of surfacing as a confusing
# "term not recognized" error deep inside the resource-scanning logic.
foreach ($requiredModule in @('Az.Accounts', 'Az.ConnectedMachine', 'Az.ResourceGraph')) {
    try {
        if (-not (Get-Module -ListAvailable -Name $requiredModule)) {
            Write-Output "$requiredModule module not found. Installing..."
            Install-Module -Name $requiredModule -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
        }
        else {
            Write-Output "$requiredModule module is already installed."
        }
        Import-Module $requiredModule -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Required module '$requiredModule' could not be installed/imported: $_. Install it manually with 'Install-Module -Name $requiredModule -Scope CurrentUser' and re-run this script."
        exit 1
    }
}

$modifiedResources = @()

# Get-AzSubscription occasionally fails with a transient HttpRequestException (e.g. network
# blips outside the usual dev environment). Previously this was a non-terminating error that
# left $subscriptions empty, so the script silently "completed" having scanned zero
# subscriptions instead of surfacing the failure. Retry a few times with increasing backoff
# (observed blips clear up within ~20-30s), then fail loudly.
$subRetryDelays = @(5, 10, 20, 30, 30)
if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne "") {
    Write-Output "Passed Subscription $($SubId)"
    $subscriptions = $null
    for ($subAttempt = 1; $subAttempt -le $subRetryDelays.Count; $subAttempt++) {
        # -TenantId scopes resolution to the requested tenant only. Without it, Get-AzSubscription
        # fans out and tries to acquire a token for *every* tenant the signed-in account belongs
        # to (including unrelated guest tenants requiring MFA/conditional access), which is why
        # unrelated 'Authentication failed against tenant ...' warnings were showing up even
        # though a specific -TenantId was passed to the script.
        try { $subscriptions = Get-AzSubscription -SubscriptionId $SubId -TenantId $TenantId -ErrorAction Stop; break }
        catch {
            if ($subAttempt -eq $subRetryDelays.Count) { Write-Error "Failed to resolve subscription '$SubId' after $subAttempt attempts: $($_.Exception.Message)"; exit 1 }
            $delay = $subRetryDelays[$subAttempt - 1]
            Write-Warning "Transient error resolving subscription '$SubId' (attempt $subAttempt/$($subRetryDelays.Count)): $($_.Exception.Message). Retrying in ${delay}s..."
            Start-Sleep -Seconds $delay
        }
    }
}else {
    $subscriptions = $null
    for ($subAttempt = 1; $subAttempt -le $subRetryDelays.Count; $subAttempt++) {
        try { $subscriptions = Get-AzSubscription -TenantId $TenantId -ErrorAction Stop; break }
        catch {
            if ($subAttempt -eq $subRetryDelays.Count) { Write-Error "Failed to list subscriptions for tenant '$tenantId' after $subAttempt attempts: $($_.Exception.Message)"; exit 1 }
            $delay = $subRetryDelays[$subAttempt - 1]
            Write-Warning "Transient error listing subscriptions for tenant '$tenantId' (attempt $subAttempt/$($subRetryDelays.Count)): $($_.Exception.Message). Retrying in ${delay}s..."
            Start-Sleep -Seconds $delay
        }
    }
}

if (-not $subscriptions -or @($subscriptions).Count -eq 0) {
    Write-Error "No subscriptions resolved (SubId='$SubId', TenantId='$tenantId'). Aborting instead of proceeding with zero subscriptions, which would otherwise look like a clean 'nothing to update' run."
    exit 1
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
        $resources = Search-AzGraph -Query "$($query)" -First $batchSize -SkipToken $skipToken -ErrorAction Stop
        if ($resources) {
            $allResults.AddRange($resources)
        }
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
        if($excludedByTags){
            $resourceRecord = [PSCustomObject]@{
                TenantID            = $TenantId
                SubID               = $setID.SubscriptionId
                ResourceName        = $setID.MachineName
                ResourceType        = $setID.ExtensionType
                Status              = $sqlvm.Status
                OriginalLicenseType = "Unknown"
                ResourceGroup       = $setID.ResourceGroup
                Location            = $setID.Location
                UpdateResult        = "SkippedTags"
                UpdateError         = "Matched exclusion tag $($tag):$value"
            }
            $modifiedResources += $resourceRecord
        } else {
           
        
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
            $resourceRecord.UpdateResult = "SkippedInvalidState"
            $resourceRecord.UpdateError = "Extension provisioning state is '$($ext.ProvisioningState)' (expected 'Succeeded')"
            continue
        } else {
            $LO_Allowed = (!$ext.Setting["enableExtendedSecurityUpdates"] -and !$EnableESU) -or  ($EnableESU -eq "No")
            
            if ($LicenseType) {
                if (($LicenseType -eq "LicenseOnly") -and !$LO_Allowed) {
                    write-Output "ESU must be disabled before license type can be set to $($LicenseType)"
                    $resourceRecord.UpdateResult = "Failed"
                    $resourceRecord.UpdateError = "ESU must be disabled before license type can be set to $LicenseType"
                } else {
                    if ($ext.Setting["LicenseType"]) {
                        if ($Force) {
                            $ext.Setting["LicenseType"] = $LicenseType
                            $WriteSettings = $true
                        }
                        elseif ("$($ext.Setting['LicenseType'])" -ne $LicenseType) {
                            # The machine already carries a license type and -Force was not
                            # supplied, so it is deliberately left alone. Say so explicitly:
                            # other settings may still be written below, and without this the
                            # run would report "Updated" for a license type that never changed.
                            Write-Warning "[$($setID.MachineName)] LicenseType is '$($ext.Setting['LicenseType'])' and was NOT changed to '$LicenseType'. Re-run with -Force to overwrite an existing license type."
                            $resourceRecord.UpdateResult = "SkippedNoForce"
                            $resourceRecord.UpdateError = "Machine carries LicenseType '$($ext.Setting['LicenseType'])'. Re-run with -Force to overwrite."
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

                        if ($WaitForCompletion) {
                            Write-Output "   Waiting for the extension update on [$($setID.MachineName)] to complete (timeout ${WaitTimeoutSeconds}s)..."
                            $wait = Wait-ArcExtensionProvisioning -ResourceGroupName $setID.ResourceGroup `
                                -MachineName $setID.MachineName -ExtensionName $setID.Name `
                                -ExpectedLicenseType "$($settings['LicenseType'])" -TimeoutSeconds $WaitTimeoutSeconds

                            $resourceRecord.UpdateResult = $wait.Result
                            $resourceRecord.UpdateError = $wait.ErrorMessage

                            switch ($wait.Result) {
                                'Succeeded' { Write-Output "   Confirmed -- [$($setID.MachineName)] provisioning state '$($wait.State)'." }
                                'TimedOut'  { Write-Warning "Timed out waiting for [$($setID.MachineName)]: $($wait.ErrorMessage)" }
                                default     { Write-Warning "The extension update for [$($setID.MachineName)] did not succeed: $($wait.ErrorMessage)" }
                            }
                        }
                    } catch {
                        $errorMessage = $_.Exception.Message
                        Write-Output "The request to modify the extension object for [$($setID.MachineName)] failed with the following error: $errorMessage"
                        $resourceRecord.UpdateResult = "Failed"
                        $resourceRecord.UpdateError = $errorMessage
                        continue
                    }
                } elseif ($resourceRecord.UpdateResult -eq "NotAttempted") {
                    $resourceRecord.UpdateResult = "SkippedNoChangeNeeded"
                    $resourceRecord.UpdateError = "No configuration changes were required."
                }
            } else {
                Write-Output "ReportOnly mode enabled. Skipping modification for: $($setID.MachineName)"
                $resourceRecord.UpdateResult = "ReportOnly"
            }
        }
        
    }
    }
}

# --- Final Report ---
$scriptEndTime = Get-Date
$executionDuration = $scriptEndTime - $scriptStartTime

Write-Output "`n===== Final Report ====="
Write-Output "Script started at: $scriptStartTime"
Write-Output "Script ended at:   $scriptEndTime"
Write-Output "Total duration:    $($executionDuration.ToString())"

# Export tracked resources for orchestrator if running in orchestrated mode
if (Test-Path variable:global:PaygTrackedResources) {
    $global:PaygTrackedResources += $modifiedResources
}
$trackedOutPath = Join-Path (Get-Location) "manage-payg-transition\tracked_arc.json"
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
    $modifiedResources | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "CSV report saved to: $csvPath"
} else {
    Write-Output "No resources were marked for modification. No CSV generated."
}

write-Output "Arc SQL Update Script completed"

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
    Azure region for the resource group and account (e.g. "EastUS").

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
            } elseif ($item.UpdateResult -eq "SkippedInvalidState") {
                "Extension is not in a valid/Succeeded state."
            } elseif ($item.UpdateResult -eq "SkippedNoChangeNeeded") {
                "No changes were needed or -Force was not specified to overwrite existing license type."
            } elseif ($item.UpdateResult -eq "SkippedNoForce") {
                "Machine carries an existing license type. Re-run with -Force to overwrite."
            } else {
                "Outcome: $($item.UpdateResult)"
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
            WaitForCompletion = [bool]$WaitForCompletion
            NoSummary = $true
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
            WaitForCompletion = [bool]$WaitForCompletion
            NoSummary = $true
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
$(if ($WaitForCompletion) { "WaitForCompletion=`$true" })
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
    $(if ($WaitForCompletion) { "WaitForCompletion= `$true" })
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
    
    $global:PaygTrackedResources = @()
    # Clean any stale tracking files from previous runs
    if (Test-Path $downloadFolder) {
        Get-ChildItem -Path $downloadFolder -Filter "tracked_*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    .\runnow.ps1

    # Gather tracked resources from global tracking and/or exported json files
    $combinedTracked = @()
    if ($global:PaygTrackedResources -and $global:PaygTrackedResources.Count -gt 0) {
        $combinedTracked += $global:PaygTrackedResources
    }
    
    Get-ChildItem -Path $downloadFolder -Filter "tracked_*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $jsonItems = Get-Content -Raw -Path $_.FullName | ConvertFrom-Json
            if ($jsonItems) {
                $combinedTracked += @($jsonItems)
            }
        } catch {}
    }

    # Dedup resources if needed by (SubID, ResourceGroup, ResourceName, ResourceType)
    $deduped = @()
    $seen = @{}
    foreach ($item in $combinedTracked) {
        $key = "$($item.SubID)/$($item.ResourceGroup)/$($item.ResourceName)/$($item.ResourceType)"
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $deduped += $item
        }
    }

    # Clean up tracking json files after aggregation
    if (Test-Path $downloadFolder) {
        Get-ChildItem -Path $downloadFolder -Filter "tracked_*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
    }

    # Print single unified outcome summary at the very end of execution
    Format-ExecutionOutcomeSummary -TrackedResources $deduped -IsReportOnly ([bool]$ReportOnly)

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
