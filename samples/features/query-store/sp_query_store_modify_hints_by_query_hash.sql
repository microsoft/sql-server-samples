/*
This stored procedure sets or clears Query Store hints 
for all queries with the specified query hash 
that are present in Query Store in the current database.

For more information about Query Store hints, see:
Overview: https://learn.microsoft.com/sql/relational-databases/performance/query-store-hints.
Best practices: https://learn.microsoft.com/sql/relational-databases/performance/query-store-hints-best-practices.
Usage scenarios: https://learn.microsoft.com/sql/relational-databases/performance/query-store-usage-scenarios.

Usage examples:

/* Set query hints for all queries with the specified query hash */
EXEC dbo.sp_query_store_modify_hints_by_query_hash
    @action = 'set',
    @query_hint_text = 'OPTION (MAXDOP 1, USE HINT (''ENABLE_QUERY_OPTIMIZER_HOTFIXES''))',
    @query_hash = 0xB5AF960709ADE6F2;

/* Clear query hints for all queries with the specified query hash */
EXEC dbo.sp_query_store_modify_hints_by_query_hash
    @action = 'clear',
    @query_hash = 0xB5AF960709ADE6F2;
*/

CREATE OR ALTER PROCEDURE dbo.sp_query_store_modify_hints_by_query_hash
    @action nvarchar(5),
    @query_hash binary(8),
    @query_hint_text nvarchar(max) = NULL,
    @replica_group_id bigint = NULL
AS
SET NOCOUNT, XACT_ABORT ON;
SET DEADLOCK_PRIORITY LOW;
SET LOCK_TIMEOUT 3000;

BEGIN TRY

DECLARE @sql_server_2022 bit = IIF(CAST(SERVERPROPERTY('ProductMajorVersion') AS nvarchar(128)) COLLATE DATABASE_DEFAULT = N'16' AND CAST(SERVERPROPERTY('EngineEdition') AS int) IN (1,2,3,4), 1, 0),
        @sql_server_2025_later bit = IIF(CAST(SERVERPROPERTY('ProductMajorVersion') AS nvarchar(128)) COLLATE DATABASE_DEFAULT >= N'17' AND CAST(SERVERPROPERTY('EngineEdition') AS int) IN (1,2,3,4), 1, 0),
        @sql_mi_2022 bit = IIF(CAST(SERVERPROPERTY('EngineEdition') AS int) = 8 AND CAST(SERVERPROPERTY('ProductMajorVersion') AS nvarchar(128)) COLLATE DATABASE_DEFAULT < N'17' AND CAST(SERVERPROPERTY('ProductUpdateType') AS nvarchar(128)) COLLATE DATABASE_DEFAULT = 'CU', 1, 0),
        @sql_mi_2025_later bit = IIF(CAST(SERVERPROPERTY('EngineEdition') AS int) = 8 AND CAST(SERVERPROPERTY('ProductMajorVersion') AS nvarchar(128)) COLLATE DATABASE_DEFAULT >= N'17' AND CAST(SERVERPROPERTY('ProductUpdateType') AS nvarchar(128)) COLLATE DATABASE_DEFAULT = 'CU', 1, 0),
        @sql_mi_always_up_to_date bit = IIF(CAST(SERVERPROPERTY('EngineEdition') AS int) = 8 AND CAST(SERVERPROPERTY('ProductUpdateType') AS nvarchar(128)) COLLATE DATABASE_DEFAULT = 'Continuous', 1, 0),
        @sql_db bit = IIF(CAST(SERVERPROPERTY('EngineEdition') AS int) = 5, 1, 0),
        @return int = -1111,
        @resource sysname = LOWER(OBJECT_NAME(@@PROCID)),
        @query_id bigint,
        @message nvarchar(max),
        @count_queries_with_existing_hints bigint = 0,
        @existing_hints_sample_query_id bigint,
        @existing_hints_sample_text nvarchar(max),
        @multiple_query_hints_sample_query_id bigint,
        @multiple_query_hints_sample_replica_group_id bigint,
        @hint_replica_group_id bigint;

/* Start validation */

