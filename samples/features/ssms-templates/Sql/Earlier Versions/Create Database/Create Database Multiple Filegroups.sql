-- =============================================
-- Create database on mulitple file groups
-- =============================================
IF EXISTS (SELECT *
	   FROM   master..sysdatabases
	   WHERE  name = N'<database_name, sysname, test_db>')
	DROP DATABASE <database_name, sysname, test_db>
GO

CREATE DATABASE <database_name, sysname, test_db>
ON PRIMARY
	( NAME = <logical_file_name_1, , test_db_file_1>,
	  FILENAME = N'<os_file_name_1, , c:\program files\microsoft sql server\mssql\data\test_db_1.mdf>',
          SIZE = 1MB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%),
	
	( NAME = <logical_file_name_2, , test_db_file_2>,
	  FILENAME = N'<os_file_name_2, , c:\program files\microsoft sql server\mssql\data\test_db_2.ndf>',
          SIZE = 1MB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%),

FILEGROUP <file_group_name_1, , test_db_group_1>
	( NAME = <logical_file_name_3, , test_db_file_3>,
	  FILENAME = N'<os_file_name_3, , c:\program files\microsoft sql server\mssql\data\test_db_3.ndf>',
          SIZE = 1MB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%),
	
	( NAME = <logical_file_name_4, , test_db_file_4>,
	  FILENAME = N'<os_file_name_4, , c:\program files\microsoft sql server\mssql\data\test_db_4.ndf>',
          SIZE = 1MB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%),

FILEGROUP <file_group_name_2, , test_db_group_2>
	( NAME = <logical_file_name_5, , test_db_file_5>,
	  FILENAME = N'<os_file_name_5, , c:\program files\microsoft sql server\mssql\data\test_db_5.ndf>',
          SIZE = 1MB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%)

LOG ON
	( NAME = <logical_log_file_name_1, , test_db_log_file_1>,
	  FILENAME = N'<os_log_file_name_1, , c:\program files\microsoft sql server\mssql\data\test_db_log_1.ldf>',
          SIZE = 1MB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%)
GO

