-- ===================================================
-- Disable All Capture Instances for a Schema Template
-- ===================================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @capture_instances table (
		source_schema           sysname,
		source_table            sysname,
		capture_instance		sysname,	
		object_id			int,		
		source_object_id		int,		
		start_lsn			binary(10),	
		end_lsn			binary(10)	NULL,	
		supports_net_changes	bit,		
		has_drop_pending		bit		NULL,		
		role_name			sysname	NULL,	
		index_name			sysname	NULL,	
		filegroup_name		sysname	NULL,				
		create_date			datetime,	
		index_column_list		nvarchar(max) NULL,
		captured_column_list	nvarchar(max))

DECLARE @source_schema sysname,
	@source_name sysname,
	@capture_instance sysname

SET @source_schema = N'<source_schema,sysname,source_schema>'

INSERT INTO @capture_instances
EXEC [sys].[sp_cdc_help_change_data_capture]

DECLARE #hinstance CURSOR LOCAL fast_forward
FOR
	SELECT source_table, capture_instance
	FROM @capture_instances
	WHERE source_schema = @source_schema

OPEN #hinstance
FETCH #hinstance INTO @source_name, @capture_instance
	
WHILE (@@fetch_status <> -1)
BEGIN
	EXEC [sys].[sp_cdc_disable_table]
		@source_schema
		,@source_name
		,@capture_instance
			
	FETCH #hinstance INTO @source_name, @capture_instance
END
	
CLOSE #hinstance
DEALLOCATE #hinstance
GO
