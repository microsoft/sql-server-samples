# Arc-enabled SQL Server license type configuration with Azure Policy

This repo deploys and remediates a custom Azure Policy that configures and enforces Arc-enabled SQL Server extension `LicenseType` to a selected target value (for example `Paid` or `PAYG`).

> **Looking for Windows Server instead?** To activate **Windows Server** Azure benefits (Software Assurance / pay-as-you-go) on Arc machines, use the companion policy: **[Activate Azure Benefits for Windows Arc Machines](https://github.com/Azure/Community-Policy/tree/main/policyDefinitions/Compute/activate-azure-benefits-for-windows-arc-machines)**. This sample is for **Arc-enabled SQL Server** only.

## What Is In This Folder

- `policy/azurepolicy.json`: Custom policy definition (DeployIfNotExists).
- `policy/azurepolicy.portal.json`: Portal paste version of the definition (`properties` contents only) for creating the policy by hand in the Azure portal.
- `scripts/deployment.ps1`: Creates/updates the policy definition and policy assignment.
- `scripts/start-remediation.ps1`: Starts a remediation task for the created assignment.
- `docs/screenshots/`: Visual references.

## Deployment paths at a glance

| Path | Use when | Files |
|---|---|---|
| **Command line / pipeline** | You want scope, assignment, role grant and remediation handled for you. | `policy/azurepolicy.json` + `scripts/deployment.ps1` + `scripts/start-remediation.ps1` |
| **Azure Portal** | You want to create the definition by hand and assign it yourself. | `policy/azurepolicy.portal.json` |

## Choosing the license type by edition (compliance)

`Paid` = **"License with Software Assurance"** and is a **customer attestation** of active SA / a SQL Server subscription. Free editions are **not** SA-eligible and must be `LicenseOnly`. See [Manage licensing and billing of SQL Server enabled by Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/manage-license-billing?view=sql-server-ver17#license-sql-server-instances-by-virtual-cores).

**Rule:** if a host has **any** Standard or Enterprise instance → `Paid`. If a host has **only** free editions → `LicenseOnly`. Use `PAYG` for pay-as-you-go hourly billing of Standard/Enterprise.

| Edition / combination | License type |
|---|---|
| Standard | `Paid` |
| Enterprise | `Paid` |
| Developer | `LicenseOnly` |
| Express | `LicenseOnly` |
| Evaluation | `LicenseOnly` |
| Enterprise + Express | `Paid` |
| Enterprise + Developer | `Paid` |
| Standard + Express | `Paid` |
| Standard + Developer | `Paid` |

> This sample applies **one** `targetLicenseType` per assignment and is **not yet edition-aware**. To stay compliant on a mixed estate, **scope each assignment** to hosts of one category (e.g. an assignment over Standard/Enterprise hosts → `Paid`; another over free-only hosts → `LicenseOnly`). The scripted path (`deployment.ps1`) currently accepts only `Paid`/`PAYG`; the portal file additionally supports `LicenseOnly` and defaults to it (the safe, non-attesting default). Automatic edition/combination detection is tracked in [issue #1492](https://github.com/microsoft/sql-server-samples/issues/1492).

## Prerequisites

- PowerShell with Az modules installed (`Az.Resources`).
- Logged in to Azure (`Connect-AzAccount`).
- Permissions to create policy definitions/assignments and remediation tasks at target scope.

## Deploy Policy

Parameter reference:

| Parameter | Required | Default | Allowed values | Description |
|---|---|---|---|---|
| `ManagementGroupId` | No | Tenant root group | Any valid management group ID | Scope where the policy definition is created. Defaults to the tenant root management group when not specified. |
| `ExtensionType` | No | `Both` | `Windows`, `Linux`, `Both` | Targets the Arc SQL extension platform. When `Both` (default), a single policy definition and assignment covers both platforms. When a specific type is selected, the naming and scope are tailored to that platform. |
| `SubscriptionId` | No | Not set | Any valid subscription ID | If provided, policy assignment scope is the subscription. |
| `TargetLicenseType` | Yes | N/A | `Paid`, `PAYG` | Target `LicenseType` value to enforce. |
| `LicenseTypesToOverwrite` | No | All | `Unspecified`, `Paid`, `PAYG`, `LicenseOnly` | Select which current license states are eligible for update. Use `Unspecified` to include resources with no `LicenseType` configured. |

Definition and assignment creation:

1. Download the required files.

```powershell
# Optional: create and enter a local working directory
mkdir sql-arc-lt-compliance
cd sql-arc-lt-compliance
```

```powershell
$baseUrl = "https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/compliance/arc-sql-license-type-compliance"

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
$TargetLicenseType    = "PAYG"                                      # "Paid" or "PAYG"

# ── Optional (uncomment to override defaults) ──
# $ManagementGroupId      = "<management-group-id>"                 # Default: tenant root management group
# $SubscriptionId         = "<subscription-id>"                     # Default: policy assigned at management group scope
# $ExtensionType          = "Both"                                  # "Windows", "Linux", or "Both" (default)
# $LicenseTypesToOverwrite = @("Unspecified","Paid","PAYG","LicenseOnly")  # Default: all
```

4. Run the deployment.

```powershell
# Minimal — uses defaults for management group, platform, and overwrite targets
.\scripts\deployment.ps1 -TargetLicenseType $TargetLicenseType

# With subscription scope
.\scripts\deployment.ps1 -TargetLicenseType $TargetLicenseType -SubscriptionId $SubscriptionId

# With all options
.\scripts\deployment.ps1 `
  -ManagementGroupId $ManagementGroupId `
  -SubscriptionId $SubscriptionId `
  -ExtensionType $ExtensionType `
  -TargetLicenseType $TargetLicenseType `
  -LicenseTypesToOverwrite $LicenseTypesToOverwrite
```

This will:
* Create/update the policy definition at the management group scope.
* Create/assign the policy (at subscription scope when `-SubscriptionId` is provided, otherwise at management group scope).
* Target the selected `ExtensionType` platform(s) — `Both` by default covers Windows and Linux.
* Enforce the selected `TargetLicenseType` on resources matching the `LicenseTypesToOverwrite` filter.

**Scenario examples:**

```powershell
# Move all Paid licenses to PAYG, both platforms
.\scripts\deployment.ps1 -TargetLicenseType "PAYG" -LicenseTypesToOverwrite @("Paid")

# Set missing and LicenseOnly to Paid, skip resources already on PAYG
.\scripts\deployment.ps1 -TargetLicenseType "Paid" -LicenseTypesToOverwrite @("Unspecified","LicenseOnly")

# Linux only — move Paid to PAYG at a specific subscription
.\scripts\deployment.ps1 -ExtensionType "Linux" -SubscriptionId "<subscription-id>" -TargetLicenseType "PAYG" -LicenseTypesToOverwrite @("Paid")
```

> **Note:** `deployment.ps1` automatically grants required roles to the policy assignment managed identity at assignment scope, preventing common `PolicyAuthorizationFailed` errors during DeployIfNotExists deployments.

## Deploy via the Azure Portal (copy & paste)

Prefer the portal? The **Policy definition → Policy rule** box expects the `properties` contents. The repo's `policy/azurepolicy.json` also carries a read-only `policyType` and a top-level `version` that the portal rejects, so `policy/azurepolicy.portal.json` has those removed (nothing else changed, plus `LicenseOnly` added to the allowed license types).

1. **Policy → Definitions → + Policy definition.**
2. Set **Definition location**, **Name** (e.g. *Configure Arc-enabled SQL Server license type*), and **Category** = `Azure Arc`.
3. Open [`policy/azurepolicy.portal.json`](./policy/azurepolicy.portal.json), copy its entire contents, clear the **Policy rule** box and paste it in.
4. **Save**, then **Assign**. On the *Parameters* tab choose your **Target license type** per the edition table above. Because the effect is `DeployIfNotExists`, the assignment needs a **system-assigned managed identity + location**; the portal grants the required roles. Create a **remediation task** to update existing instances.

## Start Remediation

Parameter reference:

| Parameter | Required | Default | Allowed values | Description |
|---|---|---|---|---|
| `ManagementGroupId` | No | Tenant root group | Any valid management group ID | Used to resolve the policy definition/assignment naming context. Defaults to the tenant root management group when not specified. |
| `ExtensionType` | No | `Both` | `Windows`, `Linux`, `Both` | Must match the platform used for the assignment. When `Both` (default), remediates the combined assignment. |
| `SubscriptionId` | No | Not set | Any valid subscription ID | If provided, remediation runs at subscription scope. |
| `TargetLicenseType` | Yes | N/A | `Paid`, `PAYG` | Must match the assignment target license type. |
| `GrantMissingPermissions` | No | `false` | Switch (`present`/`not present`) | If set, checks and assigns missing required roles before remediation. |

1. Set your variables. `TargetLicenseType` is required and must match the value used during deployment — all others are optional.

```powershell
# ── Required ──
$TargetLicenseType    = "PAYG"                                      # Must match the deployment target

# ── Optional (uncomment to override defaults) ──
# $ManagementGroupId      = "<management-group-id>"                 # Default: tenant root management group
# $SubscriptionId         = "<subscription-id>"                     # Default: remediation runs at management group scope
# $ExtensionType          = "Both"                                  # Must match the platform used for deployment
```

2. Run the remediation.

```powershell
# Minimal — uses defaults for management group and platform
.\scripts\start-remediation.ps1 -TargetLicenseType $TargetLicenseType -GrantMissingPermissions

# With subscription scope
.\scripts\start-remediation.ps1 -TargetLicenseType $TargetLicenseType -SubscriptionId $SubscriptionId -GrantMissingPermissions

# With all options
.\scripts\start-remediation.ps1 `
  -ManagementGroupId $ManagementGroupId `
  -ExtensionType $ExtensionType `
  -SubscriptionId $SubscriptionId `
  -TargetLicenseType $TargetLicenseType `
  -GrantMissingPermissions
```

> **Note:** Use `-GrantMissingPermissions` to automatically check and assign any missing required roles before remediation starts.

## Recurring Billing Consent (PAYG)

When `TargetLicenseType` is set to `PAYG`, the policy automatically includes `ConsentToRecurringPAYG` in the extension settings with `Consented: true` and a UTC timestamp. This is required for recurring pay-as-you-go billing as described in the [Microsoft documentation](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/manage-pay-as-you-go-transition?view=sql-server-ver17#recurring-billing-consent).

The policy also checks for `ConsentToRecurringPAYG` in its compliance evaluation — resources with `LicenseType: PAYG` but missing the consent property are flagged as non-compliant and remediated. This applies both when transitioning to PAYG and for existing PAYG extensions that predate the consent requirement (backward compatibility).

> **Note:** Once `ConsentToRecurringPAYG` is set on an extension, it cannot be removed — this is enforced by the Azure resource provider. When transitioning away from PAYG, the policy changes `LicenseType` but leaves the consent property in place.

## Managed Identity And Roles

The policy assignment is created with `-IdentityType SystemAssigned`. Azure creates a managed identity on the assignment and uses it to apply DeployIfNotExists changes during enforcement and remediation.

Required roles:

- `Azure Extension for SQL Server Deployment` (`7392c568-9289-4bde-aaaa-b7131215889d`)
- `Reader` (`acdd72a7-3385-48ef-bd42-f606fba81ae7`)
- `Resource Policy Contributor` (required so DeployIfNotExists can create template deployments)

## Troubleshooting

If you see `PolicyAuthorizationFailed`, the policy assignment identity is missing one or more required roles at assignment scope (or inherited scope), often causing missing `Microsoft.HybridCompute/machines/extensions/write` permission.

Use one of these options:

- Re-run `scripts/deployment.ps1` (default behavior assigns `Resource Policy Contributor` automatically).
- Re-run `scripts/deployment.ps1` (default behavior assigns required roles automatically).
- Run `scripts/start-remediation.ps1 -GrantMissingPermissions` (checks and assigns missing required roles before remediation).