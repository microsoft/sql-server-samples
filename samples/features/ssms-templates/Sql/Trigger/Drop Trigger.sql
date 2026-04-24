--======================================
--  Drop Trigger Template
--======================================
USE <database_name, sysname, AdventureWorks>
GO

IF OBJECT_ID ('<schema_name, sysname, Sales>.<trigger_name, sysname, uStore>','TR') IS NOT NULL
	DROP TRIGGER <schema_name, sysname, Sales>.<trigger_name, sysname, uStore>
GO
