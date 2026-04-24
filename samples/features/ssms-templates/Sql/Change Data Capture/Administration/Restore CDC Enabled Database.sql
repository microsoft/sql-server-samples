-- =======================================
-- Restore a CDC Enabled Database Template
-- =======================================
USE master
GO

RESTORE DATABASE <Database_Name,sysname,Database_Name>
	FROM  DISK = N'<Backup_Path,,C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Backup\><Database_Name,sysname,Database_Name>.bak'
WITH
	FILE = 1,
	NOUNLOAD,
	REPLACE,
	STATS = 10,
	KEEP_CDC
GO

USE <Database_Name,sysname,Database_Name>
GO

EXEC sys.sp_cdc_add_job @job_type = N'cleanup'
GO

EXEC sys.sp_cdc_add_job @job_type = N'capture'
GO


