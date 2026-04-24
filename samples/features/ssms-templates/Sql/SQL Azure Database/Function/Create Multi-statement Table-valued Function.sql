--=======================================================================
-- Create Multi-statement Table-valued Function for Azure SQL Database
--=======================================================================
IF OBJECT_ID (N'<schema_name, sysname, dbo>.<function_name, sysname, EmployeeByID>') IS NOT NULL
   DROP FUNCTION <schema_name, sysname, dbo>.<function_name, sysname, EmployeeByID>
GO

CREATE FUNCTION <schema_name, sysname, dbo>.<function_name, sysname, fn_FindReports>(<parameter1_name, sysname, @InEmpID> <parameter1_type,,int>)
RETURNS <returned_table_name, sysname, @retFindReports> TABLE
(
    -- columns returned by the function
    <returned_column1_name, sysname, EmployeeID> <returned_column1_datatype, , int> NOT NULL,
    <returned_column2_name, sysname, Name> <returned_column2_datatype, ,nvarchar(255)> NOT NULL,
    <returned_column3_name, sysname, Title> <returned_column3_datatype, ,nvarchar(50)> NOT NULL,
    <returned_column4_name, sysname, EmployeeLevel> <returned_column4_datatype, ,int> NOT NULL
)
AS
-- body of the function
BEGIN
   WITH DirectReports(Name, Title, EmployeeID, EmployeeLevel, Sort) AS
    (SELECT CONVERT(varchar(255), c.FirstName + ' ' + c.LastName),
        e.Title,
        e.EmployeeID,
        1,
        CONVERT(varchar(255), c.FirstName + ' ' + c.LastName)
     FROM HumanResources.Employee AS e
          JOIN Person.Contact AS c ON e.ContactID = c.ContactID
     WHERE e.EmployeeID = @InEmpID
   UNION ALL
     SELECT CONVERT(varchar(255), REPLICATE ('| ' , EmployeeLevel) +
        c.FirstName + ' ' + c.LastName),
        e.Title,
        e.EmployeeID,
        EmployeeLevel + 1,
        CONVERT (varchar(255), RTRIM(Sort) + '| ' + FirstName + ' ' +
                 LastName)
     FROM HumanResources.Employee as e
          JOIN Person.Contact AS c ON e.ContactID = c.ContactID
          JOIN DirectReports AS d ON e.ManagerID = d.EmployeeID
    )
   -- copy the required columns to the result of the function

   INSERT @retFindReports
   SELECT EmployeeID, Name, Title, EmployeeLevel
     FROM DirectReports
   ORDER BY Sort
   RETURN
END
GO


