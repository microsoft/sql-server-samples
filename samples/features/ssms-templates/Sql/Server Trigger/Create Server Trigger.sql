--====================================
--  Create server trigger template
--====================================
IF EXISTS(
  SELECT *
    FROM sys.server_triggers
   WHERE name = N'<trigger_name, sysname, your_trigger_name>'
     AND parent_class_desc = N'SERVER'
)
	DROP TRIGGER <trigger_name, sysname, your_trigger_name> ON ALL SERVER
GO


CREATE TRIGGER trigger_name ON ALL SERVER
FOR <data_definition_statements, , DROP_DATABASE, ALTER_DATABASE>
AS
IF IS_MEMBER ('db_owner') = 0
BEGIN
   PRINT 'You must ask your DBA to drop or alter databases!'
   ROLLBACK TRANSACTION
END
GO