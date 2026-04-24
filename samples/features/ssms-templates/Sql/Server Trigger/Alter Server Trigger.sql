--====================================
--  Alter server trigger template
--====================================
ALTER TRIGGER <trigger_name, sysname, your_trigger_name> ON ALL SERVER
FOR <data_definition_statements, , DROP_DATABASE, ALTER_DATABASE>
AS
IF IS_MEMBER ('db_owner') = 0
BEGIN
   PRINT 'You must ask your DBA to drop or alter databases!'
   ROLLBACK TRANSACTION
END
GO
