 --==================================================================================
-- Drop function template for Azure SQL Database and Azure Synapse Analytics Database
--===================================================================================
IF OBJECT_ID (N'<schema_name, sysname, dbo>.<function_name, sysname, EmployeeByID>') IS NOT NULL
   DROP FUNCTION <schema_name, sysname, dbo>.<function_name, sysname, EmployeeByID>
GO
