-- =======================================================
-- Create stored procedure with CURSOR OUTPUT parameters
-- =======================================================

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
	<@proc_cursor_name, , @sample_procedure_cursor> CURSOR VARYING OUTPUT
AS
   SET <@proc_cursor_name, , @sample_procedure_cursor> = CURSOR FOR
       <select_statement, , select 1>
   OPEN <@proc_cursor_name, , @sample_procedure_cursor>
GO


-- =============================================
-- Example to execute the stored procedure
-- =============================================
DECLARE <@variable_cursor_name, , @test_cursor_variable> CURSOR

EXEC <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name> <@proc_cursor_name, , @sample_procedure_cursor> = <@variable_cursor_name, , @test_cursor_variable> OUTPUT

WHILE (@@FETCH_STATUS = 0)
BEGIN
    FETCH NEXT FROM <@variable_cursor_name, , @test_cursor_variable>
    PRINT 'put user defined code here'
END

CLOSE <@variable_cursor_name, , @test_cursor_variable>

DEALLOCATE <@variable_cursor_name, , @test_cursor_variable>
GO
