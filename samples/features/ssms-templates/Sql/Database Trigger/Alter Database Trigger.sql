--====================================
--  Alter database trigger template
--====================================
USE <database_name, sysname, AdventureWorks>
GO

ALTER TRIGGER <trigger_name, sysname, table_alter_drop_safety> ON DATABASE
	FOR <data_definition_statements, , DROP_TABLE, ALTER_TABLE>
AS
IF IS_MEMBER ('db_owner') = 0
BEGIN
   PRINT 'You must ask your DBA to drop or alter tables!'
   ROLLBACK TRANSACTION
END
GO


 