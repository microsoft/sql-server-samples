# SQL Server on Azure VMs (IaaS) License Type Configuration with Azure Policy

This solution deploys and remediates a custom Azure Policy that configures and enforces the `sqlServerLicenseType` property on SQL Server on Azure Virtual Machines (`Microsoft.SqlVirtualMachine/sqlVirtualMachines`) to a selected target value.

## What Is In This Folder

- `policy/azurepolicy.json`: Custom policy definition (DeployIfNotExists).
- `scripts/deployment.ps1`: Creates/updates the policy definition and policy assignment.
- `scripts/start-remediation.ps1`: Starts a remediation task for the created assignment.

## License Type Mapping

| Parameter value | Portal label | `sqlServerLicenseType` |
|---|---|---|
| `PAYG` | Pay-as-you-go | `PAYG` |
| `AHUB` | Azure Hybrid Benefit | `AHUB` |
| `DR` | HA/DR | `DR` |

## Licensing Conditions

When selecting certain license types, ensure you meet the licensing requirements:

- **Azure Hybrid Benefit** (`AHUB`): *"I confirm that I have a SQL Server License with Software Assurance to apply this Azure Hybrid Benefit for SQL Server."*
- **HA/DR** (`DR`): *"I confirm that I will use this SQL Server VM as a passive HA/DR replica for which I have a SQL Server license with Software Assurance, or for which I use Pay-as-you-go billing option."*

The deployment script will prompt for confirmation when targeting `AHUB` or `DR`. Use `-SkipLicenseConfirmation` to suppress the prompt in automated pipelines (the operator assumes responsibility for license compliance).

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
| `TargetLicenseType` | Yes | N/A | `PAYG`, `AHUB`, `DR` | Target license type to enforce. |
| `LicenseTypesToOverwrite` | No | All | `PAYG`, `AHUB`, `DR` | Select which current license states are eligible for update. |
| `SkipLicenseConfirmation` | No | `false` | Switch (`present`/`not present`) | Skip the interactive license confirmation prompt (for CI/CD pipelines). |

Definition and assignment creation:

1. Download the required files.

```powershell
# Optional: create and enter a local working directory
mkdir sa-sql-iaas-policy
cd sa-sql-iaas-policy
```

```powershell
$baseUrl = "https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/sql-vm/sql-iaas-license-type-compliance"

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
$TargetLicenseType    = "PAYG"                                      # "PAYG", "AHUB", or "DR"

# ── Optional (uncomment to override defaults) ──
# $ManagementGroupId      = "<management-group-id>"                 # Default: tenant root management group
# $SubscriptionId         = "<subscription-id>"                     # Default: policy assigned at management group scope
# $LicenseTypesToOverwrite = @("PAYG","AHUB","DR")                  # Default: all
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
* Enforce the selected `TargetLicenseType` on resources matching the `LicenseTypesToOverwrite` filter.

**Scenario examples:**

```powershell
# Move all SQL VMs to Pay-as-you-go
.\scripts\deployment.ps1 -TargetLicenseType "PAYG"

# Move Pay-as-you-go SQL VMs to Azure Hybrid Benefit
.\scripts\deployment.ps1 -TargetLicenseType "AHUB" -LicenseTypesToOverwrite @("PAYG")

# Configure HA/DR, only for SQL VMs currently on Azure Hybrid Benefit
.\scripts\deployment.ps1 -TargetLicenseType "DR" -LicenseTypesToOverwrite @("AHUB")
```

> **Note:** `deployment.ps1` automatically grants required roles to the policy assignment managed identity at assignment scope.

## Start Remediation

Parameter reference:

| Parameter | Required | Default | Allowed values | Description |
|---|---|---|---|---|
| `ManagementGroupId` | No | Tenant root group | Any valid management group ID | Used to resolve the policy definition/assignment naming context. Defaults to the tenant root management group when not specified. |
| `SubscriptionId` | No | Not set | Any valid subscription ID | If provided, remediation runs at subscription scope. |
| `TargetLicenseType` | Yes | N/A | `PAYG`, `AHUB`, `DR` | Must match the assignment target license type. |
| `GrantMissingPermissions` | No | `false` | Switch (`present`/`not present`) | If set, checks and assigns missing required roles before remediation. |

1. Set your variables. `TargetLicenseType` is required and must match the value used during deployment — all others are optional.

```powershell
# ── Required ──
$TargetLicenseType    = "PAYG"                                      # Must match the deployment target

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

- `Virtual Machine Contributor` (`9980e02c-c2be-4d73-94e8-173b1dc7cf3c`)
- `Reader` (`acdd72a7-3385-48ef-bd42-f606fba81ae7`)
- `Resource Policy Contributor` (required so DeployIfNotExists can create template deployments)

## Troubleshooting

If you see `PolicyAuthorizationFailed`, the policy assignment identity is missing one or more required roles at assignment scope.

Use one of these options:

- Re-run `scripts/deployment.ps1` (default behavior assigns required roles automatically).
- Run `scripts/start-remediation.ps1 -GrantMissingPermissions` (checks and assigns missing required roles before remediation).