IF NOT (
       @sql_server_2022 = 1 OR @sql_server_2025_later = 1 OR @sql_mi_2022 = 1 OR @sql_mi_always_up_to_date = 1 OR @sql_db = 1
       )
    THROW 50001, 'Query Store hints are not supported in this database engine version. Use this stored procedure in SQL Server 2022 and later, in Azure SQL Database, and in Azure SQL Managed Instance.', 1;

EXEC @return = sys.sp_getapplock @Resource = @resource,
                                 @LockMode = 'Exclusive',
                                 @LockOwner = 'Session',
                                 @LockTimeout = 0;
IF @return <> 0
    THROW 50002, 'Could not acquire a lock on the execution of this stored procedure. Multiple concurrent executions are not allowed.', 1;

IF DB_ID() IN (1,2)
    THROW 50003, 'This stored procedure cannot be executed in the ''master'' or ''tempdb'' databases. Create this stored procedure in another database and execute it in the context of that database.', 1;

IF LOWER(@action) COLLATE DATABASE_DEFAULT NOT IN ('set','clear')
BEGIN
    SELECT @message = FORMATMESSAGE('The value ''%s'' specified for the @action parameter is invalid. The valid values are ''set'' and ''clear''.', @action);
    THROW 50004, @message, 1;
END;

IF LOWER(@action) COLLATE DATABASE_DEFAULT = 'set' AND @query_hint_text IS NULL
    THROW 50005, 'Parameter @query_hint_text is required when parameter @action is ''set''.', 1;

IF LOWER(@action) COLLATE DATABASE_DEFAULT = 'clear' AND @query_hint_text IS NOT NULL
    THROW 50006, 'Parameter @query_hint_text must not be specified when parameter @action is ''clear''.', 1;

IF NOT (@sql_server_2025_later = 1 OR @sql_mi_2025_later = 1 OR @sql_mi_always_up_to_date = 1 OR @sql_db = 1) AND @replica_group_id IS NOT NULL
    THROW 50007, 'Parameter @replica_group_id cannot be specified in this database engine version.', 1;

/*
Do not overwrite existing hints if they are different
*/
SELECT @count_queries_with_existing_hints = COUNT(1),
       @existing_hints_sample_query_id = MIN(q.query_id),
       @existing_hints_sample_text = MIN(qh.query_hint_text)
FROM sys.query_store_query AS q
INNER JOIN sys.query_store_query_hints AS qh
ON q.query_id = qh.query_id
WHERE q.query_hash = @query_hash
      AND
      LOWER(qh.query_hint_text) <> LOWER(@query_hint_text) COLLATE DATABASE_DEFAULT
      AND
      (@replica_group_id IS NULL OR qh.replica_group_id = @replica_group_id)
      AND
      LOWER(@action) COLLATE DATABASE_DEFAULT = 'set';

IF @count_queries_with_existing_hints > 0
BEGIN
    SELECT @message = FORMATMESSAGE(
                                   '%I64d queries with query hash %s, including query ID %I64d, already have query hints that are different from those specified, for example ''%s''. Clear existing hints from all queries with this query hash and try again.',
                                   @count_queries_with_existing_hints, CONVERT(varchar(18), @query_hash, 1), @existing_hints_sample_query_id, @existing_hints_sample_text
                                   );
    THROW 50008, @message, 1;
END;

/*
The uniqueness of {query_id, replica_group_id} in sys.query_store_query_hints is not enforced.
Abort if there is more than one row per {query_id, replica_group_id}.
*/
WITH query_replica_group_hint AS
(
SELECT qh.query_id,
       qh.replica_group_id,
       COUNT(1) OVER (PARTITION BY qh.query_id, qh.replica_group_id) AS count_hints
FROM sys.query_store_query AS q
INNER JOIN sys.query_store_query_hints AS qh
ON q.query_id = qh.query_id
WHERE q.query_hash = @query_hash
)
SELECT TOP (1) @multiple_query_hints_sample_query_id = query_id, 
               @multiple_query_hints_sample_replica_group_id = replica_group_id
FROM query_replica_group_hint
WHERE count_hints > 1
ORDER BY query_id ASC, replica_group_id ASC;

