--------------------------------------------------
-- Perf Improvements - Cyrillic - 2 Bytes per char
--------------------------------------------------

USE master;
DROP DATABASE IF EXISTS UnicodeDatabase_Cyrillic;
CREATE DATABASE UnicodeDatabase_Cyrillic COLLATE LATIN1_GENERAL_100_CI_AS_SC_UTF8
GO

USE UnicodeDatabase_Cyrillic
GO

--------------------------------------
-- INSERTs
--------------------------------------

DROP TABLE IF EXISTS dbo.Inserts_UTF16
CREATE TABLE dbo.Inserts_UTF16(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 NVARCHAR(50) NOT NULL)
GO
DROP TABLE IF EXISTS dbo.Inserts_UTF8
CREATE TABLE dbo.Inserts_UTF8(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 VARCHAR(50) NOT NULL)
GO
DROP TABLE IF EXISTS dbo.Inserts_UTF16_Compressed
CREATE TABLE dbo.Inserts_UTF16_Compressed(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 NVARCHAR(50) NOT NULL)
WITH (DATA_COMPRESSION = PAGE)
GO
DROP TABLE IF EXISTS dbo.Inserts_UTF8_Compressed
CREATE TABLE dbo.Inserts_UTF8_Compressed(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 VARCHAR(50) NOT NULL)
WITH (DATA_COMPRESSION = PAGE)
GO

-- INSERT perf UTF16:
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF16 (col1)
	SELECT REPLICATE(CONCAT(
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45)))
	  ), 2);
    SET @i += 1
END;
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF16'
COMMIT
GO

-- INSERT perf UTF8:
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF8 (col1)
	SELECT REPLICATE(CONCAT(
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45)))
	  ), 2);
    SET @i += 1
END;

SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF8'
COMMIT
GO
-- INSERT perf UTF16 Compressed:
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF16_Compressed (col1)
	SELECT REPLICATE(CONCAT(
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45)))
	  ), 2);
    SET @i += 1
END;
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF16_Compressed'
COMMIT
GO
-- INSERT perf UTF8 Compressed:
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF8_Compressed (col1)
	SELECT REPLICATE(CONCAT(
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45)))
	  ), 2);
    SET @i += 1
END;
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF8_Compressed' -- 34s
COMMIT
GO

------------------------------------
-- SELECTs
------------------------------------

USE [UnicodeDatabase_Cyrillic];
GO

-- Recreate tables
DROP TABLE IF EXISTS dbo.Inserts_UTF16
CREATE TABLE dbo.Inserts_UTF16(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 NVARCHAR(50) NOT NULL)
GO
DROP TABLE IF EXISTS dbo.Inserts_UTF8
CREATE TABLE dbo.Inserts_UTF8(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 VARCHAR(50) NOT NULL)
GO
DROP TABLE IF EXISTS dbo.Inserts_UTF16_Compressed
CREATE TABLE dbo.Inserts_UTF16_Compressed(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 NVARCHAR(50) NOT NULL)
WITH (DATA_COMPRESSION = PAGE)
GO
DROP TABLE IF EXISTS dbo.Inserts_UTF8_Compressed
CREATE TABLE dbo.Inserts_UTF8_Compressed(
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY
    , col1 VARCHAR(50) NOT NULL)
WITH (DATA_COMPRESSION = PAGE)
GO

-- Insert same data set to all tables
-- UTF16
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF16 (col1)
	SELECT REPLICATE(CONCAT(
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45))),
	  NCHAR(FLOOR(1070 + (RAND() * 45)))
	  ), 2);
    SET @i += 1
END;
COMMIT
GO
-- UTF8
SET NOCOUNT ON;
BEGIN TRAN
INSERT INTO dbo.Inserts_UTF8 (col1)
SELECT col1 FROM dbo.Inserts_UTF16
COMMIT
GO
-- UTF16 Compressed
SET NOCOUNT ON;
BEGIN TRAN
INSERT INTO dbo.Inserts_UTF16_Compressed (col1)
SELECT col1 FROM dbo.Inserts_UTF16
COMMIT
GO
-- UTF8 Compressed
SET NOCOUNT ON;
BEGIN TRAN
INSERT INTO dbo.Inserts_UTF8_Compressed (col1)
SELECT col1 FROM dbo.Inserts_UTF16
COMMIT
GO

-- Check data record sizes
-- Note data lenght sizes are the same whether compressed or not
SELECT TOP 1 DATALENGTH(col1)
FROM Inserts_UTF16
GO
SELECT TOP 1 DATALENGTH(col1)
FROM Inserts_UTF8
GO

-- Check table sizes
SELECT OBJECT_NAME(p.OBJECT_ID) AS TableName,
	p.ROWS AS NumRows, a.used_pages, a.total_pages,
	CONVERT(DECIMAL(19,2),ISNULL(a.used_pages,0))*8/1024 AS DataSizeMB
FROM sys.allocation_units a
INNER JOIN sys.partitions p ON p.hobt_id = a.container_id
	AND OBJECT_NAME(p.OBJECT_ID) LIKE 'Inserts%'
ORDER BY TableName
GO




-- Simple Read perf
SET STATISTICS IO, TIME ON
GO

DBCC DROPCLEANBUFFERS
GO
/*
SSMS:
CPU 141 ms
Elapsed 646 ms
Reads 7069 + 7069

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/

SELECT * FROM Inserts_UTF16
WHERE col1 LIKE 'ч%'
GO

DBCC DROPCLEANBUFFERS
GO
/*
SSMS:
CPU 452 ms
Elapsed 252 ms
Reads 7069 + 2888

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/
SELECT * FROM Inserts_UTF8
WHERE col1 LIKE 'ч%'
GO

DBCC DROPCLEANBUFFERS
GO
/*
SSMS:
CPU 282 ms
Elapsed 403 ms
Reads 4143

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/
SELECT * FROM Inserts_UTF16_Compressed
WHERE col1 LIKE 'ч%'
GO

DBCC DROPCLEANBUFFERS
GO
/*
SSMS:
CPU 674 ms
Elapsed 244 ms
Reads 6601

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/
SELECT * FROM Inserts_UTF8_Compressed
WHERE col1 LIKE 'ч%'
GO

SET STATISTICS IO, TIME OFF
GO