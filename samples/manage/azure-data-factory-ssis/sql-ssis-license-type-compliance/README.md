# Azure Data Factory SSIS Integration Runtime License Type Configuration with Azure Policy

This solution deploys and remediates a custom Azure Policy that audits the `licenseType` property on Azure Data Factory Managed **SSIS Integration Runtimes** (`Microsoft.DataFactory/factories/integrationRuntimes`) and provides a companion script to bring them to a selected target value.

## What Is In This Folder

- `policy/azurepolicy.json`: Custom policy definition (AuditIfNotExists).
- `scripts/deployment.ps1`: Creates/updates the policy definition and policy assignment.
- `scripts/start-remediation.ps1`: Enumerates non-compliant SSIS Integration Runtimes and updates them via `Set-AzDataFactoryV2IntegrationRuntime`.

## License Type Mapping

| Parameter value | Portal label | API `licenseType` |
|---|---|---|
| `LicenseIncluded` | Pay-as-you-go | `LicenseIncluded` |
| `BasePrice` | Azure Hybrid Benefit | `BasePrice` |

> **Note:** Only **Managed** Integration Runtimes with `ssisProperties` (i.e., SSIS-enabled IRs) are in scope. Self-Hosted IRs and Managed IRs without `ssisProperties` (data movement / managed VNet only) do not consume a SQL license and are ignored by both the policy and the remediation script.

## Why AuditIfNotExists Instead Of DeployIfNotExists

The four sibling packs (`sql-arc`, `sql-mi`, `sql-iaas`, `sql-paas`) use `DeployIfNotExists` with an embedded ARM template that PATCHes a single license property. That works because their resource providers merge nested properties on PUT.

