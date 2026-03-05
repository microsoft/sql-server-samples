-- ========================================================
-- Drop constraint template
--
-- This template creates a table with a CHECK CONSTRAINT,  
-- then it removes the CHECK CONSTRAINT from the table

-- Note: The DROP syntax can also be used to drop
-- Edge Constraint object types. To achieve this replace
-- the constraint_name attribute with the name of the
-- respective Edge Constraint object
-- ========================================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	column1      int      NOT NULL, 
	salary       money    NOT NULL CONSTRAINT <constraint_name, sysname, salary_cap> CHECK (salary < 500000)
)
GO

-- Drop CHECK CONSTRAINT from the table
ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
	DROP CONSTRAINT <constraint_name, sysname, salary_cap>
GO

