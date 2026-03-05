----------------------------------------------
-- Data type sizes - a western myth
----------------------------------------------

-- Note: my server default is SQL_Latin1_General_CP1_CI_AS

-- Test Latin character strings with Latin collation
-- Set size limit of data types to be the same under Basic Multilingual Plane (BMP)
-- Characters between 1-byte (ASCII) and 3-bytes (East Asian)
USE master;
DROP DATABASE IF EXISTS UnicodeDatabase;
CREATE DATABASE UnicodeDatabase COLLATE LATIN1_GENERAL_100_CI_AS_SC_UTF8
GO

USE UnicodeDatabase
GO
DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (c1 varchar(24) COLLATE Latin1_General_100_CI_AI, 
	c2 nvarchar(8) COLLATE Latin1_General_100_CI_AI);  
INSERT INTO t1 VALUES (N'MyString', N'MyString')  
SELECT LEN(c1) AS [varchar LEN],  
	DATALENGTH(c1) AS [varchar DATALENGTH], c1
FROM t1;  
SELECT LEN(c2) AS [nvarchar LEN], 
	DATALENGTH(c2) AS [nvarchar DATALENGTH], c2 
FROM t1;
GO





-- That's as expected. So what was I talking about?





-- Test Chinese character strings with Latin collation
DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (c1 varchar(24) COLLATE Latin1_General_100_CI_AI, 
	c2 nvarchar(8) COLLATE Latin1_General_100_CI_AI);  
INSERT INTO t1 VALUES (N'敏捷的棕色狐狸跳', N'敏捷的棕色狐狸跳')  
SELECT LEN(c1) AS [varchar LEN],  
	DATALENGTH(c1) AS [varchar DATALENGTH], c1
FROM t1;  
SELECT LEN(c2) AS [nvarchar LEN], 
	DATALENGTH(c2) AS [nvarchar DATALENGTH], c2 
FROM t1;
GO



-- uh-oh data loss on the varchar example. Why?
-- varchar is bound to code page enconding, 
-- and these code points cannot be found in the Latin code page.
SELECT ASCII('敏' COLLATE Latin1_General_100_CI_AI), CHAR(63)
SELECT ASCII('捷' COLLATE Latin1_General_100_CI_AI), CHAR(63)






-- But why didn't it happen in the nvarchar example?
-- These Chinese characters are double-byte and within the Basic Multilingual Plane (BMP)
-- nvarchar with this non-SC collation encodes in UCS-2 (BMP), not the code page
SELECT UNICODE(N'敏' COLLATE Latin1_General_100_CI_AI), NCHAR(25935)
SELECT UNICODE(N'捷' COLLATE Latin1_General_100_CI_AI), NCHAR(25463)




-- Irrespective of collation now. With a Unicode capable data type,
-- collation only sets linguistic algorithms 
-- (Compare = sort; Case sensitivity = Upper/Lowercase)
SELECT UNICODE(N'敏' COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI), NCHAR(25935)
SELECT UNICODE(N'捷' COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI), NCHAR(25463)



-- Now test Chinese character strings with Chinese collation
DROP TABLE IF EXISTS t2;
CREATE TABLE t2 (c1 varchar(24) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI, 
	c2 nvarchar(8) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI);  
INSERT INTO t2 VALUES (N'敏捷的棕色狐狸跳', N'敏捷的棕色狐狸跳')  
SELECT LEN(c1) AS [varchar LEN],  
	DATALENGTH(c1) AS [varchar DATALENGTH], c1
FROM t2;  
SELECT LEN(c2) AS [nvarchar LEN], 
	DATALENGTH(c2) AS [nvarchar DATALENGTH], c2 
FROM t2;
GO


-- Now the varchar example is correct. But there's 2 bytes per character?...
-- Myth buster: code page defines string length for varchar. It's not always 1 byte per character.
-- Wasn't East-Asian 3 bytes? Yes, but under Chinese collation code page, 
-- they are encoded using 2 bytes just like UCS-2/UTF-16



-- Test with Supplementary Characters (4 bytes) and using SC
DROP TABLE IF EXISTS t2;
CREATE TABLE t2 (c1 varchar(24) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI_SC, 
	c2 nvarchar(8) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI_SC);  
