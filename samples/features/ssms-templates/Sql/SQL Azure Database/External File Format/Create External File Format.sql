-- =========================================================================
-- Create external file format template for Azure Synapse Analytics Database 
-- =========================================================================

IF EXISTS (
  SELECT *
	FROM sys.external_file_formats	
   WHERE name = N'<file_format_name, sysname, your_file_format_name>'	 
)
DROP EXTERNAL FILE FORMAT <file_format_name, sysname, sample_file_format>
GO

CREATE EXTERNAL FILE FORMAT <file_format_name, sysname, sample_file_format> WITH
(
	FORMAT_TYPE = <format_type, nvarchar(100), sample_format_type>,
	SERDE_METHOD = N'<serde_method, nvarchar(255), sample_serde_method>',
	FORMAT_OPTIONS 
	(
		FIELD_TERMINATOR = N'<field_terminator, nvarchar(10), sample_field_terminator>',
		STRING_DELIMITER = N'<string_delimeter, nvarchar(10), sample_string_delimiter>',
		DATE_FORMAT = N'<date_format, nvarchar(50), sample_date_format>',
		USE_TYPE_DEFAULT = <default_value, bit, sample_default_value>,
		FIRST_ROW = <default_value, int, sample_default_value>  -- Optional property
	),
	DATA_COMPRESSION = N'<compression_method, nvarchar(255), sample_compression_method>'
)
GO