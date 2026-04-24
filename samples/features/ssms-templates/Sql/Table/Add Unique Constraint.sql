--======================
-- Add Unique Constraint template
--======================
ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
ADD CONSTRAINT <constraint_name, sysname, UNQ_sample_table> UNIQUE (<columns_in_unique_key, , column1>)
GO
