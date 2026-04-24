--======================================================
-- Add MEMORY_OPTIMIZED_DATA Filegroup and Create Memory Optimized Table Template
-- Use the Specify Values for Template Parameters command (Ctrl-Shift-M) to fill in the parameter values below.
-- This template adds a MEMORY_OPTIMIZED_DATA filegroup to the database, and creates a memory optimized table and indexes on the memory optimized table.
-- The database must have a MEMORY_OPTIMIZED_DATA filegroup before the memory optimized table can be created.
--======================================================

USE <database_name, sysname, AdventureWorks>
GO

--Add MEMORY_OPTIMIZED_DATA filegroup to the database.
ALTER DATABASE <database_name, sysname, Adventureworks>
ADD FILEGROUP <memory_optimized_data_filegroup, , sample_database_filegroup> CONTAINS MEMORY_OPTIMIZED_DATA

--Add file to the MEMORY_OPTIMIZED_DATA filegroup.
ALTER DATABASE <database_name, sysname, Adventureworks>
ADD FILE
  ( NAME = <logical_filegroup_filename1, , sample_database_filegroup_file1>,
    FILENAME = N'<filegroup_filename1, , C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\Datasample_database_1>')
TO FILEGROUP <memory_optimized_data_filegroup, , sample_database_filegroup>

--Drop table if it already exists.
IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name,sysname,sample_memoryoptimizedtable>','U') IS NOT NULL
    DROP TABLE <schema_name, sysname, dbo>.<table_name,sysname,sample_memoryoptimizedtable>
GO

--Create memory optimized table and indexes on the memory optimized table.
CREATE TABLE <schema_name, sysname, dbo>.<table_name,sysname,sample_memoryoptimizedtable>
(
	<column_in_primary_key, sysname, c1> <column1_datatype, , int> <column1_nullability, , NOT NULL>,
	<column2_name, sysname, c2> <column2_datatype, , float> <column2_nullability, , NOT NULL>,
	<column3_name, sysname, c3> <column3_datatype, , decimal(10,2)> <column3_nullability, , NOT NULL> INDEX <index3_name, sysname, index_sample_memoryoptimizedtable_c3> NONCLUSTERED (<column3_name, sysname, c3>),

   CONSTRAINT <constraint_name, sysname, PK_sample_memoryoptimizedtable> PRIMARY KEY NONCLUSTERED (<column1_name, sysname, c1>),
   -- See SQL Server Books Online for guidelines on determining appropriate bucket count for the index
   INDEX <index2_name, sysname, hash_index_sample_memoryoptimizedtable_c2> HASH (<column2_name, sysname, c2>) WITH (BUCKET_COUNT = <sample_bucket_count, int, 131072>)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = <durability_type, , SCHEMA_AND_DATA>)
GO