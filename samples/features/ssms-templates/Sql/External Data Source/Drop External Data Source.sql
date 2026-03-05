-- =========================================
-- Drop external data source template
-- =========================================
USE <database, sysname, AdventureWorks>
GO

IF EXISTS (
  SELECT *
    FROM sys.external_data_sources	
    WHERE name = N'<data_source_name, sysname, sample_data_source>'	 
)
DROP EXTERNAL DATA SOURCE <data_source_name, sysname, sample_data_source>
GO