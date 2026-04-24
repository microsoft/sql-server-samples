-- Make sure Optimize for Adhoc Workloads is not active if demo'ing - that is why mt demo failed.

DROP EVENT SESSION [QueryProfileXE] ON SERVER
GO
CREATE EVENT SESSION [QueryProfileXE] ON SERVER
ADD EVENT sqlserver.query_thread_profile(
    ACTION(sqlos.scheduler_id,sqlserver.database_id,sqlserver.is_system,sqlserver.plan_handle,sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text))
ADD TARGET package0.event_file(SET filename=N'C:\Demos\QueryProfileXE.xel',max_file_size=(50),max_rollover_files=(2))
--ADD TARGET package0.ring_buffer(SET max_memory=(25600))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

-- Get Actual Exec plan to compare to XE
--USE AdventureWorks2014
USE AdventureWorks2016CTP3
GO

DBCC FREEPROCCACHE
GO
ALTER EVENT SESSION [QueryProfileXE] ON SERVER STATE = START
GO
SELECT *
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
ORDER BY Style DESC
OPTION (MAXDOP 1)
GO
ALTER EVENT SESSION [QueryProfileXE] ON SERVER STATE = STOP
GO

-- After running query, get plan handle and run below to see new columns in DMV
SELECT * FROM sys.dm_exec_query_stats
WHERE plan_handle = 0x0600050006F60819800281514E02000001000000000000000000000000000000000000000000000000000000
GO
-- And to get the plan from cache
SELECT * FROM sys.dm_exec_query_plan(0x0600050006F60819800281514E02000001000000000000000000000000000000000000000000000000000000)
GO

-- After running query, get new signed query or query plan hash and run below to see new columns in DMV
SELECT * FROM sys.dm_exec_query_stats
WHERE CAST(query_hash AS BIGINT) = -5396503127623128976;
--WHERE CAST(query_plan_hash AS BIGINT) = 3230654061787450360
