PRINT 'Inserting Warehouse.PackageTypes'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT Warehouse.StockGroups
  (StockGroupID, StockGroupName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'Novelty Items', 1, @CurrentDateTime, @EndOfTime)
, (2,'Clothing', 1, @CurrentDateTime, @EndOfTime)
, (3,'Mugs', 1, @CurrentDateTime, @EndOfTime)
, (4,'T-Shirts', 1, @CurrentDateTime, @EndOfTime)
, (5,'Airline Novelties', 1, @CurrentDateTime, @EndOfTime)
, (6,'Computing Novelties', 1, @CurrentDateTime, @EndOfTime)
, (7,'USB Novelties', 1, @CurrentDateTime, @EndOfTime)
, (8,'Footwear', 1, @CurrentDateTime, @EndOfTime)
, (9,'Toys', 1, @CurrentDateTime, @EndOfTime)
, (10,'Packaging Materials', 1, @CurrentDateTime, @EndOfTime)
GO
