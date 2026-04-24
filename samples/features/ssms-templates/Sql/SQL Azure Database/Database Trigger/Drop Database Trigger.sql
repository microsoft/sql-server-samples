-- =========================================================
-- Drop database ddl trigger template for Azure SQL Database
-- =========================================================
IF EXISTS(
  SELECT *
    FROM sys.triggers
   WHERE name = N'<trigger_name, sysname, your_trigger_name>'
     AND parent_class_desc = N'DATABASE'
)
	DROP TRIGGER <trigger_name, sysname, your_trigger_name> ON DATABASE
GO
