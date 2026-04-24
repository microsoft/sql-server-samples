
CREATE PROCEDURE DataLoadSimulation.RecordDeliveryVanTemperatures
@AverageSecondsBetweenReadings int,
@NumberOfSensors int,
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Recording delivery van temperatures for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @VehicleRegistration nvarchar(20) = N'WWI-321-A';

    DECLARE @TimeCounter datetime2(7) = @StartingWhen;
    DECLARE @SensorCounter int;
    DECLARE @DelayInSeconds int;
    DECLARE @MidnightToday datetime2(7) = CAST(@StartingWhen AS date);
    DECLARE @TimeToFinishForTheDay datetime2(7) = DATEADD(hour, 16, @MidnightToday);
    DECLARE @Temperature decimal(10,2);
    DECLARE @FullSensorData nvarchar(1000);
    DECLARE @Latitude decimal(18,7);
    DECLARE @Longitude decimal(18,7);
    DECLARE @IsCompressed bit;

    WHILE @TimeCounter < @TimeToFinishForTheDay
    BEGIN
        SET @SensorCounter = 0;
        WHILE @SensorCounter < @NumberOfSensors
        BEGIN
            SET @Temperature = 3 + RAND() * 2;
            SET @Latitude = 37.78352 + RAND() * 30;
            SET @Longitude = -122.4169 + RAND() * 40;

            SET @IsCompressed = CASE WHEN @TimeCounter < '20220101' THEN 1 ELSE 0 END;

            SET @FullSensorData = N'{"Recordings": '
              + N'['
              + N'{"type":"Feature", "geometry": {"type":"Point", "coordinates":['
              + CAST(@Longitude AS nvarchar(20)) + N',' + CAST(@Latitude AS nvarchar(20))
              + N'] }, "properties":{"rego":"' + STRING_ESCAPE(@VehicleRegistration, N'json')
              + N'","sensor":' + CAST(@SensorCounter + 1 AS nvarchar(20))
              + N',"when":"' + CONVERT(nvarchar(30), @TimeCounter, 126)
              + N'","temp":' + CAST(@Temperature AS nvarchar(20))
              + N'}} ]'
              + N'}';

            INSERT Warehouse.VehicleTemperatures
                (VehicleRegistration, ChillerSensorNumber,
                 RecordedWhen, Temperature,
                 FullSensorData, IsCompressed, CompressedSensorData)
            VALUES
                (@VehicleRegistration, @SensorCounter + 1,
                 @TimeCounter, @Temperature,
                 CASE WHEN @IsCompressed = 0 THEN @FullSensorData END,
                 @IsCompressed,
                 CASE WHEN @IsCompressed <> 0 THEN COMPRESS(@FullSensorData) END);

            SET @SensorCounter += 1;
        END;
        SET @DelayInSeconds = CEILING(RAND() * @AverageSecondsBetweenReadings);
        SET @TimeCounter = DATEADD(second, @DelayInSeconds, @TimeCounter);
    END;
END;