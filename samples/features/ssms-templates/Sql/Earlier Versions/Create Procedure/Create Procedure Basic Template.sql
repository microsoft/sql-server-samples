-- =============================================
-- Create basic stored procedure template
-- =============================================
IF EXISTS (
  SELECT *
    FROM sysobjects
   WHERE name = N'<procedure_name, sysname, sample_procedure>'
	 AND type = 'P'
)
  DROP PROCEDURE <procedure_name, sysname, sample_procedure>
GO

CREATE PROCEDURE <procedure_name, sysname, sample_procedure>
	<@param1, sysname, @p1> <datatype_for_param1, , int> = <default_value_for_param1, , 0>,
	<@param2, sysname, @p2> <datatype_for_param2, , int> = <default_value_for_param2, , 0>
AS
	SELECT @p1, @p2
GO

-- =============================================
-- Example to execute the stored procedure
-- =============================================
EXECUTE <procedure_name, sysname, sample_procedure> <value_for_param1, , 1>, <value_for_param2, , 2>
GO

