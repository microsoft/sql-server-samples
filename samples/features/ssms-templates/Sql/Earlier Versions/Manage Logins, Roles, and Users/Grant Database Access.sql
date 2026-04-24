-- =============================================
-- Grant dbaccess to login (Windows or Sql Server login)
-- =============================================
sp_grantdbaccess @loginame   = N'<Windows_or_Sql_Server_login, sysname, REDMOND\john>',
		 @name_in_db = N'<db_user_name, sysname, johnny>'
GO

