# Azure SQL Database (PaaS) License Type Configuration with Azure Policy

This solution deploys and remediates a custom Azure Policy that configures and enforces the `licenseType` property on Azure SQL Databases (`Microsoft.Sql/servers/databases`) to a selected target value.

## What Is In This Folder

- `policy/azurepolicy.json`: Custom policy definition (DeployIfNotExists).
- `scripts/deployment.ps1`: Creates/updates the policy definition and policy assignment.
- `scripts/start-remediation.ps1`: Starts a remediation task for the created assignment.

## License Type Mapping

| Parameter value | Portal label | `licenseType` |
|---|---|---|
| `LicenseIncluded` | Pay-as-you-go | `LicenseIncluded` |
| `BasePrice` | Azure Hybrid Benefit | `BasePrice` |

> **Note:** License type configuration is only available for databases using the **Provisioned** compute tier. Databases configured with the **Serverless** compute tier do not support the `licenseType` property. These databases will be flagged as non-compliant by the policy, but remediation cannot change the license type. To configure the license type, switch the database to the Provisioned compute tier.

## Licensing Conditions

When selecting Azure Hybrid Benefit, ensure you meet the licensing requirements:

- **Azure Hybrid Benefit** (`BasePrice`): *"I confirm that I have a SQL Server License with Software Assurance to apply this Azure Hybrid Benefit for SQL Server."*

The deployment script will prompt for confirmation when targeting `BasePrice`. Use `-SkipLicenseConfirmation` to suppress the prompt in automated pipelines (the operator assumes responsibility for license compliance).

## Prerequisites

- PowerShell with Az modules installed (`Az.Resources`).
- Logged in to Azure (`Connect-AzAccount`).
- Permissions to create policy definitions/assignments and remediation tasks at target scope.

## Deploy Policy

Parameter reference:

| Parameter | Required | Default | Allowed values | Description |
|---|---|---|---|---|
| `ManagementGroupId` | No | Tenant root group | Any valid management group ID | Scope where the policy definition is created. Defaults to the tenant root management group when not specified. |
| `SubscriptionId` | No | Not set | Any valid subscription ID | If provided, policy assignment scope is the subscription. |
| `TargetLicenseType` | Yes | N/A | `LicenseIncluded`, `BasePrice` | Target license type to enforce. |
| `SkipLicenseConfirmation` | No | `false` | Switch (`present`/`not present`) | Skip the interactive license confirmation prompt (for CI/CD pipelines). |

Definition and assignment creation:

1. Download the required files.

```powershell
# Optional: create and enter a local working directory
mkdir sa-sql-paas-policy
cd sa-sql-paas-policy
```

```powershell
$baseUrl = "https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-sql-db/sql-paas-license-type-compliance"

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
```

4. Run the deployment.

```powershell
# Minimal — uses defaults for management group
.\scripts\deployment.ps1 -TargetLicenseType $TargetLicenseType

# With subscription scope
.\scripts\deployment.ps1 -TargetLicenseType $TargetLicenseType -SubscriptionId $SubscriptionId

# With all options
.\scripts\deployment.ps1 `
  -ManagementGroupId $ManagementGroupId `
  -SubscriptionId $SubscriptionId `
  -TargetLicenseType $TargetLicenseType
```

This will:
* Create/update the policy definition at the management group scope.
* Create/assign the policy (at subscription scope when `-SubscriptionId` is provided, otherwise at management group scope).
* Enforce the selected `TargetLicenseType` on all vCore-based SQL databases (excludes Basic/DTU-based databases and the `master` database).

**Scenario examples:**

```powershell
# Move all SQL databases to Pay-as-you-go
.\scripts\deployment.ps1 -TargetLicenseType "LicenseIncluded"

# Move all SQL databases to Azure Hybrid Benefit
.\scripts\deployment.ps1 -TargetLicenseType "BasePrice"
```

> **Note:** `deployment.ps1` automatically grants required roles to the policy assignment managed identity at assignment scope.

## Start Remediation

Parameter reference:

| Parameter | Required | Default | Allowed values | Description |
|---|---|---|---|---|
| `ManagementGroupId` | No | Tenant root group | Any valid management group ID | Used to resolve the policy definition/assignment naming context. Defaults to the tenant root management group when not specified. |
| `SubscriptionId` | No | Not set | Any valid subscription ID | If provided, remediation runs at subscription scope. |
| `TargetLicenseType` | Yes | N/A | `LicenseIncluded`, `BasePrice` | Must match the assignment target license type. |
| `GrantMissingPermissions` | No | `false` | Switch (`present`/`not present`) | If set, checks and assigns missing required roles before remediation. |

1. Set your variables. `TargetLicenseType` is required and must match the value used during deployment — all others are optional.

```powershell
# ── Required ──
$TargetLicenseType    = "LicenseIncluded"                           # Must match the deployment target

# ── Optional (uncomment to override defaults) ──
# $ManagementGroupId      = "<management-group-id>"                 # Default: tenant root management group
# $SubscriptionId         = "<subscription-id>"                     # Default: remediation runs at management group scope
```

2. Run the remediation.

```powershell
# Minimal — uses defaults for management group
.\scripts\start-remediation.ps1 -TargetLicenseType $TargetLicenseType -GrantMissingPermissions

# With subscription scope
.\scripts\start-remediation.ps1 -TargetLicenseType $TargetLicenseType -SubscriptionId $SubscriptionId -GrantMissingPermissions

# With all options
.\scripts\start-remediation.ps1 `
  -ManagementGroupId $ManagementGroupId `
  -SubscriptionId $SubscriptionId `
  -TargetLicenseType $TargetLicenseType `
  -GrantMissingPermissions
```

> **Note:** Use `-GrantMissingPermissions` to automatically check and assign any missing required roles before remediation starts.

## Managed Identity And Roles

The policy assignment is created with `-IdentityType SystemAssigned`. Azure creates a managed identity on the assignment and uses it to apply DeployIfNotExists changes during enforcement and remediation.

Required roles:

- `SQL DB Contributor` (`9b7fa17d-e63e-47b0-bb0a-15c516ac86ec`)
- `Reader` (`acdd72a7-3385-48ef-bd42-f606fba81ae7`)
- `Resource Policy Contributor` (required so DeployIfNotExists can create template deployments)

## Troubleshooting

If you see `PolicyAuthorizationFailed`, the policy assignment identity is missing one or more required roles at assignment scope.

Use one of these options:

- Re-run `scripts/deployment.ps1` (default behavior assigns required roles automatically).
- Run `scripts/start-remediation.ps1 -GrantMissingPermissions` (checks and assigns missing required roles before remediation).

## Scope

The policy targets vCore-based Azure SQL Databases only. It excludes:
- The `master` system database.
- Basic/DTU-based databases (which don't support the `licenseType` property).
