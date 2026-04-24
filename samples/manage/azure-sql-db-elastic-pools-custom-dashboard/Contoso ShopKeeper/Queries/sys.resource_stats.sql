SELECT Top(12) database_name, end_time, storage_in_megabytes as [Size_MB], avg_cpu_percent as [CPU_%], avg_data_io_percent as [IO_%], avg_log_write_percent as [Write_%],
			  max_worker_percent as [Worker_%], max_session_percent as [Session_%], dtu_limit
FROM sys.resource_stats
WHERE database_name = 'soladventureworkscycles' or database_name = 'soladventureworkscycles2'
order by end_time desc;

SELECT end_time,
  (SELECT Max(v)
   FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS
   value(v)) AS [avg_DTU_percent], dtu_limit
FROM sys.resource_stats
WHERE database_name = 'soladventureworkscycles'
ORDER BY end_time desc
;


SELECT max(end_time) end_time, database_name
FROM sys.resource_stats
WHERE database_name in (
						SELECT d.name
						FROM sys.databases d
						JOIN sys.database_service_objectives slo
						ON d.database_id = slo.database_id
						WHERE elastic_pool_name = 'sol-demo-sql-pool'
						)
GROUP BY database_name
ORDER BY end_time desc
;


SELECT r1.database_name, r1.end_time,
  (SELECT Max(v)
   FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS
   value(v)) AS [avg_DTU_percent],
   dtu_limit
FROM sys.resource_stats r1
JOIN (SELECT max(end_time) end_time, database_name
						FROM sys.resource_stats
						WHERE database_name in (
												SELECT d.name
												FROM sys.databases d
												JOIN sys.database_service_objectives slo
												ON d.database_id = slo.database_id
												WHERE elastic_pool_name = 'sol-demo-sql-pool'
												)
						GROUP BY database_name) r2
ON r1.database_name = r2.database_name AND r1.end_time = r2.end_time
ORDER BY end_time desc
;

