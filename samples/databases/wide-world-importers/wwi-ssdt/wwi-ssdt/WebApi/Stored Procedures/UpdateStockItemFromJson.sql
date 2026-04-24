CREATE PROCEDURE [WebApi].[UpdateStockItemFromJson](@StockItem NVARCHAR(MAX), @StockItemID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	
	UPDATE Warehouse.StockItems SET
		StockItemName = ISNULL(json.StockItemName, Warehouse.StockItems.StockItemName),
		SupplierID = ISNULL(json.SupplierID, Warehouse.StockItems.SupplierID),
		ColorID = json.ColorID,
		UnitPackageID = ISNULL(json.UnitPackageID, Warehouse.StockItems.UnitPackageID),
		OuterPackageID = ISNULL(json.OuterPackageID, Warehouse.StockItems.OuterPackageID),
		Brand = json.Brand,
		Size = json.Size,
		LeadTimeDays = ISNULL(json.LeadTimeDays, Warehouse.StockItems.LeadTimeDays),
		QuantityPerOuter = ISNULL(json.QuantityPerOuter, Warehouse.StockItems.QuantityPerOuter),
		IsChillerStock = ISNULL(json.IsChillerStock, Warehouse.StockItems.IsChillerStock),
		Barcode = json.Barcode,
		TaxRate = ISNULL(json.TaxRate, Warehouse.StockItems.TaxRate),
		UnitPrice = ISNULL(json.UnitPrice, Warehouse.StockItems.UnitPrice),
		RecommendedRetailPrice = json.RecommendedRetailPrice,
		TypicalWeightPerUnit = ISNULL(json.TypicalWeightPerUnit, Warehouse.StockItems.TypicalWeightPerUnit),
		MarketingComments = json.MarketingComments,
		InternalComments = json.InternalComments,
		Photo = json.Photo,
		CustomFields = json.CustomFields,
		LastEditedBy = @UserID
	FROM OPENJSON (@StockItem)
		WITH (
			StockItemName nvarchar(100),
			SupplierID int,
			ColorID int,
			UnitPackageID int,
			OuterPackageID int,
			Brand nvarchar(50),
			Size nvarchar(20),
			LeadTimeDays int,
			QuantityPerOuter int,
			IsChillerStock bit,
			Barcode nvarchar(50),
			TaxRate decimal(18,3),
			UnitPrice decimal(18,2),
			RecommendedRetailPrice decimal(18,2),
			TypicalWeightPerUnit decimal(18,3),
			MarketingComments nvarchar(MAX),
			InternalComments nvarchar(MAX),
			Photo varbinary(MAX),
			CustomFields nvarchar(MAX) AS JSON) as json
	WHERE
		Warehouse.StockItems.StockItemID = @StockItemID

END