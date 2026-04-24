
-- Enable CLR
sp_configure 'clr enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

--Drop the functions if they already exist
DROP FUNCTION IF EXISTS CURL.XGET
GO
DROP PROCEDURE IF EXISTS CURL.XPOST
GO

--Drop the schema if it already exists
DROP SCHEMA IF EXISTS CURL;
GO

--Drop "trusted assembly flag" if it is set

DECLARE @hash VARBINARY(64);

SELECT @hash = hash
FROM sys.trusted_assemblies ta
WHERE ta.description = N'SqlClrCurl'

EXEC sp_drop_trusted_assembly @hash;
GO

--Drop the assembly if it already exists
DROP ASSEMBLY IF EXISTS SqlClrCurl;
GO


DECLARE @hash VARBINARY(64);
SELECT @hash = HASHBYTES('SHA2_512', BulkColumn)
FROM OPENROWSET(BULK 'C:\GitHub\sql-server-samples\samples\features\sql-clr\Curl\bin\Release\SqlClrCurl.dll', SINGLE_BLOB) AS assembly_content

IF(@hash IS NOT NULL)
	EXEC sp_add_trusted_assembly @hash, N'SqlClrCurl'
ELSE
	PRINT 'Cannot create hash for assembly!'
GO

--Create the assembly
CREATE ASSEMBLY SqlClrCurl
FROM 'C:\GitHub\sql-server-samples\samples\features\sql-clr\Curl\bin\Release\SqlClrCurl.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS;
GO

--Create the schema where CURL modules will be placed.
CREATE SCHEMA CURL;
GO

--Create the function/procedure
CREATE FUNCTION CURL.XGET (@H NVARCHAR(MAX), @url NVARCHAR(4000))
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME SqlClrCurl.Curl.Get;
GO

CREATE PROCEDURE CURL.XPOST (@H NVARCHAR(MAX), @d NVARCHAR(MAX), @url NVARCHAR(4000))
AS EXTERNAL NAME SqlClrCurl.Curl.Post;
GO