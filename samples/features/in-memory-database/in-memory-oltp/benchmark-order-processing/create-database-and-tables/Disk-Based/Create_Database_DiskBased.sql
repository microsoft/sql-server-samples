-- With Azure SQL Database, make sure to connect to a database with name InMemDB
-- With SQL Server, make sure SQL Server authentication is enabled, and the sa account is active

--  create main database files; for large-scale workloads, add additional containers to the DiskBased_fg filegroup
IF SERVERPROPERTY('EngineEdition') != 5
BEGIN
	DECLARE @sql nvarchar(max) = N'
	CREATE DATABASE DiskBasedDB
	ON PRIMARY
	(   NAME        = DiskBasedDB_root,
		FILENAME    = ''D:\Data\DiskBasedDB_root.mdf'',
		SIZE        = 8MB,
		FILEGROWTH  = 10),
	FILEGROUP   DiskBased_fg
	(   NAME        = DiskBasedDB_1,
		FILENAME    = ''D:\Data\DiskBasedDB_1''),
	(   NAME        = DiskBasedDB_2,
		FILENAME    = ''D:\Data\DiskBasedDB_2'')
	LOG ON
	(   NAME        = DiskBasedDB_log,
		FILENAME    = ''E:\Log\DiskBasedDB_LogDiskBasedDB_log.ldf'',
		SIZE        = 1000MB,
		FILEGROWTH  = 10)

	ALTER AUTHORIZATION ON DATABASE::DiskBasedDB TO sa
	'
	EXEC sp_executesql @sql
END
GO

USE DiskBasedDB
GO

ALTER DATABASE CURRENT COLLATE Latin1_General_BIN2
GO

