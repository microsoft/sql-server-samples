USE AdventureWorks2016_EXT;
GO

-- Create regular table

DROP TABLE IF EXISTS [dbo].[TestSequentialKey];
GO

CREATE TABLE [dbo].[TestSequentialKey](
	[DatabaseLogID] [bigint] IDENTITY(1,1) NOT NULL,
	[PostTime] [datetime2] NOT NULL,
	[DatabaseUser] [sysname] NOT NULL,
	[Event] [sysname] NOT NULL,
	[Schema] [sysname] NULL,
	[Object] [sysname] NULL,
	[TSQL] [nvarchar](max) NOT NULL
 CONSTRAINT [PK_TestSequentialKey_DatabaseLogID] PRIMARY KEY NONCLUSTERED
(
	[DatabaseLogID] ASC
));

CREATE CLUSTERED INDEX CIX_TestSequentialKey_PostTime ON TestSequentialKey (PostTime);
GO

-- Create optimized table

DROP TABLE IF EXISTS [dbo].[TestSequentialKey_Optimized];
GO

CREATE TABLE [dbo].[TestSequentialKey_Optimized](
	[DatabaseLogID] [bigint] IDENTITY(1,1) NOT NULL,
	[PostTime] [datetime2] NOT NULL,
	[DatabaseUser] [sysname] NOT NULL,
	[Event] [sysname] NOT NULL,
	[Schema] [sysname] NULL,
	[Object] [sysname] NULL,
	[TSQL] [nvarchar](max) NOT NULL
 CONSTRAINT [PK_TestSequentialKey_Optimized_DatabaseLogID] PRIMARY KEY NONCLUSTERED
(
	[DatabaseLogID] ASC
)
WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY=ON));

CREATE CLUSTERED INDEX CIX_TestSequentialKey_Optimized_PostTime ON TestSequentialKey_Optimized (PostTime) WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY=ON);
GO

-- Create INSERT stored procedure

CREATE OR ALTER PROCEDURE usp_InsertLogRecord @Optimized bit = 0 AS

DECLARE @PostTime datetime2 = SYSDATETIME(), @User sysname, @Event sysname, @Schema sysname, @Object sysname, @TSQL nvarchar(max)

SELECT @User = name
FROM sys.sysusers
WHERE issqlrole = 0 and hasdbaccess = 1 and status = 0
ORDER BY NEWID();

SELECT @Object = t.name, @Schema = s.name
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY NEWID();

IF DATEPART(ms, @PostTime) % 4 = 0
BEGIN
	SET @Event = N'SELECT';
	SET @TSQL = N'SELECT * FROM ' + @Schema + '.' + @Object
END
ELSE IF DATEPART(ms, @PostTime) % 4 = 1
BEGIN
	SET @Event = N'INSERT';
	SET @TSQL = N'INSERT ' + @Schema + '.' + @Object + ' SELECT * FROM ' + @Schema + '.' + @Object
END
ELSE IF DATEPART(ms, @PostTime) % 4 = 2
BEGIN
	SET @Event = N'UPDATE';
	SET @TSQL = N'UPDATE ' + @Schema + '.' + @Object + ' SET 1=1';
END
ELSE IF DATEPART(ms, @PostTime) % 4 = 3
BEGIN
	SET @Event = N'DELETE';
	SET @TSQL = N'DELETE FROM ' + @Schema + '.' + @Object + ' WHERE 1=1';
END

IF @Optimized = 1
	INSERT TestSequentialKey_Optimized (PostTime, DatabaseUser, [Event], [Schema], [Object], [TSQL])
	VALUES (@PostTime, @User, @Event, @Schema, @Object, @TSQL);
ELSE
	INSERT TestSequentialKey (PostTime, DatabaseUser, [Event], [Schema], [Object], [TSQL])
	VALUES (@PostTime, @User, @Event, @Schema, @Object, @TSQL);

GO
