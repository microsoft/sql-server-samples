-- =============================================
-- Drop linked server login
-- =============================================
sp_droplinkedsrvlogin @rmtsrvname = N'<server_name, sysname, server1>',
		      @locallogin = N'<locallogin, sysname, test_login>'
GO

