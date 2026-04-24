-- =============================================
-- Create trigger contained If (COLUMNS_UPDATED())
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
--eg. check if all of column 2, 3, 4 are updated
IF (COLUMNS_UPDATED() & 14) = 14
BEGIN
	RAISERROR ('These columns can not be updated at the same time', 16, 1)
	ROLLBACK TRANSACTION
END
GO

