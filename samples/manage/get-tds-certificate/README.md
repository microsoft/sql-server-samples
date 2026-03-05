# Get TDS certificate from Azure SQL using PowerShell

Script that downloads TDS certificate with public key only from Azure SQL

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** Azure SQL
- **Key features:**  Database, Managed Instance
- **Workload:** n/a
- **Programming Language:** PowerShell
- **Authors:** Srdan Bozovic
- **Update history:** n/a

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. PowerShell 5.0 or higher installed

<a name=run-this-sample></a>

## Run this sample

Run the script below from either Windows or Azure Cloud Shell

```powershell

$scriptUrlBase = 'https://raw.githubusercontent.com/Microsoft/sql-server-samples/master/samples/manage/get-tds-certificate'

$parameters = @{
    hostName = '<hostName>'
    port = '<port>'
    publicCertificateFile  = '<publicCertificateFile>'
    }

Invoke-Command -ScriptBlock ([Scriptblock]::Create((iwr ($scriptUrlBase+'/getTDSCertificate.ps1?t='+ [DateTime]::Now.Ticks)).Content)) -ArgumentList $parameters

```

<a name=sample-details></a>

## Sample details

This sample shows how to retreive Azure SQL TDS certificate and save it to DER encoded X509 binary.

<a name=disclaimers></a>

## Disclaimers
The scripts and this guide are copyright Microsoft Corporations and are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.

<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

This sample reuses code from [Azure SQL Connectivity Checker](https://github.com/Azure/SQL-Connectivity-Checker)
