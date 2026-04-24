--=======================================================================
-- Drop index template for Azure SQL Database and Azure Synapse Analytics
--=======================================================================
IF EXISTS (
  SELECT *
	FROM sys.indexes
	WHERE indexes.name = N'<index_name,sysname, your_index_name>'
)
  DROP Index <index_name,sysname, your_index_name> on <schema_name, sysname, your_schema_name>.<table_name, sysname, your_table_name>
GO
