-- ================================
-- Create User-defined Data Type
-- ================================
USE <database_name,sysname,AdventureWorks>
GO

-- Create the data type
CREATE TYPE <schema_name,sysname,dbo>.<type_name,sysname,Phone>
	FROM <base_type,,nvarchar> (<precision,int,25>) <allow_null,,NULL>

-- Create table using the data type
CREATE TABLE <table_name,sysname,test_data_type>
(
	ID int NOT NULL,
	Phone <schema_name,sysname,dbo>.<type_name,sysname,Phone> NULL
)
GO
