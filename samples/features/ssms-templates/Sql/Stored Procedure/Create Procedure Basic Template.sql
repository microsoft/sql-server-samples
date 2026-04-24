-- =============================================
-- Create basic stored procedure template
-- =============================================

-- Drop stored procedure if it already exists
IF EXISTS (
  SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
   WHERE SPECIFIC_SCHEMA = N'<Schema_Name, sysname, Schema_Name>'
     AND SPECIFIC_NAME = N'<Procedure_Name, sysname, Procedure_Name>'
)
   DROP PROCEDURE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>
GO

CREATE PROCEDURE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>
	<@param1, sysname, @p1> <datatype_for_param1, , int> = <default_value_for_param1, , 0>,
	<@param2, sysname, @p2> <datatype_for_param2, , int> = <default_value_for_param2, , 0>
AS
	SELECT @p1, @p2
GO

-- =============================================
-- Example to execute the stored procedure
-- =============================================
EXECUTE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name> <value_for_param1, , 1>, <value_for_param2, , 2>
GO
