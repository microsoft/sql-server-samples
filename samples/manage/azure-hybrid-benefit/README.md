---
services: Azure SQL
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 3/27/2021
---

# Overview

This script provides a simple solution to analyze and track the consolidated utilization of SQL Server licenses by all of the SQL resources in a specific subscription or the entire account. By default, the script scans all subscriptions the user account has access to. Alternatively, you can specify a single subscription or a .CSV file with a list of subscriptions. 

| **Category** | **Description** |
|:--|:--|
|Date|Date of the scan|
|Time|Time of the scan|
|Subscription name|The name of the subscription|
|Subscription ID|The unique subscription ID|
|AHB Std vCores|Total vCores used by Standard level SQL services (General Purpose service tier or SQL Server Standard edition) that have Azure hybrid benefit enabled|
|AHB Ent vCores|Total vCores used by Premium level SQL services (Business Critical  service tier or SQL Server Enterprise edition) that have Azure hybrid benefit enabled|
|PAYG Std vCores|Total vCores used by Standard level SQL services (General Purpose service tier or SQL Server Standard edition) that are billed using the pay-as-you-go method|
|PAYG Ent vCores|Total vCores used by Premium level SQL services (Business Critical  service tier or SQL Server Enterprise edition) that are billed using the pay-as-you-go method|
|HADR Std  vCores|Total vCores used by HADR replicas running SQL Server Standard edition|
|HADR Ent vCores|Total vCores used by HADR replicas running SQL Server Enterprise edition|
|Developer vCores|Total vCores used by SQL Server Developer edition|
|Express vCores|Total vCores used by SQL Server Express edition|
|Unregistered vCores|Total vCores used by SQL Server in Virtual Machines that are not registered with SQL IaaS Agent Extension |
|Unknown vCores|Total vCores used by Azure SQL Server resources with an unknown edition or service tier|

The following resources are in scope for the license utilization analysis:
- Azure SQL databases (vCore-based purchasing model only) 
- Azure SQL elastic pools (vCore-based purchasing model only)
- Azure SQL managed instances
- Azure SQL instance pools
- Azure Data Factory SSIS integration runtimes
- SQL Servers in Azure virtual machines 
- SQL Servers in Azure virtual machines hosted in Azure dedicated host

>[!NOTE]
> - The usage data is a snapshot at the time of the script execution based on the size of the deployed SQL resources in vCores.
> - For IaaS workloads, such as SQL Server in Virtual Machines or SSIS integration runtimes, each vCPU is counted as one vCore.
> - For PaaS workloads, each vCore of Business Critical service tier is counted as one Enterprise vCore and each vCore of General Purpose service tier is counted as one Standard vCore.
> - In the DTU-based purchasing model, the SQL license cost is built into the individual SKU prices. These resources are not eligible for Azure Hybrid Benefit or HADR benefit, and therefore are not in scope of the tool.
> - You must be at least a *Reader* of each subscription you scan. 
> - To report unregistered vCores, you must be a subscription *Contributor* or *Owner*, otherwise this column will show a zero value. Selecting this option will substantially increase the execution time, especially for the   subscriptions with large numbers of virtual machines.
> - The values AHB ECs and PAYG ECs are reserved for the future use and should be ignored

# Launching the script 

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|-SubId|subscription_id *or* a file_name|Optional: subscription id or a .csv file with the list of subscriptions<sup>1</sup>|
|-UseInRunbook| \$True or \$False (default) |Optional: must be $True when executed as a Runbook|
|-Server|[protocol:]server[instance_name][,port]|Optional: SQL Server connection endpoint to save data to the database.<br>  Must be accompanied by -Database and -Cred | 
|-Database|database_name|Optional: database name where data will be saved.<br>  Must be accompanied by -Server and -Cred|
|-Cred|credential_object|Optional: value of type PSCredential to securely pass database user and password|
|-FilePath|csv_file_name|Optional: filename where the data will be saved in a .csv format. Ignored if database parameters are specified|
|-ShowUnregistered|\$True or \$False (default)|Optional: causes the script to report the total size of VMs with a  self-hosted SQL server instance that is unregistered with the IaaS SQL extension|

