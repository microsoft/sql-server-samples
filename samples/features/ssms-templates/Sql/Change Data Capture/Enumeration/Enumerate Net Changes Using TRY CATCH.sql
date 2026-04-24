-- ==============================================
-- Enumerate Net Changes Using TRY CATCH Template
-- ==============================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @from_lsn binary(10), @to_lsn binary(10)
SET @from_lsn =
   sys.fn_cdc_get_min_lsn('<capture_instance,sysname,capture_instance>')
SET @to_lsn   = sys.fn_cdc_get_max_lsn()

BEGIN TRY
SELECT * FROM cdc.fn_cdc_get_all_changes_<capture_instance,sysname,capture_instance>
  		(@from_lsn, @to_lsn, N'all')
END TRY

BEGIN CATCH
	DECLARE
        @ERROR_SEVERITY INT,
        @ERROR_STATE INT,
        @ERROR_NUMBER INT,
        @ERROR_LINE INT,
        @ERROR_MESSAGE VARCHAR(245)

    SELECT
        @ERROR_SEVERITY = ERROR_SEVERITY(),
        @ERROR_STATE = ERROR_STATE(),
        @ERROR_NUMBER = ERROR_NUMBER(),
        @ERROR_LINE = ERROR_LINE(),
        @ERROR_MESSAGE = ERROR_MESSAGE()

	IF @ERROR_NUMBER = 313
		RAISERROR(
			'Either a range parameter or the row filter option is not valid.',
			@ERROR_SEVERITY, @ERROR_STATE)
	ELSE
	IF @ERROR_NUMBER = 229
		RAISERROR(
			'The caller is not authorized to perform the query.',
			@ERROR_SEVERITY, @ERROR_STATE)
	ELSE
		RAISERROR('Msg %d, Line %d: %s',
			@ERROR_SEVERITY, @ERROR_STATE, @ERROR_NUMBER,
			@ERROR_LINE, @ERROR_MESSAGE)
END CATCH
GO
