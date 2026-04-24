---
services: Azure Arc-enabled SQL Server
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 4/6/2023
---


# Overview

This script provides a scalable solution to uninstall Azure extension for SQL Server on a specific Arc-enabled server,
all Arc-enabled servers in a specific resource group, specific subscription, a list of subscriptions or the entire account.  
You can specify a single subscription to scan, or provide a list of subscriptions as a .CSV file. 

# Prerequisites

- You must have at least a *Contributor* role in each subscription you modify.  
- The Azure extension for SQL Server is updated to version 1.1.2230.58 or newer.
- You must be connected to Azure AD and logged in to your Azure account. If your account have access to multiple tenants, make sure to log in with a specific tenant ID.

# Launching the script

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|-SubId|subscription_id *or* a file_name *or* ALL |Required: modify a specific subscription id, a list of subscriptions in a .csv file<sup>1</sup>, or ALL subscriptions |
|-ResourceGroup |resource_group_name|Optional: Limit the scope  to a specific resource group|
|-MachineName |machine_name|Optional: Limit the scope to a specific machine|


<sup>1</sup>You can create a .csv file using the following command and then edit to remove the subscriptions you don't  want to scan.
```PowerShell
Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation 
```

## Example 1

The following command will scan all the subscriptions to which the user has contributor access to, and uninstall Azure extension for SQL Server on all Arc-enabled servers where it is installed.

```PowerShell
.\uninstall-azure-extension-for-sql-server.ps1 -SubId ALL
```

## Example 2

The following command will scan the subscription `<sub_id>` and uninstall Azure extension for SQL Server on all Arc-enabled servers where it is installed.

```PowerShell
.\uninstall-azure-extension-for-sql-server.ps1 -SubId <sub_id> 
```

## Example 3

The following command will scan resource group <resource_group_name> in the subscription `<sub_id>` and and uninstall Azure extension for SQL Server on all Arc-enabled servers where it is installed.

```PowerShell
.\uninstall-azure-extension-for-sql-server.ps1 -SubId <sub_id> -ResourceGroup <resource_group_name> 
```
## Example 4

The following command will uninstall Azure extension for SQL Server on a specific Arc-enabled server.

```PowerShell
.\uninstall-azure-extension-for-sql-server.ps1 -SubId <sub_id> -MachineName <machine_name> 
```

# Running the script using Cloud Shell

This option is recommended because Cloud shell has the Azure PowerShell modules pre-installed and you are automatically authenticated.  Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

1. Connect to Azure AD

    ```console
   Connect-AzureAD
    ```

1. Upload the script to your cloud shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/uninstall-azure-extension-for-sql-server/uninstall-azure-extension-for-sql-server.ps1 -o uninstall-azure-extension-for-sql-server.ps1
    ```

1. Run the script using the desired scope. For example:

    ```console
   .\uninstall-azure-extension-for-sql-server.ps1 -SubId <sub_id>
    ```

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.

# Running the script from a PC

Use the following steps to run the script in a PowerShell session on your PC.

1. Copy the script to your current folder:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/uninstall-azure-extension-for-sql-server/uninstall-azure-extension-for-sql-server.ps1 -o uninstall-azure-extension-for-sql-server.ps1
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

1. Connect to Azure AD and login to your Azure account.

    ```console
    Connect-AzureAD
    Connect-AzAccount -TenantID (Get-AzureADTenantDetail).ObjectId
    ```

1. Run the script using the desired scope. For example:

    ```console
   .\uninstall-azure-extension-for-sql-server.ps1 -SubId <sub_id> -ResourceGroup <resource_group>
    ```
