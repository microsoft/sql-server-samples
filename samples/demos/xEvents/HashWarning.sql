-- Param Sniffing with Hash Spill

-- Setup
--USE AdventureWorks2014
USE AdventureWorks2016CTP3
GO
DROP TABLE CustomersState
GO
CREATE TABLE CustomersState (CustomerID int PRIMARY KEY, [Address] CHAR(200), [State] CHAR(2))
GO
INSERT INTO CustomersState (CustomerID, [Address])
SELECT CustomerID, 'Address' FROM Sales.Customer
GO
UPDATE CustomersState SET [State] = 'NY' WHERE CustomerID % 100 <> 1
UPDATE CustomersState SET [State] = 'WA' WHERE CustomerID % 100 = 1
GO

UPDATE STATISTICS CustomersState WITH FULLSCAN
GO

CREATE PROCEDURE CustomersByState @State CHAR(2) AS
BEGIN
	DECLARE @CustomerID int
	SELECT @CustomerID = e.CustomerID FROM Sales.Customer e
	INNER JOIN CustomersState es ON e.CustomerID = es.CustomerID
	WHERE es.[State] = @State
	OPTION (MAXDOP 1)
END
GO


-- Create xEvent session
DROP EVENT SESSION [HashSpills] ON SERVER
GO
CREATE EVENT SESSION [HashSpills] ON SERVER
ADD EVENT sqlserver.hash_spill_details(
    ACTION(sqlserver.database_name,sqlserver.is_system,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_nt_username,sqlserver.sql_text)),
ADD EVENT sqlserver.hash_warning(
    ACTION(sqlserver.database_name,sqlserver.is_system,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_nt_username,sqlserver.sql_text))
--ADD TARGET package0.ring_buffer(SET max_memory=(25600))
ADD TARGET package0.event_file(SET filename=N'C:\IP\Tiger\TR23\Demos\Demo 1.1 - Spills\HashSpills.xel',max_file_size=(50),max_rollover_files=(2))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

--Execute the stored procedure first with parameter value ‘WA’ – which will select 1% of data.
DBCC FREEPROCCACHE
GO
ALTER EVENT SESSION [HashSpills] ON SERVER STATE = START
GO
EXEC CustomersByState 'WA'
GO

EXEC CustomersByState 'NY'
GO
ALTER EVENT SESSION [HashSpills] ON SERVER STATE = STOP
GO

/*
Observe the type of Spill = Recursion
Occurs when the build input does not fit into available memory,
resulting in the split of input into multiple partitions that are processed separately.	

If any of these partitions still do not fit into available memory,
it is split into sub-partitions, which are also processed separately.
This splitting process continues until each partition fits into available memory
or until the maximum recursion level is reached.
In this case it stopped at level 1.
*/
