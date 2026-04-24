-- =============================================
-- Declare and using a KEYSET cursor
-- =============================================
DECLARE <cursor_name, sysname, test_cursor> CURSOR
KEYSET
FOR <select_statement, , SELECT au_fname FROM pubs.dbo.authors>

DECLARE @name varchar(40)

OPEN <cursor_name, sysname, test_cursor>

FETCH NEXT FROM <cursor_name, sysname, test_cursor> INTO @name
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
--		PRINT 'add user defined code here'
--		eg.
		PRINT 'updating record for ' + @name
		UPDATE pubs.dbo.authors
		SET phone = replace(phone, ' ', '-')
		WHERE CURRENT OF <cursor_name, sysname, test_cursor>
	END
	FETCH NEXT FROM <cursor_name, sysname, test_cursor> INTO @name
END

CLOSE <cursor_name, sysname, test_cursor>
DEALLOCATE <cursor_name, sysname, test_cursor>
GO

