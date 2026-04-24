-- =================================================
-- Alter Partition Schema Mark Next Used template
-- =================================================
USE <database_name, sysname, AdventureWorks>;
GO

-- Adds a filegroup to a partition scheme or alters the designation of the
-- NEXT USED filegroup for the partition scheme
ALTER PARTITION SCHEME <partition_scheme_name, sysname, MyRangePS1>
NEXT USED <filegroup_name, sysname, test5fg>;

-- Filegroup filegroup_name, sysname, test5fg> will receive any additional partition of a
-- partitioned table or index as a result of
-- an ALTER PARTITION FUNCTION statement
