-- ===========================================================
-- Create external data source template for Azure SQL Database
-- ===========================================================
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
    LOCATION = N'<location, nvarchar(3000), myserver.database.windows.net>',
    DATABASE_NAME = N'<database_name, sysname, sample_database_name>',
    SHARD_MAP_NAME = N'<shard_map_name, sysname, sample_shard_map_name>',
    CREDENTIAL = <credential_name, sysname, sample_credential>
)
GO