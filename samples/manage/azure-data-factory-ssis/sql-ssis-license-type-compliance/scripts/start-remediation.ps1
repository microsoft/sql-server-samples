param(
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$ManagementGroupId,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$SubscriptionId,

  [Parameter(Mandatory = $true)]
  [ValidateSet('LicenseIncluded', 'BasePrice')]
  [string]$TargetLicenseType,

  [Parameter(Mandatory = $false)]
  [ValidateSet('LicenseIncluded', 'BasePrice')]
  [string[]]$LicenseTypesToOverwrite = @('LicenseIncluded', 'BasePrice'),

  [Parameter(Mandatory = $false)]
  [switch]$AutoStopStart,

  [Parameter(Mandatory = $false)]
  [switch]$Force
)

# Resolve subscriptions in scope.
# SSIS IR remediation cannot use Start-AzPolicyRemediation because the underlying
# ARM CreateOrUpdate replaces the integrationRuntime's discriminated-union
# typeProperties block. We mirror the official Microsoft sample pattern instead,
# which calls Set-AzDataFactoryV2IntegrationRuntime (it performs an internal
# GET / merge / PUT against the data plane).
if ($PSBoundParameters.ContainsKey('SubscriptionId')) {
  $subscriptions = @([pscustomobject]@{ Id = $SubscriptionId })
}
else {
  if (-not $PSBoundParameters.ContainsKey('ManagementGroupId')) {
    $ManagementGroupId = (Get-AzContext).Tenant.Id
    Write-Output "ManagementGroupId not specified. Using tenant root management group: $ManagementGroupId"
  }
  try {
    $subscriptions = Get-AzManagementGroupSubscription -GroupId $ManagementGroupId -ErrorAction Stop
  }
  catch {
    throw "Failed to enumerate subscriptions under management group '$ManagementGroupId': $($_.Exception.Message)"
  }
}

if (-not (Get-Module -ListAvailable -Name Az.DataFactory)) {
  throw "Az.DataFactory module is required. Install with: Install-Module Az.DataFactory -Scope CurrentUser"
}
Import-Module Az.DataFactory -ErrorAction Stop

$candidates = @()

