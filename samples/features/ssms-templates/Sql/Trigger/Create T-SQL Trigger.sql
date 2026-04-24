--======================================
--  Create T-SQL Trigger Template
--======================================
USE <database_name, sysname, AdventureWorks>
GO

IF OBJECT_ID ('<schema_name, sysname, Sales>.<trigger_name, sysname, uStore>','TR') IS NOT NULL
   DROP TRIGGER <schema_name, sysname, Sales>.<trigger_name, sysname, uStore>
GO

CREATE TRIGGER <schema_name, sysname, Sales>.<trigger_name, sysname, uStore>
   ON  <schema_name, sysname, Sales>.<table_name, sysname, Store>
   AFTER <data_modification_statements, , UPDATE>
AS <T-SQL_statement, , UPDATE Sales.Store SET ModifiedDate = GETDATE() FROM inserted WHERE inserted.CustomerID = Sales.Store.CustomerID>
GO

