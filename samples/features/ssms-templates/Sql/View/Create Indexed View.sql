-- =============================================
-- Create Indexed View template
-- =============================================
USE <database_name, sysname, AdventureWorks>
GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF

IF object_id(N'<schema_name, sysname, dbo>.<view_name, sysname, SalesByOrderDate>', 'V') IS NOT NULL
	DROP VIEW <schema_name, sysname, dbo>.<view_name, sysname, SalesByOrderDate>
GO

CREATE VIEW <schema_name, sysname, dbo>.<view_name, sysname, SalesByOrderDate>
WITH SCHEMABINDING AS
<select_statement, , SELECT OrderDate, count_big(*) C, SUM(TotalDue) DateTotal FROM Sales.SalesOrderHeader GROUP BY OrderDate>

GO
CREATE UNIQUE CLUSTERED INDEX <view_name, sysname, SalesByOrderDate>_IndexedView
ON <schema_name, sysname, dbo>.<view_name, sysname, SalesByOrderDate>(<index_key_columns, , OrderDate>)

