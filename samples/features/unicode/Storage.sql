-------------------------------
-- Storage savings
-------------------------------

USE master;
DROP DATABASE IF EXISTS LatinDatabase;
CREATE DATABASE LatinDatabase COLLATE LATIN1_GENERAL_100_CI_AS_SC_UTF8
GO

USE LatinDatabase
GO
DROP TABLE IF EXISTS MyTable;
CREATE TABLE MyTable (c1 NCHAR(10), c2 CHAR(10))
GO

INSERT INTO MyTable (c1, c2)
VALUES ('UTF16','UTF8')
GO

SELECT DATALENGTH(c1) AS [UTF16_Col], DATALENGTH(c2) AS [UTF8_Col]
FROM MyTable
GO

-------------------------------
-- 1M Rows Latin
-------------------------------

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
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF16'
COMMIT
GO
-- UTF8
SET NOCOUNT ON;
BEGIN TRAN
DECLARE @i int = 1, @start datetime
SELECT @start = GETDATE()
INSERT INTO dbo.Inserts_UTF8 (col1)
SELECT col1 FROM dbo.Inserts_UTF16;
SELECT DATEDIFF(s, @start, GETDATE()) AS 'Inserts_UTF8'
COMMIT
GO

-- Check data record sizes
-- Note data lenght sizes are the same whether compressed or not
SELECT TOP 1 DATALENGTH(col1) AS [DataLength_UTF16]
FROM Inserts_UTF16
GO
SELECT TOP 1 DATALENGTH(col1) AS [DataLength_UTF8]
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