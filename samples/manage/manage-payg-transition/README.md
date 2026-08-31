---
services: Azure Arc-enabled SQL Server
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 12/01/2024
---

# Manage Transition to Azure Pay-as-you-go subscription

This script provides a scaleable solution to transition the SQL Server resources an Arc or Azure to Azure Pay-as-you-go subscription as a single step. 

You can specify a single subscription to scan, or provide a list of subscriptions as a .CSV file.
If not specified, all subscriptions your role has access to are scanned.

## Prerequisites

- PowerShell 5+ 
- You must have at least a *Contributor* RBAC role in each subscription you modify.
- You must have a *Tag Contributor* *Contributor* RBAC role in each subscription you modify.
- You must be connected to Azure AD and logged in to your Azure account. If your account have access to multiple tenants, make sure to log in with a specific tenant ID.

### Detailed permissions by resource type

*Contributor* is a superset of everything below and is the simplest option. If you
prefer a least-privilege role assignment instead, the dependent scripts require:

| Resource type modified | Built-in role needed |
|---|---|
| SQL Server VMs, Managed Instances, Azure SQL Databases, Elastic Pools, Instance Pools | *SQL DB Contributor* |
| Azure Arc-enabled SQL Server (Arc machine extensions) | *Azure Connected Machine Resource Administrator* |
| Azure Data Factory Azure-SSIS Integration Runtimes (only if present) | *Data Factory Contributor* |
| Reading/enumerating subscriptions and resources (all of the above) | *Reader* (included in every role above) |
| Tagging subscriptions with `ArcSQLServerExtensionDeployment:PAYG` | *Tag Contributor* |

---

