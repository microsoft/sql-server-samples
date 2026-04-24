-- ======================================
-- Return Cleanup Job Parameters Template
-- ======================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @cdc_jobs table(
		job_id uniqueidentifier,
		job_type nvarchar(20) not null,
		job_name sysname,
		maxtrans int NULL,
		maxscans int NULL,
		continuous bit NULL,
		pollinginterval  bigint NULL,
		retention bigint NULL,
		threshold bigint NULL)

INSERT INTO @cdc_jobs
EXEC [sys].[sp_cdc_help_jobs]

SELECT retention, threshold
FROM @cdc_jobs
WHERE job_type = N'cleanup'
GO
