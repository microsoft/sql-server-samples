-- =============================================
-- Add Key template
--
-- This template creates a table, then it
-- adds a PRIMARY KEY constraint to the table
-- =============================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	<columns_in_primary_key, , column1>      int      NOT NULL,
	column2      char(8)  NOT NULL
)
GO

-- Add a new PRIMARY KEY CONSTRAINT to the table
ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
  ADD CONSTRAINT <constraint_name, sysname, PK_sample_table> PRIMARY KEY (<columns_in_primary_key, , column1>)
GO
