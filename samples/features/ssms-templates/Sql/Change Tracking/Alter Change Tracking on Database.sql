-- ===============================================================
-- Alter database with modifyingt change tracking options template
-- ===============================================================
USE master
GO

ALTER DATABASE <Database_Name,sysname,Database_Name> SET CHANGE_TRACKING
(
	CHANGE_RETENTION = <Retention_Period,int,Retention_Period> <Retention_Period_Units,int,Retention_Period_Units> ,
	AUTO_CLEANUP = <Auto_Cleanup,bit,Auto_Cleanup>
)
GO