-- =============================================
-- Create database for attach
-- =============================================
IF EXISTS (SELECT *
	   FROM   master..sysdatabases
	   WHERE  name = N'<database_name, sysname, test_db>')
	DROP DATABASE <database_name, sysname, test_db>
GO

CREATE DATABASE <database_name, sysname, test_db>
ON PRIMARY
	(FILENAME = N'<os_file_name, , c:\program files\microsoft sql server\mssql\data\test_db.mdf>')
FOR ATTACH
GO


