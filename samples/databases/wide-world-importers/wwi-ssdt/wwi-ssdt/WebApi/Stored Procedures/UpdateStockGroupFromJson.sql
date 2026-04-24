CREATE PROCEDURE [WebApi].[UpdateStockGroupFromJson](@StockGroup NVARCHAR(MAX), @StockGroupID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Warehouse.StockGroups SET
		StockGroupName = json.StockGroupName,
		LastEditedBy = @UserID
	FROM OPENJSON (@StockGroup)
		WITH (StockGroupName nvarchar(50)) as json
	WHERE
		Warehouse.StockGroups.StockGroupID = @StockGroupID

END