# T-SQL Procedures that generate T-SQL JSON CRUD procedures

This project contains a set of T-SQL scripts that generate:
- Stored procedures that INSERT, UPDATE, or MERGE input JSON text into table
- Stored procedures that generate SELECT statements that generate JSON from SQL tables.

### Contents

[About this sample](#about-this-sample)<br/>
[Setup](#setup)<br/>
[Generate](#generate)<br/>
[Modify generated source](#modify)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database
- **Programming Language:** Transact-SQL
- **Authors:** Jovan Popovic

<a name="setup"></a>

## Setup

To generate procedures, apply script in generate-json-crud.sql file.

<a name="generate"></a>
## Generate procedures


** GENERATE CRUD Functions for WWI tables. **

```sql
declare @SchemaName sysname = 'Application'		--> Name of the table where we want to insert JSON
declare @TableName sysname = 'People'			--> Name of the table schema where we want to insert JSON
declare @JsonColumns nvarchar(max) = '|CustomFields|'	--> List of pipe-separated NVARCHAR(MAX) column names that contain JSON text
declare @IgnoredColumns nvarchar(max) = N'LastEditedBy' --> List of comma-separated columns that should not be imported

print (codegen.GenerateJsonCreateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonRetrieveProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpdateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpsertProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))

GO

declare @SchemaName sysname = 'Sales'		--> Name of the table where we want to insert JSON
declare @TableName sysname = 'Orders'		--> Name of the table schema where we want to insert JSON
declare @JsonColumns nvarchar(max) = '||'	--> List of pipe-separated NVARCHAR(MAX) column names that contain JSON text
declare @IgnoredColumns nvarchar(max) = N'LastEditedBy,LastEditedWhen' --> List of comma-separated columns that should not be imported


print (codegen.GenerateJsonCreateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonRetrieveProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpdateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpsertProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))

GO

declare @SchemaName sysname = 'Application'		--> Name of the table where we want to insert JSON
declare @TableName sysname = 'Countries'		--> Name of the table schema where we want to insert JSON
declare @JsonColumns nvarchar(max) = '||'	--> List of pipe-separated NVARCHAR(MAX) column names that contain JSON text, e.g. '|AdditionalContactInfo|Demographics|'
declare @IgnoredColumns nvarchar(max) = N'LastEditedBy' --> List of comma-separated columns that should not be imported


print (codegen.GenerateJsonCreateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonRetrieveProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpdateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpsertProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))

GO

declare @SchemaName sysname = 'Application'		--> Name of the table where we want to insert JSON
declare @TableName sysname = 'Cities'		--> Name of the table schema where we want to insert JSON
declare @JsonColumns nvarchar(max) = '||'	--> List of pipe-separated NVARCHAR(MAX) column names that contain JSON text, e.g. '|AdditionalContactInfo|Demographics|'
declare @IgnoredColumns nvarchar(max) = N'Location,LastEditedBy' --> List of comma-separated columns that should not be imported


print (codegen.GenerateJsonCreateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonRetrieveProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpdateProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))
print (codegen.GenerateJsonUpsertProcedure('Website', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))


```


**GENERATE CRUD Functions for Custom table.**

```sql
DROP TABLE IF EXISTS dbo.Product
GO
CREATE TABLE dbo.Product(
	ProductID int IDENTITY PRIMARY KEY,
	Name nvarchar(50) NOT NULL,
	Color nvarchar(15) NULL,
	Size nvarchar(5) NULL,
	Price money NOT NULL,
	[Special JSON chars: " \ /
			] int NULL,
	[Special sql chars [[ " ]]
		] int NULL,
	Data nvarchar(4000) NULL,
	Tags nvarchar(4000) NULL,
	DateCreated datetime2 NOT NULL DEFAULT(GETDATE())
)
GO

declare @SchemaName sysname = 'dbo'		--> Name of the table where we want to insert JSON
declare @TableName sysname = 'Product'		--> Name of the table schema where we want to insert JSON
declare @JsonColumns nvarchar(max) = '|Data|Tags|'	--> List of pipe-separated NVARCHAR(MAX) column names that contain JSON text, e.g. '|AdditionalContactInfo|Demographics|'
declare @IgnoredColumns nvarchar(max) = N'DateCreated' --> List of comma-separated columns that should not be imported

print (codegen.GenerateJsonCreateProcedure('dbo', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))

print (codegen.GenerateJsonRetrieveProcedure('dbo', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))

print (codegen.GenerateJsonUpdateProcedure('dbo', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))

print (codegen.GenerateJsonUpsertProcedure('dbo', @SchemaName, @TableName, @JsonColumns, @IgnoredColumns))

```

## Modify generated code

You can create your own functions codegen.GenerateProcedureHead and codegen.GenerateProcedureTail to generate custom header and footer for every generated procedure, e.g.:

```sql

DROP FUNCTION IF EXISTS codegen.GenerateProcedureHead
GO
CREATE FUNCTION codegen.GenerateProcedureHead(@Table sysname, @JsonParam sysname)
RETURNS NVARCHAR(max)
AS BEGIN

	Declare @ret nvarchar(max) = '
    SET XACT_ABORT ON;

    DECLARE @HelpMessage nvarchar(max) = N''JSON '+ @Table +' data is invalid.
Execute SELECT TOP 1 * FROM ' + @Table + ' FOR JSON PATH to see an example of required JSON structure.'';

    IF ISJSON('+ @JsonParam + ') = 0
    BEGIN
        PRINT @HelpMessage;
        THROW 51000, N'''+ @JsonParam + ' must be valid JSON data'', 1;
        RETURN 1;
    END;

    BEGIN TRY

        BEGIN TRAN;
		
		';

	RETURN @ret

END
GO

GO
DROP FUNCTION IF EXISTS codegen.GenerateProcedureTail
GO
CREATE FUNCTION codegen.GenerateProcedureTail(@Table sysname)
RETURNS NVARCHAR(max)
AS BEGIN

	Declare @ret nvarchar(max) = '

        IF @@ROWCOUNT = 0
        BEGIN
            PRINT N''Warning: No valid '+@Table+' data found'';
            PRINT @HelpMessage;
        END;

        COMMIT;

    END TRY
    BEGIN CATCH
        PRINT @HelpMessage;
		PRINT ERROR_MESSAGE();

        THROW 51000, N''Valid JSON was supplied but does not match the '+@Table+' array structure'', 2;

        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        RETURN 1;
    END CATCH;
';

	RETURN @ret

END
GO
```
## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.

## Questions
Email questions to: [sqlserversamples@microsoft.com](mailto: sqlserversamples@microsoft.com).
