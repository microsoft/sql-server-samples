--======================================================
-- Alter Natively Compiled Stored Procedure Template
--======================================================

ALTER PROCEDURE <Schema_Name, sysname, dbo>.<Procedure_Name, sysname, Procedure_Name>
  -- Add the parameters for the stored procedure here
  <@param1, sysname, @p1> <datatype_for_param1, , int> = <default_value_for_param1, , 0>,
  <@param2, sysname, @p2> <datatype_for_param2, , int> = <default_value_for_param2, , 0>
WITH NATIVE_COMPILATION, SCHEMABINDING
AS BEGIN ATOMIC WITH
(
TRANSACTION ISOLATION LEVEL = <transaction_isolation_level, , SNAPSHOT>, LANGUAGE = <language, , N'us_english'>
)
   --Insert statements for the stored procedure here
SELECT <@param1, sysname, @p1>, <@param2, sysname, @p2>
END
GO

-- =============================================
-- Example to execute the stored procedure
-- =============================================
EXECUTE <Schema_Name, sysname, dbo>.<Procedure_Name, sysname, Procedure_Name> <value_for_param1, , 1>, <value_for_param2, , 2>
GO

