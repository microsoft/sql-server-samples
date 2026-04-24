-- ============================
-- Create default constraint
-- ============================

ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, table_name>
   ADD CONSTRAINT df_<column_name, sysname, column_name>
   DEFAULT <default_expression, sysname, 0>
   FOR <column_name, sysname, column_name>
GO

