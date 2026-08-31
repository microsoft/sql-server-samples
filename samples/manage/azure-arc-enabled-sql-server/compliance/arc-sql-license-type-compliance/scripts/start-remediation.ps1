param(
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$ManagementGroupId,

  [Parameter(Mandatory = $false)]
  [ValidateSet('Windows', 'Linux', 'Both')]
  [string]$ExtensionType = 'Both',

  [Parameter(Mandatory = $true)]
  [ValidateSet('Paid', 'PAYG')]
  [string]$TargetLicenseType,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$SubscriptionId,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$PolicyAssignmentName,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$RemediationName,

  [Parameter(Mandatory = $false)]
  [ValidateSet('ExistingNonCompliant', 'ReEvaluateCompliance')]
  [string]$ResourceDiscoveryMode,

  [Parameter(Mandatory = $false)]
  [switch]$GrantMissingPermissions
)

if (-not $PSBoundParameters.ContainsKey('ManagementGroupId')) {
  $ManagementGroupId = (Get-AzContext).Tenant.Id
  Write-Output "ManagementGroupId not specified. Using tenant root management group: $ManagementGroupId"
}

$AssignmentScope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"

if ($PSBoundParameters.ContainsKey('SubscriptionId')) {
  $AssignmentScope = "/subscriptions/$SubscriptionId"
}

$LicenseToken = if ($TargetLicenseType -eq 'PAYG') { 'payg' } else { 'sa' }

if ($ExtensionType -eq 'Both') {
  $PlatformToken = 'all'
}
else {
  $PlatformToken = $ExtensionType.ToLowerInvariant()
}

if (-not $PSBoundParameters.ContainsKey('PolicyAssignmentName')) {
  $PolicyAssignmentName = "sql-arc-$LicenseToken-$PlatformToken"
}

if (-not $PSBoundParameters.ContainsKey('RemediationName')) {
  $RemediationName = "remediate-sql-arc-$LicenseToken-$PlatformToken"
}

if (-not $PSBoundParameters.ContainsKey('ResourceDiscoveryMode')) {
  if ($PSBoundParameters.ContainsKey('SubscriptionId')) {
    $ResourceDiscoveryMode = 'ReEvaluateCompliance'
  }
  else {
    $ResourceDiscoveryMode = 'ExistingNonCompliant'
  }
}

# Validate assignment exists before creating remediation.
$PolicyAssignmentObj = Get-AzPolicyAssignment -Scope $AssignmentScope -Name $PolicyAssignmentName -ErrorAction Stop

$requiredRoleNames = @(
  'Azure Extension for SQL Server Deployment'
  'Reader'
  'Resource Policy Contributor'
)
$principalId = $PolicyAssignmentObj.IdentityPrincipalId

if ([string]::IsNullOrEmpty($principalId)) {
  throw "Policy assignment identity principal ID is empty. Cannot verify required roles."
}

$missingRoles = @()

foreach ($requiredRoleName in $requiredRoleNames) {
  $requiredRole = Get-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName $requiredRoleName `
    -Scope $AssignmentScope `
    -ErrorAction SilentlyContinue

  if (-not $requiredRole) {
    $missingRoles += $requiredRoleName
  }
}

if ($missingRoles.Count -gt 0) {
  if ($GrantMissingPermissions) {
    foreach ($missingRole in $missingRoles) {
      New-AzRoleAssignment `
        -ObjectId $principalId `
        -RoleDefinitionName $missingRole `
        -Scope $AssignmentScope `
        -ErrorAction Stop | Out-Null

      Write-Output "Assigned '$missingRole' to policy assignment identity ($principalId) at scope $AssignmentScope."
    }
  }
  else {
    throw "Missing required roles [$($missingRoles -join ', ')] for policy assignment identity ($principalId) at scope $AssignmentScope. Re-run with -GrantMissingPermissions or assign the roles manually."
  }
}

$CommonParams = @{
  Name                  = $RemediationName
  PolicyAssignmentId    = $PolicyAssignmentObj.Id
  Scope                 = $AssignmentScope
  ResourceDiscoveryMode = $ResourceDiscoveryMode
}

if (Get-Command -Name Start-AzPolicyRemediation -ErrorAction SilentlyContinue) {
  Start-AzPolicyRemediation @CommonParams
}
elseif (Get-Command -Name New-AzPolicyRemediation -ErrorAction SilentlyContinue) {
  New-AzPolicyRemediation @CommonParams
}
else {
  throw "Neither Start-AzPolicyRemediation nor New-AzPolicyRemediation is available. Install/update Az.PolicyInsights."
}
