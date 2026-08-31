param(
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$ManagementGroupId,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$SubscriptionId,

  [Parameter(Mandatory = $true)]
  [ValidateSet('LicenseIncluded', 'BasePrice', 'HybridFailoverRights')]
  [string]$TargetLicenseType,

  [Parameter(Mandatory = $false)]
  [ValidateSet('LicenseIncluded', 'BasePrice', 'HybridFailoverRights')]
  [string[]]$LicenseTypesToOverwrite = @('LicenseIncluded', 'BasePrice', 'HybridFailoverRights'),

  [Parameter(Mandatory = $false)]
  [switch]$SkipManagedIdentityRoleAssignment,

  [Parameter(Mandatory = $false)]
  [switch]$SkipLicenseConfirmation
)

$LicenseConfirmations = @{
  'BasePrice'            = "I confirm that I have a SQL Server License with Software Assurance to apply this Azure Hybrid Benefit for SQL Server."
  'HybridFailoverRights' = "I confirm that I will use this Managed Instance as a passive replica of SQL Server(s) for which I have a SQL Server license with Software Assurance, or for which I use Pay-as-you-go billing option."
}

if (-not $SkipLicenseConfirmation -and $LicenseConfirmations.ContainsKey($TargetLicenseType)) {
  $confirmationMessage = $LicenseConfirmations[$TargetLicenseType]
  Write-Host "`n$confirmationMessage" -ForegroundColor Yellow
  $response = Read-Host "Do you agree? (Y/N)"
  if ($response -notin @('Y', 'y', 'Yes', 'yes')) {
    Write-Output "Deployment cancelled. License confirmation was not accepted."
    return
  }
}

if (-not $PSBoundParameters.ContainsKey('ManagementGroupId')) {
  $ManagementGroupId = (Get-AzContext).Tenant.Id
  Write-Output "ManagementGroupId not specified. Using tenant root management group: $ManagementGroupId"
}

$AssignmentScope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"

if ($PSBoundParameters.ContainsKey('SubscriptionId')) {
  $AssignmentScope = "/subscriptions/$SubscriptionId"
}

$PolicyJsonPath = Join-Path $PSScriptRoot '..\policy\azurepolicy.json'

$LicenseToken = switch ($TargetLicenseType) {
  'LicenseIncluded'      { 'payg' }
  'BasePrice'            { 'ahb' }
  'HybridFailoverRights' { 'hfr' }
}

$LicenseTypeLabel = switch ($TargetLicenseType) {
  'LicenseIncluded'      { 'Pay-as-you-go' }
  'BasePrice'            { 'Azure Hybrid Benefit' }
  'HybridFailoverRights' { 'Hybrid failover rights' }
}

$PolicyDefinitionName    = "activate-sql-mi-$LicenseToken"
$PolicyAssignmentName    = "sql-mi-$LicenseToken"
$PolicyDefinitionDisplayName = "Configure SQL Managed Instance license type to '$LicenseTypeLabel'"
$PolicyAssignmentDisplayName = "Configure SQL Managed Instance license type to '$LicenseTypeLabel'"

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
    targetLicenseType      = $TargetLicenseType
    licenseTypesToOverwrite = $LicenseTypesToOverwrite
  } `
  -Scope $AssignmentScope `
  -Location 'westeurope' `
  -IdentityType 'SystemAssigned' `
  -ErrorAction Stop

if (-not $SkipManagedIdentityRoleAssignment) {
  $requiredRoleNames = @(
    'SQL Managed Instance Contributor'
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
      $maxRetries = 5
      $retryDelay = 10
      for ($i = 1; $i -le $maxRetries; $i++) {
        try {
          New-AzRoleAssignment `
            -ObjectId $principalId `
            -RoleDefinitionName $requiredRoleName `
            -Scope $AssignmentScope `
            -ErrorAction Stop | Out-Null

          Write-Output "Assigned '$requiredRoleName' to policy assignment identity ($principalId) at scope $AssignmentScope."
          break
        }
        catch {
          if ($_.Exception.Message -match 'Conflict') {
            Write-Output "Assigned '$requiredRoleName' to policy assignment identity ($principalId) at scope $AssignmentScope (confirmed after retry)."
            break
          }
          if ($i -eq $maxRetries) { throw }
          Write-Output "Waiting ${retryDelay}s for identity replication before assigning '$requiredRoleName' ($i/$maxRetries)..."
          Start-Sleep -Seconds $retryDelay
        }
      }
    }
    else {
      Write-Output "Policy assignment identity already has '$requiredRoleName' at scope $AssignmentScope."
    }
  }
}
