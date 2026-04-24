SELECT end_time, avg_cpu_percent as [CPU_%], avg_data_io_percent as [IO_%], avg_log_write_percent as [Write_%], avg_storage_percent as [Size_%],
			  max_worker_percent as [Worker_%], max_session_percent as [Session_%], elastic_pool_dtu_limit as [pool_dtu], elastic_pool_storage_limit_mb as [pool_size]
			  FROM sys.elastic_pool_resource_stats
WHERE elastic_pool_name = 'sol-demo-sql-pool'
ORDER BY end_time DESC;

SELECT end_time,
	  (SELECT Max(v)
	   FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS
	   value(v)) AS [avg_DTU_percent],
	   elastic_pool_dtu_limit
FROM sys.elastic_pool_resource_stats
WHERE elastic_pool_name = 'sol-demo-sql-pool'
ORDER BY end_time DESC;


