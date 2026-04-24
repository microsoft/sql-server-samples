--============================================
-- Drop column template
--
-- This template creates a table, then it
-- drops one of the columns of the table.
--============================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	column1 int      NOT NULL,
	column2 char(10) NULL,
	<new_column_name, sysname, column3> datetime NULL
)
GO

-- Drop a column from the table
ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
	DROP COLUMN <new_column_name, sysname, column3>
GO
