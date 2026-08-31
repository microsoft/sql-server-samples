---
services: Azure SQL Virtual Machines
platforms: Azure
author: qingquanxu
ms.date: 06/11/2026
---

# About this sample

- **Applies to:** Azure SQL Virtual Machines (`Microsoft.SqlVirtualMachine/sqlVirtualMachines`)
- **Workload:** n/a
- **Programming Language:** PowerShell
- **Authors:** Qingquan Xu
- **Update history:**

    06/11/2026 - initial version

    06/11/2026 - added detection of the four prerequisites shown on the Azure portal SQL Server configuration page (SqlIaaSAgent extension version >= 2.0.227.1, system-assigned managed identity, Microsoft.AzureArcData RP registration, SQL Management mode = Full). Results appear in the transcript and as new CSV columns; they are informational only and do not block license / ESU updates.

    06/11/2026 - emit Azure portal deep-links for any unmet prerequisite (recorded in CSV only). Added opt-in `-FixManagedIdentity`, `-FixArcDataRp`, `-FixManagementMode` switches that remediate the safe-to-automate prerequisites in bulk.

# Overview

This script provides a scaleable solution to set or change the SQL Server license type and/or enable or disable the ESU policy on Azure SQL VMs in a specified scope.

For every in-scope VM the script also detects (read-only) the four prerequisites surfaced by the Azure portal SQL Server configuration page:

1. `SqlIaaSAgent` extension version >= **2.0.227.1**
2. The compute VM has a **system-assigned managed identity**
3. **`Microsoft.AzureArcData`** resource provider is **Registered** on the subscription
4. SqlIaaSAgent **SQL Management mode** is `Full`

For every unmet prerequisite the script records an **Azure portal deep-link** in the CSV report (the same blade the portal hyperlinks open), so an operator can click through and remediate exactly like they would from the portal. Three opt-in switches (`-FixManagedIdentity`, `-FixArcDataRp`, `-FixManagementMode`) let the script remediate the safe-to-automate prerequisites in bulk. The SqlIaaSAgent **extension version** is intentionally not remediated by the script because the extension auto-upgrades itself on the next operation that touches it (e.g. a license type or ESU change made by this script will already trigger an upgrade where one is needed).

Prerequisite detection is **informational only** — it never blocks the license or ESU updates.

You can specify a single subscription to scan, or provide a list of subscriptions as a `.csv` file. If not specified, all subscriptions your role has access to are scanned.

The script is the Azure SQL VM counterpart of [`modify-arc-sql-license-type.ps1`](../../azure-arc-enabled-sql-server/modify-license-type/modify-arc-sql-license-type.ps1) (which targets Arc-enabled SQL Servers). It uses the same parameter conventions and reporting shape, adapted to the Azure SQL VM resource model.

# Prerequisites

- PowerShell **7.0+**.
- The following Az PowerShell modules: `Az.Accounts`, `Az.SqlVirtualMachine`, `Az.Compute`, `Az.ResourceGraph`.
- You must have at least the *SQL Virtual Machine Contributor* and *Virtual Machine Contributor* roles (or Contributor) on each subscription/resource you modify.
- The `SqlIaaSAgent` extension (publisher `Microsoft.SqlServer.Management`, version `2.0`) must be installed on the target VM (this is the default for any Azure SQL VM created via the Azure portal/CLI).
- You must be connected to Microsoft Entra ID and logged in to your Azure account. If your account has access to multiple tenants, make sure to log in with a specific tenant id.

```powershell
Install-Module Az.Accounts, Az.SqlVirtualMachine, Az.Compute, Az.ResourceGraph -Scope CurrentUser
```

