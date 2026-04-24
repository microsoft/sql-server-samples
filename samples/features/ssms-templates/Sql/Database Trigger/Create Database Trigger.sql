--====================================
--  Create database trigger template
--====================================
USE <database_name, sysname, AdventureWorks>
GO

IF EXISTS(
  SELECT *
    FROM sys.triggers
   WHERE name = N'<trigger_name, sysname, table_alter_drop_safety>'
     AND parent_class_desc = N'DATABASE'
)
	DROP TRIGGER <trigger_name, sysname, table_alter_drop_safety> ON DATABASE
GO

CREATE TRIGGER <trigger_name, sysname, table_alter_drop_safety> ON DATABASE
	FOR <data_definition_statements, , DROP_TABLE, ALTER_TABLE>
AS
IF IS_MEMBER ('db_owner') = 0
BEGIN
   PRINT 'You must ask your DBA to drop or alter tables!'
   ROLLBACK TRANSACTION
END
GO


