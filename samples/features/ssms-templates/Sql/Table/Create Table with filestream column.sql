-- =========================================
-- Create table with filestream column
-- =========================================
USE <database, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
	<columns_in_primary_key, , c1> <column1_datatype, , int> <column1_nullability,, NOT NULL>,
	<column2_name, sysname, c2> <column2_datatype, , char(10)> <column2_nullability,, NULL>,
	<column3_name, sysname, c3> <column3_datatype, , datetime> <column3_nullability,, NULL>,
	<column4_name, sysname, c4> varbinary(max) filestream <column4_nullability,, NULL>,
	<column5_name, sysname, c5> uniqueidentifier NOT NULL rowguidcol unique,
    CONSTRAINT <contraint_name, sysname, PK_sample_table> PRIMARY KEY (<columns_in_primary_key, , c1>)
)
GO