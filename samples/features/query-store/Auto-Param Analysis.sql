USE [AdventureWorks2016_EXT]
GO

/* (1) Do cardinality analysis when suspect on ad-hoc workloads*/
SELECT COUNT(*) AS CountQueryTextRows FROM sys.query_store_query_text;
SELECT COUNT(*) AS CountQueryRows FROM sys.query_store_query;
SELECT COUNT(DISTINCT query_hash) AS CountDifferentQueryRows FROM sys.query_store_query;
SELECT COUNT(*) AS CountPlanRows FROM sys.query_store_plan;
SELECT COUNT(DISTINCT query_plan_hash) AS CountDifferentPlanRows FROM sys.query_store_plan;

/* (2) Get Compile Vs Execution times: ad-hoc workloads tend to spend lot of time in compilation*/
EXEC sp_GetCompilAndExecutionTotalTime

/* (3) See query pattern*/
SELECT TOP 10 * FROM sys.query_store_query_text


/* (4) I'm not getting new queries?
Look at Query Store parameters - is Query Store in READ_ONLY mode?
*/
SELECT current_storage_size_mb, max_storage_size_mb, desired_state, desired_state_desc, actual_state, actual_state_desc, readonly_reason, flush_interval_seconds,
interval_length_minutes, stale_query_threshold_days, max_plans_per_query, query_capture_mode, query_capture_mode_desc, size_based_cleanup_mode,
size_based_cleanup_mode_desc, actual_state_additional_info
FROM sys.database_query_store_options

ALTER DATABASE [AdventureWorks2016_EXT] SET QUERY_STORE CLEAR;
ALTER DATABASE [AdventureWorks2016_EXT] SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
GO

/* (5) How do we fix the Auto-Param problem?*/

/* At the query level: apply the plan guide for selected query template */
DECLARE @stmt nvarchar(max);
DECLARE @params nvarchar(max);
EXEC sp_get_query_template
    N'select * from part p join partdetails pp on p.partid = pp.partid where p.partid = 46911',
    @stmt OUTPUT,
    @params OUTPUT;

EXEC sp_create_plan_guide
    N'TemplateGuide1',
    @stmt,
    N'TEMPLATE',
    NULL,
    @params,
    N'OPTION(PARAMETERIZATION FORCED)';

/*(6) Alternative (at the database level): force parametrization for all queries*/
ALTER DATABASE [AdventureWorks2016_EXT] SET PARAMETERIZATION FORCED;

/* Run analysis query (1), (2) again to see results of parametrization */

/*(7) Reset the DB state*/
ALTER DATABASE [AdventureWorks2016_EXT] SET PARAMETERIZATION SIMPLE;
GO
EXEC sp_control_plan_guide N'DROP', N'TemplateGuide1';
GO
ALTER DATABASE [AdventureWorks2016_EXT] SET QUERY_STORE CLEAR;
ALTER DATABASE [AdventureWorks2016_EXT] SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
SELECT * FROM sys.database_query_store_options
GO