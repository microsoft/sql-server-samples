-- ===============================================
-- Enable All Tables of a Database Schema Template
-- ===============================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @source_schema sysname, @source_name sysname
SET @source_schema = N'<source_schema,sysname,source_schema>'
DECLARE #hinstance CURSOR LOCAL fast_forward
FOR
	SELECT name
	FROM [sys].[tables]
	WHERE SCHEMA_NAME(schema_id) = @source_schema
	AND is_ms_shipped = 0

OPEN #hinstance
FETCH #hinstance INTO @source_name
	
WHILE (@@fetch_status <> -1)
BEGIN
	EXEC [sys].[sp_cdc_enable_table]
		@source_schema
		,@source_name
		,@role_name = NULL
		,@supports_net_changes = 1
			
	FETCH #hinstance INTO @source_name
END
	
CLOSE #hinstance
DEALLOCATE #hinstance
GO
