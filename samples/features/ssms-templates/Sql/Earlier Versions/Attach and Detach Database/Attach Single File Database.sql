-- =============================================
-- Attach database via sp_attach_single_file_db
-- =============================================
-- note: it builds a new log file and performs additional cleanup work
-- 	 to remove replication from the newly attached database
EXECUTE sp_attach_single_file_db @dbname   = N'<database_name, sysname, test_db>',
   		     		 @physname = N'<physname, nvarchar(260), c:\program files\microsoft sql server\mssql\data\test_db.mdf>'
GO

