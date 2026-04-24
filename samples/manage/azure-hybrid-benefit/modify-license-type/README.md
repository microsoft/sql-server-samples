---
services: Azure SQL
platforms: Azure
author: anosov1960,rodrigomonteiro-gbb
ms.author: sashan.romontei
ms.date: 10/13/2025
---

# About this sample

- **Applies to:** Azure SQL Server resources
- **Workload:** n/a
- **Programming Language:** PowerShell. CLI
- **Authors:** Alexander (Sasha) Nosov, Rodrigo Gerhardt Monteiro
- **Update history:** 
    
    04/29/2025 - Initial version

    05/13/2025 - Modified to fix errors and to remove the auto-start of the offline resources.

    05/30/2025 - Added transcript support

    06/10/2025 - Fixed a RG filter for SQL DB

    10/13/2025 - blocked modification of the DR replica


# Overview

This script provides a scaleable solution to change the license type of various Azure SQL resources within the selected scope. It automates the process of modifying license settings for SQL Databases, Elastic Pools, SQL Managed Instances, SQL Instance Pools, SQL Virtual Machines, and DataFactory SSIS Integration Runtimes. The script supports targeting a single subscription, a list of subscriptions defined in a CSV file, or all accessible subscriptions. Optionally, it can also start resources that are stopped (if the -ForceStartOnResources parameter is enabled).

This script is designed to help administrators standardize SQL licensing across their Azure environment by automating license updates. It accepts a subscription ID or CSV file (for a list of subscriptions). If no subscription is specified, it defaults to updating resources in all accessible subscriptions. The update will preserve the existing configuration of the passive replicas with failover rights (with License type value set to "DR").

# Target Resource Types

- SQL Virtual Machines: Updates license types after checking if the VM is running. If not, it can optionally start the VM to perform the update.
- SQL Managed Instances: Detects instances that are stopped or not in the "Ready" state and can force them to start before updating.
- SQL Databases & Elastic Pools: Scans individual SQL servers to locate databases and elastic pools with a different license type and updates them accordingly.
- SQL Instance Pools: Locates instance pools that require an update.
- DataFactory SSIS Integration Runtimes: Checks for integration runtimes with an out-of-date license setting and updates them.
 
> [!IMPORTANT]
> - SQL Virtual Machines must be in PowerState = "VM running" to be updated
> - SQL Managed Instances must be in State = "Ready" to be updated
> - DataFactory SSIS Integration Runtimes must be in State = "Stopped" to be updated


# Required Permissions
The automation account needs to have the bellow permissions in order to be able to successfully run the Runbook and update all the SQL Server resources license type:

1. **SQL DB Contributor**: *SQL DB Contributor role*. 
1. **SQL Managed Instance Contributor**: *SQL Managed Instance Contributor*
1. **SQL Server Contributor**: *SQL Managed Instance Contributor*
1. **Data Factory Contributor**: *Data Factory Contributor role*.
1. **Virtual Machine Contributor**: *Virtual Machine Contributor role*. 

A *Subscription Contributor* role has sufficient permissions to modify any of the above resources. 

# Interactive Reporting

The script logs steps along the process and compiles a final report summarizing which resources were updated in each category.

# Integration with Azure Authentication

The scripts is seamlessly integrated with Azure Authentication. It uses managed identity authentication (via Connect-AzAccount -Identity and az login --identity) to connect to your Azure environment securely.

# Script parameters


| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|`-SubId`|`subscription_id` *or* a file_name|Optional: Subscription id or a .csv file with the list of subscriptions<sup>1</sup>. If not specified all subscriptions will be scanned|
|`-ResourceGroup` |`resource_group_name`|Optional: Limits the scope  to a specific resource group|
|`-ResourceName` |`resource_name`|Optional: Limits the scope  to resources associated with this name. For SQL Server - updates all databases under the specified server. For SQL Managed Instance - updates the specified instance. For SQL VM - updates the specified VM |
|`-LicenseType` | `LicenseIncluded` (default) or `BasePrice` | Optional: Sets the license type to the specified value<sup>2</sup> |
|`-ExclusionTags`| `'{"tag1":"value1","tag2":"value2"}'` |*Optional*. If specified, excludes the resources that have these tags assigned.|
|`-TenantId`| `tenant_id` |*Optional*. If specified, uses this tenant id to log in. Otherwise, the current context is used.|
|`-ReportOnly`| |*Optional*. If true, generates a csv file with the list of resources that are to be modified, but doesn't make the actual change.|
|`-UseManagedIdentity`| |*Optional*. If true, logs in both PowerShell and CLI using managed identity. Required to run the script as a runbook.|

