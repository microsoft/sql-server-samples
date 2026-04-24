----------------------------------------------
-- UTF-8 Functional
----------------------------------------------

USE master;
GO

DROP DATABASE IF EXISTS MyNonUtf8Database;

DROP DATABASE IF EXISTS MyUtf8Database;

DROP DATABASE IF EXISTS MyFormerlyUnicodeOnlyDatabase;

DROP DATABASE IF EXISTS MaskingDatabase;

--
-- Create a database that is NOT collated with UTF-8.
-- This demonstrates that you can insert Unicode data into VARCHAR columns collated with UTF-8.
--
CREATE DATABASE MyNonUtf8Database COLLATE SQL_Latin1_General_CP1_CI_AI;
GO

USE MyNonUtf8Database;
GO

CREATE TABLE MyUtf8Table (datakind VARCHAR(100), data VARCHAR(8000) COLLATE Latin1_General_100_CI_AS_SC_UTF8);
GO

INSERT INTO MyUtf8Table
VALUES ('ASCII - 1 byte per character', N'Thequickbrownfoxjumpsoverthelazydog'),
	('Cyrillic - 2 bytes per character', N'Быстраякоричневаялисапрыгаетчерезленивуюсобаку'),
	('Far East - 3 bytes per character', N'敏捷的棕色狐狸跳过了懒狗'),
	('Emojis - 4 bytes per character', N'👶👦👧👨👩👴👵👨👩👨👩👨👩👨👩'),
	('Emojis with Variation Selector - 6 bytes per glyph', N'⚕️⚖️↔︎↕︎↖︎↗︎↘︎↙︎↩︎↪︎↔️↕️↖️↗️↘️↙️↩️↪️'),
	('Ashi with Supplementary Variation Selector - 7 bytes per glyph', N'芦󠄀芦󠄁芦󠄂芦󠄃芦󠄄芦󠄅芦󠄆芦󠄇芦󠄈芦󠄉芦󠄃芦󠄂芦󠄁芦󠄀芦󠄁芦󠄂芦󠄃芦󠄄芦󠄈芦󠄉');
GO

SELECT datakind, data
FROM MyUtf8Table;
GO

-- This demo used the N' syntax, as string literals are always collated in the collation
-- of the currently active database.



--
-- Create a database collated with UTF-8.
-- This is to demonstrate that now string literals can be used without N'',
-- as string literals are collated with the database collation, and can hold any characters.
--
CREATE DATABASE MyUtf8Database COLLATE Lithuanian_100_CS_AI_WS_SC_UTF8;
GO

USE MyUtf8Database;
GO

CREATE TABLE MyTableWithInheritedCollation (datakind VARCHAR(100), data VARCHAR(8000));
GO

INSERT INTO MyTableWithInheritedCollation
VALUES ('ASCII - 1 byte per character', 'Thequickbrownfoxjumpsoverthelazydog'),
	('Cyrillic - 2 bytes per character', 'Быстраякоричневаялисапрыгаетчерезленивуюсобаку'),
	('Far East - 3 bytes per character', '敏捷的棕色狐狸跳过了懒狗'),
	('Emojis - 4 bytes per character', '👶👦👧👨👩👴👵👨👩👨👩👨👩👨👩'),
	('Emojis with Variation Selector - 6 bytes per glyph', '⚕️⚖️↔︎↕︎↖︎↗︎↘︎↙︎↩︎↪︎↔️↕️↖️↗️↘️↙️↩️↪️'),
	('Ashi with Supplementary Variation Selector - 7 bytes per glyph', '芦󠄀芦󠄁芦󠄂芦󠄃芦󠄄芦󠄅芦󠄆芦󠄇芦󠄈芦󠄉芦󠄃芦󠄂芦󠄁芦󠄀芦󠄁芦󠄂芦󠄃芦󠄄芦󠄈芦󠄉');
GO

SELECT datakind, data
FROM MyTableWithInheritedCollation;
GO

--
-- Create a collation prefixed with formerly Unicode-only collation (not having its own Windows code page).
-- You can do it now.
--
CREATE DATABASE GonnaFailDueToUnicodeOnlyCollation COLLATE Lao_100_CS_AS_KS_WS_SC;
GO

CREATE DATABASE MyFormerlyUnicodeOnlyDatabase COLLATE Lao_100_CS_AS_KS_WS_SC_UTF8;
GO

USE MyFormerlyUnicodeOnlyDatabase;
GO

CREATE TABLE MyFormerlyUnicodeOnlyTable (datakind VARCHAR(100), data VARCHAR(8000));
GO

