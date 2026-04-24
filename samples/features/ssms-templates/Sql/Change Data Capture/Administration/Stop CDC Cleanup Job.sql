-- =============================
-- Stop CDC Cleanup Job Template
-- =============================
USE <Database_Name,sysname,Database_Name>
GO

EXEC [sys].[sp_cdc_stop_job]
	@job_type = N'cleanup'
GO