<sup>1</sup>You can generate a .csv file that lists only specific subscriptions. E.g., the following command will include only production subscriptions (exclude dev/test).
<sup>2</sup>The script will skip the resources with the LicenseType property set to "DR"
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

# Logging & Error Handling

The script logs key actions to the console and captures error messages using Write-Error. Check the console output for a summary report detailing which resources were updated.

# Reporting

The script produces a report listing the affected resources by creating a `ModifiedResources_{yyyyMMdd_HHmmss}.csv` file that contains the following information about each resource:

- Tenant id
- Subscription id
- Resource name
- Resource type
- Status
- Original license type
- Resource group
- Location

> [!NOTE]
> - If `-ReportOnly` is specified, the report shows the resources that would be affected without the actual change being applied.


# Script execution examples

## Example 1

The following command will scan all the subscriptions in tenant `<tenant_id>`, and generates the list of the resources that would change the license type to "LicenseIncluded".

```PowerShell
.\modify-azure-sql-license-type.ps1 -TenantId <tenant_id> -LicenseType LicenseIncluded -ReportOnly
```

## Example 2

The following commands will create a list of production subscriptions in tenant `<tenant_id>`, and generates the list of the resources that would change the license type to "LicenseIncluded".

```PowerShell
$tenantId = "<tenant-id>"
Get-AzSubscription -TenantId $tenantId | Where-Object {
    $sub = $_
    $details = Get-AzSubscription -SubscriptionId $sub.Id -TenantId $tenantId
    if ($details -and $details.ExtendedProperties -and $details.ExtendedProperties.SubscriptionPolicies) {
        $quotaId = ($details.ExtendedProperties.SubscriptionPolicies | ConvertFrom-Json).quotaId
        return $quotaId -notmatch 'MSDN|DEV|VS|TEST'
    }
    return $false
} | Export-Csv .\mysubscriptions.csv -NoTypeInformation
.\modify-azure-sql-license-type.ps1 -TenantId <tenant_id> -SubId .\mysubscriptions.csv -LicenseType LicenseIncluded -ReportOnly
```

## Example 3

The following command will scan resource group `<resource_group_name>` in the subscription `<sub_id>` within the current tenant, set the license type value to "LicenseIncluded" on each resource that has a different license type.

```PowerShell
.\modify-azure-sql-license-type.ps1 -SubId <sub_id> -ResourceGroup <resource_group_name> -LicenseType LicenseIncluded 
```

## Example 4

The following command will scan all subscriptions in the account using managed identity, set the license type value to "LicenseIncluded" on all resources in tenant <tenant_id> that have a different license type.  The resources with the tag `Environment:Dev` will be excluded.

```PowerShell
.\modify-azure-sql-license-type.ps1 -TenantId <tenant_id> -LicenseType LicenseIncluded -UseManagedIdentity -ExclusionTags '{"Environment":"Dev"}' 
```

# Running the script using Cloud Shell

This option is recommended because Cloud shell has the Azure PowerShell modules pre-installed and you are automatically authenticated.  Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

1. Connect to Azure AD. You can skip this step if you specify `<tenant_id>` as a parameter of the script. 

    ```console
   Connect-AzureAD -TenantID <tenant_id>
    ```

1. Upload the script to your cloud shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/modify-azure-sql-license-type/modify-azure-sql-license-type.ps1 -o modify-azure-sql-license-type.ps1
    ```

 1. Run the script by following an appropriate example. 


> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.

# Running the script from a PC


Use the following steps to run the script in a PowerShell session on your PC.

1. Copy the script to your current folder:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/modify-azure-sql-license-type/modify-azure-sql-license-type.ps1 -o modify-azure-sql-license-type.ps1
    ```

1. Connect to Azure AD. You can skip this step if you specify `<tenant_id>` as a parameter of the script.

    ```console
    Connect-AzureAD -TenantID <tenant_id>
    ```

1. Run the script by following an appropriate example. 