# Launching the script

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|`-SubId`|`subscription_id` *or* `file_name`|*Optional*: Subscription id or a `.csv` file with the list of subscriptions<sup>1</sup>. If not specified, all subscriptions are scanned.|
|`-ResourceGroup`|`resource_group_name`|*Optional*: Limits the scope to a specific resource group.|
|`-VMName`|`vm_name` *or* `file_name`|*Optional*: A single Azure SQL VM name or a `.csv` file with a list of VM names<sup>2</sup>.|
|`-LicenseType`|`PAYG`, `AHUB`, or `DR`|*Optional*: Sets `sqlServerLicenseType` to the specified value via `Update-AzSqlVM`.|
|`-EnableESU`|`Yes`, `No`|*Optional*: Enables the ESU policy if the value is `Yes` or disables it if the value is `No`. To enable, the license type must be `PAYG` or `AHUB`.|
|`-Force`||*Optional*: Forces the change of the license type to the specified value on all matching resources. Without `-Force`, the value is only set where it is currently undefined. Ignored when `-LicenseType` is not specified.|
|`-ExclusionTags`|`'{"tag1":"value1","tag2":"value2"}'`|*Optional*: If specified, excludes the resources that have any of these tags assigned.|
|`-TenantId`|`tenant_id`|*Optional*: If specified, uses this tenant id to log in. Otherwise, the current context is used.|
|`-ReportOnly`||*Optional*: If specified, generates a CSV file with the list of resources that would be modified, but does not make the actual change.|
|`-UseManagedIdentity`||*Optional*: If specified, logs in using managed identity. Required to run the script as a runbook.|
|`-FixManagedIdentity`||*Optional*: If specified (and `-ReportOnly` is not), enables a system-assigned managed identity on any VM where it is missing. Additive — existing user-assigned identities are preserved.|
|`-FixArcDataRp`||*Optional*: If specified (and `-ReportOnly` is not), registers the `Microsoft.AzureArcData` resource provider on any in-scope subscription where it is not yet `Registered`.|
|`-FixManagementMode`||*Optional*: If specified (and `-ReportOnly` is not), upgrades the SqlIaaSAgent **SQL Management mode** to `Full` for VMs where it is not already Full. Note: this re-runs the extension handler and can take several minutes per VM.|
|`-BatchSize`|`int` (default 500)|*Optional*: Page size for `Search-AzGraph`.|

<sup>1</sup>The subscription `.csv` file must include a column **SubscriptionId**. E.g.:

```
"SubscriptionId"
"00000000-0000-0000-0000-000000000001"
"00000000-0000-0000-0000-000000000002"
```

You can generate a `.csv` file that lists only specific subscriptions. For example, the following command includes only production subscriptions (excluding dev/test):

```powershell
$tenantId = "<your-tenant-id>"
Get-AzSubscription -TenantId $tenantId | Where-Object {
    $sub = $_
    $details = Get-AzSubscription -SubscriptionId $sub.Id -TenantId $tenantId
    if ($details -and $details.ExtendedProperties -and $details.ExtendedProperties.SubscriptionPolices) {
        $quotaId = ($details.ExtendedProperties.SubscriptionPolices | ConvertFrom-Json).quotaId
        return $quotaId -notmatch 'MSDN|DEV|VS|TEST'
    }
    return $false
} | Select-Object @{n='SubscriptionId';e={$_.Id}} | Export-Csv .\mysubscriptions.csv -NoTypeInformation
```

<sup>2</sup>The VM names `.csv` file must include a column **VMName**. E.g.:

```
"VMName"
"sqlvm-prod-eastus-01"
"sqlvm-prod-eastus-02"
"sqlvm-stage-westus-01"
```

# Recommended workflow

The script is parameter-driven (no interactive menus). If you run it with **no scope parameters**, it will scan **every Azure SQL VM in every subscription** your account has access to — that is intentional for automation/runbook scenarios, but you almost certainly want to narrow the scope when running it by hand.

**Always preview with `-ReportOnly` first.** It produces the same CSV report and transcript, but performs no writes.

## Scoping cheat-sheet

