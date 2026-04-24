-- =============================
-- Create Bound Rule template
-- =============================
-- This feature is marked for deprecation

USE <database_name, sysname, AdventureWorks>
GO

-- Define the rule for use in the database
CREATE RULE <schema_name,sysname,dbo>.<rule_name, sysname,positive_value>
AS
	@value >= 0
GO

-- Bind the rule to a specific column in a table
EXEC sp_bindrule
	'<schema_name,sysname,dbo>.<rule_name, sysname,positive_value>',
	'<table_schema_name,,Sales>.<table_name,,SalesOrderDetail>.<column_name,,OrderQty>'
GO
