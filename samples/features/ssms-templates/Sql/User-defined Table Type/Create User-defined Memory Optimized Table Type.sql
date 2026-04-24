--======================================================
-- Create User-defined Memory Optimized Table Type Template
-- Use the Specify Values for Template Parameters command (Ctrl-Shift-M) to fill in the parameter values below.
-- This template creates a memory optimized table type and indexes on the memory optimized table type.
-- The database must have a MEMORY_OPTIMIZED_DATA filegroup before the memory optimized table type can be created.
--======================================================

USE <database, sysname, AdventureWorks>
GO

--Drop table if it already exists.
IF TYPE_ID('<schema_name, sysname, dbo>.<type_name,sysname,sample_memoryoptimizedtabletype>') IS NOT NULL
    DROP TYPE <schema_name, sysname, dbo>.<type_name,sysname,sample_memoryoptimizedtabletype>
GO

CREATE TYPE <schema_name, sysname, dbo>.<type_name,sysname,sample_memoryoptimizedtabletype> AS TABLE
(
	<column_in_primary_key, sysname, c1> <column1_datatype, , int> <column1_nullability, , NOT NULL>,
	<column2_name, sysname, c2> <column2_datatype, , float> <column2_nullability, , NOT NULL>,
	<column3_name, sysname, c3> <column3_datatype, , decimal(10,2)> <column3_nullability, , NOT NULL> INDEX <index3_name, sysname, index_sample_memoryoptimizedtabletype_c3> NONCLUSTERED (<column3_name, sysname, c3>),

   PRIMARY KEY NONCLUSTERED (<column1_name, sysname, c1>),
   -- See SQL Server Books Online for guidelines on determining appropriate bucket count for the index
   INDEX <index2_name, sysname, hash_index_sample_memoryoptimizedtabletype_c2> HASH (<column2_name, sysname, c2>) WITH (BUCKET_COUNT = <sample_bucket_count, int, 131072>)
) WITH (MEMORY_OPTIMIZED = ON)
GO

