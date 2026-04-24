-- =============================================
-- Create view with CHECK OPTION
-- =============================================
IF EXISTS (SELECT TABLE_NAME
	   FROM   INFORMATION_SCHEMA.VIEWS
	   WHERE  TABLE_NAME = N'<view_name, sysname, view_test>')
    DROP VIEW <view_name, sysname, view_test>
GO

CREATE VIEW <view_name, sysname, view_test>
AS
	<select_statement, , SELECT * FROM authors>
WITH CHECK OPTION
GO