# Launching the script

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|`-Target`|`Arc`, `Azure`, `Both`|*Optional*. Which environment(s) to process. Defaults to `Both`.|
|`-RunMode`|`Single`, `Scheduled`|*Optional*. `Single` runs once and exits. `Scheduled` registers a recurring Azure Automation runbook. Defaults to `Single`.|
|`-targetSubscription`|`<subscription_id>`|*Optional*: Subscription id to limit the scope of the transition. If not specified, all subscriptions in the tenant will be transitioned.|
|`-targetResourceGroup` |`<name>`|*Optional*: Limits the scope of the transition to the specified resource group.|
|`-TenantId`|`<tenant_id>`|*Optional*. Azure AD tenant to operate against. If not specified, the tenant of the current Az PowerShell context (`(Get-AzContext).Tenant.Id`) is used. Specify explicitly to avoid running against whichever tenant happens to be selected in your session.|
|`-ReportOnly`|*(switch)*|*Optional*. Read-only dry run: reports the resources that would be changed without modifying anything.|
|`-WaitForCompletion`|*(switch)*|*Optional*. Wait for each license change to reach a terminal state and report a confirmed outcome. By default changes are submitted asynchronously and reported as `RequestSubmitted`. SSIS integration runtimes always wait (no asynchronous option exists for them). See [How It Works](#how-it-works).|
|`-UsePcoreLicense` | `Yes`, `No` |*Optional*. Passed to Arc script to control PCore licensing behavior. Set to `No` if not specified.|
|`-TargetLicenseType`|`PAYG`, `AHUB`|*Optional*. License type to transition resources to. Defaults to `PAYG`.|
|`-AutomationAccResourceGroupName`| `<name>`|*Required* only if `-RunMode Scheduled`. Resource group hosting the Automation Account, created if it does not already exist. Not used by `-RunMode Single`.|
|`-AutomationAccountName`| `<name>`|*Optional*. Name of the Automation Account used in `Scheduled` mode. Defaults to `aaccAzureArcSQLLicenseType`.|
|`-Location`|`<region>`|*Required* only if `-RunMode Scheduled`. Azure region for the Automation Account. Not used by `-RunMode Single`.|
|`-cleanDownloads`|`$true`, `$false`|*Optional*. Removes the `.\manage-payg-transition\` working folder after the run. Defaults to `$false`.|

> [!NOTE]
> The script does not expose a `-SubId` parameter; use `-targetSubscription`. Scoping to a
> list of subscriptions from a `.csv` file is supported by the underlying
> `modify-azure-sql-license-type.ps1` / `modify-arc-sql-license-type.ps1` scripts when they
> are run directly, but is not passed through by this wrapper.


## How It Works

- This script is **fully self-contained**: the logic of the following three scripts is
  embedded directly in `manage-payg-transition.ps1` and requires no external downloads
  to run:

   `set-azurerunbook.ps1` - imports & publishes the helper runbook that and run if a scheduled execution is selected. 

   `modify-azure-sql-license-type.ps1` - configures the Azure SQL resources

   `modify-arc-sql-license-type.ps1` - configures the existing Arc SQL resources

- At runtime, the embedded content of each script is written to local files under
  `.\manage-payg-transition\` (created automatically if it doesn't exist) so it can be
  invoked as a normal PowerShell script / imported as an Azure Automation runbook. No
  network calls to GitHub are made to fetch these dependent scripts.
- Use `-TargetLicenseType` (`PAYG` by default, or `AHUB`) to control which license
  model resources are transitioned to. This value is translated internally to the
  vocabulary each embedded script expects (e.g. `LicenseIncluded`/`BasePrice` for Azure
  SQL resources, `PAYG`/`Paid` for Arc SQL Server).
- Use `-ReportOnly` to perform a read-only dry run first. The script discovers and reports
  every resource it would change (and writes a `ModifiedResources_<timestamp>.csv` report)
  without modifying any license types. This is the recommended way to confirm the blast
  radius before a real run.
- The script selects the tenant from `-TenantId` if supplied; otherwise it falls back to the
  tenant of your current Az PowerShell context. Run `Get-AzContext` first, or pass
  `-TenantId` explicitly, to be certain which tenant will be affected.
- Resources that already have the target license type are excluded from discovery by design,
  so re-running the script is safe and idempotent. A converged environment correctly reports
  `Found 0 resource(s) to update`.
- Arc-connected machines whose agent is `Disconnected` or `Expired` cannot be updated, because
  the extension setting must be pushed to a reachable agent. These are skipped and will be
  picked up on a later run once the machines reconnect.
- The offline Azure VMs will be reactivated for a brief period to change the configuration.
- Each run writes a `ModifiedResources_<timestamp>.csv` report. The `UpdateResult` column
  records the per-resource outcome and `UpdateError` carries the service error text when a
  change was rejected.
- **By default the script does not wait for changes to finish.** Updates are submitted
  asynchronously and the report records `RequestSubmitted`, which means *"the service accepted
  the request"* — **not** *"the license type has changed"*. Pass `-WaitForCompletion` to wait
  for each change to reach a terminal state and report a confirmed outcome instead.

  | Resource | Default | With `-WaitForCompletion` |
  |---|---|---|
  | SQL Managed Instance, database, elastic pool, instance pool | `--no-wait`, reports `RequestSubmitted` | waits, reports `Updated` |
  | Arc-connected machine | `-NoWait`, reports `RequestSubmitted` | polls the extension, reports `Succeeded` / `Failed` / `TimedOut` |
  | SQL virtual machine | direct ARM request, reports `RequestSubmitted` | `az sql vm update` waits, reports `Updated` |
  | **SSIS integration runtime** | **always waits**, reports `Updated` | same |

  SSIS integration runtimes are the one exception, because
  `Set-AzDataFactoryV2IntegrationRuntime` exposes no asynchronous option.

  SQL virtual machines are a special case. `az sql vm update` has no `--no-wait` option and
  blocks for roughly two minutes per VM, and although `Update-AzSqlVM` advertises `-NoWait`
  and `-AsJob`, both are broken in `Az.SqlVirtualMachine` 2.4.0. The script therefore submits
  the change to ARM directly (read the resource, change `sqlServerLicenseType`, write it
  back), which returns in seconds. If that request fails for any reason it automatically
  falls back to the synchronous `az sql vm update` path.

  For Arc, a `TimedOut` result is inconclusive rather than a failure — the agent may still
  apply the setting after the script stops waiting.
- To confirm outcomes after a default (non-waiting) run, either re-run the script — already
  converged resources are excluded by discovery, so a second run reports only what genuinely
  still needs changing — or query the current state directly. For Arc:

  ```powershell
  Search-AzGraph -Query @"
  resources
  | where type =~ 'microsoft.hybridcompute/machines/extensions'
  | where properties.type in~ ('WindowsAgent.SqlServer','LinuxAgent.SqlServer')
  | project name = split(id,'/')[8], licenseType = properties.settings.LicenseType,
            state = properties.provisioningState
  "@
  ```
- The subscriptions in scope of the transition will be automatically tagged with `ArcSQLServerExtensionDeployment:PAYG` to ensure that the furure SQL Servers onboarded to Azure Arc are configured to use the pay-as-you-go subscription.  For details, see [Manage automatic connection for SQL Server enabled by Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/manage-autodeploy).

## Example 1

Switch all machines to pay-as-you-go in a single subscription immediately and use unlimited virtualization.

```powershell
.\manage-payg-transition.ps1 `
    -targetSubscription "00000000-0000-0000-0000-000000000000" `
    -UsePcoreLicense Yes
````

## Example 2

Preview (dry run) what would change across an entire tenant, without modifying anything. This is the recommended first step before any real run.

```powershell
.\manage-payg-transition.ps1 `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ReportOnly
````

## Example 3

Switch the machines in a single resource group back to Azure Hybrid Benefit (AHUB).

```powershell
.\manage-payg-transition.ps1 `
    -targetSubscription "00000000-0000-0000-0000-000000000000" `
    -targetResourceGroup "MyResourceGroup" `
    -TargetLicenseType AHUB
````

## Example 4

Schedule a recurring daily transition for Azure resources only, using an automation account in the `EastUS` region.

```powershell
.\manage-payg-transition.ps1 `
    -Target Azure `
    -RunMode Scheduled `
    -AutomationAccResourceGroupName "MyAutomationRG" `
    -AutomationAccountName "MyAutomation" `
    -Location "EastUS"
```
# Running the script using Cloud Shell

This option is recommended because Cloud shell has the Azure PowerShell modules pre-installed and you are automatically authenticated.  Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

1. Connect to Azure. You must specify `<tenant_id>` if you have access to more than one AAD tenant.

    ```console
   Connect-AzAccount -TenantId <tenant_id>
    ```

1. Upload the script to your cloud shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/manage-payg-transition/manage-payg-transition.ps1 -o manage-payg-transition.ps1
    ```

1. Run the script.

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.

# Running the script from a PC


Use the following steps to run the script in a PowerShell session on your PC.

1. Copy the script to your current folder:

   ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/manage-payg-transition/manage-payg-transition.ps1 -o manage-payg-transition.ps1
    ```

1. Make sure the NuGet package provider is installed:

    ```console
    Set-ExecutionPolicy  -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Install-packageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force
    ```

1. Make sure the the Az module is installed. For more information, see [Install the Azure Az PowerShell module](https://learn.microsoft.com/powershell/azure/install-az-ps):

    ```console
    Install-Module Az -Scope CurrentUser -Repository PSGallery -Force
    ```

1. Connect to Azure AD and log in to your Azure account. You must specify `<tenant_id>` if you have access to more than one AAD tenants.

    ```console
    Connect-AzureAD -TenantID <tenant_id>
    Connect-AzAccount -TenantID (Get-AzureADTenantDetail).ObjectId
    ```

1. Run the script. 
