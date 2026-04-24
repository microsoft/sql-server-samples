USE [AdventureWorks2016_EXT]
GO

DROP VIEW IF EXISTS [vw_QueryStoreCompileInfo];
GO

CREATE VIEW [dbo].[vw_QueryStoreCompileInfo]
AS
SELECT qt.query_text_id, q.query_id, p.plan_id, qt.query_sql_text, s.name AS ContainingSchema, o.name AS ContainingObject, q.query_hash, qt.statement_sql_handle, q.is_internal_query,
	q.query_parameterization_type_desc, q.count_compiles AS query_count_compiles, p.query_plan_hash, p.count_compiles AS plan_count_compiles, p.last_compile_start_time, p.engine_version,
	p.compatibility_level, p.query_plan, p.is_trivial_plan, p.is_parallel_plan, p.is_forced_plan
FROM sys.query_store_query_text AS qt INNER JOIN
	sys.query_store_query AS q ON qt.query_text_id = q.query_text_id INNER JOIN
	sys.query_store_plan AS p ON q.query_id = p.query_id LEFT OUTER JOIN
	sys.objects AS o ON q.object_id = o.object_id LEFT OUTER JOIN
	sys.schemas AS s ON s.schema_id = o.schema_id
GO


