/*

SELECT * FROM sys.dm_db_resource_stats
SELECT * FROM sys.dm_exec_requests
SELECT * FROM sys.dm_db_column_store_row_group_physical_stats

SELECT COUNT(*) FROM [dbo].[MeterMeasurementHistory] with (nolock)
SELECT COUNT(*) FROM [dbo].[MeterMeasurement]

*/
DROP PROCEDURE IF EXISTS [dbo].[InsertMeterMeasurement];
DROP PROCEDURE IF EXISTS [dbo].[InsertMeterMeasurementHistory];
DROP TYPE IF EXISTS [dbo].[udtMeterMeasurement];
DROP TABLE IF EXISTS [dbo].[MeterMeasurement];
DROP TABLE IF EXISTS [dbo].[MeterMeasurementHistory];
DROP VIEW IF EXISTS [dbo].[vwMeterMeasurement]

CREATE TABLE [dbo].[MeterMeasurement]
(
	[MeasurementID] bigint identity(1,1),
	[MeterID] [int] NOT NULL,
	[MeasurementInkWh] [decimal](9, 4) NOT NULL,
	[PostalCode] [nvarchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MeasurementDate] [datetime2](7) NOT NULL,	

	PRIMARY KEY NONCLUSTERED HASH ( MeasurementID) WITH ( BUCKET_COUNT = 10000000)

) WITH (MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY);

ALTER TABLE [MeterMeasurement] ADD INDEX ix NONCLUSTERED HASH (MeterID) WITH ( BUCKET_COUNT = 1000000);

CREATE TABLE [dbo].[MeterMeasurementHistory]
(	
	[MeterID] [int] NOT NULL,
	[MeasurementInkWh] [decimal](9, 4) NOT NULL,
	[PostalCode] [nvarchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MeasurementDate] [datetime2](7) NOT NULL
);

CREATE CLUSTERED COLUMNSTORE INDEX [ix_MeterMeasurementHistory] ON [dbo].[MeterMeasurementHistory] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY];

CREATE TYPE [dbo].[udtMeterMeasurement] AS TABLE(
	[RowID] int NOT NULL,
	[MeterID] [int] NOT NULL,
	[MeasurementInkWh] [decimal](9, 4) NOT NULL,
	[PostalCode] [nvarchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MeasurementDate] [datetime2](7) NOT NULL
	
	INDEX [IX_RowID] NONCLUSTERED HASH ([RowID])WITH ( BUCKET_COUNT = 100000)

) WITH ( MEMORY_OPTIMIZED = ON );
GO
CREATE PROCEDURE [dbo].[InsertMeterMeasurement]
	@Batch AS dbo.udtMeterMeasurement READONLY,
	@BatchSize INT

WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')

	INSERT INTO dbo.MeterMeasurement (MeterID, MeasurementInkWh, PostalCode, MeasurementDate)
	SELECT MeterID, MeasurementInkWh, PostalCode, MeasurementDate FROM @Batch
	
END;
GO
CREATE PROCEDURE [dbo].[InsertMeterMeasurementHistory]
	@MeterID INT
AS
BEGIN
	BEGIN TRAN		
		INSERT INTO dbo.MeterMeasurementHistory (MeterID, MeasurementInkWh, PostalCode, MeasurementDate)
		SELECT MeterID, MeasurementInkWh, PostalCode, MeasurementDate FROM dbo.MeterMeasurement WITH (SNAPSHOT)
		WHERE MeterID = @MeterID

		DELETE FROM dbo.MeterMeasurement WITH (SNAPSHOT) WHERE MeterID = @MeterID
	COMMIT
END;
GO
CREATE VIEW [dbo].[vwMeterMeasurement]
AS
SELECT	PostalCode,
		DATETIMEFROMPARTS(
			YEAR(MeasurementDate),
			MONTH(MeasurementDate),
			DAY(MeasurementDate),
			DATEPART(HOUR,MeasurementDate),
			DATEPART(MINUTE,MeasurementDate),
			DATEPART(ss,MeasurementDate)/1,
			0
		) AS MeasurementDate,
		count(*) AS MeterCount,
		AVG(MeasurementInkWh) AS AvgMeasurementInkWh
FROM	[dbo].[MeterMeasurement] WITH (NOLOCK)
GROUP BY
		PostalCode,
		DATETIMEFROMPARTS(
		YEAR(MeasurementDate),
		MONTH(MeasurementDate),
		DAY(MeasurementDate),
		DATEPART(HOUR,MeasurementDate),
		DATEPART(MINUTE,MeasurementDate),
		DATEPART(ss,MeasurementDate)/1,0);
	GO
