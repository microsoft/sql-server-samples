-- =================================================================================
-- Create index template for Azure SQL Database and Azure Synapse Analytics Database 
-- =================================================================================

CREATE INDEX <index_name, sysname, ind_test>
ON <schema_name, sysname, Person>.<table_name, sysname, Address> 
(
	<column_name1, sysname, PostalCode>
)
GO
