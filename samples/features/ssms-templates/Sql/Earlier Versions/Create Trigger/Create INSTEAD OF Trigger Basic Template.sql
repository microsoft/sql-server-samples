-- =============================================
-- Create basic Instead Of Trigger
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'<trigger_name, sysname, trig_test>'
	   AND 	  type = 'TR')
    DROP TRIGGER <trigger_name, sysname, trig_test>
GO

CREATE TRIGGER <trigger_name, sysname, trig_test>
ON <table_or_view_name, sysname, pubs.dbo.sales>
INSTEAD OF INSERT
AS
BEGIN
	RAISERROR (50009, 16, 10)
	EXEC sp_who
END
GO

