-- =========================
-- Drop Database Template
-- =========================
USE master
GO

IF  EXISTS (
	SELECT name
		FROM sys.databases
		WHERE name = N'<Database_Name, sysname, Database_Name>'
)
DROP DATABASE <Database_Name, sysname, Database_Name>
GO