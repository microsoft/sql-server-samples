-- ==========================================
-- Alter Partition Function Split template
-- ==========================================
USE <database_name, sysname, AdventureWorks>
GO

-- Create the partition function with an original defined range
CREATE PARTITION FUNCTION <partition_function_name, sysname, myRangePF> ( <data_type_name, sysname, int> )
AS RANGE LEFT FOR VALUES (<data_value1,,1>, <data_value2,,100>, <data_value3,,1000>);
GO

--Split the partition between boundary_values <data_value2,,100> and <data_value3,,1000>
--to create two partitions between boundary_values <data_value2,,100> and <data_value4,,500>
--and between boundary_values <data_value4,,500> and <data_value3,,1000>.
ALTER PARTITION FUNCTION <partition_function_name, sysname, myRangePF> ()
SPLIT RANGE (<data_value4,,500>);
GO


