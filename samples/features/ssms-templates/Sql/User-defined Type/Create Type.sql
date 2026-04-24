-- =======================
-- Create Type template
-- =======================

USE <database_name, sysname, AdventureWorks>;
GO

-- Create the assembly reference that contains the type definition
CREATE ASSEMBLY <assembly_name, sysname, utf8string>
FROM '<assembly_path>, ,\\ComputerName\utf8string\utf8string.dll>' ;
GO

-- Create the new data type
CREATE TYPE <type_name, sysname, Utf8String>
EXTERNAL NAME <assembly_name, sysname, utf8string>.<class_name, ,[Microsoft.Samples.SqlServer.utf8string]>;
GO

-- Create a table that uses the data type
CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	<columns_in_primary_key, , c1> <column1_datatype, , int> <column1_nullability,, NOT NULL>,
	<column2_name, sysname, c2> <type_name, sysname, Utf8String>
)
GO
