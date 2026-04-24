-- ==============================================================
-- Create User-defined Table Type template for Azure SQL Database
-- ==============================================================

CREATE TYPE <schema_name,sysname,dbo>.<type_name,sysname,TVP> AS TABLE
(
	<columns_in_primary_key, , c1> <column1_datatype, , int> <column1_nullability,, NOT NULL>,
	<column2_name, sysname, c2> <column2_datatype, , char(10)> <column2_nullability,, NULL>,
	<column3_name, sysname, c3> <column3_datatype, , datetime> <column3_nullability,, NULL>,
    PRIMARY KEY (<columns_in_primary_key, , c1>)
)
GO
