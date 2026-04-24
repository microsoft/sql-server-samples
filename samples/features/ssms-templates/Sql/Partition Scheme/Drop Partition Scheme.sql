-- =================================
-- Drop Partition Scheme template
-- =================================
USE <database_name, sysname, AdventureWorks>;
GO

DROP PARTITION SCHEME <partition_scheme_name, sysname, schema_name>;

-- A partition scheme can be dropped only if there are no
-- tables or indexes currently using the partition scheme.
