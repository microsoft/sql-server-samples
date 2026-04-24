-- ==========================================
-- Create Login For SysAdmin User template
-- ==========================================

CREATE LOGIN [<domain_name,,domain>\<user_name,,windows_user>] FROM WINDOWS WITH DEFAULT_DATABASE= <default_database, sysname, master>
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [<domain_name,,domain>\<user_name,,windows_user>]
GO

 