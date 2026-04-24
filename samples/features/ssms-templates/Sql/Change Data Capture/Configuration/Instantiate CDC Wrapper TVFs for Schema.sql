-- ==================================================
-- Instantiate CDC Wrapper TVFs for a Schema Template
-- ==================================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @capture_instances table (
		source_schema           sysname,
		source_table            sysname,
		capture_instance		sysname,	
		object_id				int,		
		source_object_id		int,		
		start_lsn				binary(10),	
		end_lsn					binary(10)	NULL,	
		supports_net_changes	bit,		
		has_drop_pending		bit			NULL,		
		role_name				sysname		NULL,	
		index_name				sysname		NULL,	
		filegroup_name			sysname		NULL,				
		create_date				datetime,	
		index_column_list		nvarchar(max) NULL,
		captured_column_list	nvarchar(max))
		
DECLARE @wrapper_functions table (
		function_name			sysname,
		create_script			nvarchar(max))		

DECLARE @source_schema sysname,
	@source_name sysname,
	@capture_instance sysname,
	@create_script nvarchar(max)
	
SET @source_schema = N'<source_schema,sysname,source_schema>'

INSERT INTO @capture_instances
EXEC [sys].[sp_cdc_help_change_data_capture]

DECLARE #hinstance CURSOR LOCAL fast_forward
FOR
	SELECT capture_instance
	FROM @capture_instances
	WHERE source_schema = @source_schema

OPEN #hinstance
FETCH #hinstance INTO @capture_instance
	
WHILE (@@fetch_status <> -1)
BEGIN
	INSERT INTO @wrapper_functions
	EXEC [sys].[sp_cdc_generate_wrapper_function] @capture_instance
			
	FETCH #hinstance INTO @capture_instance
END
	
CLOSE #hinstance
DEALLOCATE #hinstance

DECLARE #hscript CURSOR LOCAL fast_forward
FOR
	SELECT create_script
	FROM @wrapper_functions
	
OPEN #hscript
FETCH #hscript INTO @create_script
	
WHILE (@@fetch_status <> -1)
BEGIN
	EXEC (@create_script)
	FETCH #hscript INTO @create_script
END
	
CLOSE #hscript
DEALLOCATE #hscript
GO
