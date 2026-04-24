CREATE PROCEDURE [dbo].[InsertMeterMeasurement]
	@Batch AS dbo.udtMeterMeasurement READONLY,
	@BatchSize INT

WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')

	INSERT INTO dbo.MeterMeasurement (MeterID, MeasurementInkWh, PostalCode, MeasurementDate)
	SELECT MeterID, MeasurementInkWh, PostalCode, MeasurementDate FROM @Batch
	
END;