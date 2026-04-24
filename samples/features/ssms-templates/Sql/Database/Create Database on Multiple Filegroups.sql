-- =============================================
-- Create database on multiple filegroups
-- =============================================
IF EXISTS (
  SELECT *
    FROM sys.databases
   WHERE name = N'<database_name, sysname, sample_database>'
)
  DROP DATABASE <database_name, sysname, sample_database>
GO

CREATE DATABASE <database_name, sysname, sample_database>
ON PRIMARY
	(NAME = <logical_filename1, , sample_database_file1>,
	  FILENAME = N'<data_filename1, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_1.mdf>',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%),
	
	( NAME = <logical_filename2, , sample_database_file2>,
	  FILENAME = N'<data_filename2, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_2.ndf>',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%),

FILEGROUP <filegroup_1, , sample_database_filegroup1>
	( NAME = <logical_filename3, , sample_database_file3>,
	  FILENAME = N'<data_filename3, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_3.ndf>',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%),
	
	( NAME = <logical_filename4, , sample_database_file4>,
	  FILENAME = N'<data_filename4, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_4.ndf>',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%),

FILEGROUP <filegroup2, , sample_database_group_2>
	( NAME = <logical_filename5, , sample_database_file5>,
	  FILENAME = N'<data_filename5, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_5.ndf>',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%)

LOG ON
	( NAME = <logical_log_filename1, , sample_database_log_file1>,
	  FILENAME = N'<log_filename1, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_1.ldf>',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%),

	( NAME = <logical_log_filename2, , sample_database_log_file2>,
	  FILENAME = N'<log_filename2, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_2.ldf>',
          SIZE = 5MB,
          MAXSIZE = 25MB,
          FILEGROWTH = 5MB)
GO

