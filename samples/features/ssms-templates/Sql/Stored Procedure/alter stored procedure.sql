-- ==================================
-- Alter Stored Procedure Template
-- ==================================

ALTER PROCEDURE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>
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
