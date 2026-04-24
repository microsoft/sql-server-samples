-- ===========================================
-- Add constraint template
--
-- This template creates a table, then it
-- adds a CHECK CONSTRAINT to the table
-- ===========================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	column1      int      NOT NULL,
	<constraint_column_name,sysname,phone>        char(8)  NOT NULL
)
GO

-- Add a new CHECK CONSTRAINT to the table
ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
	ADD CONSTRAINT <contraint_name, sysname, phone_chk> <constraint_type,,CHECK> (<constraint_column_name,sysname,phone> <logical_expression,,LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')>
GO

