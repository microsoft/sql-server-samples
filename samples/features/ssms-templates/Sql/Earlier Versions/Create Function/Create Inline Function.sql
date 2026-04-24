-- =============================================
-- Create inline function (IF)
-- =============================================
IF EXISTS (SELECT *
	   FROM   sysobjects
	   WHERE  name = N'<inline_function_name, sysname, test_function>')
	DROP FUNCTION <inline_function_name, sysname, test_function>
GO

CREATE FUNCTION <inline_function_name, sysname, test_function>
	(<@param1, sysname, @p1> <data_type_for_param1, , int>,
	 <@param2, sysname, @p2> <data_type_for_param2, , char>)
RETURNS TABLE
AS
	RETURN SELECT   @p1 AS c1,
			@p2 AS c2
GO

-- =============================================
-- Example to execute function
-- =============================================
SELECT *
FROM <owner, , dbo>.<inline_function_name, sysname, test_function>
	(<value_for_@param1, , 1>,
	 <value_for_@param2, , 'a'>)
GO

