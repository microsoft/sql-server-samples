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

---

# Launching the script

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|`-SubId`|`<subscription_id>` *or* `<file name>`|*Optional*: Subscription id or a .csv file with the list of subscriptions<sup>1</sup>. If not specified all subscriptions will be transitioned.|
|`-ResourceGroup` |`<name>`|*Optional*: Limits the scope of transition to a specified resource|
|`-RunAt` |`YYYY-MM-DD HH:MM:SS` |*Optional*: Sets the transition time in UTC time zone. E.g. 2025-05-01 14:00:00 means May 1, 2025 at 2pm UTC time. If not specified, the transition will be executed immediately.|
|`-UsePcoreLicense` | `Yes`, `No` |*Optional*. Passed to Arc script to control PCore licensing behavior. Set to `No` if not specified.|
|`-AutomationAccount`| `<name>`|*Required* if `-RunAt` is specified. The script will automatically create an automation account with this name unless one with this name alreday exists. It will be used for the “General” runbook import operation. |
|`-Location`|`<region>`|*Required* if `-RunAt` is specified. Azure region for the “General” runbook import operation.|
|`-ExclusionTag`|`<name:value>`|*Optional*. Specifies the tag name and value to exclude the tagged offline VMs from the forced activation during the transition |

<sup>1</sup>You can create a .csv file using the following command and then edit to remove the subscriptions you don't  want to scan.
```PowerShell
Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation
```


## How It Works

- This script internally runs the following scripts

   `set-azurerunbook.ps1` - imports & publishes the helper runbook that and run if a scheduled execution is selected. 

   `modify-azure-sql-license-type.ps1` - configures the Azure SQL resources to pay-as-you-go

   `modify-license-type.ps1` configures the existing Arc SQL resources to pay-as-you-go

- The dependent scripts are downloaded to `.\PaygTransitionDownloads\`. It is created automatically if doesn't exist. The downloaded scripts are refreshed automatically on each run to ensure that the up-to-date version is used.
- The offline Azure VMs will be reactivated for a brief period to change the configuration. If the VM should not be recativated, use `-ExclusionTag` option.
- The subscriptions in scope of the transition will be automatically tagged with `ArcSQLServerExtensionDeployment:PAYG` to ensure that the furure SQL Servers onboarded to Azure Arc are configured to use the pay-as-you-go subscription.  For details, see [Manage automatic connection for SQL Server enabled by Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/manage-autodeploy).

## Example 1

Switch all machines to pay-as-you-go in a single subscription immediately and use unlimited virtualization.

```powershell
.\manage-payg-transition.ps1 `
    -SubId "00000000-0000-0000-0000-000000000000" `
    -UsePcoreLicense Yes 
````

## Example 2 

Switch all machines to pay-as-you-go in subscriptions listed in MySusbcriptions.csv immediately without using unlimited virtualization. Exclude the VMs that tagged with `DoNotActivate:True`

```powershell
.\manage-payg-transition.ps1 `
-SubId MySubscription.csv
-ExclusionTag DoNotActivate:True
````

## Example 3 

Switch all machines to pay-as-you-go in *all* subscriptions on May 1, 2025 at 0:00 using an automation account `MyAutomation` in `EatUS` region.

```powershell
.\manage-payg-transition.ps1 `
    -SubId "00000000-0000-0000-0000-000000000000" `
    -RunAt "2025-05-01 00:00:00"
    -AutomationAccount MyAutomation
    -Location "EastUS"
```
# Running the script using Cloud Shell

This option is recommended because Cloud shell has the Azure PowerShell modules pre-installed and you are automatically authenticated.  Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

1. Connect to Azure AD. You must specify `<tenant_id>` if you have access to more than one AAD tenants.

    ```console
   Connect-AzureAD -TenantID <tenant_id>
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
