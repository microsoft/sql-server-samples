param(
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$ManagementGroupId,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$SubscriptionId,

  [Parameter(Mandatory = $false)]
  [ValidateSet('Windows', 'Linux', 'Both')]
  [string]$ExtensionType = 'Both',

  [Parameter(Mandatory = $true)]
  [ValidateSet('Paid', 'PAYG')]
  [string]$TargetLicenseType,

  [Parameter(Mandatory = $false)]
  [ValidateSet('Unspecified', 'Paid', 'PAYG', 'LicenseOnly')]
  [string[]]$LicenseTypesToOverwrite = @('Unspecified', 'Paid', 'PAYG', 'LicenseOnly'),

  [Parameter(Mandatory = $false)]
  [switch]$SkipManagedIdentityRoleAssignment
)

if (-not $PSBoundParameters.ContainsKey('ManagementGroupId')) {
  $ManagementGroupId = (Get-AzContext).Tenant.Id
  Write-Output "ManagementGroupId not specified. Using tenant root management group: $ManagementGroupId"
}

$AssignmentScope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"

if ($PSBoundParameters.ContainsKey('SubscriptionId')) {
  $AssignmentScope = "/subscriptions/$SubscriptionId"
}

$ExtensionTypes = if ($ExtensionType -eq 'Both') {
  @('Windows', 'Linux')
}
else {
  @($ExtensionType)
}

$SqlServerExtensionTypes = $ExtensionTypes | ForEach-Object {
  if ($_ -eq 'Linux') { 'LinuxAgent.SqlServer' } else { 'WindowsAgent.SqlServer' }
}

$PolicyJsonPath = Join-Path $PSScriptRoot '..\policy\azurepolicy.json'
$LicenseToken = if ($TargetLicenseType -eq 'PAYG') { 'payg' } else { 'sa' }

if ($ExtensionType -eq 'Both') {
  $PlatformToken = 'all'
  $PlatformLabel = 'All platforms'
}
else {
  $PlatformToken = $ExtensionType.ToLowerInvariant()
  $PlatformLabel = $ExtensionType
}

$PolicyDefinitionName = "activate-sql-arc-$LicenseToken-$PlatformToken"
$PolicyAssignmentName = "sql-arc-$LicenseToken-$PlatformToken"

$LicenseTypeLabel = if ($TargetLicenseType -eq 'PAYG') { 'Pay-as-you-go' } else { 'License With Software Assurance' }
$PolicyDefinitionDisplayName = "Configure Arc-enabled SQL Server ($PlatformLabel) license type to '$LicenseTypeLabel'"
$PolicyAssignmentDisplayName = "Configure Arc-enabled SQL Server ($PlatformLabel) license type to '$LicenseTypeLabel'"

#Create policy definition
New-AzPolicyDefinition `
  -Name $PolicyDefinitionName `
  -DisplayName $PolicyDefinitionDisplayName `
  -Policy $PolicyJsonPath `
  -ManagementGroupName $ManagementGroupId `
  -Mode Indexed `
  -ErrorAction Stop

#Assign policy definition
$Policy = Get-AzPolicyDefinition -Name $PolicyDefinitionName -ManagementGroupName $ManagementGroupId
$PolicyAssignment = New-AzPolicyAssignment `
  -Name $PolicyAssignmentName `
  -DisplayName $PolicyAssignmentDisplayName `
  -PolicyDefinition $Policy `
  -PolicyParameterObject @{
    sqlServerExtensionTypes = $SqlServerExtensionTypes
    targetLicenseType       = $TargetLicenseType
    licenseTypesToOverwrite = $LicenseTypesToOverwrite
  } `
  -Scope $AssignmentScope `
  -Location 'westeurope' `
  -IdentityType 'SystemAssigned' `
  -ErrorAction Stop

if (-not $SkipManagedIdentityRoleAssignment) {
  $requiredRoleNames = @(
    'Azure Extension for SQL Server Deployment'
    'Reader'
    'Resource Policy Contributor'
  )
  $principalId = $PolicyAssignment.IdentityPrincipalId

  if ([string]::IsNullOrEmpty($principalId)) {
    throw "Policy assignment identity principal ID is empty. Cannot assign required roles."
  }

  foreach ($requiredRoleName in $requiredRoleNames) {
    $existingRole = Get-AzRoleAssignment `
      -ObjectId $principalId `
      -RoleDefinitionName $requiredRoleName `
      -Scope $AssignmentScope `
      -ErrorAction SilentlyContinue

    if (-not $existingRole) {
      New-AzRoleAssignment `
        -ObjectId $principalId `
        -RoleDefinitionName $requiredRoleName `
        -Scope $AssignmentScope `
        -ErrorAction Stop | Out-Null

      Write-Output "Assigned '$requiredRoleName' to policy assignment identity ($principalId) at scope $AssignmentScope."
    }
    else {
      Write-Output "Policy assignment identity already has '$requiredRoleName' at scope $AssignmentScope."
    }
  }
}