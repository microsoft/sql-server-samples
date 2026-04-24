-- ==============================
-- Start CDC Capture Job Template
-- ==============================
USE <Database_Name,sysname,Database_Name>
GO

EXEC [sys].[sp_cdc_start_job]
	@job_type = N'capture'
GO

