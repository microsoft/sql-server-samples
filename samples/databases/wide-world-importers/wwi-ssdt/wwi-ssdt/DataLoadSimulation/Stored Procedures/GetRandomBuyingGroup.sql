CREATE PROCEDURE [DataLoadSimulation].[GetRandomBuyingGroup]
  @BuyingGroupID   INT          OUTPUT
, @BuyingGroupName NVARCHAR(50) OUTPUT
AS
BEGIN
/*
Notes:
  Retrieves a random buying group.
  1 is reserved for individual buyers, so we want to
  get an ID above that.

Usage:
  DECLARE @BuyingGroupID INT
  DECLARE @BuyingGroupName NVARCHAR(50)
  EXEC [DataLoadSimulation].[GetRandomBuyingGroup]
      @BuyingGroupID   = @BuyingGroupID   OUTPUT
    , @BuyingGroupName = @BuyingGroupName OUTPUT
  SELECT @BuyingGroupID, @BuyingGroupName
*/

  SELECT TOP 1
         @BuyingGroupID = [BuyingGroupID]
       , @BuyingGroupName = [BuyingGroupName]
    FROM [Sales].[BuyingGroups]
   WHERE [ValidTo] = '9999-12-31 23:59:59.9999999'
     AND [BuyingGroupID] > 1
   ORDER BY NEWID()

END
