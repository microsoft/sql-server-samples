-- ==================================
-- Add Server Role Member template
-- ==================================
USE [master]
GO

-- Add an existing principal as a role member
ALTER SERVER ROLE [<server_role_name, sysname, Server_Role_Name>]
ADD MEMBER [<server_principal, sysname, Server_Principal_Name>]
GO
