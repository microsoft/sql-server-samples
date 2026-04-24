-- =================================================
-- Common Table Expression With Averages template
-- =================================================
-- Using a common table expression to limit counts and report averages
-- The following example shows the average number of employees reporting
-- to managers with Adventure Works database.

USE <database_name, sysname, AdventureWorks>;
GO

WITH <CTE_name, sysname, DirReps> (<parent_col,,Manager>, <count_col,,DirectReports>) AS
(
    SELECT <parent_col_id,,ManagerID>, COUNT(*) AS <count_col,,DirectReports>
    FROM <schema_name,,HumanResources>.<table_name,,Employee>
    GROUP BY <parent_col_id,,ManagerID>
)
SELECT AVG(<count_col,,DirectReports>) AS [Average Number of Direct Reports]
FROM <CTE_name, sysname, DirReps>
WHERE <count_col,,DirectReports> >= 2 ;
GO

