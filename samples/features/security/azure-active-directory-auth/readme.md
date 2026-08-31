# Sample name

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>
## About this sample

<!-- Delete the ones that don't apply -->
- **Applies to:** Azure SQL Database, Azure SQL Data Warehouse
- **Key features:** Azure Active Directory Authentication
- **Programming Language:** C#
- **Authors:** Mirek Sztajno [mireks-msft]

## About this sample

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites:

**Software prerequisites:**

1. Visual Studio 2015 (or higher) with the latest SSDT installed (using .Net Framework 4.6 or higher)
	+ .Net Framework 4.6 must be set as the target framework for the Visual Studio project. To do this, double-click on Properties in Solution Explorer, then click the Application tab and check that the Target framework is set to .Net Framework 4.6
	+ To install .Net Framework 4.6, see https://msdn.microsoft.com/library/5a4x27ek.aspx
2. Active Directory Authentication Library for SQL Server (ADALSQL.DLL)
	+ ADALSQL.DLL enables applications to authenticate to Microsoft Azure SQL Database using Azure Active Directory. The ADALSQL.DLL is not installed with Visual Studio so download the DLL at http://www.microsoft.com/en-us/download/details.aspx?id=48742
	+ ADALSQL.DLL is automatically downloaded with Visual Studio 2015 Update 2, SQL Server Management Studio, and the newest version of SQL Server Data tools

1. Create Microsoft Entra tenant (formerly known as Azure Active Directory), or federate your domain with existing Microsoft Entra ID. This allows either to use managed or federated accounts associated with a specific Microsoft Entra ID.
2. Create Microsoft Entra ID administrator for Azure SQL Database using the Azure portal, PowerShell command, or Rest API.
3. With help from T-SQL query interface (i.e. SSMS query editor), using  Microsoft Entra ID admin credentials for Azure SQL Database and dedicated SQL pools in Azure Synapse, create an Microsoft Entra ID user in a designated database. The database user represents your Microsoft Entra ID principal (or one of the groups you belong to) and must exist in the database having CONNECT permission prior to executing a connection attempt.


**Other Prerequisites**

1. For Microsoft Entra ID integrated authentication a computer joined to a domain that is federated with Azure Active Directory is required.
2. An existing database created before a connection attempt is required. The database can be created using credentials for SQL administrator, or Microsoft Entra SQL administrator.

<a name=run-this-sample></a>

## Run this sample

<!-- Place sample links here -->

[Integrated Demo](integrated)

[Password Demo](password)

[Token Demo](token)

<a name=sample-details></a>

## Sample details

This demo provides a simple tool for exploring Azure Active Directory authentication to Azure SQL Database and dedicated SQL pools in Azure Synapse.

Azure Active Directory authentication with Azure SQL Database V12 supports the following authentication methods:
- User/password authentication
- Integrated authentication
- Application token authentication

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is only intended to provide a method to demonstrate sucessful authentication to Azure SQL Database or Azure SQL Data Warehouse via Azure Active Directory authentication methods.

<a name=related-links></a>
## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

<!-- For more information, see these articles: -->
