-- =========================================
-- Change CDC Cleanup Job Retention Template
-- =========================================
USE <Database_Name,sysname,Database_Name>
GO

EXEC [sys].[sp_cdc_change_job]
	@job_type = N'cleanup',
	@retention = <retention,bigint,retention>
GO

