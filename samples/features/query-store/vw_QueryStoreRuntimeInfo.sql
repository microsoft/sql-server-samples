USE [AdventureWorks2016_EXT]
GO

DROP VIEW IF EXISTS [dbo].[vw_QueryStoreRuntimeInfo]
GO

CREATE VIEW [dbo].[vw_QueryStoreRuntimeInfo]
AS
SELECT qt.query_text_id, q.query_id, p.plan_id, qt.query_sql_text, s.name AS ContainingSchema, o.name AS ContainingObject, qt.statement_sql_handle, rsi.start_time, rsi.end_time, rs.execution_type_desc,
	rs.count_executions, rs.avg_duration, rs.max_duration, rs.avg_cpu_time, rs.max_cpu_time, rs.avg_logical_io_reads, rs.max_logical_io_reads, rs.avg_physical_io_reads, rs.max_physical_io_reads,
	rs.avg_logical_io_writes, rs.max_logical_io_writes, rs.avg_query_max_used_memory, rs.max_query_max_used_memory, rs.avg_rowcount, rs.max_rowcount, rs.avg_dop, rs.max_dop
FROM sys.query_store_query_text AS qt INNER JOIN
	sys.query_store_query AS q ON qt.query_text_id = q.query_text_id INNER JOIN
	sys.query_store_plan AS p ON q.query_id = p.query_id LEFT OUTER JOIN
	sys.objects AS o ON q.object_id = o.object_id LEFT OUTER JOIN
	sys.schemas AS s ON s.schema_id = o.schema_id INNER JOIN
	sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id INNER JOIN
	sys.query_store_runtime_stats_interval AS rsi ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
GO


