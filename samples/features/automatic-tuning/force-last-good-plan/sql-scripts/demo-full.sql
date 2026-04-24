/********************************************************
*	SETUP - clear everything
********************************************************/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE current SET QUERY_STORE CLEAR ALL;
ALTER DATABASE current SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = OFF);

/********************************************************
*	PART I
*	Plan regression identification & manual tuning
********************************************************/

-- Execute the query and include "Actual execution plan" in SSMS and show the plan - it should have Hash Match (Aggregate) operator with Columnstore Index Scan
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int', @packagetypeid = 7;
GO 60
-- 1. Execute this query 45-300 times to setup the baseline.
-- If you have QUERY_STORE CAPTURE_POLICY=AUTO increase number in GO <number> to at least 60


-- 2. Execute the procedure that causes plan regression
-- Optionally, include "Actual execution plan" in SSMS and show the plan - it should have Stream Aggregate, Index Seek & Nested Loops
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int',
					@packagetypeid = 0;

-- 3. Start the workload again - verify that is slower.
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int',
					@packagetypeid = 7;
go 20
-- Optionally, include "Actual execution plan" in SSMS and show the plan - it should have Stream Aggregate with Non-clustered index seek.




-- 4. Find a recommendation that can fix this issue:
SELECT reason, score,
	 script = JSON_VALUE(details, '$.implementationDetails.script')
 FROM sys.dm_db_tuning_recommendations;




-- 4.1. Optionally get more detailed information about the regression and recommendation.
SELECT reason, score,
	 script = JSON_VALUE(details, '$.implementationDetails.script'),
	 planForceDetails.[query_id],
	 planForceDetails.[new plan_id],
	 planForceDetails.[recommended plan_id],
	 estimated_gain = (regressedPlanExecutionCount+recommendedPlanExecutionCount)*(regressedPlanCpuTimeAverage-recommendedPlanCpuTimeAverage)/1000000,
	 error_prone = IIF(regressedPlanErrorCount>recommendedPlanErrorCount, 'YES','NO')
 FROM sys.dm_db_tuning_recommendations
     CROSS APPLY OPENJSON (Details, '$.planForceDetails')
                 WITH ( [query_id] int '$.queryId',
                        [new plan_id] int '$.regressedPlanId',
                        [recommended plan_id] int '$.recommendedPlanId',
                        regressedPlanErrorCount int,
                        recommendedPlanErrorCount int,
                        regressedPlanExecutionCount int,
                        regressedPlanCpuTimeAverage float,
                        recommendedPlanExecutionCount int,
                        recommendedPlanCpuTimeAverage float ) as planForceDetails;
-- IMPORTANT NOTE: check is estimated_gain > 10.
-- If estimated_gain < 10 THEN FLGP=ON will not automatically force the plan!!!
-- In that case increase the number of executions in initial workload.
-- Make sure that SQL Engine uses columnstore in original plan and nonclustered index in regressed plan.

-- Note: User can apply script and force the recommended plan to correct the error.
<<Insert T-SQL from the script column here and execute the script>>
-- e.g.: exec sp_query_store_force_plan @query_id = 3, @plan_id = 1

-- 5. Execute the query again - verify that it is faster.
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int', @packagetypeid = 7;
GO 20
-- Optionally, include "Actual execution plan" in SSMS and show the plan - it should have Hash Aggregate & Columnstore again


-- In part II will be shown better approach - automatic tuning.

/********************************************************
*	PART II
*	Automatic tuning
********************************************************/

/********************************************************
*	RESET - clear everything
********************************************************/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE current SET QUERY_STORE CLEAR ALL;

-- Enable automatic tuning on the database:
ALTER DATABASE current
SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON);

-- Verify that actual state on FLGP is ON:
SELECT name, actual_state_desc, status = IIF(desired_state_desc <> actual_state_desc, reason_desc, 'Status:OK')
FROM sys.database_automatic_tuning_options
WHERE name = 'FORCE_LAST_GOOD_PLAN';

-- 1. Start workload - execute procedure 30-300 times like in the phase I
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int',
					@packagetypeid = 7;
GO 60 -- NOTE: This number shoudl be incrased if you don't get a plan change regression.



-- 2. Cause the plan regression
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int',
					@packagetypeid = 0;




-- 3. Start the workload again.
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int', @packagetypeid = 7;
go 20





-- 4. Find a recommendation and check is it in "Verifying" or "Success" state:
SELECT reason, score,
	JSON_VALUE(state, '$.currentValue') state,
	JSON_VALUE(state, '$.reason') state_transition_reason,
    JSON_VALUE(details, '$.implementationDetails.script') script,
    planForceDetails.*
FROM sys.dm_db_tuning_recommendations
  CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            [new plan_id] int '$.regressedPlanId',
            [recommended plan_id] int '$.recommendedPlanId'
          ) as planForceDetails;

		
-- 5. Recommendation is in "Verifying" state, but the last good plan is forced, so the query will be faster:
EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int', @packagetypeid = 7;


-- Open Query Store/"Top Resource Consuming Queries" dialog in SSMS and show that the better plan is forced.

