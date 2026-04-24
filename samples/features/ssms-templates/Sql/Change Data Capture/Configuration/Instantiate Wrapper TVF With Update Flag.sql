-- ======================================================
-- Instantiate a Wrapper TVF With an Update Flag Template
-- ======================================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @wrapper_functions table (
		function_name			sysname,
		create_script			nvarchar(max))		

DECLARE @create_script nvarchar(max),
	@capture_instance sysname,
	@update_flag_list nvarchar(max)
	
SET @capture_instance = N'<capture_instance,sysname,capture_instance>'
SET @update_flag_list = N'<column_needing_update_flag,sysname,column_needing_update_flag>'

INSERT INTO @wrapper_functions
EXEC [sys].[sp_cdc_generate_wrapper_function]
	@capture_instance = @capture_instance,
	@update_flag_list = @update_flag_list
			
SELECT @create_script = create_script
FROM @wrapper_functions
WHERE function_name like N'fn_net_changes%'
	
EXEC (@create_script)
GO