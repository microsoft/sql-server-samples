-- =============================================
-- Create database specifying collation
-- =============================================
IF EXISTS (SELECT *
	   FROM   master..sysdatabases
	   WHERE  name = N'<database_name, sysname, test_db>')
	DROP DATABASE <database_name, sysname, test_db>
GO

CREATE DATABASE <database_name, sysname, test_db>
COLLATE <collation_name, , Latin1_General_CI_AI>
GO

-- ==========================================================
-- sample query to retrieve all types of collations available
-- ==========================================================
-- SELECT *
-- FROM   ::fn_helpcollations()
-- GO




