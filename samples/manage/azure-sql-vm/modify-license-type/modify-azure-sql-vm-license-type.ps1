<#
.SYNOPSIS
    Updates the SQL Server license type and Extended Security Updates (ESU) settings for
    Azure SQL VMs (Microsoft.SqlVirtualMachine/sqlVirtualMachines).

.DESCRIPTION
    Companion script to modify-arc-sql-license-type.ps1 (which targets Arc-enabled SQL Servers).
    This script targets Azure SQL VMs. For each in-scope resource it can:

      * Change the SQL Server license type (PAYG / AHUB / DR) via Update-AzSqlVM.
      * Enable or disable ESU by updating the SqlIaaSAgent extension settings on the
        underlying compute VM (preserving any other operator-set extension settings).

    It also detects (read-only, never gates writes) the four prerequisites surfaced by
    the Azure portal SQL Server configuration page (SqlVmManagementSection.tsx):

      1. SqlIaaSAgent extension version >= 2.0.227.1
      2. Compute VM has a system-assigned managed identity
      3. Microsoft.AzureArcData resource provider is registered on the subscription
      4. SqlIaaSAgent SQL Management mode is 'Full'

    Per-VM prerequisite results are echoed to the transcript and added as columns on
    the CSV report. They are informational only and do not block license or ESU writes.

    Scope is selected by subscription (single id or CSV file), optional resource group,
    and optional VM name (single name or CSV file). Resources are discovered via Azure
    Resource Graph and paged with -BatchSize. Tags listed in -ExclusionTags are skipped.

    Always writes a transcript log (modify-azure-sql-vm-license-type.log) and, when any
    resources are touched, a CSV report (ModifiedResources_<timestamp>.csv).

.VERSION
    1.2.0

.PARAMETER SubId
    A single subscription ID or a .csv file with a 'SubscriptionId' column. If omitted,
    every enabled subscription in the current tenant is scanned.

.PARAMETER ResourceGroup
    Optional. Limits scope to a single resource group.

.PARAMETER VMName
    Optional. A single Azure SQL VM name or a .csv file with a 'VMName' column.

.PARAMETER LicenseType
    Optional. License type to apply. Allowed values: 'PAYG', 'AHUB', 'DR'.

.PARAMETER EnableESU
    Optional. 'Yes' enables ESU, 'No' disables it. Requires LicenseType to be (or
    already be) 'PAYG' or 'AHUB' when enabling.

.PARAMETER Force
    Optional. When set, updates LicenseType even on resources where it is already
    populated. Without -Force, license type is only written when the current value is
    empty/unset (matching the Arc script's semantics).

.PARAMETER ExclusionTags
    Optional. Hashtable or JSON object of tag key/value pairs. Resources whose tags
    match any listed pair are skipped.

.PARAMETER TenantId
    Optional. Tenant id to authenticate against. Defaults to the current Az context tenant.

.PARAMETER ReportOnly
    Optional. Discover and log changes that would be made; do not call Update-AzSqlVM
    or Set-AzVMExtension.

.PARAMETER UseManagedIdentity
    Optional. Authenticate using a managed identity. Required for Azure Automation
    runbooks (auto-detected in that environment as well).

.PARAMETER FixManagedIdentity
    Optional. When set (and -ReportOnly is not), enables a system-assigned managed
    identity on the underlying compute VM if it is missing. Additive — preserves any
    existing user-assigned identities.

.PARAMETER FixArcDataRp
    Optional. When set (and -ReportOnly is not), registers the Microsoft.AzureArcData
    resource provider on each in-scope subscription where it is not yet Registered.

.PARAMETER FixManagementMode
    Optional. When set (and -ReportOnly is not), upgrades the SqlIaaSAgent SQL
    Management mode to 'Full' for VMs where it is not already Full. Note: this
    re-runs the extension handler and can take several minutes per VM.

.PARAMETER BatchSize
    Optional. Page size for Search-AzGraph. Defaults to 500.

.EXAMPLE
    # Preview changes across the whole tenant
    ./modify-azure-sql-vm-license-type.ps1 -ReportOnly

.EXAMPLE
    # Set all Azure SQL VMs in a subscription to PAYG and enable ESU
    ./modify-azure-sql-vm-license-type.ps1 -SubId <subId> -LicenseType PAYG -EnableESU Yes -Force

.EXAMPLE
    # Apply to a single VM
    ./modify-azure-sql-vm-license-type.ps1 -SubId <subId> -ResourceGroup myRG -VMName mySqlVm `
        -LicenseType AHUB -EnableESU Yes

.EXAMPLE
    # Bulk run from CSVs, excluding tagged resources
    ./modify-azure-sql-vm-license-type.ps1 -SubId .\subscriptions.csv -VMName .\vms.csv `
        -LicenseType PAYG -ExclusionTags '{"env":"prod"}'

.NOTES
    Requires PowerShell 7+ and the following modules:
        Az.Accounts, Az.SqlVirtualMachine, Az.Compute, Az.ResourceGraph
    Minimum RBAC: Contributor (or SQL Virtual Machine Contributor + Virtual Machine
    Contributor) on the in-scope resources.
#>

#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.SqlVirtualMachine, Az.Compute, Az.ResourceGraph

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $SubId,

    [Parameter(Mandatory = $false)]
    [string] $ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string] $VMName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('PAYG', 'AHUB', 'DR', IgnoreCase = $false)]
    [string] $LicenseType,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Yes', 'No', IgnoreCase = $false)]
    [string] $EnableESU,

    [Parameter(Mandatory = $false)]
    [switch] $Force,

    [Parameter(Mandatory = $false)]
    [object] $ExclusionTags,

    [Parameter(Mandatory = $false)]
    [string] $TenantId,

    [Parameter(Mandatory = $false)]
    [switch] $ReportOnly,

    [Parameter(Mandatory = $false)]
    [switch] $UseManagedIdentity,

    [Parameter(Mandatory = $false)]
    [switch] $FixManagedIdentity,

    [Parameter(Mandatory = $false)]
    [switch] $FixArcDataRp,

    [Parameter(Mandatory = $false)]
    [switch] $FixManagementMode,

    [Parameter(Mandatory = $false)]
    [int] $BatchSize = 500
)

