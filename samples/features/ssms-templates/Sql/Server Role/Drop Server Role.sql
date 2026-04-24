-- ============================
-- Drop Server Role template
-- ============================
USE [master]
GO

-- Drop the server role if it exists
IF  EXISTS (
	SELECT name
		FROM sys.server_principals
		WHERE name = N'<server_role_name, sysname, Server_Role_Name>'
)

-- Drop an existing server role
DROP SERVER ROLE [<server_role_name, sysname, Server_Role_Name>]
GO