The Azure Data Factory resource provider does **not**: `properties.typeProperties` on `Microsoft.DataFactory/factories/integrationRuntimes` is a discriminated union, and a partial PUT through ARM would null out `computeProperties` (node size, count, VNet, etc.) and break the runtime. The official Microsoft sample [`enable-payg-for-azure-sql.ps1`](https://github.com/microsoft/sql-server-samples/blob/master/samples/manage/enable-payg-for-azure-sql/enable-payg-for-azure-sql.ps1) avoids this by calling `Set-AzDataFactoryV2IntegrationRuntime`, which performs an internal GET → merge → PUT against the data plane.

The `Modify` effect is also not available: the `Managed.typeProperties.ssisProperties.licenseType` alias is **not** marked `Modifiable`.

This pack therefore:

- **Audits** drift via the policy assignment (so SSIS IRs show up in the compliance dashboard alongside the other SQL workloads).
- **Remediates** out-of-band via `scripts/start-remediation.ps1`, which mirrors the Microsoft sample.

## Licensing Conditions

When selecting Azure Hybrid Benefit, ensure you meet the licensing requirements:

- **Azure Hybrid Benefit** (`BasePrice`): *"I confirm that I have a SQL Server License with Software Assurance to apply this Azure Hybrid Benefit for SQL Server."*

The deployment script will prompt for confirmation when targeting `BasePrice`. Use `-SkipLicenseConfirmation` to suppress the prompt in automated pipelines (the operator assumes responsibility for license compliance).

## Prerequisites

- PowerShell with Az modules installed (`Az.Resources` for deployment; `Az.DataFactory` for remediation).
- Logged in to Azure (`Connect-AzAccount`).
- Permissions to create policy definitions/assignments at target scope.
- For remediation: Contributor on each Data Factory whose Integration Runtimes will be updated.

## Deploy Policy

Parameter reference:

| Parameter | Required | Default | Allowed values | Description |
|---|---|---|---|---|
| `ManagementGroupId` | No | Tenant root group | Any valid management group ID | Scope where the policy definition is created. Defaults to the tenant root management group when not specified. |
| `SubscriptionId` | No | Not set | Any valid subscription ID | If provided, policy assignment scope is the subscription. |
| `TargetLicenseType` | Yes | N/A | `LicenseIncluded`, `BasePrice` | Target license type to enforce. |
| `LicenseTypesToOverwrite` | No | All | `LicenseIncluded`, `BasePrice` | Select which current license states are eligible for update. |
| `SkipLicenseConfirmation` | No | `false` | Switch (`present`/`not present`) | Skip the interactive license confirmation prompt (for CI/CD pipelines). |

Definition and assignment creation:

1. Download the required files.

```powershell
# Optional: create and enter a local working directory
mkdir sa-sql-ssis-policy
cd sa-sql-ssis-policy
```

```powershell
$baseUrl = "https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-data-factory-ssis/sql-ssis-license-type-compliance"

New-Item -ItemType Directory -Path policy, scripts -Force | Out-Null

curl -sLo policy/azurepolicy.json "$baseUrl/policy/azurepolicy.json"
curl -sLo scripts/deployment.ps1 "$baseUrl/scripts/deployment.ps1"
curl -sLo scripts/start-remediation.ps1 "$baseUrl/scripts/start-remediation.ps1"
```

> **Note:** On Windows PowerShell 5.1, `curl` is an alias for `Invoke-WebRequest`. Use `curl.exe` instead, or run the commands in PowerShell 7+.

2. Login to Azure.

```powershell
Connect-AzAccount
```

3. Set your variables. Only `TargetLicenseType` is required — all others are optional.

```powershell
# ── Required ──
$TargetLicenseType    = "LicenseIncluded"                           # "LicenseIncluded" or "BasePrice"

# ── Optional (uncomment to override defaults) ──
# $ManagementGroupId      = "<management-group-id>"                 # Default: tenant root management group
# $SubscriptionId         = "<subscription-id>"                     # Default: policy assigned at management group scope
# $LicenseTypesToOverwrite = @("LicenseIncluded","BasePrice")       # Default: all
```

4. Run the deployment.

```powershell
# Minimal — uses defaults for management group and overwrite targets
.\scripts\deployment.ps1 -TargetLicenseType $TargetLicenseType

# With subscription scope
.\scripts\deployment.ps1 -TargetLicenseType $TargetLicenseType -SubscriptionId $SubscriptionId

# With all options
.\scripts\deployment.ps1 `
  -ManagementGroupId $ManagementGroupId `
  -SubscriptionId $SubscriptionId `
  -TargetLicenseType $TargetLicenseType `
  -LicenseTypesToOverwrite $LicenseTypesToOverwrite
```

This will:
* Create/update the policy definition at the management group scope.
* Create/assign the policy (at subscription scope when `-SubscriptionId` is provided, otherwise at management group scope).
* Audit (no system-assigned identity is created — `AuditIfNotExists` does not require one) all Managed SSIS Integration Runtimes whose current `licenseType` is in `LicenseTypesToOverwrite` and does not match `TargetLicenseType`.

**Scenario examples:**

```powershell
# Audit all SSIS IRs against Pay-as-you-go
.\scripts\deployment.ps1 -TargetLicenseType "LicenseIncluded"

# Audit only IRs currently on Pay-as-you-go against Azure Hybrid Benefit
.\scripts\deployment.ps1 -TargetLicenseType "BasePrice" -LicenseTypesToOverwrite @("LicenseIncluded")
```

## Start Remediation

Unlike the sibling packs, remediation does **not** use `Start-AzPolicyRemediation` — see [Why AuditIfNotExists Instead Of DeployIfNotExists](#why-auditifnotexists-instead-of-deployifnotexists). Instead, `scripts/start-remediation.ps1` enumerates SSIS IRs in scope and updates each one via `Set-AzDataFactoryV2IntegrationRuntime`.

Parameter reference:

| Parameter | Required | Default | Allowed values | Description |
|---|---|---|---|---|
| `ManagementGroupId` | No | Tenant root group | Any valid management group ID | Enumerates all subscriptions under this management group when `SubscriptionId` is not specified. |
| `SubscriptionId` | No | Not set | Any valid subscription ID | If provided, remediation is limited to this subscription. |
| `TargetLicenseType` | Yes | N/A | `LicenseIncluded`, `BasePrice` | Must match the assignment target license type. |
| `LicenseTypesToOverwrite` | No | All | `LicenseIncluded`, `BasePrice` | Filter which current license states are eligible for update. Should match the value used at deployment time. |
| `Force` | No | `false` | Switch (`present`/`not present`) | Skip the interactive confirmation that lists candidates before applying updates. |

1. Set your variables. `TargetLicenseType` is required and must match the value used during deployment — all others are optional.

```powershell
# ── Required ──
$TargetLicenseType    = "LicenseIncluded"                           # Must match the deployment target

# ── Optional (uncomment to override defaults) ──
# $ManagementGroupId      = "<management-group-id>"                 # Default: tenant root management group
# $SubscriptionId         = "<subscription-id>"                     # Default: scans all subscriptions under the management group
# $LicenseTypesToOverwrite = @("LicenseIncluded","BasePrice")       # Default: all
```

2. Run the remediation.

```powershell
# Minimal — scans all subscriptions under the tenant root management group
.\scripts\start-remediation.ps1 -TargetLicenseType $TargetLicenseType

# With subscription scope
.\scripts\start-remediation.ps1 -TargetLicenseType $TargetLicenseType -SubscriptionId $SubscriptionId

# With all options (non-interactive)
.\scripts\start-remediation.ps1 `
  -ManagementGroupId $ManagementGroupId `
  -SubscriptionId $SubscriptionId `
  -TargetLicenseType $TargetLicenseType `
  -LicenseTypesToOverwrite $LicenseTypesToOverwrite `
  -Force
```

The script:

1. Enumerates Data Factories and Integration Runtimes in scope.
2. Filters to Managed SSIS IRs whose `LicenseType` does not match `TargetLicenseType` and whose current value is in `LicenseTypesToOverwrite`.
3. Prints the candidate list and prompts for confirmation (skip with `-Force`).
4. Calls `Set-AzDataFactoryV2IntegrationRuntime -LicenseType <target> -Force` against each candidate (the cmdlet performs the required GET → merge → PUT internally).
5. Reports per-IR success or failure.

> **Note:** `Set-AzDataFactoryV2IntegrationRuntime` requires the caller to have at least **Data Factory Contributor** (or Contributor) on each factory. The script runs in the interactive Az context — there is no managed identity involved.

## Scope

The policy targets `Microsoft.DataFactory/factories/integrationRuntimes` resources and is filtered to:

- IRs whose `type` is `Managed`.
- IRs that have `typeProperties.ssisProperties` (i.e., SSIS-enabled). Self-Hosted IRs and Managed IRs without SSIS properties are out of scope.

## Reference

- Microsoft sample script (origin of this pattern): [enable-payg-for-azure-sql.ps1](https://github.com/microsoft/sql-server-samples/blob/master/samples/manage/enable-payg-for-azure-sql/enable-payg-for-azure-sql.ps1)
- Azure Data Factory: [Configure Azure-SSIS Integration Runtime](https://learn.microsoft.com/azure/data-factory/create-azure-ssis-integration-runtime)
