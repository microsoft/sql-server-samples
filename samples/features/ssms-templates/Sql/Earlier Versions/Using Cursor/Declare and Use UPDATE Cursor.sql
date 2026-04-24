-- =============================================
-- Declare and using an UPDATE cursor
-- =============================================
DECLARE <@variable_1, sysname, @v1> <datatype_for_variable_1, sysname, varchar(20)>,
	<@variable_2, sysname, @v2> <datatype_for_variable_2, sysname, varchar(40)>

DECLARE	<cursor_name, sysname, test_cursor> CURSOR
FOR SELECT <column_1, sysname, au_fname>, <column_2, sysname, au_lname> FROM <table_name, sysname, pubs.dbo.authors>
FOR UPDATE of <column_1, sysname, au_fname>

DECLARE @count smallint
SELECT @count = 1

OPEN <cursor_name, sysname, test_cursor>
FETCH NEXT FROM <cursor_name, sysname, test_cursor> INTO <@variable_1, sysname, @v1>, <@variable_2, sysname, @v2>

WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
--		PRINT	'add user-defined code here...'
--		eg
		PRINT 'updating record of ' + @v1 + ' ' + @v2
		UPDATE pubs.dbo.authors
		SET au_fname = @v1 + '-' + CAST(@count AS varchar(4))
		WHERE au_lname = @v2
	END
	FETCH NEXT FROM <cursor_name, sysname, test_cursor> INTO <@variable_1, sysname, @v1>, <@variable_2, sysname, @v2>
	SELECT @count = @count + 1
END

CLOSE <cursor_name, sysname, test_cursor>
DEALLOCATE <cursor_name, sysname, test_cursor>
GO

