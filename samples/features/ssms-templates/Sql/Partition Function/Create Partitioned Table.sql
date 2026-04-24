--====================================================
-- Create partitioned table template
--
-- This template assumes AdventureWorks database
-- has three filegroups named,
--		PRIMARY
--		TransactionHistoryGroup
--      WorkOrderGroup
--====================================================
USE AdventureWorks
GO

-- Drop existing objects in reverse order, if necessary
IF OBJECT_ID('<schema_name, sysname, dbo>.<partition_table_name, sysname, partition_table_name>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<partition_table_name, sysname, partition_table_name>
GO

IF EXISTS(
  SELECT *
    FROM sys.partition_schemes
   WHERE name = N'<partition_scheme_name, sysname, partition_scheme_name>'
)
	DROP PARTITION SCHEME <partition_scheme_name, sysname, partition_scheme_name>
GO

IF EXISTS(
  SELECT *
    FROM sys.partition_functions
   WHERE name = N'<partition_function_name, sysname, part_function_name>'
)
	DROP PARTITION FUNCTION <partition_function_name, sysname, part_function_name>
GO

-- Create partition function
CREATE PARTITION FUNCTION <partition_function_name, sysname, part_function_name>(<input_parameter_type,,int>)
AS
	RANGE LEFT FOR VALUES (1, 1000)
GO

-- Create partition scheme
CREATE PARTITION SCHEME <partition_scheme_name, sysname, partition_scheme_name>
AS
	PARTITION <partition_function_name, sysname, part_function_name> TO ([PRIMARY], TransactionHistoryGroup, WorkOrderGroup)
GO

-- Create table on partition scheme
CREATE TABLE <schema_name, sysname, dbo>.<partition_table_name, sysname, partition_table_name>
(
	col1 int,
    col2 char(10)
)
	ON <partition_scheme_name, sysname, partition_scheme_name> (col1)
GO
