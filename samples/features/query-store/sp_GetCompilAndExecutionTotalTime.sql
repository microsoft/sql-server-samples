USE [AdventureWorks2016_EXT]
GO

DROP PROCEDURE IF EXISTS sp_GetCompilAndExecutionTotalTime
GO

CREATE PROCEDURE sp_GetCompilAndExecutionTotalTime
AS

DECLARE @totalCompiles int
DECLARE @totalExecutions int
DECLARE @totalCompileTime decimal(18,4)
DECLARE @totalExecutionTime decimal(18,4)

SELECT @totalCompiles = SUM(count_compiles),
	@totalCompileTime = SUM(count_compiles * avg_compile_duration / 1000.)
FROM sys.query_store_plan;

SELECT @totalExecutions = SUM(count_executions),
	@totalExecutionTime = SUM(count_executions * avg_duration / 1000.)
FROM sys.query_store_runtime_stats

SELECT @totalCompiles AS TotalCompiles, @totalExecutions AS TotalExecutions,
@totalCompileTime AS TotalCompileTime, @totalExecutionTime AS TotalDurationTime
GO