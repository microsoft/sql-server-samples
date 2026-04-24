-- ===================================
-- Create Schema User template
-- ===================================
USE <database_name, sysname, AdventureWorks>;
GO

-- Create a login using a Windows user
CREATE LOGIN [<domain_name,,domain>\<user_name,,windows_user>] FROM WINDOWS WITH DEFAULT_DATABASE = <database_name, sysname, AdventureWorks>;

-- Add the user to the database using their login name and the user name
CREATE USER [<domain_name,,domain>\<user_name,,windows_user>]
	FOR LOGIN [<domain_name,,domain>\<user_name,,windows_user>]
	WITH DEFAULT_SCHEMA = <default_schema, sysname, Production>;
GO

-- Grant specific access rights to use based on Schema
GRANT
	DELETE,
	EXECUTE,
	INSERT,
	SELECT,
	UPDATE,
	VIEW DEFINITION
ON SCHEMA::[<default_schema, sysname, Production>]
	TO [<domain_name,,domain>\<user_name,,windows_user>];
