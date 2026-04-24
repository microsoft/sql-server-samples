-- =============================================
-- Add user to database role
-- =============================================
sp_addrolemember @rolename = N'<db_role, sysname, db_owner>',
		 @membername = N'<db_user_name, sysname, test_user>'
GO

