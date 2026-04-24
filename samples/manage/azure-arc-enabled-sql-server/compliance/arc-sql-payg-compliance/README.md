# Paygo-SQLArc (Windows only)

This Azure Policy ensures that all SQL Arc servers using `LicenseType = Paid` are marked as non-compliant. Servers with `LicenseType = LicenseOnly` are treated as compliant. The remediation task sets `LicenseType = PAYG`.

Use Azure CLI or PowerShell to create the policy definition:

## Artifacts

- **policy.json**: Main policy definition referencing external parameter and rule files.
- **params.json**: Defines policy parameters.
- **rules.json**: Contains the policy rule logic.

## Copy policy artifacts to your environment

```PowerShell

curl https://raw.githubusercontent.com/microsoft/sql-server-samples/refs/heads/master/samples/manage/azure-arc-enabled-sql-server/compliance/arc-sql-payg-compliance/params.json -o params.json
curl https://raw.githubusercontent.com/microsoft/sql-server-samples/refs/heads/master/samples/manage/azure-arc-enabled-sql-server/compliance/arc-sql-payg-compliance/rules.json -o rules.json

```

## Create policy

Use the following command to create policy

```PowerShell

$SubId    = "<your-subscription-id>"
$PolicyName = "Paygo-SQLArc"

az policy definition create `
  --name $PolicyName `
  --display-name $PolicyName `
  --description "This Azure Policy ensures that all SQL Arc servers using LicenseType = Paid are marked as non-compliant. Servers with LicenseType = LicenseOnly are treated as compliant. The remediation task sets LicenseType = PAYG." `
  --rules "@rules.json" `
  --params "@params.json" `
  --mode Indexed `
  --subscription $SubId `
  --only-show-errors | Out-Null
```

## Assign policy

Use the following command to assign policy

```PowerShell

$SubId    = "<your-subscription-id>"
$RgName   = "<your-resource-group>"    # optional; set to "" to target subscription scope
$Location = "<your-azure-region>"      # e.g., eastus, westus2

if ([string]::IsNullOrWhiteSpace($RgName)) {
  $Scope = "/subscriptions/$SubId"
} else {
  $Scope = "/subscriptions/$SubId/resourceGroups/$RgName"
}

az account set --subscription $SubId

az policy assignment create `
  --name "Paygo-SQLArc-Assign" `
  --policy "Paygo-SQLArc" `
  --scope "$Scope" `
  --params '{ "effect": { "value": "DeployIfNotExists" } }' `
  --mi-system-assigned `
  --role "Contributor" `
  --identity-scope "$Scope" `
  --location "$Location" `
  --only-show-errors | Out-Null
```

## Create remediation task

Use the following command to create a remediation task

```PowerShell

$RemediationName = "Remediate-Paygo-SQLArc"
$PolicyAssignmentName = "Paygo-SQLArc-Assign"
$SubId    = "<your-subscription-id>"
$RgName   = "<your-resource-group>"

az account set --subscription $SubId

if ([string]::IsNullOrWhiteSpace($RgName)) {
  az policy remediation create `
    --name $RemediationName `
    --policy-assignment $PolicyAssignmentName `
    --resource-discovery-mode ReEvaluateCompliance `
    --only-show-errors | Out-Null
  } else {
  az policy remediation create `
    --name $RemediationName `
    --policy-assignment $PolicyAssignmentName `
    --resource-group "$RgName" `
    --resource-discovery-mode ReEvaluateCompliance `
    --only-show-errors | Out-Null
}
```

## Remove remediation task

```PowerShell

$RemediationName = "Remediate-Paygo-SQLArc"
$RgName = "<your-resource-group>"
$SubId = "<your-subscription-id>"

if ([string]::IsNullOrWhiteSpace($RgName)) {
    az policy remediation cancel `
      --name $RemediationName `
      --subscription $SubId `
      --only-show-errors | Out-Null
    az policy remediation delete `
      --name $RemediationName `
      --subscription $SubId `
      --only-show-errors | Out-Null
} else {
    az policy remediation cancel `
      --name $RemediationName `
      --resource-group $RgName `
      --subscription $SubId `
      --only-show-errors | Out-Null
    az policy remediation delete `
      --name $RemediationName `
      --resource-group $RgName `
      --subscription $SubId `
      --only-show-errors | Out-Null
}
```