-- =============================================
-- Create Database Snapshot Template
-- =============================================
USE master
GO

-- Drop database snapshot if it already exists
IF  EXISTS (
	SELECT name
		FROM sys.databases
		WHERE name = N'<Database_Name, sysname, Database_Name>_<Snapshot_Id,,Snapshot_ID>'
)
DROP DATABASE <Database_Name, sysname, Database_Name>_<Snapshot_Id,,Snapshot_ID>
GO

-- Create the database snapshot
CREATE DATABASE <Database_Name, sysname, Database_Name>_<Snapshot_Id,,Snapshot_ID> ON
( NAME = <Database_Name, sysname, Database_Name>, FILENAME =
'C:\Program Files\Microsoft SQL Server\%INST_PRE%.MSSQLSERVER\MSSQL\Data\<Database_Name, sysname, Database_Name>_<Snapshot_Id,,Snapshot_ID>.ss' )
AS SNAPSHOT OF <Database_Name, sysname, Database_Name>;
GO
