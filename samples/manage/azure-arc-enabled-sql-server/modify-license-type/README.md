---
services: Azure Arc-enabled SQL Server
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 05/01/2025
---

# About this sample

- **Applies to:** Arc-enabled SQL Server
- **Workload:** n/a
- **Programming Language:** PowerShell
- **Authors:** Alexander (Sasha) Nosov
- **Update history:** 
    
    05/01/2025 - added the consent parameter for teh CSP-managed subscriptions

    05/09/2025 - added *-ReportOnly* and *-TenandId* parameters

    05/13/2025 - added support for a .CSV file with the machine names 

# Overview

This script provides a scaleable solution to set or change the license type and/or enable or disable the ESU policy on all Azure-connected SQL Servers in a specified scope.

You can specify a single subscription to scan, or provide a list of subscriptions as a .CSV file.
If not specified, all subscriptions your role has access to are scanned.

# Prerequisites

- You must have at least a *Azure Connected Machine Resource Administrator* role in each subscription you modify.
- The Azure extension for SQL Server is updated to version 1.1.2230.58 or newer.
- You must be connected to Azure AD and logged in to your Azure account. If your account have access to multiple tenants, make sure to log in with a specific tenant ID.


# Launching the script

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|`-SubId`|`subscription_id` *or* `file_name`|*Optional*: Subscription id or a .csv file with the list of subscriptions<sup>1</sup>. If not specified all subscriptions will be scanned|
|`-ResourceGroup` |`resource_group_name`|*Optional*: Limits the scope  to a specific resource group|
|`-MachineName` |`machine_name`|*Optional*: A single machine name or a CSV file name containing a list of machine names<sup>2</sup>.|
|`-LicenseType` | `Paid`, `PAYG` or `LicenseOnly`| *Optional*: Sets the license type to the specified value |
|`-ConsentToRecurringPAYG` | `Yes`, `No` |*Optional*. Consents to enabling the recurring PAYG billing. LicenseType must be "PAYG". Applies to CSP subscriptions only.|
|`-UsePcoreLicense` | `Yes`, `No` | *Optional*. Enables unlimited virtualization license if the value is "Yes" or disables it if the value is "No". To enable, the license type must be "Paid" or "PAYG"|
|`-EnableESU` | `Yes`, `No` | *Optional*. Enables the ESU policy the value is "Yes" or disables it if the value is "No". To enable, the license type must be "Paid" or "PAYG"|
|`-Force`| |*Optional*. Forces the change of the license type to the specified value on all installed extensions. If `-Force` is not specified, the `-LicenseType` value is set only if undefined. Ignored if `-LicenseType`  is not specified|
|`-ExclusionTags`| `'{"tag1":"value1","tag2":"value2"}'` |*Optional*. If specified, excludes the resources that have these tags assigned.|
|`-TenantId`| `tenant_id` |*Optional*. If specified, uses this tenant id to log in. Otherwise, the current context is used.|
|`-ReportOnly`| |*Optional*. If true, generates a csv file with the list of resources that are to be modified, but doesn't make the actual change.|
|`-UseManagedIdentity`| |*Optional*. If true, logs in both PowerShell and CLI using managed identity. Required to run the script as a runbook.|

<sup>1</sup>You can generate a .csv file that lists only specific subscriptions. E.g., the following command will include only production subscriptions (exclude dev/test).
```PowerShell
$tenantId = "<your-tenant-id>"
Get-AzSubscription -TenantId $tenantId | Where-Object {
    $sub = $_
    $details = Get-AzSubscription -SubscriptionId $sub.Id -TenantId $tenantId
    if ($details -and $details.ExtendedProperties -and $details.ExtendedProperties.SubscriptionPolices) {
        $quotaId = ($details.ExtendedProperties.SubscriptionPolices | ConvertFrom-Json).quotaId
        return $quotaId -notmatch 'MSDN|DEV|VS|TEST'
    }
    return $false
} | Export-Csv .\mysubscriptions.csv -NoTypeInformation
```
<sup>2</sup>The .csv file must include a column *MachineName*. E.g.:
```
"MachineName",
"Prod1",
"Prod2",
"Prod3"
```

# Script execution examples

## Example 1

The following command will scan all the subscriptions in tenant `<tenant_id>`, and list the machines that would have the license type change to "PAYG" on all servers where license type is undefined. 

```PowerShell
.\modify-arc-sql-license-type.ps1 -TenantId <tenant_id> -LicenseType PAYG -ReportOnly
```

## Example 2

The following command will scan the subscription `<sub_id>` in the current tenant and set the license type value to "Paid" on all servers listed in `machines.csv`.

```PowerShell
.\modify-arc-sql-license-type.ps1 -SubId <sub_id> -MachineName machines.csv -LicenseType Paid -Force
```

## Example 3

The following command will scan resource group `<resource_group_name>` in the subscription `<sub_id>` within the current tenant, set the license type value to "PAYG" and enable unlimited virtualization license on all servers in the specified resource group.

```PowerShell
.\modify-arc-sql-license-type.ps1 -SubId <sub_id> -ResourceGroup <resource_group_name> -LicenseType PAYG -UsePcoreLicense Yes -Force
```

## Example 4

The following command will set License Type to "Paid" and enables ESU on all servers in the subscriptions `<sub_id>` of tenant `<tenant_id>` and the resource group `<resource_group_name>` except those with the tag `Environment:Dev`

```console
.\modify-arc-sql-license-type.ps1 -TenantId <tenant_id> -SubId <sub_id> -ResourceGroup <resource_group_name> -LicenseType Paid -EnableESU Yes -Force -ExclusionTags {"Environment":"Dev"}
```

## Example 5

The following command will disable ESU on all servers in the subscriptions `<sub_id>`.
    
```console
.\modify-arc-sql-license-type.ps1 -SubId <sub_id> -EnableESU No 
```

## Example 6

The following command will scan all subscriptions in the account using managed identity, set the license type value to "PAYG" and consents to enabling recurring billing on all servers in the account.

```PowerShell
.\modify-arc-sql-license-type.ps1 -LicenseType PAYG -ConsentToRecurringPAYG Yes -Force -UseManagedIdentity
```
> [!NOTE]
> The recurring billing only supported in the CSP accounts.

# Running the script using Cloud Shell

This option is recommended because Cloud shell has the Azure PowerShell modules pre-installed and you are automatically authenticated.  Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

1. Connect to Azure AD. You can skip this step if you specify `<tenant_id>` as a parameter of the script. 

    ```console
   Connect-AzureAD -TenantID <tenant_id>
    ```

1. Upload the script to your cloud shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/modify-arc-sql-license-type/modify-arc-sql-license-type.ps1 -o modify-arc-sql-license-type.ps1
    ```

1. Run the script by following an appropriate example. 

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.

# Running the script from a PC


Use the following steps to run the script in a PowerShell session on your PC.

1. Copy the script to your current folder:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/modify-arc-sql-license-type/modify-arc-sql-license-type.ps1 -o modify-arc-sql-license-type.ps1
    ```

1. Connect to Azure AD. You can skip this step if you specify `<tenant_id>` as a parameter of the script.

    ```console
    Connect-AzureAD -TenantID <tenant_id>
    ```

1. Run the script by following an appropriate example. 
