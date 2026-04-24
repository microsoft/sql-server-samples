-- ==================================================
-- Create Filtered Statistics Template
-- ==================================================

CREATE STATISTICS <statistics_name, sysname, statistics_name>
ON <schema_name, sysname, schema_name>.<table_name, sysname, table_name>
(
   <column_name1, sysname, column1>,
   <column_name2, sysname, column2>
)
WHERE <column_name1, sysname, column1> <@comparison_operator,,@operator> <@value,sysname,@val>

GO
