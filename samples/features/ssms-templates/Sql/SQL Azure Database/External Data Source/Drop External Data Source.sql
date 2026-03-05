-- ======================================================================================================================================
-- Drop external data source template for Azure SQL Database, Azure Synapse Analytics Database, and Azure Synapse SQL Analytics on-demand
-- ======================================================================================================================================

IF EXISTS (
  SELECT *
    FROM sys.external_data_sources	
    WHERE name = N'<data_source_name, sysname, sample_data_source>'	 
)
DROP EXTERNAL DATA SOURCE <data_source_name, sysname, sample_data_source>
GO