-- ======================================================
-- Create Memory Optimized System-Versioned Temporal Table Template
-- Use the Specify Values for Template Parameters command (Ctrl-Shift-M) to fill in the parameter values below.
-- 
-- This template creates a memory optimized system-versioned temporal table and indexes on the memory optimized table.
-- 
-- The database must have a MEMORY_OPTIMIZED_DATA filegroup before the memory optimized table can be created.
-- To learn about prerequistes for creating memory-optimized tables, take a look at "Creating a Memory-Optimized Table and a Natively Compiled Stored Procedure":
-- https://msdn.microsoft.com/en-us/library/dn133079.aspx
-- 
-- For more details on system-versioned temporal tables please refer to MSDN documentation:
-- https://msdn.microsoft.com/en-IN/library/dn935015.aspx#Anchor_0
-- 
-- To learn more how to use system-versioned tables in your applications, take a look at "Getting Started with System-Versioned Temporal Tables":
-- https://msdn.microsoft.com/en-US/library/mt604462.aspx
-- =========================================

USE <database, sysname, AdventureWorks>
GO

BEGIN
       IF ((SELECT temporal_type FROM sys.tables WHERE object_id = OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_memoryoptimizedtable>', 'U')) = 2)
       BEGIN
            ALTER TABLE [<schema_name, sysname, dbo>].[<table_name, sysname, sample_memoryoptimizedtable>] SET (SYSTEM_VERSIONING = OFF)
       END
       DROP TABLE IF EXISTS [<schema_name, sysname, dbo>].[<table_name, sysname, sample_memoryoptimizedtable>]
END
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name,sysname,sample_memoryoptimizedtable>
(
    <columns_in_primary_key, sysname, c1> <column1_datatype, , int> <column1_nullability, , NOT NULL>,
    <column2_name, sysname, c2> <column2_datatype, , float> <column2_nullability, , NOT NULL>,
    <column3_name, sysname, c3> <column3_datatype, , decimal(10,2)> <column3_nullability, , NOT NULL> INDEX <index3_name, sysname, index_sample_memoryoptimizedtable_c3> NONCLUSTERED (<column3_name, sysname, c3>),

     --Period columns and PERIOD FOR SYSTEM_TIME definition
    <column4_name, sysname, SysStartTime> datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    <column5_name, sysname, SysEndTime> datetime2(7) GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME(<column4_name, sysname, SysStartTime>,<column5_name, sysname, SysEndTime>),

    --Primary key definition
    CONSTRAINT <constraint_name, sysname, PK_sample_memoryoptimizedtable> PRIMARY KEY NONCLUSTERED (<columns_in_primary_key, sysname, c1>),

    -- See SQL Server Books Online for guidelines on determining appropriate bucket count for the index
    INDEX <index2_name, sysname, hash_index_sample_memoryoptimizedtable_c2> HASH (<column2_name, sysname, c2>) WITH (BUCKET_COUNT = <sample_bucket_count, int, 131072>)
)
WITH 
(
    MEMORY_OPTIMIZED = ON,
    DURABILITY = <durability_type, , SCHEMA_AND_DATA>,
    --Set SYSTEM_VERSIONING to ON and provide reference to HISTORY_TABLE. 
    SYSTEM_VERSIONING = ON
    (
        --If HISTORY_TABLE does not exists, default table will be created.
        HISTORY_TABLE = [<history_schema_name, sysname, dbo>].[<history_table_name, sysname, sample_memoryoptimizedtable_history>],
        --Specifies whether data consistency check will be performed across current and history tables (default is ON)
        DATA_CONSISTENCY_CHECK = <data_consistency_check,, ON>
    )
)
GO