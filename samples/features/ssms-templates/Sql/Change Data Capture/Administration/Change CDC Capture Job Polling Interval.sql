-- ===============================================
-- Change CDC Capture Job Pollinginterval Template
-- ===============================================
USE <Database_Name,sysname,Database_Name>
GO

EXEC [sys].[sp_cdc_change_job]
	@job_type = N'capture',
	@pollinginterval = <pollinginterval,bigint,pollinginterval>
GO

