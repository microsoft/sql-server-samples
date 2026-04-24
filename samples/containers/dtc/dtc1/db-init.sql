USE master
GO
EXEC master.dbo.sp_addlinkedserver
    @server = N'dtc2', @srvproduct=N'SQL Server'
GO
CREATE DATABASE dtclinux1
GO
USE [dtclinux1]
GO
CREATE TABLE dtctable (col1 int)
GO
