-- =========================================
-- Create external data source template
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

CREATE EXTERNAL DATA SOURCE <data_source_name, sysname, sample_data_source> WITH
(
    TYPE = <data_source_type, sysname, sample_type>,
    LOCATION = N'<location, nvarchar(3000), sample_location>',
    RESOURCE_MANAGER_LOCATION = N'<resource_manager_location, nvarchar(512), sample_resource_manager_location>',
    CREDENTIAL = <credential_name, sysname, sample_credential>
)
GO