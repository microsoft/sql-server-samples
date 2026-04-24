-- =================================================
-- Compute CPS for Recent Log Scan Sessions Template
-- =================================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @command_count bigint,
	@duration int,
	@total_commands bigint,
	@total_duration int

DECLARE @log_scan_sessions TABLE(
	session_id				int,
	start_time				datetime,
	end_time				datetime,	
	duration				int,
	scan_phase				nvarchar(200),
	error_count				int,
	start_lsn				nvarchar(24),
	current_lsn				nvarchar(24),
	end_lsn					nvarchar(24),
	tran_count				bigint,
	last_commit_lsn			nvarchar(24),
	last_commit_time		datetime,
	log_record_count		bigint,
	schema_change_count		int,
	command_count			bigint,
	first_begin_cdc_lsn		nvarchar(24),
	last_commit_cdc_lsn		nvarchar(24),
	last_commit_cdc_time	datetime,
	latency					int,
	empty_scan_count		int,
	failed_sessions_count	int)
	
INSERT INTO @log_scan_sessions
SELECT * FROM [sys].[dm_cdc_log_scan_sessions]
WHERE empty_scan_count = 0
AND   session_id <> 0

SET @total_commands = 0
SET @total_duration = 0

DECLARE #session CURSOR LOCAL fast_forward
FOR
	SELECT command_count, duration
	FROM @log_scan_sessions

OPEN #session
FETCH #session INTO @command_count, @duration
	
WHILE (@@fetch_status <> -1)
BEGIN

	SET @total_commands = @total_commands + @command_count
	SET @total_duration = @total_duration + @duration
	
	FETCH #session INTO @command_count, @duration
END

SELECT (@total_commands / @total_duration) AS "Commands Per Second"
	
CLOSE #session
DEALLOCATE #session
GO
	
	