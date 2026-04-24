CREATE PROCEDURE [DataLoadSimulation].[PopulateColdRoomTemperatures_temp]
@AverageSecondsBetweenReadings int,
@NumberOfSensors int,
@TimeCounter datetime2(7),
@EndTime datetime2(7)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
	(TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')

	DECLARE @ValidTo datetime2(7)
	DECLARE @DelayInSeconds int
	DECLARE @SensorCounter int
	DECLARE @Temperature decimal(10,2);
	DECLARE @ColdRoomTemperatureID bigint

	SELECT @ColdRoomTemperatureID = ISNULL(MAX(ColdRoomTemperatureID), 0) + 1
	FROM DataLoadSimulation.[ColdRoomTemperatures_temp]

	WHILE @TimeCounter < @EndTime
	BEGIN
		SET @SensorCounter = 0;
		SET @DelayInSeconds = CEILING(RAND() * @AverageSecondsBetweenReadings);
		SET @ValidTo = DATEADD(second, @DelayInSeconds, @TimeCounter);

		WHILE @SensorCounter < @NumberOfSensors
		BEGIN
			SET @Temperature = 3 + RAND() * 2;

			INSERT DataLoadSimulation.[ColdRoomTemperatures_temp]
				(ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo)
			VALUES
				(@ColdRoomTemperatureID, @SensorCounter + 1, @TimeCounter, @Temperature, @TimeCounter, @ValidTo);

			SET @SensorCounter += 1;
			SET @ColdRoomTemperatureID += 1;
		END;
		SET @TimeCounter = @ValidTo
	END;
END;