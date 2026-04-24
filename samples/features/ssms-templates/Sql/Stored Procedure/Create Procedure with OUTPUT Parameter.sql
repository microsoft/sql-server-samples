-- ===============================================
-- Create stored procedure with OUTPUT parameters
-- ===============================================
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
	<@param2, sysname, @p2> <datatype_for_param2, , int>  OUTPUT
AS
	SELECT @p2 = @p2 + @p1
GO

-- =============================================
-- Example to execute the stored procedure
-- =============================================
DECLARE <@variable_for_output_parameter, sysname, @p2_output> <datatype_for_output_parameter, , int>

EXECUTE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name> <value_for_param1, , 1>, <@variable_for_output_parameter, sysname, @p2_output> OUTPUT

SELECT <@variable_for_output_parameter, sysname, @p2_output>
GO

