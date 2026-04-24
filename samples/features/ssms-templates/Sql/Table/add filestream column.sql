--==========================================================================
-- Add filestream column template
--
-- This template creates a table, then it adds a new filestream column to the table.
--==========================================================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	column1 int      NOT NULL,
	column2 uniqueidentifier NOT NULL rowguidcol unique
)
GO

-- Add a new column to the table
ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
	ADD <new_column_name, sysname, column3> varbinary(max) filestream <new_column_nullability,, NULL>
GO
