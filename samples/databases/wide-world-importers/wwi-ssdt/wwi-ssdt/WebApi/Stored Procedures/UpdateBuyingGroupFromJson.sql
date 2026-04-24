CREATE PROCEDURE [WebApi].[UpdateBuyingGroupFromJson](@BuyingGroup NVARCHAR(MAX), @BuyingGroupID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Sales.BuyingGroups SET
		BuyingGroupName = json.BuyingGroupName,
		LastEditedBy = @UserID
	FROM OPENJSON (@BuyingGroup)
		WITH (BuyingGroupName nvarchar(50)) as json
	WHERE
		Sales.BuyingGroups.BuyingGroupID = @BuyingGroupID
END