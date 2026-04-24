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
