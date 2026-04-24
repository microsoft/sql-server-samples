CREATE PROCEDURE [DataLoadSimulation].[GetRandomBuyingGroupNotInUse]
  @CityID            AS INT           OUTPUT
, @CityName          AS NVARCHAR(50)  OUTPUT
, @StateProvinceCode AS NVARCHAR(5)   OUTPUT
, @StateProvinceName AS NVARCHAR(50)  OUTPUT
, @AreaCode          AS NVARCHAR(4)   OUTPUT
, @BuyingGroupID     AS INT           OUTPUT
, @BuyingGroupName   AS NVARCHAR(50)  OUTPUT
, @WebDomain         AS NVARCHAR(256) OUTPUT
, @EmailDomain       AS NVARCHAR(256) OUTPUT
, @CustomerName      AS NVARCHAR(100) OUTPUT
AS
BEGIN
/*
Notes:
  Gets a buying group/city combination that will be used
  as a new customer. Get one that is not already in use.

Usage:
  DECLARE @myCityID            AS INT
  DECLARE @myCityName          AS NVARCHAR(50)
  DECLARE @myStateProvinceCode AS NVARCHAR(5)
  DECLARE @myStateProvinceName AS NVARCHAR(50)
  DECLARE @myAreaCode          AS NVARCHAR(4)
  DECLARE @myBuyingGroupID     AS INT
  DECLARE @myBuyingGroupName   AS NVARCHAR(50)
  DECLARE @myWebDomain         AS NVARCHAR(256)
  DECLARE @myEmailDomain       AS NVARCHAR(256)
  DECLARE @myCustomerName      AS NVARCHAR(100)

  EXEC [DataLoadSimulation].[GetRandomBuyingGroupNotInUse]
      @CityID            = @myCityID            OUTPUT
    , @CityName          = @myCityName          OUTPUT
    , @StateProvinceCode = @myStateProvinceCode OUTPUT
    , @StateProvinceName = @myStateProvinceName OUTPUT
    , @AreaCode          = @myAreaCode          OUTPUT
    , @BuyingGroupID     = @myBuyingGroupID     OUTPUT
    , @BuyingGroupName   = @myBuyingGroupName   OUTPUT
    , @WebDomain         = @myWebDomain         OUTPUT
    , @EmailDomain       = @myEmailDomain       OUTPUT
    , @CustomerName      = @myCustomerName      OUTPUT

  SELECT @myCityID, @myCityName, @myStateProvinceCode
       , @myStateProvinceName, @myAreaCode, @myBuyingGroupID
       , @myBuyingGroupName, @myWebDomain, @myEmailDomain
       , @myCustomerName

*/
  DECLARE @InUseCounter AS INT

  SET @InUseCounter = 1 -- Reset from last run
  WHILE @InUseCounter > 0
  BEGIN
    EXEC [DataLoadSimulation].[GetRandomCity]
        @CityID            = @CityID            OUTPUT
      , @CityName          = @CityName          OUTPUT
      , @StateProvinceCode = @StateProvinceCode OUTPUT
      , @StateProvinceName = @StateProvinceName OUTPUT
      , @AreaCode          = @AreaCode          OUTPUT

    EXEC [DataLoadSimulation].[GetRandomBuyingGroup]
        @BuyingGroupID   = @BuyingGroupID   OUTPUT
      , @BuyingGroupName = @BuyingGroupName OUTPUT

    -- See if this is in use, if not it'll exit the loop and
    -- we can continue
    SET @InUseCounter = [DataLoadSimulation].[GetCustomerCount]
      ( @BuyingGroupName
        + ' (' + @CityName + ', '
        + @StateProvinceCode + ')'
      )
  END -- WHILE @InUseCounter > 0

  EXEC [DataLoadSimulation].[GetBuyingGroupDomain]
      @BuyingGroup = @BuyingGroupName
    , @WebDomain   = @WebDomain OUTPUT
    , @EmailDomain = @EmailDomain OUTPUT

  SET @CustomerName = @BuyingGroupName
                    + ' (' + @CityName
                    + ', ' + @StateProvinceCode + ')'

  RETURN 0
END
