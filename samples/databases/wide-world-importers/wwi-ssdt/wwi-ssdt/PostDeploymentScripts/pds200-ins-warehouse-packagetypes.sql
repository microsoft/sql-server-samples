PRINT 'Inserting Warehouse.PackageTypes'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT Warehouse.PackageTypes
  (PackageTypeID, PackageTypeName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (0,'Unknown', 1, @CurrentDateTime, @EndOfTime)
, (1,'Bag', 1, @CurrentDateTime, @EndOfTime)
, (2,'Block', 1, @CurrentDateTime, @EndOfTime)
, (3,'Bottle', 1, @CurrentDateTime, @EndOfTime)
, (4,'Box', 1, @CurrentDateTime, @EndOfTime)
, (5,'Can', 1, @CurrentDateTime, @EndOfTime)
, (6,'Carton', 1, @CurrentDateTime, @EndOfTime)
, (7,'Each', 1, @CurrentDateTime, @EndOfTime)
, (8,'Kg', 1, @CurrentDateTime, @EndOfTime)
, (9,'Packet', 1, @CurrentDateTime, @EndOfTime)
, (10,'Pair', 1, @CurrentDateTime, @EndOfTime)
, (11,'Pallet', 1, @CurrentDateTime, @EndOfTime)
, (12,'Tray', 1, @CurrentDateTime, @EndOfTime)
, (13,'Tub ', 1, @CurrentDateTime, @EndOfTime)
, (14,'Tube', 1, @CurrentDateTime, @EndOfTime)
GO