<sup>1</sup>You can create a .csv file using the following command and then edit to remove the subscriptions you don't  want to scan.
```PowerShell
Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation 
```
If both database parameters and *FilePath* are omitted, the script will write the results to a `.\sql-license-usage.csv` file. The file is created automatically. If the file already exists, the consecutive scans will append the results to it. If the database parameters are specified, the data will be saved in a *Usage-per-subscription* table. If the table doesn't exist, it will be created automatically.

## Example 1

The following command will scan all the subscriptions to which the user has access to and save the results in `.\sql-license-usage.csv`

```PowerShell
.\sql-license-usage.ps1
```

## Example 2

The following command will scan the subscription `<sub_id>` and save the results in `<my_csv_file>` file.

```PowerShell
.\sql-license-usage.ps1 -SubId <sub_id> -FilePath .\<my_csv_file>.csv
```

## Example 3

The following command will scan all the subscriptions the user has access to and save the results in a SQL database `sql-license-usage` on a SQL Server instance `my-westus2-server.database.windows.net`. It will prompt for the database user name and password.

```PowerShell
$cred = Get-Credential
.\sql-license-usage.ps1 -Server my-westus2-server.database.windows.net -Database sql-license-usage -Cred $cred 
```

## Example 4

The following command uses a parameter splatting method to achieve the same outcome as Example 3.

```PowerShell
$params =@{
    Server="my-westus2-server.database.windows.net";
    Database="sql-license-usage";
    Cred=Get-Credential;
}    
.\sql-license-usage.ps1 @params
```

# Running the script using Cloud Shell

To run the script in the Cloud Shell, use the following steps:

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, read [PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Upload the script to the shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-hybrid-benefit/sql-license-usage.ps1 -o sql-license-usage.ps1
    ```

3. Run the script with a set of parameters that reflect your desired configuration.

    ```console
    ./sql-license-usage.ps1 <parameters>
    ```

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The `curl` command will copy the script directly to the home folder associated with your Cloud Shell session.

# Running the script as a Azure runbook

You can track your license utilization over time by running this script on schedule as a runbook. To set it up using Azure Portal, follow these steps. 

1. Open a command shell on your device and run this command. It will copy the script to your local folder.
```console
curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-hybrid-benefit/sql-license-usage.ps1 -o sql-license-usage.ps1
```
2. [Create a new automation account](https://ms.portal.azure.com/#create/Microsoft.AutomationAccount)  or open an existing one.
1. Select *Rus as accounts* in the **Account Settings** group, open the automatically created *Azure Run As Account* and note or copy the Display Name property. You must add this user to all the target subscriptions with at least a *Reader* access role. To collect the Unregistered vCores, the user must be at least a *Contributor*. See [Role assignment portal](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal) for the instructions about role assignments.
1. Select *Credentials* in the **Shared resources** group and create a credential object with the database username and password. The script will use these to connect to the specified database to save the license utilization data.
1. Select *Modules* in the **Shared resources** group and make sure your automation account have the following PowerShell modules installed. If not, add them from the Gallery.
    - Az.Accounts
    - Az.Compute
    - Az.DataFactory
    - Az.Resources
    - Az.Sql
    - Az.SqlVirtualMachine
1. Select *Runbooks* in the **Process automation** group and click on *Import a runbook*, select the file you downloaded in Step 1 and click **Create**.
1. When import is completed, click the *Publish* button.
1. From the runbook blade, click on the *Link to schedule* button and select an existing schedule or create a new one with the desired frequency of runs and the expiration time.
1. Click on *Parameters and run settings* and specify the following parameters:
    - SUBID. Put in a subscription ID or leave it blank if you want to scan all the subscriptions the *Azure Run As Account* has been given access to in Step 3.
    - SERVER. Put in the SQL Server connection endpoint (e.g. my-westus2-sql-server.database.windows.net)
    - CRED. Put in the name of the credential object you created in Step 4.
    - DATABASE. Put in the database name where you want to save the license utilization data.
    - USEINRUNBOOKS. Select True to activate the logic that authenticates the runbook using the *Azure Run As Account*.
1. Click **OK** to link to the schedule and **OK** again to create the job.

For more information about the runbooks, see the [Runbook tutorial](https://docs.microsoft.com/en-us/azure/automation/learn/automation-tutorial-runbook-textual-powershell) 

>[!IMPORTANT]
> When running the script as a runbook, it is necessary to save the data in a database so that the results could be analyzed outside of the runbook.
