-- ==========================
-- Create Default template
-- ==========================
-- This feature is marked for deprecation

USE <database_name, sysname, AdventureWorks>
GO

CREATE DEFAULT <schema_name, sysname, dbo>.<default_name, , today>
AS
   getdate()
GO

-- Bind the default to a column
EXEC sp_bindefault
   N'<schema_name, sysname, dbo>.<default_name, , today>',
   N'<table_schema,,HumanResources>.<table_name,,Employee>.<column_name,,HireDate>'
GO
