---
services: Azure SQL
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 06/24/2024
---

# Overview

This script performes a scheduled activation of a SQL Server p-core license.

# Required permissions

Your RBAC role must include the following permissions:

- Microsoft.AzureArcData/SqlLicenses/read
- Microsoft.AzureArcData/SqlLicenses/write
- Microsoft.Management/managementGroups/read
- Microsoft.Resources/subscriptions/read
- Microsoft.Resources/subscriptions/resourceGroups/read
- Microsoft.Support/supporttickets/write

# Creating a Azure runbook

You can scahedule to run the the command as a runbook. To set it up using Azure Portal, follow these steps.

1. Open a command shell on your device and run this command. It will copy the script to your local folder.
```console
curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/activate-pcore-license/activate-pcore-license.ps1 -o activate-pcore-license.ps1
```
1. [Create a new automation account](https://ms.portal.azure.com/#create/Microsoft.AutomationAccount)  or open an existing one. In the Advanced section, make sure that *System assigned identity* is selecetd.
1. In the **Process automation** group select **Runbooks**
1. Click on the *Import a runbook* tab and configure it:
    * select the file you downloaded in Step 1  
    * type in a name of the runbook
    * select the type as PowerShell 
    * select the runtime version 5.1 
    * click **Import**.
1. When import is completed, click the *Publish* button.
1. Once the status changes to *Published* on the runbook blade, click on the *Link to schedule* button 
1. Select *Link a schedule to your runbook* and click *+ Add a schedule*  
1. Configure the schedule: 
    * type in the name of the schedule
    * set the start time
    * set *Recurrance* to Once
    * click **Create**
1. In a separate browser window, open the Azure resource of your inactive licence, go to the *Settings* group, select *Properties* and copy the license ID (URI) to the clipboard.
1. Go back to *Schedule runbook page*, click on *Parameters and run settings* and paste the license ID value you copied to the clipboard.
1. Click **OK** to link to the schedule and **OK** again to create the job.
1. On the runbook Overview page, click to open a recent job that was completed right after the specified start time.
1. Click on the *Output* tab and notice the `Properties.activationState=Activated`. Your license is now active.

For more information about the runbooks, see the [Runbook tutorial](https://docs.microsoft.com/en-us/azure/automation/learn/automation-tutorial-runbook-textual-powershell)
