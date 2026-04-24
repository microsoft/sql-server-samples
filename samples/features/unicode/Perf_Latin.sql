----------------------------------------------
-- Perf Improvements - ASCII - 1 byte per char
----------------------------------------------

USE master;
DROP DATABASE IF EXISTS LatinDatabase;
CREATE DATABASE LatinDatabase COLLATE LATIN1_GENERAL_100_CI_AS_SC_UTF8
GO

USE LatinDatabase
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

-- INSERT perf UTF16: 37s
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF16 (col1)
	SELECT REPLICATE(CONCAT(
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25)))
	  ), 5);
    SET @i += 1
END;
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF16'
COMMIT
GO
-- INSERT perf UTF8: 34s
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF8 (col1)
	SELECT REPLICATE(CONCAT(
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25)))
	  ), 5);
    SET @i += 1
END;

SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF8'
COMMIT
GO
-- INSERT perf UTF16 Compressed: 40s
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF16_Compressed (col1)
	SELECT REPLICATE(CONCAT(
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25)))
	  ), 5);
    SET @i += 1
END;
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF16_Compressed'
COMMIT
GO
-- INSERT perf UTF8 Compressed: 38s
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
WHILE @i < 1000000
BEGIN
    INSERT INTO dbo.Inserts_UTF8_Compressed (col1)
	SELECT REPLICATE(CONCAT(
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25)))
	  ), 5);
    SET @i += 1
END;
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF8_Compressed' -- 34s
COMMIT
GO

------------------------------------
-- SELECTs
------------------------------------

USE [LatinDatabase];
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
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25))),
	  CHAR(FLOOR(65 + (RAND() * 25)))
	  ), 5);
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
-- Note data length sizes are the same whether compressed or not
SELECT TOP 1 DATALENGTH(col1) AS [DataLength_UTF16]
FROM Inserts_UTF16
GO
SELECT TOP 1 DATALENGTH(col1) AS [DataLength_UTF8]
FROM Inserts_UTF8
GO

-- Check table sizes
-- Highlights: UTF8 uncompressed is close to UTF16 compressed.
-- UTF8 compressed doesn't get much further as expected.
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
CPU 171 ms
Elapsed 1982 ms
Reads 14893 + 14523

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/

SELECT * FROM Inserts_UTF16
-- WHERE ID BETWEEN 5000 AND 12500
WHERE col1 LIKE 'P%'
GO

DBCC DROPCLEANBUFFERS
GO
/*
SSMS:
CPU 266 ms
Elapsed 703 ms
Reads 8787 + 8365

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/
SELECT * FROM Inserts_UTF8
-- WHERE ID BETWEEN 5000 AND 12500
WHERE col1 LIKE 'P%'
GO

DBCC DROPCLEANBUFFERS
GO
/*
SSMS:
CPU 423 ms
Elapsed 662 ms
Reads 8367 + 7964

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/
SELECT * FROM Inserts_UTF16_Compressed
-- WHERE ID BETWEEN 5000 AND 12500
WHERE col1 LIKE 'P%'
GO

DBCC DROPCLEANBUFFERS
GO
/*
SSMS:
CPU 371 ms
Elapsed 664 ms
Reads 8238 + 7235

SQLCMD:
CPU  ms
Elapsed  ms
Reads
*/
SELECT * FROM Inserts_UTF8_Compressed
-- WHERE ID BETWEEN 5000 AND 12500
WHERE col1 LIKE 'P%'
GO

SET STATISTICS IO, TIME OFF
GO