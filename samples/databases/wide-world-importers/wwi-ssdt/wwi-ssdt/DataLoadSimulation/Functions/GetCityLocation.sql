CREATE FUNCTION [DataLoadSimulation].[GetCityLocation]
(@CityID INT)
RETURNS GEOGRAPHY
AS
BEGIN
/*
Notes:
  Returns the location for the passed in city id

Usage:
  DECLARE @myLoc GEOGRAPHY = [DataLoadSimulation].[GetCityLocation] (1)
  SELECT @myLoc

*/

  DECLARE @Loc AS GEOGRAPHY

  SELECT TOP 1 @Loc = [Location]
    FROM [Application].Cities
   WHERE CityID = @CityID

  RETURN @Loc

END

