-- =======================================
-- Restore File and Filegroups template
-- =======================================

-- Create database using three file groups, including PRIMARY
CREATE DATABASE [<database_name, sysname, TestDB>] ON
	PRIMARY (
		Name= N'<database_name, sysname, TestDB>_data',
		FILENAME= N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>_data.mdf'),
	FILEGROUP [<filegroup_name1, sysname, FG_1>] (
		NAME=N' <database_name, sysname, TestDB>_<filegroup_name1, sysname, FG_1>',
		FILENAME =N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>_<filegroup_name1, sysname, FG_1>.ndf'),
	FILEGROUP [<filegroup_name2, sysname, FG_2>] (
		NAME=N' <database_name, sysname, TestDB>_<filegroup_name2, sysname, FG_2>',
		FILENAME =N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>_<filegroup_name2, sysname, FG_2>.ndf')
	LOG ON (
		NAME =N'<database_name, sysname, TestDB>_log',
		FILENAME =N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>_log.ldf');
GO

-- Backup database
BACKUP DATABASE [<database_name, sysname, TestDB>]
	FILEGROUP=N'PRIMARY',
	FILEGROUP=N'<filegroup_name1, sysname, FG_1>',
	FILEGROUP=N'<filegroup_name2, sysname, FG_2>'
	TO DISK = N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>.bak'

-- Backup log
BACKUP LOG [<database_name, sysname, TestDB>]
	TO DISK = '<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>.bak'
	WITH
		NO_TRUNCATE ,
		NORECOVERY,
		NOFORMAT,
		NOINIT,
		NAME = '<database_name, sysname, TestDB> backup',
		SKIP,
		NOREWIND,
		NOUNLOAD,
		STATS = 10

-- Restore filegroups - one at a time
RESTORE DATABASE [<database_name, sysname, TestDB>]
	FILE = N'<database_name, sysname, TestDB>_data'
	FROM DISK = N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>.bak'
	WITH
		FILE = 1,
		NORECOVERY,
		NOUNLOAD,
		STATS = 10
GO

RESTORE DATABASE [<database_name, sysname, TestDB>]
	FILE = N' <database_name, sysname, TestDB>_<filegroup_name1, sysname, FG_1>'
	FROM  DISK = N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>.bak'
	WITH
		FILE = 1,
		NORECOVERY,
		NOUNLOAD,
		STATS = 10
GO

RESTORE DATABASE [<database_name, sysname, TestDB>]
	FILE = N' <database_name, sysname, TestDB>_<filegroup_name2, sysname, FG_2>'
	FROM  DISK = N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>.bak'
	WITH
		FILE = 1,
		NORECOVERY,
		NOUNLOAD,
		STATS = 10

-- Restore log
RESTORE LOG [<database_name, sysname, TestDB>]
	FROM DISK = N'<file_location, sysname, D:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\DATA\><database_name, sysname, TestDB>.bak'
	WITH
		FILE = 2,
		NOUNLOAD,
		STATS = 10
GO
