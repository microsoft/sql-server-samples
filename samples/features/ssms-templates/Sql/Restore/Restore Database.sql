-- ============================
-- Restore Database Template
-- ============================
USE master
GO

RESTORE DATABASE <Database_Name, sysname, Database_Name>
	FROM  DISK = N'<Backup_Path,,C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Backup\><Database_Name, sysname, Database_Name>.bak'
WITH
	FILE = 1,
	NOUNLOAD,
	REPLACE,
	STATS = 10
GO