| To target… | Pass… |
|---|---|
| One subscription | `-SubId <sub_id>` |
| Many subscriptions | `-SubId .\subs.csv` (column `SubscriptionId`) |
| One resource group | `-SubId <sub_id> -ResourceGroup <rg>` |
| One VM | `-SubId <sub_id> -ResourceGroup <rg> -VMName <vm>` |
| Many VMs | `-SubId <sub_id> -VMName .\vms.csv` (column `VMName`) |
| Everything in tenant | *omit `-SubId`, `-ResourceGroup`, `-VMName`* — broad on purpose, intended for automation/runbooks |

## Suggested first run

```powershell
# 1) Preview a single VM
./modify-azure-sql-vm-license-type.ps1 -SubId <sub_id> -ResourceGroup <rg> -VMName <vm> -ReportOnly

# 2) Inspect ModifiedResources_*.csv (current license type, prerequisite columns, what would change)

# 3) Apply for real once the preview looks right
./modify-azure-sql-vm-license-type.ps1 -SubId <sub_id> -ResourceGroup <rg> -VMName <vm> `
    -LicenseType PAYG -EnableESU Yes -Force
```

## Safety guardrails to remember

- **`-ReportOnly`** — run with this on every new scope until you trust the preview. No writes happen.
- **`-Force`** — required to *change* an existing `LicenseType`. Without `-Force`, the script only sets license type on VMs where it is currently unset (matches the Arc script's behavior).
- **`-ExclusionTags '{"env":"prod"}'`** — skip VMs that carry any of the listed tag key/value pairs.

# Script execution examples

## Example 1

Scan all subscriptions in tenant `<tenant_id>` and list the Azure SQL VMs that would have their license type changed to `PAYG` (only those where the current value is undefined).

```powershell
./modify-azure-sql-vm-license-type.ps1 -TenantId <tenant_id> -LicenseType PAYG -ReportOnly
```

## Example 2

Scan subscription `<sub_id>` and set the license type to `AHUB` on all VMs listed in `vms.csv`, overwriting any existing value.

```powershell
./modify-azure-sql-vm-license-type.ps1 -SubId <sub_id> -VMName vms.csv -LicenseType AHUB -Force
```

## Example 3

Scan resource group `<resource_group_name>` in subscription `<sub_id>`, set the license type to `PAYG`, and enable ESU on all VMs in the resource group.

```powershell
./modify-azure-sql-vm-license-type.ps1 -SubId <sub_id> -ResourceGroup <resource_group_name> `
    -LicenseType PAYG -EnableESU Yes -Force
```

## Example 4

Set license type to `AHUB` and enable ESU on all VMs in subscription `<sub_id>` of tenant `<tenant_id>`, except those with the tag `Environment:Dev`.

```powershell
./modify-azure-sql-vm-license-type.ps1 -TenantId <tenant_id> -SubId <sub_id> `
    -LicenseType AHUB -EnableESU Yes -Force -ExclusionTags '{"Environment":"Dev"}'
```

## Example 5

Disable ESU on all VMs in subscription `<sub_id>`.

```powershell
./modify-azure-sql-vm-license-type.ps1 -SubId <sub_id> -EnableESU No
```

## Example 6

Run as an Azure Automation runbook using managed identity, setting license type to `PAYG` across the whole tenant.

```powershell
./modify-azure-sql-vm-license-type.ps1 -LicenseType PAYG -Force -UseManagedIdentity
```

## Example 7

Set every VM in a subscription to `PAYG` with ESU enabled, and also auto-fix the two safe-to-automate prerequisites (missing system-assigned identity, unregistered `Microsoft.AzureArcData` RP).

```powershell
./modify-azure-sql-vm-license-type.ps1 -SubId <sub_id> -LicenseType PAYG -EnableESU Yes -Force `
    -FixManagedIdentity -FixArcDataRp
```

## Example 8

Audit only — discover unmet prerequisites across a subscription and record the portal deep-links in the CSV, without writing anything.

