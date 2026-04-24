-- =============================================
-- Create Clustered Columnstore Index template
-- Use the Specify Values for Template Parameters command (Ctrl-Shift-M) to fill in the parameter values below.
-- This template creates a clustered columnstore index.
-- =============================================
USE <database_name, sysname, AdventureWorks>
GO

CREATE CLUSTERED COLUMNSTORE INDEX <index_name, sysname, ind_test>
ON <schema_name, sysname, Person>.<table_name, sysname, Address>
WITH (DATA_COMPRESSION = <compression_type, , COLUMNSTORE>)
GO
