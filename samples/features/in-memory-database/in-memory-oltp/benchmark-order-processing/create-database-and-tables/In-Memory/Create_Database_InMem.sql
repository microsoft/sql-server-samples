-- With Azure SQL Database, make sure to connect to a database with name InMemDB
-- With SQL Server, make sure SQL Server authentication is enabled, and the sa account is active

--  create main database files; for large-scale workloads, add additional containers in the InMem_fg filegroup
IF SERVERPROPERTY('EngineEdition') != 5
BEGIN
	DECLARE @sql nvarchar(max) = N'
	CREATE DATABASE InMemDB
	ON PRIMARY
	(   NAME        = InMemDB_root,
		FILENAME    = ''D:\Data\InMem_root.mdf'',
		SIZE        = 8MB,
		FILEGROWTH  = 10),
	FILEGROUP   InMem_fg   CONTAINS MEMORY_OPTIMIZED_DATA
	(   NAME        = InMemDB_1,
		FILENAME    = ''D:\Data\InMem_1'')
	LOG ON
	(   NAME        = InMemDB_log,
		FILENAME    = ''E:\Log\InMem_log.ldf'',
		SIZE        = 1000MB,
		FILEGROWTH  = 10)
	ALTER AUTHORIZATION ON DATABASE::InMemDB TO sa
	'
	EXEC sp_executesql @sql
END
GO

USE InMemDB
GO

ALTER DATABASE CURRENT COLLATE Latin1_General_BIN2
GO


/** For memory-optimized tables, automatically map all lower isolation levels (including READ COMMITTED) to SNAPSHOT **/
ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON
GO

