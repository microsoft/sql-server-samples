-- ==============================
-- Create User as DBO template
-- ==============================

USE [<database_name, sysname, AdventureWorks>]
GO

-- For login <login_name, sysname, login_name>, create a user in the database
CREATE USER [<user_name, sysname, user_name>]
	FOR LOGIN [<login_name, sysname, login_name>]
	WITH DEFAULT_SCHEMA = <default_schema, sysname, dbo>
GO

-- Add user to the database owner role
ALTER ROLE [db_owner]
ADD MEMBER [<user_name, sysname, user_name>]
GO
