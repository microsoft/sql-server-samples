--==========================================================================
-- Add column template
--
-- This template creates a table, then it adds a new column to the table.
--==========================================================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	column1 int      NOT NULL,
	column2 char(10) NULL
)
GO

-- Add a new column to the table
ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
	ADD <new_column_name, sysname, column3> <new_column_datatype,, datetime> <new_column_nullability,, NULL>
GO
