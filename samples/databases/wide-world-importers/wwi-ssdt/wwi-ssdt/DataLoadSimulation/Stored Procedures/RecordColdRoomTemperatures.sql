-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.RecordColdRoomTemperatures;
GO

CREATE PROCEDURE DataLoadSimulation.RecordColdRoomTemperatures
@AverageSecondsBetweenReadings int,
@NumberOfSensors int,
@CurrentDateTime datetime2(7),
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	BEGIN TRAN

    DECLARE @TimeCounter datetime2(7) = CAST(@CurrentDateTime AS date);
    DECLARE @SensorCounter int;
    DECLARE @DelayInSeconds int;
    DECLARE @TimeToFinishForTheDay datetime2(7) = DATEADD(second, -30, DATEADD(day, 1, @TimeCounter));
    DECLARE @Temperature decimal(10,2);

	-- clean up any artifacts from earlier runs
	DELETE FROM DataLoadSimulation.[ColdRoomTemperatures_temp] WITH (SNAPSHOT)

	IF @TimeCounter < @TimeToFinishForTheDay
	BEGIN
		-- seed temporary table with current status of sensors
		DELETE Warehouse.ColdRoomTemperatures WITH (SNAPSHOT)
		OUTPUT deleted.ColdRoomTemperatureID,
			 deleted.ColdRoomSensorNumber,
			 deleted.RecordedWhen,
			 deleted.Temperature,
			 deleted.ValidFrom,
			 @TimeCounter
		INTO DataLoadSimulation.[ColdRoomTemperatures_temp]
			(ColdRoomTemperatureID,
			 ColdRoomSensorNumber,
			 RecordedWhen,
			 Temperature,
			 ValidFrom,
			 ValidTo)

		-- populate data for the day in temp table
		DECLARE @ArchiveEndTime datetime2(7) = DATEADD(second, (0 - @AverageSecondsBetweenReadings),  @TimeToFinishForTheDay)
		EXEC DataLoadSimulation.PopulateColdRoomTemperatures_temp @AverageSecondsBetweenReadings, @NumberOfSensors, @TimeCounter, @ArchiveEndTime

		-- move daily data into archive table
		DELETE DataLoadSimulation.ColdRoomTemperatures_temp WITH (SNAPSHOT)
		OUTPUT deleted.ColdRoomTemperatureID,
			 deleted.ColdRoomSensorNumber,
			 deleted.RecordedWhen,
			 deleted.Temperature,
			 deleted.ValidFrom,
			 deleted.ValidTo
		INTO Warehouse.ColdRoomTemperatures_Archive

		-- add last daily reading to current table
		SET @SensorCounter = 0;
		WHILE @SensorCounter < @NumberOfSensors
		BEGIN
			SET @Temperature = 3 + RAND() * 2;

			INSERT Warehouse.ColdRoomTemperatures
				(ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo)
			VALUES
				(@SensorCounter + 1, @ArchiveEndTime, @Temperature, @ArchiveEndTime, @EndOfTime);

			SET @SensorCounter += 1;
		END;

	END;
	COMMIT
END;
