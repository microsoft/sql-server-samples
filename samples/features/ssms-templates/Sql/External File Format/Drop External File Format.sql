-- =========================================
-- Drop external file format template
-- =========================================
USE <database, sysname, AdventureWorks>
GO

IF EXISTS (
  SELECT *
	FROM sys.external_file_formats	
   WHERE name = N'<file_format_name, sysname, your_file_format_name>'	
)
DROP EXTERNAL FILE FORMAT <file_format_name, sysname, sample_file_format>
GO