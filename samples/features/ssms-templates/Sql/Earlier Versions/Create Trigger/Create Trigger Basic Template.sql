-- =============================================
-- Create trigger basic template(After trigger)
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'<trigger_name, sysname, trig_test>'
	   AND 	  type = 'TR')
    DROP TRIGGER <trigger_name, sysname, trig_test>
GO

CREATE TRIGGER <trigger_name, sysname, trig_test>
ON <table_name, sysname, pubs.dbo.sales>
FOR DELETE, INSERT, UPDATE
AS
BEGIN
	RAISERROR (50009, 16, 10)
END
GO

