-- ======================================================================================================================================
-- Create Sampled Statistics Template for Azure SQL Database, Azure Synapse Analytics Database, and Azure Synapse SQL Analytics on-demand
-- ======================================================================================================================================
CREATE STATISTICS <statistics_name, sysname, statistics_name> 
ON <schema_name, sysname, schema_name>.<table_name, sysname, table_name>
( 
   <column_name1, sysname, column1>,
   <column_name2, sysname, column2>
) 
WITH SAMPLE <percent_value, int, 100> PERCENT;
GO
-- Instead of PERCENT, you can say ROWS to specify the number of rows to sample.

