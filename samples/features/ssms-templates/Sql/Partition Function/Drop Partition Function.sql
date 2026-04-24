-- ==========================
-- Drop Partition Function
-- ==========================

-- A partition function can be dropped only if there are no partition
-- schemes currently using the partition function.
DROP PARTITION FUNCTION <partition_function_name, sysname, myRangePF>;
GO
