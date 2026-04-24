-- =============================================
-- Create schemabinding view
-- =============================================
IF EXISTS (SELECT TABLE_NAME
	   FROM   INFORMATION_SCHEMA.VIEWS
	   WHERE  TABLE_NAME = N'<view_name, sysname, view_test>')
    DROP VIEW <view_name, sysname, view_test>
GO

CREATE VIEW <view_name, sysname, view_test> WITH SCHEMABINDING
AS
<select_statement, , SELECT au_id FROM dbo.authors>
--note: need to specify specific column names and owner of the table
--eg. SELECT column_1, column_2 FROM owner.table_or_view_name WHERE search_condition
GO

