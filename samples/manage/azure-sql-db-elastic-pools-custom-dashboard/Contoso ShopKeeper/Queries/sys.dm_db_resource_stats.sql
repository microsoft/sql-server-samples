SELECT Top(40) end_time, avg_cpu_percent as [CPU_%], avg_data_io_percent as [IO_%], avg_log_write_percent as [Write_%],
			  avg_memory_usage_percent as [Mem_%], xtp_storage_percent as [Storage_%],
			  max_worker_percent as [Worker_%], max_session_percent as [Session_%], dtu_limit
FROM sys.dm_db_resource_stats;

SELECT Top(40) end_time,
  (SELECT Max(v)
   FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS
   value(v)) AS [avg_DTU_percent], dtu_limit
FROM sys.dm_db_resource_stats
; 