-- =============================================
-- Create Nonclustered Columnstore Index template
-- Use the Specify Values for Template Parameters command (Ctrl-Shift-M) to fill in the parameter values below.
-- This template creates a nonclustered columnstore index.
-- =============================================
USE <database_name, sysname, AdventureWorks>
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX <index_name, sysname, ind_test>
ON <schema_name, sysname, Person>.<table_name, sysname, Address>
(
	<column_name1, sysname, PostalCode>
)
WITH (DATA_COMPRESSION = <compression_type, , COLUMNSTORE>)
GO
