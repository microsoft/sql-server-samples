-- =======================================================
-- Create stored procedure with CURSOR OUTPUT parameters
-- =======================================================

-- drop stored procedure if it already exists
IF EXISTS (
  SELECT *
    FROM sysobjects
   WHERE name = N'<procedure_name, sysname, sample_procedure>'
	 AND type = 'P'
)
   DROP PROCEDURE <procedure_name, sysname, sample_procedure>
GO

-- create the specified stored procedure
CREATE PROCEDURE <procedure_name, sysname, sample_procedure>
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

EXEC <procedure_name, sysname, sample_procedure> <@proc_cursor_name, , @sample_procedure_cursor> = <@variable_cursor_name, , @test_cursor_variable> OUTPUT

WHILE (@@FETCH_STATUS = 0)
BEGIN
    FETCH NEXT FROM <@variable_cursor_name, , @test_cursor_variable>
    PRINT 'put user defined code here'
END

CLOSE <@variable_cursor_name, , @test_cursor_variable>

DEALLOCATE <@variable_cursor_name, , @test_cursor_variable>
GO
