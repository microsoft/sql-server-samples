-- =========================================
-- Create system-versioned temporal table template
-- Use the Specify Values for Template Parameters command (Ctrl-Shift-M) to fill in the parameter values below.
-- 
-- This template creates a system-versioned temporal table.
-- 
-- For more details on system-versioned temporal tables please refer to MSDN documentation:
-- https://msdn.microsoft.com/en-IN/library/dn935015.aspx#Anchor_0
-- 
-- To learn more how to use system-versioned tables in your applications, take a look at "Getting Started with System-Versioned Temporal Tables":
-- https://msdn.microsoft.com/en-US/library/mt604462.aspx
-- =========================================

BEGIN
    --If table is system-versioned, SYSTEM_VERSIONING must be set to OFF first 
    IF ((SELECT temporal_type FROM sys.tables WHERE object_id = OBJECT_ID('<schema_name, sysname, dbo>.<temporal_table_name, sysname, sample_table>', 'U')) = 2)
    BEGIN
        ALTER TABLE [<schema_name, sysname, dbo>].[<temporal_table_name, sysname, sample_table>] SET (SYSTEM_VERSIONING = OFF)
    END
    DROP TABLE IF EXISTS [<schema_name, sysname, dbo>].[<temporal_table_name, sysname, sample_table>]
END
GO

--Create system-versioned temporal table. It must have primary key and two datetime2 columns that are part of SYSTEM_TIME period definition
CREATE TABLE [<schema_name, sysname, dbo>].[<temporal_table_name, sysname, sample_table>]
(
    <columns_in_primary_key, , c1> <column1_datatype, , int> <column1_nullability,, NOT NULL>,
    <column2_name, sysname, c2> <column2_datatype, , char(10)> <column2_nullability,, NULL>,
    <column3_name, sysname, c3> <column3_datatype, , datetime> <column3_nullability,, NULL>,

    --Period columns and PERIOD FOR SYSTEM_TIME definition
    <period_start_column_name, sysname, SysStartTime> datetime2(7) GENERATED ALWAYS AS ROW START <period_start_column_hidden,,> NOT NULL ,
    <period_end_column_name, sysname, SysEndTime> datetime2(7) GENERATED ALWAYS AS ROW END <period_end_column_hidden,,> NOT NULL ,
    PERIOD FOR SYSTEM_TIME(<period_start_column_name, sysname, SysStartTime>,<period_end_column_name, sysname, SysEndTime>),

    --Primary key definition
    CONSTRAINT <constraint_name, sysname, PK_sampletable> PRIMARY KEY (<columns_in_primary_key, , c1>)
)
WITH
(
    --Set SYSTEM_VERSIONING to ON and provide reference to HISTORY_TABLE. 
    SYSTEM_VERSIONING = ON 
    (
        --If HISTORY_TABLE does not exists, default table will be created.
        HISTORY_TABLE = [<history_table_schema_name, sysname, dbo>].[<history_table_name, sysname, sample_table_history>],
        --Specifies whether data consistency check will be performed across current and history tables (default is ON)
        DATA_CONSISTENCY_CHECK = <data_consistency_check,, ON>
    )
)
GO
