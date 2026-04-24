-- ==================================================
-- Create Fullscan Norecompute Statistics Template
-- ==================================================
-- Note: Statistics created with NORECOMPUTE are not updated by SQL Server's
-- automatic statistics update feature (auto-stats). Therefore, they many cause
-- suboptimal plans.
CREATE STATISTICS <statistics_name, sysname, statistics_name>
ON <schema_name, sysname, schema_name>.<table_name, sysname, table_name>
(
   <column_name1, sysname, column1>,
   <column_name2, sysname, column2>
)
WITH FULLSCAN, NORECOMPUTE;
GO

