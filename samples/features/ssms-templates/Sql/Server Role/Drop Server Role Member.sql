-- ====================================
-- Drop Server Role Member template
-- ====================================
USE [master]
GO

-- Revoke membership of an existing principal from a server role
ALTER SERVER ROLE [<server_role_name, sysname, Server_Role_Name>]
DROP MEMBER [<server_principal, sysname, Server_Principal_Name>]
GO
