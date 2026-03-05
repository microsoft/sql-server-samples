-- Assess space requirements for UTF8 in context database

DROP TABLE IF EXISTS #tmpObjects;

CREATE TABLE #tmpObjects (ObjectName sysname, 
	ColumnName sysname, 
	ColumnType sysname, 
	DefinedTypeSize smallint, 
	ActualMaxBytes smallint,
	UTF8BytesNeeded smallint,
	[isdone] bit,
    CONSTRAINT PK_ObjName_ColName
        PRIMARY KEY NONCLUSTERED (ObjectName, ColumnName)
		WITH (IGNORE_DUP_KEY = ON)
	);

INSERT INTO #tmpObjects
SELECT QUOTENAME(SS.[name]) + '.' + QUOTENAME(STbl.[name]), QUOTENAME(SC.[name]), ST.[name], SC.max_length, NULL, NULL, 0
FROM sys.columns AS SC
INNER JOIN sys.types AS ST ON SC.user_type_id = ST.user_type_id
INNER JOIN sys.tables AS STbl ON STbl.[object_id] = SC.[object_id]
INNER JOIN sys.schemas AS SS ON STbl.[schema_id] = SS.[schema_id]
WHERE STbl.[type] = 'U' 
	AND STbl.is_ms_shipped = 0
	--AND STbl.temporal_type IN (0,1)
	AND ST.system_type_id IN (167, 175, 231, 239)
	AND ST.[name] <> 'sysname'
	AND SC.is_hidden = 0
	AND SC.max_length > 0;

DECLARE @OName sysname, @CName sysname, @CurrBytes smallint, @UTF8Bytes smallint, @sqlcmd NVARCHAR(4000), @params NVARCHAR(60), @cnt int, @maxcnt int

SELECT @maxcnt = COUNT(*) FROM #tmpObjects;
SET @cnt = 0 
SET @params = '@CurrBytesOut smallint OUTPUT, @UTF8BytesOut smallint OUTPUT'

WHILE @cnt < @maxcnt
BEGIN
	SELECT TOP 1 @OName = ObjectName, @CName = ColumnName FROM #tmpObjects WHERE isdone = 0
	SELECT @sqlcmd = 'SELECT @CurrBytesOut = MAX(DATALENGTH(' + @CName + ')), @UTF8BytesOut = MAX(DATALENGTH(CAST(' + @CName + ' AS VARCHAR(4000)) COLLATE Latin1_General_100_CI_AI_SC_UTF8)) FROM ' + @OName + ' WITH (NOLOCK)';  

	EXEC sp_executesql @sqlcmd, @params, @CurrBytesOut = @CurrBytes OUTPUT, @UTF8BytesOut = @UTF8Bytes OUTPUT

	UPDATE #tmpObjects
	SET ActualMaxBytes = @CurrBytes, UTF8BytesNeeded = @UTF8Bytes, isdone = 1 
	WHERE ObjectName = @OName AND ColumnName = @CName

	SET @cnt = @cnt + 1
END;

SELECT * FROM #tmpObjects;