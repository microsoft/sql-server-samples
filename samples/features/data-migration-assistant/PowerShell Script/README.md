# PowerShell Script for Importing Assessment Results

This contains a PowerShell script for importing assessment results from JSON files into a SQL Server database. Assessments are generated using Data Migration Assistant, to evaluate moving data to SQL Server or to Azure SQL Database.


### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database
- **Key features:** Migration assessments
- **Programming Language:** PowerShell
- **Authors:** Chris Lound


<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. PowerShell
2. SQL Server 2016 (or higher) or an Azure SQL Database
3. Data Migration Assistant

**Azure prerequisites:**

1. Permission to create an Azure SQL Database

<a name=run-this-sample></a>

## Run this sample


1. Open the script in a text editor and add the following values to the EXECUTE FUNCTIONS section.
    - serverName
    - databaseName
    - jsonDirectory
    - processTo

   For more information, see [Consolidate Assessment Reports](https://docs.microsoft.com/sql/dma/dma-consolidatereports).

2. Set  PowerShell execution policy to bypass for current session, as follows.

   `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
1. Run the script in PowerShell.

<a name=sample-details></a>

## Sample details

PowerShell script for imports assessment results from JSON files into a SQL Server database. The results are imported into the table ReportData. Views, stored procedures, and table types are created in the SQL Server instance and database that you specified in the script. For more information, see [Consolidate Assessment Reports](https://docs.microsoft.com/sql/dma/dma-consolidatereports).

<a name=disclaimers></a>

## Disclaimers
This sample code is provided for the purpose of illustration only and is not intended to be used in a production environment. The sample code and any related information are provided "as is" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and/or fitness for a particular purpose.

<a name=related-links></a>

## Related Links

For more information, see these articles:

[Consolidate Assessment Reports](https://docs.microsoft.com/sql/dma/dma-consolidatereports)