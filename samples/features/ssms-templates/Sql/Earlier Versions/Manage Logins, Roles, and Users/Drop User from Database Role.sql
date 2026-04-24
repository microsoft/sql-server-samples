-- =============================================
-- Drop user from database role
-- =============================================
sp_droprolemember @rolename   = N'<db_role, sysname, db_owner>',
		  @membername = N'<db_user_name, sysname, johnny>'
GO