foreach ($sub in $subscriptions) {
  # Normalize: Get-AzManagementGroupSubscription returns .Id as a full ARM path
  # (/providers/Microsoft.Management/managementGroups/<mg>/subscriptions/<guid>),
  # while the synthetic pscustomobject we create from -SubscriptionId puts the
  # bare GUID in .Id. Extract the GUID for Set-AzContext.
  $subId = $null
  if ($sub.Id -match 'subscriptions/([0-9a-fA-F-]{36})$') { $subId = $matches[1] }
  elseif ($sub.Id -match '^[0-9a-fA-F-]{36}$')            { $subId = $sub.Id }
  elseif ($sub.SubscriptionId)                            { $subId = $sub.SubscriptionId }
  elseif ($sub.Name -match '^[0-9a-fA-F-]{36}$')          { $subId = $sub.Name }
  else { $subId = [string]$sub }

  try {
    Set-AzContext -SubscriptionId $subId -ErrorAction Stop | Out-Null
  }
  catch {
    Write-Warning "Skipping subscription $subId (cannot set context): $($_.Exception.Message)"
    continue
  }

  $factories = Get-AzDataFactoryV2 -ErrorAction SilentlyContinue
  foreach ($factory in $factories) {
    $irs = Get-AzDataFactoryV2IntegrationRuntime `
             -ResourceGroupName $factory.ResourceGroupName `
             -DataFactoryName  $factory.DataFactoryName `
             -ErrorAction SilentlyContinue
    foreach ($ir in $irs) {
      # Only Managed SSIS IRs have NodeSize set.
      if ($null -eq $ir.NodeSize)               { continue }
      if ($null -eq $ir.LicenseType)            { continue }
      if ($ir.LicenseType -eq $TargetLicenseType) { continue }
      if ($ir.LicenseType -notin $LicenseTypesToOverwrite) { continue }

      $candidates += [pscustomobject]@{
        SubscriptionId     = $subId
        ResourceGroupName  = $factory.ResourceGroupName
        DataFactoryName    = $factory.DataFactoryName
        Name               = $ir.Name
        CurrentLicenseType = $ir.LicenseType
        State              = $ir.State
      }
    }
  }
}

if ($candidates.Count -eq 0) {
  Write-Output "No SSIS Integration Runtimes require remediation to '$TargetLicenseType'."
  return
}

Write-Output ([Environment]::NewLine + "Found $($candidates.Count) SSIS Integration Runtime(s) to remediate to '$TargetLicenseType':")
$candidates |
  Format-Table SubscriptionId, ResourceGroupName, DataFactoryName, Name, CurrentLicenseType, State -AutoSize |
  Out-String |
  Write-Output

$startedCandidates = @($candidates | Where-Object { $_.State -eq 'Started' })
if ($startedCandidates.Count -gt 0) {
  if ($AutoStopStart) {
    Write-Warning "$($startedCandidates.Count) IR(s) are in 'Started' state. With -AutoStopStart, each will be STOPPED, reconfigured, then STARTED again (provisioning a Managed SSIS IR back to Started typically takes 20-30 minutes per IR)."
  }
  else {
    Write-Warning "$($startedCandidates.Count) IR(s) are in 'Started' state. ARM will reject the licenseType change with 'IntegrationRuntimeCannotModify'. Re-run with -AutoStopStart to stop, reconfigure, and restart automatically."
  }
}

if (-not $Force) {
  $response = Read-Host "Proceed with remediation? (Y/N)"
  if ($response -notin @('Y', 'y', 'Yes', 'yes')) {
    Write-Output "Remediation cancelled."
    return
  }
}

foreach ($c in $candidates) {
  $stoppedByUs = $false
  try {
    Set-AzContext -SubscriptionId $c.SubscriptionId -ErrorAction Stop | Out-Null

    # Stop the IR first if requested and currently Started.
    if ($AutoStopStart -and $c.State -eq 'Started') {
      Write-Output "Stopping $($c.DataFactoryName)/$($c.Name) (rg=$($c.ResourceGroupName))..."
      Stop-AzDataFactoryV2IntegrationRuntime `
        -ResourceGroupName $c.ResourceGroupName `
        -DataFactoryName   $c.DataFactoryName `
        -Name              $c.Name `
        -Force `
        -ErrorAction Stop | Out-Null
      $stoppedByUs = $true
    }

    Set-AzDataFactoryV2IntegrationRuntime `
      -ResourceGroupName $c.ResourceGroupName `
      -DataFactoryName   $c.DataFactoryName `
      -Name              $c.Name `
      -LicenseType       $TargetLicenseType `
      -Force `
      -ErrorAction Stop | Out-Null

    Write-Output "Updated $($c.DataFactoryName)/$($c.Name) from '$($c.CurrentLicenseType)' to '$TargetLicenseType' (rg=$($c.ResourceGroupName), sub=$($c.SubscriptionId))."

    # Restart only IRs that we stopped (preserves operator intent for IRs that
    # were already Stopped at the time of discovery).
    if ($stoppedByUs) {
      Write-Output "Starting $($c.DataFactoryName)/$($c.Name) (this can take 20-30 minutes)..."
      $startErr = $null
      try {
        Start-AzDataFactoryV2IntegrationRuntime `
          -ResourceGroupName $c.ResourceGroupName `
          -DataFactoryName   $c.DataFactoryName `
          -Name              $c.Name `
          -Force `
          -ErrorAction Stop | Out-Null
      }
      catch {
        # The cmdlet's status-polling step is known to fail transiently even
        # when ARM accepted the Start request. Verify the actual IR state
        # before deciding whether to warn.
        $startErr = $_
      }

      try {
        $postState = (Get-AzDataFactoryV2IntegrationRuntime `
          -ResourceGroupName $c.ResourceGroupName `
          -DataFactoryName   $c.DataFactoryName `
          -Name              $c.Name `
          -Status            -ErrorAction Stop).State
      }
      catch {
        $postState = $null
      }

      if ($postState -in @('Started','Starting')) {
        if ($startErr) {
          Write-Output "Start cmdlet returned a polling error but the IR is actually '$postState'. Treating as success."
        }
        Write-Output "Started $($c.DataFactoryName)/$($c.Name) (state=$postState)."
      }
      elseif ($startErr) {
        throw $startErr
      }
      else {
        Write-Warning "$($c.DataFactoryName)/$($c.Name) did not transition to Started/Starting (current state: '$postState'). Please investigate."
      }
    }
  }
  catch {
    Write-Warning "Failed to update $($c.DataFactoryName)/$($c.Name) (rg=$($c.ResourceGroupName), sub=$($c.SubscriptionId)): $($_.Exception.Message)"
    if ($stoppedByUs) {
      Write-Warning "$($c.DataFactoryName)/$($c.Name) was stopped by this run but the Set/Start step failed. Please review and start it manually if intended."
    }
  }
}
