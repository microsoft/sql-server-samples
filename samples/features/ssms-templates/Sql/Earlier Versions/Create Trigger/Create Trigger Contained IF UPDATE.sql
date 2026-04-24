-- =============================================
-- Create trigger contained If UPDATE(column)
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'<trigger_name, sysname, trig_test>'
	   AND 	  type = 'TR')
    DROP TRIGGER <trigger_name, sysname, trig_test>
GO

CREATE TRIGGER <trigger_name, sysname, trig_test>
ON <table_or_view_name, sysname, pubs.dbo.sales>
FOR INSERT, UPDATE
AS
If UPDATE(<column_1, sysname, stor_id>) OR UPDATE(<column_2, sysname, ord_num>)
BEGIN
	RAISERROR ('These columns should never be updated', 16, 1)
	ROLLBACK TRANSACTION
END
GO

