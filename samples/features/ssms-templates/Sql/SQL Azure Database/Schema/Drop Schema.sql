--=========================================================================================================================
-- Drop Schema template for Azure SQL Database, Azure Synapse Analytics Database, and Azure Synapse SQL Analytics on-demand
--=========================================================================================================================
IF EXISTS(
  SELECT *
    FROM sys.schemas
   WHERE name = N'<sample_schema, sysname, sample_schema>'
)
DROP SCHEMA <sample_schema, sysname, sample_schema>
GO
