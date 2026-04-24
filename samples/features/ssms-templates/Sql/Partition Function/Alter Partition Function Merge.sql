-- ==========================================
-- Alter Partition Function Merge template
-- ==========================================
USE <database_name, sysname, AdventureWorks>
GO

-- Create the partition function with an original defined range
CREATE PARTITION FUNCTION <partition_function_name, sysname, myRangePF> ( <data_type_name, sysname, int> )
AS RANGE LEFT FOR VALUES (<data_value1,,1>, <data_value2,,100>, <data_value3,,1000>);
GO

-- Merge the partitions between boundary_values <data_value1,,1> and <data_value2,,100>
-- and between boundary_values <data_value2,,100> and <data_value3,,1000> to create one partition
-- between boundary_values <data_value1,,1> and <data_value3,,1000>.
ALTER PARTITION FUNCTION <partition_function_name, sysname, myRangePF> ()
MERGE RANGE (<data_value2,,100>);
GO


