-- =============================================
-- Detach database via sp_detach_db
-- =============================================
EXECUTE sp_detach_db @dbname     = N'<database_name, sysname, test_db>',
   		     @skipchecks = N'<skipchecks, nvarchar(10), TRUE>'
GO

