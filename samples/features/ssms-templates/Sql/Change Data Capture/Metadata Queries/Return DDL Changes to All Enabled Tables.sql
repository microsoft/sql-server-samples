-- =====================================================
-- Return the DDL Changes to All Enabled Tables Template
-- =====================================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @capture_instance sysname

DECLARE @capture_instances table (
		source_schema           sysname,
		source_table            sysname,
		capture_instance		sysname,	
		object_id				int,		
		source_object_id		int,		
		start_lsn				binary(10),	
		end_lsn					binary(10)	NULL,	
		supports_net_changes	bit,		
		has_drop_pending		bit		NULL,		
		role_name				sysname	NULL,	
		index_name				sysname	NULL,	
		filegroup_name			sysname	NULL,				
		create_date				datetime,	
		index_column_list		nvarchar(max) NULL,
		captured_column_list	nvarchar(max))
		
DECLARE @ddl_history table (
        source_schema		sysname,
		source_table		sysname,
		capture_instance	sysname,
		required_column_update	bit,		
		ddl_command			nvarchar(max),
		ddl_lsn				binary(10),
		ddl_time			datetime)

INSERT INTO @capture_instances
EXEC [sys].[sp_cdc_help_change_data_capture]

DECLARE #hinstance CURSOR LOCAL fast_forward
FOR
	SELECT capture_instance
	FROM @capture_instances

OPEN #hinstance
FETCH #hinstance INTO @capture_instance
	
WHILE (@@fetch_status <> -1)
BEGIN
	INSERT INTO @ddl_history
	EXEC [sys].[sp_cdc_get_ddl_history] @capture_instance
			
	FETCH #hinstance INTO @capture_instance
END
	
CLOSE #hinstance
DEALLOCATE #hinstance

SELECT source_schema, source_table, capture_instance, ddl_time, ddl_command
FROM @ddl_history
ORDER BY ddl_time
GO
