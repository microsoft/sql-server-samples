--=============================================================================================================================
-- Drop Statistics template for Azure SQL Database, Azure Synapse Analytics Database, and Azure Synapse SQL Analytics on-demand
--=============================================================================================================================
IF EXISTS (
  SELECT *
	FROM sys.stats as st
	JOIN sys.tables as tb
	  ON st.object_id = tb.object_id
	JOIN sys.schemas as sc
	  ON tb.schema_id = sc.schema_id
   WHERE sc.name = N'<schema_name, sysname, schema_name>'
	 AND tb.name = N'<table_name, sysname, table_name>'
	 AND st.name = N'<statistics_name, sysname, statistics_name>'
)

DROP STATISTICS <schema_name, sysname, schema_name>.<table_name, sysname, table_name>.<statistics_name, sysname, statistics_name>;
GO
