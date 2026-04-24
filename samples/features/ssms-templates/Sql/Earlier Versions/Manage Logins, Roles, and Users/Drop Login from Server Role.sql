-- =============================================
-- Drop login from server role
-- =============================================
sp_dropsrvrolemember @loginame = N'<Windows_or_Sql_Server_login, sysname, REDMOND\john>',
		     @rolename = N'<server_role, sysname, sysadmin>'
GO

