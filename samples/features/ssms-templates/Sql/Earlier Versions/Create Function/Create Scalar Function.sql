-- =============================================
-- Create scalar function (FN)
-- =============================================
IF EXISTS (SELECT *
	   FROM   sysobjects
	   WHERE  name = N'<scalar_function_name, sysname, test_function>')
	DROP FUNCTION <scalar_function_name, sysname, test_function>
GO

CREATE FUNCTION <scalar_function_name, sysname, test_function>
	(<@param1, sysname, @p1> <data_type_for_param1, , int>,
	 <@param2, sysname, @p2> <data_type_for_param2, , int>)
RETURNS <function_data_type, ,int>
AS
BEGIN
	<function_body, , RETURN @p1 + @p2 >
--	eg.
--	DECLARE @sum AS int
--	SELECT @sum = @p1 + @P2
--	RETURN @sum
END
GO

-- =============================================
-- Example to execute function
-- =============================================
SELECT <owner, , dbo>.<scalar_function_name, sysname, test_function>
	(<value_for_@param1, , 1>,
	 <value_for_@param2, , 2>)
GO

