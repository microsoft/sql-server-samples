-- =============================================
-- Create index basic template
-- =============================================
USE <database_name, sysname, AdventureWorks>
GO

CREATE INDEX <index_name, sysname, ind_test>
ON <schema_name, sysname, Person>.<table_name, sysname, Address>
(
	<column_name1, sysname, PostalCode>
)
GO
