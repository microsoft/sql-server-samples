-- =============================================
-- Alter Server Audit Template
-- =============================================

-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER SERVER AUDIT <audit_name,nvarchar,AUDIT_NAME>
    TO FILE(FILEPATH = <filepath,nvarchar,N'file_path'>,
			MAXSIZE=<size,integer,2147483647>,
			MAX_ROLLOVER_FILES =<files,integer,0>,
			RESERVE_DISK_SPACE =<reserve_disk_space,bool,OFF>)
	WITH	(QUEUE_DELAY = <milliseconds,integer,1000>,
			ON_FAILURE = <On_failure,,SHUTDOWN> )
