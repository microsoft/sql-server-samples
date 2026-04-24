CREATE VIEW [WebApi].[StockItems]
AS
SELECT	si.StockItemID, si.StockItemName, s.SupplierName, s.SupplierReference, c.ColorName,
		opt.PackageTypeName AS OuterPackage, upt.PackageTypeName AS UnitPackage,
		si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter, si.IsChillerStock,
		si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice, si.TypicalWeightPerUnit,
		si.MarketingComments, si.InternalComments, si.CustomFields, sih.QuantityOnHand, sih.BinLocation,
		sih.LastStocktakeQuantity, sih.LastCostPrice, sih.ReorderLevel, sih.TargetStockLevel,
		si.SupplierID, si.ColorID, si.UnitPackageID, si.OuterPackageID
FROM	Warehouse.StockItems AS si
		INNER JOIN Warehouse.StockItemHoldings AS sih ON si.StockItemID = sih.StockItemID
		INNER JOIN Purchasing.Suppliers AS s ON si.SupplierID = s.SupplierID
		INNER JOIN Warehouse.Colors AS c ON si.ColorID = c.ColorID
		INNER JOIN Warehouse.PackageTypes AS opt ON si.OuterPackageID = opt.PackageTypeID
		INNER JOIN Warehouse.PackageTypes AS upt ON si.UnitPackageID = upt.PackageTypeID
