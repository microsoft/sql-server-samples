-- =============================================
-- Create Database with MEMORY_OPTIMIZED_DATA Filegroup Template
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

FILEGROUP <memory_optimized_data_filegroup, , sample_database_filegroup> CONTAINS MEMORY_OPTIMIZED_DATA
  ( NAME = <logical_filegroup_filename1, , sample_database_filegroup_file1>,
    FILENAME = N'<filegroup_filename1, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_1>')

LOG ON
  ( NAME = <logical_log_filename1, , sample_database_log_file1>,
    FILENAME = N'<log_filename1, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_1.ldf>',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%)
GO
