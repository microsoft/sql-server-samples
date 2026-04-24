-- =========================================================
-- Return All Accessible Database Capture Instances Template
-- =========================================================
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

INSERT INTO @capture_instances
EXEC [sys].[sp_cdc_help_change_data_capture]

SELECT source_schema, source_table, capture_instance
FROM @capture_instances
GO
