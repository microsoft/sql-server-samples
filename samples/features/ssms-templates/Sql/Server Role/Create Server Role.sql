-- ==============================
-- Create Server Role template
-- ==============================
USE [master]
GO

-- Drop the server role if it already exists
IF  EXISTS (
	SELECT name
		FROM sys.server_principals
		WHERE name = N'<server_role_name, sysname, New_Server_Role>'
)
DROP SERVER ROLE [<server_role_name, sysname, New_Server_Role>]


-- Create the server role
CREATE SERVER ROLE [<server_role_name, sysname, New_Server_Role>]
AUTHORIZATION [<server_principal, sysname, sa>]
GO