INSERT INTO t2 VALUES (N'👶👦👧👨👩👴👵👨', N'👶👦👧👨👩👴👵👨')  
SELECT LEN(c1) AS [varchar LEN],  
	DATALENGTH(c1) AS [varchar DATALENGTH], c1
FROM t2;  
SELECT LEN(c2) AS [nvarchar LEN], 
	DATALENGTH(c2) AS [nvarchar DATALENGTH], c2 
FROM t2;
GO



-- Fix the error
DROP TABLE IF EXISTS t2;
CREATE TABLE t2 (c1 varchar(24) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI_SC, 
	c2 nvarchar(16) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI_SC);  
INSERT INTO t2 VALUES (N'👶👦👧👨👩👴👵👨', N'👶👦👧👨👩👴👵👨')  
SELECT LEN(c1) AS [varchar LEN],  
	DATALENGTH(c1) AS [varchar DATALENGTH], c1
FROM t2;  
SELECT LEN(c2) AS [nvarchar LEN], 
	DATALENGTH(c2) AS [nvarchar DATALENGTH], c2 
FROM t2;
GO


-- Varchar still doesn't encode? 
DROP TABLE IF EXISTS t2;
CREATE TABLE t2 (c1 varchar(48) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI_SC_UTF8, 
	c2 nvarchar(16) COLLATE Chinese_Traditional_Stroke_Order_100_CI_AI_SC);  
INSERT INTO t2 VALUES (N'👶👦👧👨👩👴👵👨', N'👶👦👧👨👩👴👵👨')  
SELECT LEN(c1) AS [varchar LEN],  
	DATALENGTH(c1) AS [varchar DATALENGTH], c1
FROM t2;  
SELECT LEN(c2) AS [nvarchar LEN], 
	DATALENGTH(c2) AS [nvarchar DATALENGTH], c2 
FROM t2;
GO




-- What if I needed all these in one database? Easy, I could just use nvarchar.
DROP TABLE IF EXISTS t3;
CREATE TABLE t3 (c1 nvarchar(110) COLLATE Latin1_General_100_CI_AI_SC);  
INSERT INTO t3 VALUES (N'MyStringThequickbrownfoxjumpsoverthelazydogIsLatinAscii敏捷的棕色狐狸跳👶👦')  
SELECT LEN(c1) AS [nvarchar UTF16 LEN],  
	DATALENGTH(c1) AS [nvarchar UTF16 DATALENGTH], c1
FROM t3; 
GO




-- But the majority of my data is set to Latin (ASCII)
DROP TABLE IF EXISTS t4;
CREATE TABLE t4 (c1 varchar(110) COLLATE Latin1_General_100_CI_AI_SC_UTF8);  
INSERT INTO t4 VALUES (N'MyStringThequickbrownfoxjumpsoverthelazydogIsLatinAscii敏捷的棕色狐狸跳👶👦')  
SELECT LEN(c1) AS [varchar UTF8 LEN],  
	DATALENGTH(c1) AS [varchar UTF8 DATALENGTH], c1
FROM t4; 
GO



-- Where are the savings?
SELECT DATALENGTH(N'MyStringThequickbrownfoxjumpsoverthelazydogIsLatinAscii') AS [Latin_UTF16_2bytes], 
	DATALENGTH(N'敏捷的棕色狐狸跳') AS [Chinese_UTF16_2bytes], 
	DATALENGTH(N'👶') AS [SC_UTF16_4bytes]
SELECT DATALENGTH('MyStringThequickbrownfoxjumpsoverthelazydogIsLatinAscii' COLLATE Latin1_General_100_CI_AI_SC_UTF8) AS [Latin_UTF8_1byte], 
	DATALENGTH('敏捷的棕色狐狸跳' COLLATE Latin1_General_100_CI_AI_SC_UTF8) AS [Chinese_UTF8_3bytes], 
	DATALENGTH('👶' COLLATE Latin1_General_100_CI_AI_SC_UTF8) AS [SC_UTF8_4bytes]
GO