---
services: Azure Arc-enabled SQL Server
platforms: Azure
author: racarb
ms.date: 24/8/2023
---

## Azure Arc SQL Reclass Report
# Overview

This script provides a report of the Azure Arc SQL resources that generate SQL Reclass, including the following information from each resource in a CSV format:



| **Promerty** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|
|createdAt|The time when the Azure Arc SQL resource was created|
|subscriptionId|Id of the subscription
|resourceGroup|Resource group name
|AzureArcServerName|Azure Arc server where the SQL instance is in
|Status|Status of the SQL Instance Resource
|SQLInstanceName|SQL Instance name
|version|Version of the SQL instance
|edition| Edition of the SQL instance
|vcores|Number of cores
|licenseTypeinGraph| Licence setting's value, from Azure Graph perspective
|licenseTypeInExt|License setting's value, from the extension perspective (Powershell query)
|ExVersion| Version of the WindowsAgent.SqlServer extension
|provisioningState|Provision state of the WindowsAgent.SqlServer extension

The file is stored in the local folder with the name ***ArcSQLServerinstanceswithReclass.csv***

  <br>


Aditionaly, another CSV is created with the information of all the WindowsAgent.SqlServer extensions from azure Arc Servers

| **Promerty** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|
|subscriptionId|Id of the subscription
|resourceGroup|Resource group name
|name|Azure Arc server where the SQL extension is installed
|Status|Status of the SQL extension
|ExVersion|Version of the SQL extension
|provisioningState|Provision state of the WindowsAgent.SqlServer extension

The information is stored in the local folder with the name ***SQLExtensionStatus.csv***

<br>

# Prerequisites

- The following powershell modules are needed: *Az.ResourceGraph, Az.ConnectedMachine, Az.Accounts*
- You must have at least a *Reader* role in each subscription from wich you want to extract the information
- You must be connected to Azure AD and logged in to your Azure account. If your account have access to multiple tenants, make sure to log in with a specific tenant ID.


# Launching the script

The script doesn't have any parameter and it is launched as is:

## Example 1

The following example gets a report from the subcriptions wich the users have access to

```PowerShell
.\Get-SQLAzureArcReclassReport.ps1
```
