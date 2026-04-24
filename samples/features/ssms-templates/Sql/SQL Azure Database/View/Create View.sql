-- ================================================================================
-- Create View template for Azure SQL Database and Azure Synapse Analytics Database
-- ================================================================================

IF object_id(N'<schema_name, sysname, dbo>.<view_name, sysname, Top10Sales>', 'V') IS NOT NULL
	DROP VIEW <schema_name, sysname, dbo>.<view_name, sysname, Top10Sales>
GO

CREATE VIEW <schema_name, sysname, dbo>.<view_name, sysname, Top10Sales> AS
<select_statement, , SELECT TOP 10 * FROM Sales.SalesOrderHeader ORDER BY TotalDue DESC>
