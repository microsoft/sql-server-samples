DECLARE @ExtendedEventsSessionName sysname = N'Demo';
DECLARE @StartTime datetimeoffset;
DECLARE @EndTime datetimeoffset;
DECLARE @Offset int;

DROP TABLE IF EXISTS #xmlResults;
CREATE TABLE #xmlResults
(
      xeTimeStamp datetimeoffset NOT NULL
    , xeXML XML NOT NULL
);

SET @StartTime = DATEADD(HOUR, -4, GETDATE()); --modify this to suit your needs
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);


DECLARE @target_data xml;
SELECT @target_data = CONVERT(xml, target_data)
FROM sys.dm_xe_database_sessions AS s
JOIN sys.dm_xe_database_session_targets AS t
    ON t.event_session_address = s.address
WHERE s.name = @ExtendedEventsSessionName
    AND t.target_name = N'ring_buffer';


;WITH src AS
(
    SELECT xeXML = xm.s.query('.')
    FROM @target_data.nodes('/RingBufferTarget/event') AS xm(s)
)
INSERT INTO #xmlResults (xeXML, xeTimeStamp)
SELECT src.xeXML
    , [xeTimeStamp] = src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')
FROM src;

DECLARE @xe xml;

SELECT * FROM (
	SELECT
		[TimeStamp] = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, xr.xeTimeStamp), 120)
		, [Query] = xr.xeXML.query (N'/event/data[11]/value')
	FROM #xmlResults xr
	WHERE xr.xeTimeStamp >= @StartTime
    AND xr.xeTimeStamp<= @EndTime
) AS [t]
WHERE
CONVERT(nvarchar(max), Query) LIKE '%Employees%'
	AND CONVERT(nvarchar(max), Query) LIKE '%SSN%'
	AND CONVERT(nvarchar(max), Query) NOT LIKE '%sp_describe_parameter_encryption%'
	AND CONVERT(nvarchar(max), Query) NOT LIKE '%COUNT%'
ORDER BY [TimeStamp] DESC

