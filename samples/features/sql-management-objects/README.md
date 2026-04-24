# SmoSamples

This unit test project is meant to demonstrate features of the Sql Management Objects framework and to help developers optimize performance of their SMO-based applications.


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
- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database, Azure SQL Data Warehouse
- **Key features:**
- Unit tests and a docker file that demonstrate proper use of SMO features against a working SQL Server instance.
- **Programming Language:**
- C#

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database with the full WideWorldImporters sample database, or
2. Docker
3. At minimum the dotnet 2.2 SDK, or Visual Studio 2017

<a name=run-this-sample></a>

## Run this sample
If using Docker, use runtests.sh or runtests.cmd as appropriate. If using a separate instance of SQL Server or Azure SQL Database, create a .runsettings file and run the unit tests using Visual Studio or "dotnet vstest".

<a name=sample-details></a>

## Sample details

Each unit test demonstrates a specific aspect of SMO-based application development, either in isolation or in conjunction with other SMO components. <br/>
Feature areas tested include:
1. Efficient use of collections
2. Sql query capture
3. Events
4. URNs
5. Script generation


<a name=related-links></a>

## Related Links
The SMO NuGet package is at https://www.nuget.org/packages/Microsoft.SqlServer.SqlManagementObjects/ <br/>
Documentation for the APIs is at https://docs.microsoft.com/sql/relational-databases/server-management-objects-smo/overview-smo<br/>
The WideWorldImporters sample database can be found at https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak <br/>