INSERT INTO MyFormerlyUnicodeOnlyTable (datakind, data)
SELECT datakind, data
FROM MyNonUtf8Database..MyUtf8Table;
GO

SELECT datakind, data
FROM MyFormerlyUnicodeOnlyTable;
GO









--
-- Demo of one orthogonality feature - data masking
--
CREATE DATABASE MaskingDatabase COLLATE Chinese_PRC_90_CI_AI_SC_UTF8;
GO

USE MaskingDatabase;
GO

CREATE user ToBeKeptAway without LOGIN;
GO

CREATE TABLE KeepAway (top_secret_data VARCHAR(8000) COLLATE Mapudungan_100_CS_AS_SC_UTF8 masked
WITH (FUNCTION = 'partial(2, "💩💩💩💩💩", 2)'));
GO

INSERT INTO KeepAway (top_secret_data)
SELECT data
FROM MyNonUtf8Database..MyUtf8Table;
GO

GRANT SELECT
	ON KeepAway
	TO ToBeKeptAway;
GO

EXECUTE AS user = 'ToBeKeptAway';

SELECT top_secret_data
FROM KeepAway;

REVERT;
GO

----------------------------
/*
See how many bytes each character requires for both UTF-8 and UTF-16 encodings.
Returns all 65,536 BMP (Base Multilingual Plan) characters (which is also the entire UCS-2 character set), and 3 Supplementary Characters.
Since all Supplementary Characters are 4 bytes in both encodings, there is no need to return more of them, but we do need to see a few of them to see that they are:
a) all 4 bytes
b) encoded slightly differently
*/
	;

WITH nums ([CodePoint])
AS (
	SELECT TOP (65536) (
			ROW_NUMBER() OVER (
				ORDER BY (
						SELECT 0
						)
				) - 1
			)
	FROM [master].[sys].[columns] col
	CROSS JOIN [master].[sys].[objects] obj
	), chars
AS (
	SELECT nums.[CodePoint], CONVERT(VARCHAR(4), NCHAR(nums.[CodePoint]) COLLATE Latin1_General_100_CI_AS_SC_UTF8) AS [TheChar], CONVERT(VARBINARY(4), CONVERT(VARCHAR(4), NCHAR(nums.[CodePoint]) COLLATE Latin1_General_100_CI_AS_SC_UTF8)) AS [UTF8]
	FROM nums
	
	UNION ALL
	
	SELECT tmp.val, CONVERT(VARCHAR(4), CONVERT(NVARCHAR(5), tmp.hex) COLLATE Latin1_General_100_CI_AS_SC_UTF8) AS [TheChar], CONVERT(VARBINARY(4), CONVERT(VARCHAR(4), CONVERT(NVARCHAR(5), tmp.hex) COLLATE Latin1_General_100_CI_AS_SC_UTF8)) AS [UTF8]
	FROM (
		VALUES (65536, 0x00D800DC), -- Linear B Syllable B008 A (U+10000)
			(67618, 0x02D822DC), -- Cypriot Syllable Pu (U+10822)
			(129384, 0x3ED868DD) -- Pretzel (U+1F968)
		) tmp(val, hex)
	)
SELECT chr.[CodePoint], COALESCE(chr.[TheChar], N'TOTALS:') AS [Character], chr.[UTF8] AS [UTF8_Hex], DATALENGTH(chr.[UTF8]) AS [UTF8_Bytes], COUNT(CASE DATALENGTH(chr.[UTF8]) WHEN 1 THEN 'x' END) AS [1-byte], COUNT(CASE DATALENGTH(chr.[UTF8]) WHEN 2 THEN 'x' END) AS [2-bytes], COUNT(CASE DATALENGTH(chr.[UTF8]) WHEN 3 THEN 'x' END) AS [3-bytes], COUNT(CASE DATALENGTH(chr.[UTF8]) WHEN 4 THEN 'x' END) AS [4-bytes],
	---
	CONVERT(VARBINARY(4), CONVERT(NVARCHAR(3), chr.[TheChar])) AS [UTF16(LE)_Hex], DATALENGTH(CONVERT(NVARCHAR(3), chr.[TheChar])) AS [UTF16_Bytes],
	---
	((DATALENGTH(CONVERT(NVARCHAR(3), chr.[TheChar]))) - (DATALENGTH(chr.[TheChar]))) AS [UTF8savingsOverUTF16]
FROM chars chr
GROUP BY ROLLUP((chr.[CodePoint], chr.[TheChar], chr.[UTF8]));
