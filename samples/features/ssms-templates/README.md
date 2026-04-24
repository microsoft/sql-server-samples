# SSMS Query Templates

SQL Server Management Studio supports templatized queries for multiple languages, including T-SQL, DAX, and MDX. The templates contain variables of the form "<variable_name, [data type], [default value]>". SSMS users typically open the templates in one of the following ways:

1. The Template Explorer, which presents the hierarchy as a tree control. Users can drag the query templates to the current editor window or double click to open them in a new window.
2. A "New <object>" menu item in Object Explorer.
3. The File/Open menu to open their own templates.

The SSMS query editor detects the presence of these variables and offers a menu item to open the dialog to specify values for the template parameters.

These templates are offered for anyone to download and customize for their own use. Community contributions back to the master branch are welcomed. Approved contributions may be picked up for installation with future versions of SSMS.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2008 (or higher), Azure SQL Database, Azure SQL Data Warehouse, Parallel Data Warehouse

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2008 (or higher) or an Azure SQL Database or SQL Analysis Services
2. SSMS 2008 or higher

<a name=run-this-sample></a>

## Run this sample

Download the templates to a folder of your choice and open them from the File/Open menu in SSMS.

<a name=related-links></a>

## Related Links

For more information, see these articles:
https://docs.microsoft.com/sql/ssms/tutorials/templates-ssms
