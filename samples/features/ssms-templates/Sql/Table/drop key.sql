-- ===================================================
-- Drop Key template
--
-- This template creates a table with a primary key,
-- then it drops the primary key of the table.
-- ===================================================
USE <database_name, sysname, AdventureWorks>
GO

IF OBJECT_ID(N'<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	c1 int      NOT NULL,
	c2 char(10) NULL,
	c3 datetime NULL,
    CONSTRAINT <primary_key_name, sysname, primary_key_name> PRIMARY KEY(c1)
)
GO

ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
  DROP CONSTRAINT <primary_key_name, sysname, primary_key_name>
GO

