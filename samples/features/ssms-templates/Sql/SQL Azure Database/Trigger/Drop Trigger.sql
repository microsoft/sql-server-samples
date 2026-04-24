-- ============================================
-- Drop dml trigger template Azure SQL Database
-- ============================================

IF EXISTS(
  SELECT *
    FROM sys.triggers
   WHERE name = N'<Trigger_Name, sysname, Trigger_Name>'
     AND parent_class_desc = N'OBJECT_OR_COLUMN'
)
	DROP TRIGGER <Schema_Name, sysname, Schema_Name>.<Trigger_Name, sysname, Trigger_Name>
GO
	