```powershell
./modify-azure-sql-vm-license-type.ps1 -SubId <sub_id> -ReportOnly `
    -FixManagedIdentity -FixArcDataRp -FixManagementMode
```

# Running the script using Cloud Shell

This option is recommended because Cloud Shell has the Azure PowerShell modules pre-installed and you are automatically authenticated. Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/) and select **PowerShell**. For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Connect to Microsoft Entra ID. You can skip this step if you specify `<tenant_id>` as a parameter of the script.

    ```powershell
    Connect-AzAccount -TenantId <tenant_id>
    ```

3. Upload the script to your Cloud Shell:

    ```powershell
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-sql-vm/modify-license-type/modify-azure-sql-vm-license-type.ps1 -o modify-azure-sql-vm-license-type.ps1
    ```

4. Run the script using one of the examples above.

> [!NOTE]
> - To paste commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-V` on macOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.

# Running the script from a PC

Use the following steps to run the script in a PowerShell 7 session on your PC.

1. Install PowerShell 7 if you don't have it: <https://aka.ms/powershell-release?tag=stable>.

2. Install the required Az modules (once):

    ```powershell
    Install-Module Az.Accounts, Az.SqlVirtualMachine, Az.Compute, Az.ResourceGraph -Scope CurrentUser
    ```

3. Copy the script to your current folder:

    ```powershell
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-sql-vm/modify-license-type/modify-azure-sql-vm-license-type.ps1 -o modify-azure-sql-vm-license-type.ps1
    ```

4. Connect to Microsoft Entra ID. You can skip this step if you specify `<tenant_id>` as a parameter of the script.

    ```powershell
    Connect-AzAccount -TenantId <tenant_id>
    ```

5. Run the script using one of the examples above.

# Output

| File | Purpose |
|---|---|
| `modify-azure-sql-vm-license-type.log` | Full transcript (appended each run). |
| `ModifiedResources_<yyyyMMdd_HHmmss>.csv` | One row per reviewed VM. Columns: `TenantID`, `SubID`, `ResourceGroup`, `ResourceName`, `ResourceType`, `Location`, `OriginalLicenseType`, `TargetLicenseType`, `EsuAction`, `Mode`, `LicenseStatus`, `EsuStatus`, `Error`, plus the prerequisite columns below. |

## Prerequisite columns (informational, do not block writes)

| Column | Meaning |
|---|---|
| `SqlIaaSExtensionVersion` | The installed `SqlIaaSAgent` extension `typeHandlerVersion` (e.g. `2.0.227.1`). Empty when not installed. |
| `IsSqlIaaSExtensionVersionMet` | `True` when the installed version is at least `MinRequiredSqlIaaSExtensionVersion`. |
| `MinRequiredSqlIaaSExtensionVersion` | Constant minimum version (currently `2.0.227.1`, matching the Azure portal). |
| `HasSystemAssignedIdentity` | `True` when the underlying compute VM's `identity.type` contains `SystemAssigned`. |
| `IsAzureArcDataRpRegistered` | `True` when `Microsoft.AzureArcData` is `Registered` on the subscription. Cached per subscription. |
| `SqlManagementMode` | Current SqlIaaS management mode from the SQL VM resource (`Full` / `LightWeight` / `NoAgent`). |
| `IsSqlManagementModeFull` | `True` when `SqlManagementMode` equals `Full`. |
| `PrereqRemediationLinks` | Semicolon-separated `<key>=<portalUrl>` pairs for each unmet prerequisite. Empty when all prerequisites pass. The URLs deep-link to the same Azure portal blades the portal hyperlinks open. |
| `FixManagedIdentityResult` | Outcome of the `-FixManagedIdentity` switch: empty (not invoked), `WouldFix` (under `-ReportOnly`), `Fixed`, or `Failed: <message>`. |
| `FixArcDataRpResult` | Outcome of the `-FixArcDataRp` switch (same vocabulary). |
| `FixManagementModeResult` | Outcome of the `-FixManagementMode` switch (same vocabulary). |
