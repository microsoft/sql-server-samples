-- =============================================
-- Create database on multiple data and transaction log files
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

	( NAME = <logical_file_name_2, ,test_db_file_2>,
	  FILENAME = N'<os_file_name_2, , c:\program files\microsoft sql server\mssql\data\test_db_2.ndf>',
          SIZE = 1MB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%)

LOG ON
	( NAME = <logical_log_file_name_1, ,test_db_log_file_1>,
	  FILENAME = N'<os_log_file_name_1, , c:\program files\microsoft sql server\mssql\data\test_db_log_1.ldf>',
          SIZE = 512KB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%),
	
	( NAME = <logical_log_file_name_2, ,test_db_log_file_2>,
	  FILENAME = N'<os_log_file_name_2, , c:\program files\microsoft sql server\mssql\data\test_db_log_2.ldf>',
          SIZE = 512KB,
          MAXSIZE = 200MB,
          FILEGROWTH = 10%)
GO

