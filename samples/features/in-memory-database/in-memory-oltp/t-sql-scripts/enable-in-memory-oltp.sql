-- The below scipt enables the use of In-Memory OLTP in the current database,
--   provided it is supported in the edition / pricing tier of the database.
-- It does the following:
-- 1. Validate that In-Memory OLTP is supported.
-- 2. In SQL Server, it will add a MEMORY_OPTIMIZED_DATA filegroup to the database
--    and create a container within the filegroup in the default data folder.
-- 3. Change the database compatibility level to 130 (needed for parallel queries
--    and auto-update of statistics).
-- 4. Enables the database option MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT to avoid the
--    need to use the WITH (SNAPSHOT) hint for ad hoc queries accessing memory-optimized
--    tables.
--
-- Applies To: SQL Server 2016 (or higher); Azure SQL Database
-- Author: Jos de Bruijn (Microsoft)
-- Last Updated: 2016-05-02

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. validate that In-Memory OLTP is supported
IF SERVERPROPERTY(N'IsXTPSupported') = 0
BEGIN
    PRINT N'Error: In-Memory OLTP is not supported for this server edition or database pricing tier.';
END
IF DB_ID() < 5
BEGIN
    PRINT N'Error: In-Memory OLTP is not supported in system databases. Connect to a user database.';
END
ELSE
BEGIN
	BEGIN TRY;
-- 2. add MEMORY_OPTIMIZED_DATA filegroup when not using Azure SQL DB
	IF SERVERPROPERTY('EngineEdition') != 5
	BEGIN
		DECLARE @SQLDataFolder nvarchar(max) = cast(SERVERPROPERTY('InstanceDefaultDataPath') as nvarchar(max))
		DECLARE @MODName nvarchar(max) = DB_NAME() + N'_mod';
		DECLARE @MemoryOptimizedFilegroupFolder nvarchar(max) = @SQLDataFolder + @MODName;

		DECLARE @SQL nvarchar(max) = N'';

		-- add filegroup
		IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE type = N'FX')
		BEGIN
			SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILEGROUP ' + QUOTENAME(@MODName) + N' CONTAINS MEMORY_OPTIMIZED_DATA;';
			EXECUTE (@SQL);

		END;

		-- add container in the filegroup
		IF NOT EXISTS (SELECT * FROM sys.database_files WHERE data_space_id IN (SELECT data_space_id FROM sys.filegroups WHERE type = N'FX'))
		BEGIN
			SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILE (name = N''' + @MODName + ''', filename = '''
						+ @MemoryOptimizedFilegroupFolder + N''')
TO FILEGROUP ' + QUOTENAME(@MODName);
			EXECUTE (@SQL);
		END
	END

	-- 3. set compat level to 130 if it is lower
	IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()) < 130
		ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 130

	-- 4. enable MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT for the database
	ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;


    END TRY
    BEGIN CATCH
        PRINT N'Error enabling In-Memory OLTP';
		IF XACT_STATE() != 0
			ROLLBACK;
        THROW;
    END CATCH;
END;
