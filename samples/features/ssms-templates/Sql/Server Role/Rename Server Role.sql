-- =====================================
-- Rename Server Role Member template
-- =====================================
USE [master]
GO

-- Rename the server role
ALTER SERVER ROLE [<server_role_name, sysname, Server_Role_Name>]
WITH NAME = [<new_name, sysname, New_Name>]
GO
