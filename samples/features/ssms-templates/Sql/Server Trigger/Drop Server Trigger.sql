--====================================
--  Drop server trigger template
--====================================
IF EXISTS(
  SELECT *
    FROM sys.server_triggers
   WHERE name = N'<trigger_name, sysname, your_trigger_name>'
     AND parent_class_desc = N'SERVER'
)
	DROP TRIGGER <trigger_name, sysname, your_trigger_name> ON ALL SERVER
GO 