-- =========================================
-- Add Extended Properties to Table template
-- =========================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	<columns_in_primary_key, , c1> <column1_datatype, , int> <column1_nullability,, NOT NULL>,
    CONSTRAINT <contraint_name, sysname, PK_sample_table> PRIMARY KEY (<columns_in_primary_key, , c1>)
)
-- Add description to table object
EXEC sys.sp_addextendedproperty
	@name=N'MS_Description',
	@value=N'<table_description_value,,Table description here>' ,
	@level0type=N'SCHEMA',
	@level0name=N'<schema_name, sysname, dbo>',
	@level1type=N'TABLE',
	@level1name=N'<table_name, sysname, sample_table>'
GO

-- Add description to a specific column
EXEC sys.sp_addextendedproperty
	@name=N'MS_Description',
	@value=N'<column_description,,Column description here>' ,
	@level0type=N'SCHEMA',
	@level0name=N'<schema_name, sysname, dbo>',
	@level1type=N'TABLE',
	@level1name=N'<table_name, sysname, sample_table>',
	@level2type=N'COLUMN',
	@level2name=N'<columns_in_primary_key, , c1>'
GO
