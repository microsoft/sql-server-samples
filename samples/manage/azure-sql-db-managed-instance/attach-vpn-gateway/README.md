# Attaches VPN gateway to Managed Instance virtual network

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

- **Applies to:** Azure SQL Database
- **Key features:**  Managed Instance
- **Workload:** n/a
- **Programming Language:** PowerShell
- **Authors:** Srdan Bozovic
- **Update history:** n/a

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. PowerShell 5.1 or PowerShell Core 6.0
2. Azure PowerShell Az module

**Linux prerequisites**
1. strongSwan

**Azure prerequisites:**

1. Permission to manage Azure virtual network

<a name=run-this-sample></a>

## Run this sample

Run the script below from PowerShell

```powershell

$scriptUrlBase = 'https://raw.githubusercontent.com/Microsoft/sql-server-samples/master/samples/manage/azure-sql-db-managed-instance/attach-vpn-gateway'

$parameters = @{
    subscriptionId = '<subscriptionId>'
    resourceGroupName = '<resourceGroupName>'
    virtualNetworkName = '<virtualNetworkName>'
    certificateNamePrefix  = '<certificateNamePrefix>'
    }

Invoke-Command -ScriptBlock ([Scriptblock]::Create((iwr ($scriptUrlBase+'/attachVPNGateway.ps1?t='+ [DateTime]::Now.Ticks)).Content)) -ArgumentList $parameters, $scriptUrlBase

```

<a name=sample-details></a>

## Sample details

This sample shows how to attach VPN Gateway to Managed Instance virtual network using PowerShell

This is done in three steps:
- Create and install certificates on client machine
- Calculate future VPN Gateway subnet IP range
- Deploy ARM template that will attach VPN Gateway to subnet

<a name=disclaimers></a>

## Disclaimers
The scripts and this guide are copyright Microsoft Corporations and are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.

<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For more information, see these articles:

- [What is a Managed Instance (preview)?](https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance)
- [Configure a VNet for Azure SQL Database Managed Instance](https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance-vnet-configuration)