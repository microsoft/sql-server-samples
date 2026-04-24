-- ===============================================
-- Create stored procedure with OUTPUT parameters
-- ===============================================
IF EXISTS (
  SELECT name
    FROM   sysobjects
   WHERE name = N'<stored_procedure_name, sysname, your_procedure_name>'
     AND type = 'P'
)
  DROP PROCEDURE <stored_procedure_name, sysname, your_procedure_name>
GO

CREATE PROCEDURE <stored_procedure_name, sysname, your_procedure_name>
	<@param1, sysname, @p1> <datatype_for_param1, , int> = <default_value_for_param1, , 0>,
	<@param2, sysname, @p2> <datatype_for_param2, , int>  OUTPUT
AS
	SELECT @p2 = @p2 + @p1
GO

-- =============================================
-- Example to execute the stored procedure
-- =============================================
DECLARE <@variable_for_output_parameter, sysname, @p2_output> <datatype_for_output_parameter, , int>
EXECUTE <stored_procedure_name, sysname, your_procedure_name> <value_for_param1, , 1>, <@variable_for_output_parameter, sysname, @p2_output> OUTPUT
SELECT <@variable_for_output_parameter, sysname, @p2_output>
GO