# Constants for the SqlIaaSAgent extension
$Script:ESU_EXT_PUBLISHER = 'Microsoft.SqlServer.Management'
$Script:ESU_EXT_TYPE      = 'SqlIaaSAgent'
$Script:ESU_EXT_VERSION   = '2.0'

# Minimum SqlIaaSAgent version surfaced as a prerequisite by the SQL Server
# configuration UX (SqlVmUnifiedConfiguration.tsx -> minRequiredSqlIaaSVersion).
$Script:MIN_SQLIAAS_VERSION = '2.0.227.1'

# Cache of Microsoft.AzureArcData RP registration state, keyed by subscription id.
$Script:ArcDataRpCache = @{}

Start-Transcript -Path '.\modify-azure-sql-vm-license-type.log' -Append | Out-Null
$scriptStartTime = Get-Date
Write-Output "Script execution started at: $($scriptStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

function Connect-Azure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [string] $TenantId,
        [Parameter(Mandatory = $false)] [switch] $UseManagedIdentity
    )

    $envType = 'Local'
    if ($env:AZUREPS_HOST_ENVIRONMENT -like 'cloud-shell*') {
        $envType = 'CloudShell'
    }
    elseif (($env:AZUREPS_HOST_ENVIRONMENT -like 'AzureAutomation*') -or $PSPrivateMetadata.JobId) {
        $envType = 'AzureAutomation'
        $UseManagedIdentity = $true
    }
    Write-Output "Environment detected: $envType"

    try { Update-AzConfig -LoginExperienceV2 Off -ErrorAction SilentlyContinue | Out-Null }
    catch { Write-Verbose "Update-AzConfig not available or failed: $($_.Exception.Message)" }

    $currentCtx = Get-AzContext -ErrorAction SilentlyContinue
    if ($currentCtx -and $currentCtx.Account) {
        if ($TenantId) {
            if ($currentCtx.Tenant.Id -eq $TenantId) {
                Write-Output "Already in Az tenant $TenantId"
            }
            else {
                Write-Output "Switching Az context to tenant $TenantId"
                $newContext = Set-AzContext -Tenant $TenantId -ErrorAction SilentlyContinue
                if ($null -eq $newContext -or $newContext.Tenant.Id -ne $TenantId) {
                    Connect-AzAccount -Tenant $TenantId | Out-Null
                }
            }
        }
        else {
            Write-Output "Using existing Az context: Tenant $($currentCtx.Tenant.Id)"
        }
    }
    else {
        Write-Output 'Not connected to Azure PowerShell. Running Connect-AzAccount...'
        if ($UseManagedIdentity) {
            if ($TenantId) { Connect-AzAccount -Identity -Tenant $TenantId | Out-Null }
            else           { Connect-AzAccount -Identity -ErrorAction Stop | Out-Null }
        }
        else {
            if ($TenantId) { Connect-AzAccount -Tenant $TenantId | Out-Null }
            else           { Connect-AzAccount | Out-Null }
        }
        $ctx = Get-AzContext
        Write-Output "Connected to Az PowerShell as: $($ctx.Account) in tenant $($ctx.Tenant.Id)"
    }

    return $envType
}

function ConvertTo-TagHashtable {
    param([Parameter(Mandatory = $false)] [object] $InputObject)
    $result = @{}
    if ($null -eq $InputObject) { return $result }
    if ($InputObject -is [hashtable]) { return $InputObject }
    try {
        ($InputObject | ConvertFrom-Json -ErrorAction Stop).PSObject.Properties | ForEach-Object {
            $result[$_.Name] = $_.Value
        }
    }
    catch {
        Write-Warning "ExclusionTags could not be parsed as JSON or hashtable; ignoring."
    }
    return $result
}

