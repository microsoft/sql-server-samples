-- =============================================
-- Attach database via sp_attach_db
-- =============================================
EXECUTE sp_attach_db @dbname    = N'<database_name, sysname, test_db>',
   		     @filename1 = N'<filename1, nvarchar(260), c:\program files\microsoft sql server\mssql\data\test_db.mdf>',
   		     @filename2 = N'<filename2, nvarchar(260), c:\program files\microsoft sql server\mssql\data\test_db_log.ldf>'
GO

