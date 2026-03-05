IF EXISTS (SELECT *
      FROM sys.database_event_sessions
      WHERE name = 'Demo')
BEGIN
    DROP EVENT SESSION Demo
          ON Database;
END
go

CREATE EVENT SESSION [Demo] ON DATABASE 
ADD EVENT sqlserver.rpc_completed(SET collect_data_stream=(1),collect_statement=(1)
    ACTION(sqlserver.sql_text)
	WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%SSN%')AND [package0].[not_equal_unicode_string]([statement],N'exec sp_reset_connection'))
	)
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

--CREATE EVENT SESSION [Demo] ON DATABASE 
--ADD EVENT sqlserver.rpc_completed(SET collect_data_stream=(1),collect_statement=(1)
--    	WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'ContosoHR') AND [package0].[not_equal_unicode_string]([statement],N'exec sp_reset_connection')))
--ADD TARGET package0.ring_buffer(SET max_memory=(4096))
--WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=2 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
--GO


ALTER EVENT SESSION [Demo]
      ON DATABASE
    STATE = START;   -- STOP;

