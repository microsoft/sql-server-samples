-- ======================================
-- Backup a CDC Enabled Database Template
-- ======================================
USE master
GO

BACKUP DATABASE <Database_Name,sysname,Database_Name>
	TO  DISK = N'<Backup_Path,,C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Backup\><Database_Name,sysname,Database_Name>.bak'
WITH
	NOFORMAT,
	NOINIT,
	NAME = N'<Database_Name,sysname,Database_Name>-Full Database Backup',
	SKIP,
	STATS = 10;
GO

