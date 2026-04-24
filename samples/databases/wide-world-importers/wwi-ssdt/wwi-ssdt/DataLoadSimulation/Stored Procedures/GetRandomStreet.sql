CREATE PROCEDURE [DataLoadSimulation].[GetRandomStreet]
@randomStreet NVARCHAR(50) OUTPUT
AS
BEGIN
/*
Notes:
  This procedure will randomly select a street name from the table
  variable loaded herein.

  While it would be preferable to have implemented this as a function,
  the NEWID mechanism needed to make this work are not allowed within
  a function hence the requirement to implement in a stored procedure.

Usage:
  DECLARE @r AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreet] @randomStreet = @r OUTPUT;
  SELECT @r
*/

  DECLARE @fullStreet AS NVARCHAR(50)
  DECLARE @streetNumber AS NVARCHAR(10)

  SET @streetNumber = CAST((ABS(CHECKSUM(NEWID())) % 8999) + 100 AS NVARCHAR)

  DECLARE @streetName AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreetName] @randomStreetName = @streetName OUTPUT;

  DECLARE @streetSuffix AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreetSuffix] @randomStreetSuffix = @streetSuffix OUTPUT;

  SET @randomStreet = @streetNumber + N' '
                    + @streetName + N' '
                    + @streetSuffix

END;

