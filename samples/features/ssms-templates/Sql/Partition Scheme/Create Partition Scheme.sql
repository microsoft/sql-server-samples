-- ===================================
-- Create Partition Scheme template
-- ===================================
USE <database_name, sysname, AdventureWorks>
GO

-- Step 1. Create a partition function
CREATE PARTITION FUNCTION <partition_function_name, sysname, part_function_name>(<input_parameter_type,,int>)
AS
	RANGE LEFT FOR VALUES (<data_value1,,1>, <data_value2,,1000>)
GO

-- Step 2. Create a partition scheme that references the function
CREATE PARTITION SCHEME <partition_scheme_name, sysname, partition_scheme_name>
AS
	PARTITION <partition_function_name, sysname, part_function_name>
	TO (<file_group_1,,[PRIMARY]>, <file_group_2,,file_group_name>, <file_group_3,,file_group_name>)
GO
