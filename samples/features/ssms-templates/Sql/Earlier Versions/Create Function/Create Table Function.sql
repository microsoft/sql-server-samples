-- =============================================
-- Create table function (TF)
-- =============================================
IF EXISTS (SELECT *
	   FROM   sysobjects
	   WHERE  name = N'<table_function_name, sysname, test_function>')
	DROP FUNCTION <table_function_name, sysname, test_function>
GO

CREATE FUNCTION <table_function_name, sysname, test_function>
	(<@param1, sysname, @p1> <data_type_for_param1, , int>,
	 <@param2, sysname, @p2> <data_type_for_param2, , char>)
RETURNS <@table_variable_name, sysname, @table_var> TABLE
	(<column_1, sysname, c1> <data_type_for_column1, , int>,
	 <column_2, sysname, c2> <data_type_for_column2, , int>)
AS
BEGIN
	INSERT <@table_variable_name, sysname, @table_var>
	SELECT 1, 2
	RETURN
END
GO

-- =============================================
-- Example to execute function
-- =============================================
SELECT * FROM <owner, , dbo>.<table_function_name, sysname, test_function>
	(<value_for_@param1, , 1>,
	 <value_for_@param2, , 2>)
GO