function Test-ExcludedByTag {
    param(
        [hashtable] $ResourceTags,
        [hashtable] $ExclusionTagTable
    )
    if (-not $ResourceTags -or $ExclusionTagTable.Count -eq 0) { return $false }
    foreach ($key in $ExclusionTagTable.Keys) {
        if ($ResourceTags.ContainsKey($key) -and ($ResourceTags[$key] -eq $ExclusionTagTable[$key])) {
            Write-Output "    Exclusion tag $key=$($ExclusionTagTable[$key]) matched. Skipping..."
            return $true
        }
    }
    return $false
}

function Import-CsvColumn {
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string] $Column
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "CSV file not found: $Path"
    }
    $rows = Import-Csv -Path $Path
    if (-not $rows) { return @() }
    if (-not ($rows[0].PSObject.Properties.Name -contains $Column)) {
        throw "CSV '$Path' is missing required column '$Column'."
    }
    return @($rows | ForEach-Object { $_.$Column } | Where-Object { $_ })
}

function Get-SqlIaasExtensionSetting {
    param(
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $VMName,
        [Parameter(Mandatory = $true)] [string] $ExtensionName
    )
    try {
        $ext = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName `
                                 -Name $ExtensionName -ErrorAction Stop
    }
    catch {
        return $null
    }

    $settings = @{}
    if ($ext.Settings) {
        # PublicSettings comes back as a JSON string on some platforms, a hashtable on others.
        if ($ext.Settings -is [string]) {
            try {
                ($ext.Settings | ConvertFrom-Json).PSObject.Properties | ForEach-Object {
                    $settings[$_.Name] = $_.Value
                }
            } catch {
                Write-Verbose "Could not parse SqlIaaSAgent Settings as JSON: $($_.Exception.Message)"
            }
        }
        elseif ($ext.Settings -is [hashtable]) {
            $settings = $ext.Settings.Clone()
        }
        else {
            $ext.Settings.PSObject.Properties | ForEach-Object {
                $settings[$_.Name] = $_.Value
            }
        }
    }
    return @{ Extension = $ext; Settings = $settings }
}

function Set-EsuOnSqlVm {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $VMName,
        [Parameter(Mandatory = $true)] [string] $Location,
        [Parameter(Mandatory = $true)] [string] $ExtensionName,
        [Parameter(Mandatory = $true)] [bool]   $Enable
    )
    $existing = Get-SqlIaasExtensionSetting -ResourceGroupName $ResourceGroupName -VMName $VMName -ExtensionName $ExtensionName
    if ($null -eq $existing) {
        throw "SqlIaaSAgent extension '$ExtensionName' not found on VM '$VMName' in RG '$ResourceGroupName'. Cannot toggle ESU."
    }

    $settings = $existing.Settings
    $settings['enableExtendedSecurityUpdates'] = $Enable
    $settings['esuLastUpdatedTimestamp']       = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

    if ($PSCmdlet.ShouldProcess("$ResourceGroupName/$VMName", "Set SqlIaaSAgent ESU=$Enable")) {
        Set-AzVMExtension -ResourceGroupName   $ResourceGroupName `
                          -VMName              $VMName `
                          -Location            $Location `
                          -Name                $ExtensionName `
                          -Publisher           $Script:ESU_EXT_PUBLISHER `
                          -ExtensionType       $Script:ESU_EXT_TYPE `
                          -TypeHandlerVersion  $Script:ESU_EXT_VERSION `
                          -Settings            $settings `
                          -ErrorAction         Stop | Out-Null
    }
}

# ---------------------------------------------------------------------------
# Prerequisite-detection helpers (mirror SqlVmManagementSection.tsx)
# ---------------------------------------------------------------------------

function Test-VersionGreaterOrEqual {
    <#
    .SYNOPSIS
        Returns $true if Actual >= Required. Mirrors the TSX isVersionGreaterOrEqual
        helper used by the Azure portal SQL Server configuration page.
    #>
    param(
        [Parameter(Mandatory = $false)] [string] $Actual,
        [Parameter(Mandatory = $true)]  [string] $Required
    )
    if ([string]::IsNullOrWhiteSpace($Actual)) { return $false }
    $a = $null; $r = $null
    if ([Version]::TryParse($Actual,   [ref] $a) -and
        [Version]::TryParse($Required, [ref] $r)) {
        return ($a -ge $r)
    }
    # Fallback: lexicographic compare of dotted segments
    $aParts = $Actual.Split('.')   | ForEach-Object { [int]::TryParse($_, [ref] $null) | Out-Null; [int]$_ }
    $rParts = $Required.Split('.') | ForEach-Object { [int]::TryParse($_, [ref] $null) | Out-Null; [int]$_ }
    for ($i = 0; $i -lt [Math]::Max($aParts.Count, $rParts.Count); $i++) {
        $av = if ($i -lt $aParts.Count) { $aParts[$i] } else { 0 }
        $rv = if ($i -lt $rParts.Count) { $rParts[$i] } else { 0 }
        if ($av -gt $rv) { return $true }
        if ($av -lt $rv) { return $false }
    }
    return $true
}

function Test-AzureArcDataRpRegistered {
    <#
    .SYNOPSIS
        Returns $true if Microsoft.AzureArcData RP is registered on the subscription.
        Results are cached per subscription id for the lifetime of the script.
    #>
    param(
        [Parameter(Mandatory = $true)] [string] $SubscriptionId
    )
    if ($Script:ArcDataRpCache.ContainsKey($SubscriptionId)) {
        return $Script:ArcDataRpCache[$SubscriptionId]
    }
    $registered = $null
    try {
        $rp = Get-AzResourceProvider -ProviderNamespace 'Microsoft.AzureArcData' -ErrorAction Stop |
              Select-Object -First 1
        $registered = ($rp -and $rp.RegistrationState -eq 'Registered')
    }
    catch {
        Write-Verbose "Get-AzResourceProvider failed for $SubscriptionId : $($_.Exception.Message)"
        $registered = $null
    }
    $Script:ArcDataRpCache[$SubscriptionId] = $registered
    return $registered
}

# ---------------------------------------------------------------------------
# Portal deep-link helpers
# Mirror the navigation that SqlVmManagementSection.tsx performs via Az.openBlade.
# ---------------------------------------------------------------------------

function Get-PortalResourceUrl {
    param(
        [Parameter(Mandatory = $true)]  [string] $TenantId,
        [Parameter(Mandatory = $true)]  [string] $ResourceId,
        [Parameter(Mandatory = $false)] [string] $SubBlade = ''
    )
    # Friendly deep-link form: https://portal.azure.com/#@<tenant>/resource<resourceId>[/<subblade>]
    $url = "https://portal.azure.com/#@$TenantId/resource$ResourceId"
    if ($SubBlade) { $url += "/$SubBlade" }
    return $url
}

function Get-PrereqRemediationLink {
    <#
    .SYNOPSIS
        Returns a hashtable of remediation hints (Url + suggested action) for any
        unmet prerequisite. Mirrors the hyperlinks shown in the Azure portal.
    #>
    param(
        [Parameter(Mandatory = $true)]  [string] $TenantId,
        [Parameter(Mandatory = $true)]  [string] $SubscriptionId,
        [Parameter(Mandatory = $true)]  [string] $VmResourceId,
        [Parameter(Mandatory = $true)]  [string] $SqlVmResourceId,
        [Parameter(Mandatory = $true)]  [bool]   $IsExtVersionMet,
        [Parameter()]                   $HasSysIdentity,
        [Parameter()]                   $ArcDataReg,
        [Parameter(Mandatory = $true)]  [bool]   $IsMgmtFull
    )
    $links = [ordered]@{}

    if (-not $IsExtVersionMet) {
        $links['SqlIaaSExtensionVersion'] = [PSCustomObject]@{
            Action = "Upgrade SqlIaaSAgent extension to >= $($Script:MIN_SQLIAAS_VERSION)"
            Url    = Get-PortalResourceUrl -TenantId $TenantId -ResourceId $VmResourceId -SubBlade 'extensions'
        }
    }
    if ($HasSysIdentity -eq $false) {
        $links['SystemAssignedIdentity'] = [PSCustomObject]@{
            Action = 'Enable system-assigned managed identity on the VM'
            Url    = Get-PortalResourceUrl -TenantId $TenantId -ResourceId $VmResourceId -SubBlade 'identity'
        }
    }
    if ($ArcDataReg -ne $true) {
        $links['AzureArcDataRp'] = [PSCustomObject]@{
            Action = 'Register the Microsoft.AzureArcData resource provider on the subscription'
            Url    = "https://portal.azure.com/#@$TenantId/resource/subscriptions/$SubscriptionId/resourceProviders"
        }
    }
    if (-not $IsMgmtFull) {
        $links['SqlManagementMode'] = [PSCustomObject]@{
            Action = "Upgrade SQL Management mode to 'Full' (Update-AzSqlVM -SqlManagementType Full)"
            # No portal blade — the portal calls upgradeSqlVmManagementMode inline.
            # Deep-link to the SQL VM resource overview so the operator can take action there.
            Url    = Get-PortalResourceUrl -TenantId $TenantId -ResourceId $SqlVmResourceId
        }
    }
    return $links
}

# ---------------------------------------------------------------------------
# Auto-remediation helpers
# Each is opt-in via the corresponding -Fix* switch; each respects -ReportOnly.
# ---------------------------------------------------------------------------

function Enable-SystemAssignedIdentity {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $VMName
    )
    if (-not $PSCmdlet.ShouldProcess("$ResourceGroupName/$VMName", 'Enable SystemAssigned identity')) { return }
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction Stop
    $currentType = if ($vm.Identity) { [string]$vm.Identity.Type } else { '' }
    # Preserve existing user-assigned identities by switching to SystemAssigned,UserAssigned when needed.
    $newType = if ($currentType -match 'UserAssigned') { 'SystemAssigned,UserAssigned' } else { 'SystemAssigned' }
    Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -IdentityType $newType -ErrorAction Stop | Out-Null
}

function Register-ArcDataResourceProvider {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory = $true)] [string] $SubscriptionId
    )
    if (-not $PSCmdlet.ShouldProcess("subscription $SubscriptionId", 'Register Microsoft.AzureArcData RP')) { return }
    Register-AzResourceProvider -ProviderNamespace 'Microsoft.AzureArcData' -ErrorAction Stop | Out-Null
    # Invalidate cache so subsequent VMs in the same sub see the new state.
    if ($Script:ArcDataRpCache.ContainsKey($SubscriptionId)) {
        $Script:ArcDataRpCache.Remove($SubscriptionId) | Out-Null
    }
}

function Set-SqlVmManagementModeFull {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $VMName
    )
    if (-not $PSCmdlet.ShouldProcess("$ResourceGroupName/$VMName", "Set SqlManagementType=Full")) { return }
    Update-AzSqlVM -ResourceGroupName $ResourceGroupName -Name $VMName -SqlManagementType Full -ErrorAction Stop | Out-Null
}

# -----------------
# Auth + bootstrap
# -----------------
$envType = Connect-Azure -TenantId $TenantId -UseManagedIdentity:$UseManagedIdentity

$context = Get-AzContext -ErrorAction SilentlyContinue
if ($null -eq $context) { throw 'No Azure context after Connect-Azure.' }
Write-Output "Connected to Azure as: $($context.Account)"

if (-not $TenantId) {
    $TenantId = $context.Tenant.Id
    Write-Output "No TenantId provided. Using current context TenantId: $TenantId"
}
else {
    Write-Output "Using provided TenantId: $TenantId"
}

$tagTable = ConvertTo-TagHashtable -InputObject $ExclusionTags

# -----------------
# Resolve scope
# -----------------
$subscriptions = @()
if ($SubId -and ($SubId -like '*.csv')) {
    $subIds = Import-CsvColumn -Path $SubId -Column 'SubscriptionId'
    foreach ($s in $subIds) {
        try   { $subscriptions += Get-AzSubscription -SubscriptionId $s -ErrorAction Stop }
        catch { Write-Warning "Subscription '$s' not accessible: $($_.Exception.Message)" }
    }
}
elseif ($SubId) {
    $subscriptions = Get-AzSubscription -SubscriptionId $SubId
}
else {
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $TenantId }
}

if (-not $subscriptions -or $subscriptions.Count -eq 0) {
    throw 'No subscriptions resolved for the requested scope.'
}

$vmNames = @()
if ($VMName) {
    if ($VMName -like '*.csv') {
        $vmNames = Import-CsvColumn -Path $VMName -Column 'VMName'
        Write-Output "Loaded $($vmNames.Count) VM name(s) from CSV."
    }
    else {
        $vmNames = @($VMName)
    }
}

# Validate ESU/license combination up-front (cheap)
if ($EnableESU -eq 'Yes') {
    $effective = if ($LicenseType) { $LicenseType } else { '<existing>' }
    if ($LicenseType -eq 'DR') {
        throw "ESU cannot be enabled when LicenseType is 'DR'. Use 'PAYG' or 'AHUB'."
    }
    Write-Output "ESU will be enabled (effective LicenseType: $effective). 'DR' resources will be skipped."
}

# -----------------
# Process
# -----------------
$modifiedResources = [System.Collections.Generic.List[object]]::new()

Write-Output ([Environment]::NewLine + '-- Scanning subscriptions --')

foreach ($sub in $subscriptions) {
    if ($sub.State -and $sub.State -ne 'Enabled') {
        Write-Output "Skipping non-Enabled subscription: $($sub.Id) ($($sub.State))"
        continue
    }

    try {
        Set-AzContext -SubscriptionId $sub.Id -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Warning "Invalid subscription: $($sub.Id) - $($_.Exception.Message)"
        continue
    }

    Write-Output "[$($sub.Id)] Collecting Azure SQL VMs..."

    $query = @"
resources
| where type =~ 'microsoft.sqlvirtualmachine/sqlvirtualmachines'
| where subscriptionId =~ '$($sub.Id)'
"@

    if ($ResourceGroup) {
        $query += "`n| where resourceGroup =~ '$ResourceGroup'"
    }
    if ($vmNames.Count -gt 0) {
        $list = ($vmNames | ForEach-Object { "'$_'" }) -join ', '
        $query += "`n| where name in~ ($list)"
    }
    if ($LicenseType) {
        $query += "`n| where isnull(properties.sqlServerLicenseType) or tostring(properties.sqlServerLicenseType) !~ '$LicenseType'"
    }
    $query += @"

| extend vmIdLower = tolower(tostring(properties.virtualMachineResourceId))
| project sqlVmName = name, resourceGroup, location, subscriptionId,
          currentLicenseType = tostring(properties.sqlServerLicenseType),
          sqlManagement      = tostring(properties.sqlManagement),
          vmIdLower, tags
| join kind=leftouter (
    resources
    | where type =~ 'microsoft.compute/virtualmachines'
    | extend vmIdLower    = tolower(id)
    | extend identityType = tostring(identity.type)
    | project vmIdLower, identityType
) on vmIdLower
| join kind=leftouter (
    resources
    | where type =~ 'microsoft.compute/virtualmachines/extensions'
    | where properties.publisher =~ 'Microsoft.SqlServer.Management'
    | where properties.type =~ 'SqlIaaSAgent'
    | extend vmIdLower       = tolower(substring(id, 0, indexof(id, '/extensions/')))
    | extend sqlIaasExtName  = name
    | extend sqlIaasVersion  = tostring(properties.typeHandlerVersion)
    | project vmIdLower, sqlIaasExtName, sqlIaasVersion
) on vmIdLower
| project name = sqlVmName, resourceGroup, location, subscriptionId,
          currentLicenseType, sqlManagement, identityType, sqlIaasExtName, sqlIaasVersion, tags
| order by name asc
"@

    Write-Verbose $query

    $allResults = [System.Collections.Generic.List[object]]::new()
    $skipToken  = $null
    do {
        if ($skipToken) {
            $page = Search-AzGraph -Query $query -First $BatchSize -SkipToken $skipToken
        } else {
            $page = Search-AzGraph -Query $query -First $BatchSize
        }
        if ($page) { $allResults.AddRange($page) }
        $skipToken = $page.SkipToken
    } while ($skipToken)

    Write-Output "    Found $($allResults.Count) Azure SQL VM resource(s) needing review."

    foreach ($r in $allResults) {
        $rgName    = $r.resourceGroup
        $vmName    = $r.name
        $location  = $r.location
        $currentLT = $r.currentLicenseType

        Write-Output "  -- $rgName/$vmName (location=$location, currentLicenseType=$([string]::IsNullOrEmpty($currentLT) ? '<unset>' : $currentLT))"

        # Build a hashtable view of tags (Resource Graph returns a PSCustomObject)
        $resourceTags = @{}
        if ($r.tags) {
            $r.tags.PSObject.Properties | ForEach-Object { $resourceTags[$_.Name] = $_.Value }
        }
        if (Test-ExcludedByTag -ResourceTags $resourceTags -ExclusionTagTable $tagTable) {
            continue
        }

        # ---- Prerequisite detection (informational; never blocks apply paths) ----
        # Resource Graph only has the major.minor version (e.g. "2.0"). The full version
        # (e.g. "2.0.227.1") lives in the extension instanceView, so we fetch it via ARM
        # the same way the Azure portal does ($expand=instanceView).
        $sqlIaasExtName    = if ($r.PSObject.Properties.Name -contains 'sqlIaasExtName')  { [string]$r.sqlIaasExtName }  else { '' }
        $identityType      = if ($r.PSObject.Properties.Name -contains 'identityType')   { [string]$r.identityType }   else { '' }
        $sqlManagementMode = if ($r.PSObject.Properties.Name -contains 'sqlManagement')  { [string]$r.sqlManagement }  else { '' }

        $vmResourceId = "/subscriptions/$($r.subscriptionId)/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName"
        $sqlIaasVer = ''
        if (-not [string]::IsNullOrEmpty($sqlIaasExtName)) {
            try {
                # Fetch the extension with $expand=instanceView to get the full version
                # (mirrors the portal's getVmExtensionMetadata call).
                $extPath = "$vmResourceId/extensions/$($sqlIaasExtName)?api-version=2023-09-01&`$expand=instanceView"
                $resp = Invoke-AzRestMethod -Path $extPath -Method GET -ErrorAction Stop
                if ($resp.StatusCode -eq 200) {
                    $extJson = $resp.Content | ConvertFrom-Json
                    $sqlIaasVer = [string]$extJson.properties.instanceView.typeHandlerVersion
                }
            }
            catch {
                Write-Verbose "    Could not fetch extension instanceView for $rgName/$vmName/$sqlIaasExtName : $($_.Exception.Message)"
            }
        }

        $isExtVersionMet = Test-VersionGreaterOrEqual -Actual $sqlIaasVer -Required $Script:MIN_SQLIAAS_VERSION
        $hasSysIdentity  = ($identityType -match 'SystemAssigned')
        $isMgmtFull      = ($sqlManagementMode -and $sqlManagementMode.ToLower() -eq 'full')
        $arcDataReg      = Test-AzureArcDataRpRegistered -SubscriptionId $r.subscriptionId

        $glyph = { param($b) if ($null -eq $b) { '?' } elseif ($b) { '+' } else { '-' } }
        Write-Output ("    Prereqs: SqlIaaSAgent>={0} [{1}] (actual={2})  SystemAssignedMI [{3}]  AzureArcDataRP [{4}]  SqlManagement=Full [{5}] (actual={6})" -f `
            $Script:MIN_SQLIAAS_VERSION,
            (& $glyph $isExtVersionMet),
            ($sqlIaasVer | ForEach-Object { if ([string]::IsNullOrEmpty($_)) { '<none>' } else { $_ } }),
            (& $glyph $hasSysIdentity),
            (& $glyph $arcDataReg),
            (& $glyph $isMgmtFull),
            ($sqlManagementMode | ForEach-Object { if ([string]::IsNullOrEmpty($_)) { '<none>' } else { $_ } })
        )

        # ---- Collect portal deep-links for unmet prereqs (written to CSV only) ----
        $sqlVmResourceId = "/subscriptions/$($r.subscriptionId)/resourceGroups/$rgName/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/$vmName"
        $remediation     = Get-PrereqRemediationLink `
                              -TenantId        $TenantId `
                              -SubscriptionId  $r.subscriptionId `
                              -VmResourceId    $vmResourceId `
                              -SqlVmResourceId $sqlVmResourceId `
                              -IsExtVersionMet $isExtVersionMet `
                              -HasSysIdentity  $hasSysIdentity `
                              -ArcDataReg      $arcDataReg `
                              -IsMgmtFull      $isMgmtFull

        # ---- Auto-remediation (opt-in via -Fix* switches; honors -ReportOnly) ----
        $fixIdentityResult = ''
        $fixArcRpResult    = ''
        $fixMgmtResult     = ''

        if ($FixManagedIdentity.IsPresent -and $hasSysIdentity -eq $false) {
            if ($ReportOnly.IsPresent) {
                $fixIdentityResult = 'WouldFix'
                Write-Output '    [ReportOnly] Would enable system-assigned managed identity.'
            } else {
                try {
                    Write-Output '    Enabling system-assigned managed identity...'
                    Enable-SystemAssignedIdentity -ResourceGroupName $rgName -VMName $vmName
                    $fixIdentityResult = 'Fixed'
                    $hasSysIdentity    = $true
                }
                catch {
                    $fixIdentityResult = "Failed: $($_.Exception.Message)"
                    Write-Warning "    Enabling system-assigned identity failed: $($_.Exception.Message)"
                }
            }
        }

        if ($FixArcDataRp.IsPresent -and $arcDataReg -ne $true) {
            if ($ReportOnly.IsPresent) {
                $fixArcRpResult = 'WouldFix'
                Write-Output '    [ReportOnly] Would register Microsoft.AzureArcData RP on the subscription.'
            } else {
                try {
                    Write-Output '    Registering Microsoft.AzureArcData RP on the subscription...'
                    Register-ArcDataResourceProvider -SubscriptionId $r.subscriptionId
                    $fixArcRpResult = 'Fixed'
                    $arcDataReg     = $true
                }
                catch {
                    $fixArcRpResult = "Failed: $($_.Exception.Message)"
                    Write-Warning "    Registering Microsoft.AzureArcData RP failed: $($_.Exception.Message)"
                }
            }
        }

        if ($FixManagementMode.IsPresent -and -not $isMgmtFull) {
            if ($ReportOnly.IsPresent) {
                $fixMgmtResult = 'WouldFix'
                Write-Output "    [ReportOnly] Would upgrade SqlManagementType to 'Full'."
            } else {
                try {
                    Write-Output "    Upgrading SqlManagementType to 'Full' (this may take several minutes)..."
                    Set-SqlVmManagementModeFull -ResourceGroupName $rgName -VMName $vmName
                    $fixMgmtResult     = 'Fixed'
                    $isMgmtFull        = $true
                    $sqlManagementMode = 'Full'
                }
                catch {
                    $fixMgmtResult = "Failed: $($_.Exception.Message)"
                    Write-Warning "    Upgrading SqlManagementType failed: $($_.Exception.Message)"
                }
            }
        }

        # Compute desired actions
        $writeLicense   = $false
        $writeEsu       = $false
        $effectiveLT    = $currentLT

        if ($LicenseType) {
            if ([string]::IsNullOrEmpty($currentLT)) {
                $writeLicense = $true
                $effectiveLT  = $LicenseType
            }
            elseif ($Force.IsPresent -and ($currentLT -ne $LicenseType)) {
                $writeLicense = $true
                $effectiveLT  = $LicenseType
            }
            elseif ($currentLT -ne $LicenseType) {
                Write-Output '    LicenseType differs but -Force not specified. Leaving as-is.'
            }
        }

        if ($EnableESU) {
            $esuTargetBool = ($EnableESU -eq 'Yes')
            if ($esuTargetBool -and ($effectiveLT -notin @('PAYG','AHUB'))) {
                Write-Output "    ESU requires LicenseType in PAYG/AHUB (effective='$effectiveLT'). Skipping ESU change."
            }
            else {
                $writeEsu = $true
            }
        }

        $record = [PSCustomObject]@{
            TenantID                        = $TenantId
            SubID                           = $r.subscriptionId
            ResourceGroup                   = $rgName
            ResourceName                    = $vmName
            ResourceType                    = 'Microsoft.SqlVirtualMachine/sqlVirtualMachines'
            Location                        = $location
            OriginalLicenseType             = $currentLT
            TargetLicenseType               = if ($writeLicense) { $LicenseType } else { $currentLT }
            EsuAction                       = if ($writeEsu) { $EnableESU } else { '' }
            Mode                            = if ($ReportOnly.IsPresent) { 'ReportOnly' } else { 'Apply' }
            LicenseStatus                   = ''
            EsuStatus                       = ''
            Error                           = ''
            # Prerequisite checks (informational; do not gate updates)
            SqlIaaSExtensionVersion         = $sqlIaasVer
            IsSqlIaaSExtensionVersionMet    = $isExtVersionMet
            MinRequiredSqlIaaSExtensionVersion = $Script:MIN_SQLIAAS_VERSION
            HasSystemAssignedIdentity       = $hasSysIdentity
            IsAzureArcDataRpRegistered      = $arcDataReg
            SqlManagementMode               = $sqlManagementMode
            IsSqlManagementModeFull         = $isMgmtFull
            # Portal deep-links for any unmet prereq (semicolon-separated key=url pairs)
            PrereqRemediationLinks          = (($remediation.Keys | ForEach-Object { "$_=$($remediation[$_].Url)" }) -join ' ; ')
            # Auto-remediation outcomes (populated only when the corresponding -Fix* switch is set)
            FixManagedIdentityResult        = $fixIdentityResult
            FixArcDataRpResult              = $fixArcRpResult
            FixManagementModeResult         = $fixMgmtResult
        }

        if (-not $writeLicense -and -not $writeEsu) {
            Write-Output '    No changes required.'
            $record.LicenseStatus = 'NoChange'
            $record.EsuStatus     = 'NoChange'
            $modifiedResources.Add($record)
            continue
        }

        if ($ReportOnly.IsPresent) {
            Write-Output "    [ReportOnly] Would set LicenseType=$($record.TargetLicenseType), ESU=$($record.EsuAction)"
            $record.LicenseStatus = if ($writeLicense) { 'WouldUpdate' } else { 'NoChange' }
            $record.EsuStatus     = if ($writeEsu)     { 'WouldUpdate' } else { 'NoChange' }
            $modifiedResources.Add($record)
            continue
        }

        # ----- Apply license type -----
        if ($writeLicense) {
            try {
                Write-Output "    Setting LicenseType=$LicenseType via Update-AzSqlVM..."
                Update-AzSqlVM -ResourceGroupName $rgName -Name $vmName -LicenseType $LicenseType -ErrorAction Stop | Out-Null
                $record.LicenseStatus = 'Updated'
            }
            catch {
                $msg = $_.Exception.Message
                Write-Warning "    Update-AzSqlVM failed for $rgName/$vmName : $msg"
                $record.LicenseStatus = 'Failed'
                $record.Error         = $msg
                $modifiedResources.Add($record)
                continue
            }
        }
        else {
            $record.LicenseStatus = 'NoChange'
        }

        # ----- Apply ESU -----
        if ($writeEsu) {
            if ([string]::IsNullOrEmpty($sqlIaasExtName)) {
                Write-Warning "    ESU update skipped for $rgName/$vmName : SqlIaaSAgent extension not found"
                $record.EsuStatus = 'Failed'
                $record.Error     = ($record.Error, 'SqlIaaSAgent extension not found') | Where-Object { $_ } -join ' | '
            }
            else {
                try {
                    Write-Output "    Setting ESU=$($EnableESU) on SqlIaaSAgent extension..."
                    Set-EsuOnSqlVm -ResourceGroupName $rgName -VMName $vmName -Location $location -ExtensionName $sqlIaasExtName -Enable ($EnableESU -eq 'Yes')
                    $record.EsuStatus = 'Updated'
                }
                catch {
                    $msg = $_.Exception.Message
                    Write-Warning "    ESU update failed for $rgName/$vmName : $msg"
                    $record.EsuStatus = 'Failed'
                    $record.Error     = ($record.Error, $msg | Where-Object { $_ }) -join ' | '
                }
            }
        }
        else {
            $record.EsuStatus = 'NoChange'
        }

        $modifiedResources.Add($record)
    }
}

# -----------------
# Report
# -----------------
if ($modifiedResources.Count -gt 0) {
    $csvPath = "ModifiedResources_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $modifiedResources | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "CSV report saved to: $csvPath"

    $applied = ($modifiedResources | Where-Object { $_.LicenseStatus -eq 'Updated' -or $_.EsuStatus -eq 'Updated' }).Count
    $would   = ($modifiedResources | Where-Object { $_.LicenseStatus -eq 'WouldUpdate' -or $_.EsuStatus -eq 'WouldUpdate' }).Count
    $failed  = ($modifiedResources | Where-Object { $_.LicenseStatus -eq 'Failed' -or $_.EsuStatus -eq 'Failed' }).Count
    Write-Output ''
    Write-Output '================ Azure SQL VM License Update Summary ================'
    Write-Output "Resources reviewed:  $($modifiedResources.Count)"
    Write-Output "Applied changes:     $applied"
    Write-Output "Would change (-ReportOnly): $would"
    Write-Output "Failed:              $failed"
}
else {
    Write-Output 'No resources matched the requested scope. No CSV generated.'
}

$scriptEndTime     = Get-Date
$executionDuration = $scriptEndTime - $scriptStartTime
Write-Output "Script execution ended at: $($scriptEndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "Total execution time:      $($executionDuration.ToString('hh\:mm\:ss'))"
Stop-Transcript | Out-Null
