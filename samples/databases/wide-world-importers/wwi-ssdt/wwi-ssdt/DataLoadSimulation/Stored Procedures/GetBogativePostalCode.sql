CREATE PROCEDURE [DataLoadSimulation].[GetBogativePostalCode]
  @CityID INT
, @PostalCode NVARCHAR(10) OUTPUT
AS
BEGIN

/*
Notes:
  Generates a fake postal code formatted accurately for the country
  needed.

  Note only countries for which data is being generated are included.
  As time goes by this will be expanded.

  If the country is not found then the procedure just defaults to the
  standard US format.

Usage:
  DECLARE @myPostalCode AS NVARCHAR(10)
  EXEC [DataLoadSimulation].[GetBogativePostalCode]
      @CityID = 1
    , @PostalCode = @myPostalCode OUTPUT
  SELECT @myPostalCode

*/

  DECLARE @CountryName AS NVARCHAR(60)

  SELECT TOP 1 @CountryName = o.[CountryName]
    FROM [Application].[Cities] c
    JOIN [Application].[StateProvinces] s
      ON c.StateProvinceID = s.StateProvinceID
    JOIN [Application].[Countries] o
      ON s.CountryID = o.CountryID
   WHERE c.[CityID] = @CityID
     AND c.[ValidTo] = '9999-12-31 23:59:59.9999999'

  -- Generate a fake postal code but formatted for the country
  SET @PostalCode
    = CASE @CountryName
        WHEN 'United States'
        THEN RIGHT('00000' + CAST((ABS(CHECKSUM(NEWID())) % 99999) AS NVARCHAR), 5)
        ELSE RIGHT('00000' + CAST((ABS(CHECKSUM(NEWID())) % 99999) AS NVARCHAR), 5)
      END

END


