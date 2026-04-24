-- =======================================================
-- Enable a Table for All and Net Changes Queries Template
-- =======================================================
USE <Database_Name,sysname,Database_Name>
GO

EXEC sys.sp_cdc_enable_table
	@source_schema = N'<source_schema,sysname,source_schema>',
	@source_name   = N'<source_name,sysname,source_name>',
	@role_name     = N'<role_name,sysname,role_name>',
	@supports_net_changes = 1
GO
