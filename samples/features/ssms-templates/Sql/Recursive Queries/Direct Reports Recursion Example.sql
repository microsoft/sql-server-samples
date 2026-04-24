-- ===================================
-- Direct Reports Recursion Example
-- ===================================
-- The following example shows the semantics of the recursive CTE structure by returning a
-- hierarchical list of employees, starting with the highest ranking employee, in the
-- Adventure Works Cycles company. The statement that executes the CTE limits the result
-- set to employees in the Research and Development Group. A walkthrough of the code execution
-- follows the example.

USE <database_name,sysname,AdventureWorks>;
GO

WITH <CTE_name,sysname,DirectReports> (<parent_id_col,,ManagerID>, <child_id_col,,EmployeeID>, Title, DeptID, <level_col,,Level>)
AS
(
-- Anchor member definition
    SELECT e.<parent_id_col,,ManagerID>, e.<child_id_col,,EmployeeID>, e.Title, edh.DepartmentID,
        0 AS <level_col,,Level>
    FROM <schema_name,,HumanResources>.<recursive_table,,Employee> AS e
    INNER JOIN <schema_name,,HumanResources>.EmployeeDepartmentHistory AS edh
        ON e.<child_id_col,,EmployeeID> = edh.<child_id_col,,EmployeeID> AND edh.EndDate IS NULL
    WHERE <parent_id_col,,ManagerID> IS NULL
    UNION ALL
-- Recursive member definition
    SELECT e.<parent_id_col,,ManagerID>, e.<child_id_col,,EmployeeID>, e.Title, edh.DepartmentID,
        <level_col,,Level> + 1
    FROM <schema_name,,HumanResources>.<recursive_table,,Employee> AS e
    INNER JOIN <schema_name,,HumanResources>.EmployeeDepartmentHistory AS edh
        ON e.<child_id_col,,EmployeeID> = edh.<child_id_col,,EmployeeID> AND edh.EndDate IS NULL
    INNER JOIN DirectReports AS d
        ON e.<parent_id_col,,ManagerID> = d.<child_id_col,,EmployeeID>
)
-- Statement that executes the common table expression
SELECT ManagerID, <child_id_col,,EmployeeID>, Title, <level_col,,Level>
FROM <CTE_name,sysname,DirectReports>
INNER JOIN <schema_name,,HumanResources>.Department AS dp
    ON <CTE_name,sysname,DirectReports>.DeptID = dp.DepartmentID
WHERE dp.GroupName = N'Research and Development' OR <level_col,,Level> = 0;
GO

 