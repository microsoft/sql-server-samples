CREATE PROCEDURE [DataLoadSimulation].[GetRandomCity]
  @CityID            INT          OUTPUT
, @CityName          NVARCHAR(50) OUTPUT
, @StateProvinceCode NVARCHAR(5)  OUTPUT
, @StateProvinceName NVARCHAR(50) OUTPUT
, @AreaCode          NVARCHAR(4)  OUTPUT
AS
BEGIN
/*
  Usage:
    DECLARE @myCityID            AS INT
    DECLARE @myCityName          AS NVARCHAR(50)
    DECLARE @myStateProvinceCode AS NVARCHAR(5)
    DECLARE @myStateProvinceName AS NVARCHAR(50)
    DECLARE @myAreaCode          AS NVARCHAR(3)

    EXEC [DataLoadSimulation].[GetRandomCity]
      @CityID            = @myCityID            OUTPUT
    , @CityName          = @myCityName          OUTPUT
    , @StateProvinceCode = @myStateProvinceCode OUTPUT
    , @StateProvinceName = @myStateProvinceName OUTPUT
    , @AreaCode          = @myAreaCode          OUTPUT

    SELECT @myCityID , @myCityName, @myStateProvinceCode, @myStateProvinceName, @myAreaCode
*/

  SET @CityID = NULL
  WHILE @CityID IS NULL
  BEGIN
    SELECT TOP 1
           @CityID            = c.[CityID]
         , @CityName          = c.[CityName]
         , @StateProvinceCode = s.[StateProvinceCode]
         , @StateProvinceName = s.[StateProvinceName]
         , @AreaCode          = a.[AreaCode]
      FROM [Application].[Cities] c
      JOIN [Application].[StateProvinces] s
        ON c.[StateProvinceID] = s.[StateProvinceID]
      JOIN [DataLoadSimulation].[AreaCode] a
        ON a.[StateProvinceCode] = s.[StateProvinceCode]
     ORDER BY NEWID()
  END

  RETURN

END;
