CREATE VIEW [WebApi].[PurchaseOrderLines]
AS
SELECT	ol.PurchaseOrderLineID, ol.PurchaseOrderID, ol.Description, ol.IsOrderLineFinalized,
		ProductName = si.StockItemName, si.Brand, si.Size, c.ColorName, pt.PackageTypeName,
		ol.ReceivedOuters, ol.OrderedOuters, ol.ExpectedUnitPricePerOuter
FROM	Purchasing.PurchaseOrderLines ol
		INNER JOIN Warehouse.StockItems si
			ON ol.StockItemID = si.StockItemID
			INNER JOIN Warehouse.Colors c
				ON c.ColorID = si.ColorID
		INNER JOIN Warehouse.PackageTypes pt
			ON ol.PackageTypeID = pt.PackageTypeID
