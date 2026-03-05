-- ==================================================================================================================
-- Drop external file format template for Azure Synapse Analytics Database, and Azure Synapse SQL Analytics on-demand
-- ==================================================================================================================

IF EXISTS (
  SELECT *
	FROM sys.external_file_formats	
   WHERE name = N'<file_format_name, sysname, your_file_format_name>'	 
)
DROP EXTERNAL FILE FORMAT <file_format_name, sysname, sample_file_format>
GO