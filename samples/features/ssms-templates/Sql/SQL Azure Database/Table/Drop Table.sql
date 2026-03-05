--================================================================================
-- Drop Table template for Azure SQL Database and Azure Synapse Analytics Database 
--================================================================================
IF EXISTS (
  SELECT *
	FROM sys.tables
	JOIN sys.schemas
	  ON tables.schema_id = schemas.schema_id
   WHERE schemas.name = N'<schema_name, sysname, your_schema_name>'
	 AND tables.name = N'<table_name, sysname, your_table_name>'
)
  DROP TABLE <schema_name, sysname, your_schema_name>.<table_name, sysname, your_table_name>
GO