IF @@ROWCOUNT > 0
BEGIN
    SELECT @message = FORMATMESSAGE(
                                   'Some queries with query hash %s, including query ID %I64d with replica group ID %I64d, unexpectedly have multiple query hint rows in sys.query_store_query_hints.',
                                   CONVERT(varchar(18), @query_hash, 1), @multiple_query_hints_sample_query_id, @multiple_query_hints_sample_replica_group_id
                                   );
    THROW 50009, @message, 1;
END;

/* End validation */

/* Loop over all queries matching the specified query hash, with or without existing query hints */

DECLARE query_hints CURSOR LOCAL STATIC FOR
SELECT q.query_id,
       qh.replica_group_id
FROM sys.query_store_query AS q
LEFT JOIN sys.query_store_query_hints AS qh
ON q.query_id = qh.query_id
WHERE q.query_hash = @query_hash
ORDER BY query_id ASC;

OPEN query_hints;

WHILE 1 = 1
BEGIN

FETCH NEXT FROM query_hints
INTO @query_id, @hint_replica_group_id;

IF @@FETCH_STATUS <> 0
    BREAK;

/* Set or clear hints for each eligible query */

IF LOWER(@action) COLLATE DATABASE_DEFAULT = 'set'
BEGIN
    IF (@sql_server_2025_later = 1 OR @sql_mi_2025_later = 1 OR @sql_mi_always_up_to_date = 1 OR @sql_db = 1)
       AND
       @replica_group_id IS NOT NULL
    BEGIN
        EXEC sys.sp_query_store_set_hints @query_id = @query_id,
                                          @query_hints = @query_hint_text,
                                          @replica_group_id = @replica_group_id;

        SELECT @message = FORMATMESSAGE('Executed sys.sp_query_store_set_hints to set hints ''%s'' for query ID %I64d and replica group ID %I64d.', @query_hint_text, @query_id, @replica_group_id);
    END;
    ELSE
    BEGIN
        EXEC sys.sp_query_store_set_hints @query_id = @query_id,
                                          @query_hints = @query_hint_text;

        SELECT @message = FORMATMESSAGE('Executed sys.sp_query_store_set_hints to set hints ''%s'' for query ID %I64d.', @query_hint_text, @query_id);
    END;
    
    PRINT @message;
END
ELSE IF LOWER(@action) COLLATE DATABASE_DEFAULT = 'clear'
BEGIN
    IF @replica_group_id <> @hint_replica_group_id
    BEGIN
        SELECT @message = FORMATMESSAGE(
                                       'Skipped executing sys.sp_query_store_clear_hints for query ID %I64d because the replica group ID of the current hint %I64d is different from the specified replica group ID %I64d.',
                                       @query_id, @hint_replica_group_id, @replica_group_id
                                       );
    END
    ELSE IF (@sql_server_2025_later = 1 OR @sql_mi_2025_later = 1 OR @sql_mi_always_up_to_date = 1 OR @sql_db = 1)
            AND
            @replica_group_id IS NOT NULL
    BEGIN
        EXEC sys.sp_query_store_clear_hints @query_id = @query_id,
                                            @replica_group_id = @replica_group_id;

        SELECT @message = FORMATMESSAGE('Executed sys.sp_query_store_clear_hints for query ID %I64d and replica group ID %I64d.', @query_id, @replica_group_id);
    END;
    ELSE
    BEGIN
        EXEC sys.sp_query_store_clear_hints @query_id = @query_id;

        SELECT @message = FORMATMESSAGE('Executed sys.sp_query_store_clear_hints for query ID %I64d.', @query_id);
    END;
    
    PRINT @message;
END;

END;

SELECT @message = FORMATMESSAGE(
                               CONCAT(CHAR(13), CHAR(10), 'Query hash: %s. Queries processed: %d'),
                               CONVERT(varchar(18), @query_hash, 1), @@CURSOR_ROWS
                               );
PRINT @message;

CLOSE query_hints;
DEALLOCATE query_hints;

END TRY
BEGIN CATCH
    THROW;
END CATCH;

BEGIN TRY
    EXEC sys.sp_releaseapplock @Resource = @resource,
                               @LockOwner = 'Session';
END TRY
BEGIN CATCH
END CATCH;
GO