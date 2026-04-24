-- =============================================
-- Basic Create Database Template
-- =============================================
IF EXISTS (SELECT *
	   FROM   master..sysdatabases
	   WHERE  name = N'<database_name, sysname, test_db>')
	DROP DATABASE <database_name, sysname, test_db>
GO

CREATE DATABASE <database_name, sysname, test_db>
GO

