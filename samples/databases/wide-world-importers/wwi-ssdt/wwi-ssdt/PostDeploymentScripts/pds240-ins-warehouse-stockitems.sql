PRINT 'Inserting Warehouse.StockItems'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

-- Rather than looking up some of these IDs on every row,
-- we'll look them up once at the start
-- Fetch Supplier IDs
DECLARE @SupplierIDPhoneCo   INT
DECLARE @SupplierIDGDI       INT
DECLARE @SupplierIDNorthwind INT
DECLARE @SupplierIDFabrikam  INT
DECLARE @SupplierIDContoso   INT
DECLARE @SupplierIDLitware   INT
SELECT @SupplierIDPhoneCo   = SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'The Phone Company'
SELECT @SupplierIDGDI       = SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'Graphic Design Institute'
SELECT @SupplierIDNorthwind = SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'Northwind Electric Cars'
SELECT @SupplierIDFabrikam  = SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'Fabrikam, Inc.'
SELECT @SupplierIDContoso   = SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'Contoso, Ltd.'
SELECT @SupplierIDLitware   = SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'Litware, Inc.'

-- Package Types
DECLARE @PackageTypeIDEach   INT
DECLARE @PackageTypeIDCarton INT
DECLARE @PackageTypeIDPair   INT
DECLARE @PackageTypeIDPacket INT
SELECT @PackageTypeIDEach   = PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Each'
SELECT @PackageTypeIDCarton = PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'
SELECT @PackageTypeIDPair   = PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Pair'
SELECT @PackageTypeIDPacket = PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Packet'

-- Colors
DECLARE @ColorIDWhite      INT
DECLARE @ColorIDBlack      INT
DECLARE @ColorIDNone       INT
DECLARE @ColorIDGreen      INT
DECLARE @ColorIDRed        INT
DECLARE @ColorIDBlue       INT
DECLARE @ColorIDYellow     INT
DECLARE @ColorIDPink       INT
DECLARE @ColorIDGray       INT
DECLARE @ColorIDLightBrown INT
DECLARE @ColorIDBrown      INT
DECLARE @ColorIDNull       INT
SELECT @ColorIDWhite      = ColorID FROM Warehouse.Colors WHERE ColorName = N'White'
SELECT @ColorIDBlack      = ColorID FROM Warehouse.Colors WHERE ColorName = N'Black'
SELECT @ColorIDNone       = ColorID FROM Warehouse.Colors WHERE ColorName = N''
SELECT @ColorIDGreen      = ColorID FROM Warehouse.Colors WHERE ColorName = N'Green'
SELECT @ColorIDRed        = ColorID FROM Warehouse.Colors WHERE ColorName = N'Red'
SELECT @ColorIDBlue       = ColorID FROM Warehouse.Colors WHERE ColorName = N'Blue'
SELECT @ColorIDYellow     = ColorID FROM Warehouse.Colors WHERE ColorName = N'Yellow'
SELECT @ColorIDPink       = ColorID FROM Warehouse.Colors WHERE ColorName = N'Pink'
SELECT @ColorIDGray       = ColorID FROM Warehouse.Colors WHERE ColorName = N'Gray'
SELECT @ColorIDLightBrown = ColorID FROM Warehouse.Colors WHERE ColorName = N'Light Brown'
SELECT @ColorIDBrown      = ColorID FROM Warehouse.Colors WHERE ColorName = N'Brown'
SELECT @ColorIDNull       = ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'

INSERT Warehouse.StockItems
  (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'USB missile launcher (Green)', @SupplierIDPhoneCo, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,25,37.38,0.3,'Complete with 12 projectiles', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (2,'USB rocket launcher (Gray)', @SupplierIDPhoneCo, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,25,37.38,0.3,'Complete with 12 projectiles', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (3,'Office cube periscope (Black)', @SupplierIDPhoneCo, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL, NULL, 14, 10,0, NULL, 15, 18.5,27.66,0.25,'Need to see over your cubicle wall? This is just what''s needed.', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (4,'USB food flash drive - sushi roll', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (5,'USB food flash drive - hamburger', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (6,'USB food flash drive - hot dog', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (7,'USB food flash drive - pizza slice', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (8,'USB food flash drive - dim sum 10 drive variety pack', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDPacket, @PackageTypeIDPacket, NULL, NULL, 14, 1,0, NULL, 15,240,358.8,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (9,'USB food flash drive - banana', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (10,'USB food flash drive - chocolate bar', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (11,'USB food flash drive - cookie', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (12,'USB food flash drive - donut', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (13,'USB food flash drive - shrimp cocktail', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (14,'USB food flash drive - fortune cookie', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 14, 1,0, NULL, 15,32,47.84,0.05, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (15,'USB food flash drive - dessert 10 drive variety pack', @SupplierIDPhoneCo, @ColorIDNone, @PackageTypeIDPacket, @PackageTypeIDPacket, NULL, NULL, 14, 1,0, NULL, 15,240,358.8,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (16,'DBA joke mug - mind if I join you? (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (17,'DBA joke mug - mind if I join you? (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (18,'DBA joke mug - daaaaaa-ta (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (19,'DBA joke mug - daaaaaa-ta (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (20,'DBA joke mug - you might be a DBA if (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (21,'DBA joke mug - you might be a DBA if (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (22,'DBA joke mug - it depends (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (23,'DBA joke mug - it depends (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (24,'DBA joke mug - I will get you in order (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (25,'DBA joke mug - I will get you in order (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (26,'DBA joke mug - SELECT caffeine FROM mug (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (27,'DBA joke mug - SELECT caffeine FROM mug (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (28,'DBA joke mug - two types of DBAs (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (29,'DBA joke mug - two types of DBAs (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (30,'Developer joke mug - Oct 31 = Dec 25 (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (31,'Developer joke mug - Oct 31 = Dec 25 (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (32,'Developer joke mug - that''s a hardware problem (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (33,'Developer joke mug - that''s a hardware problem (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (34,'Developer joke mug - fun was unexpected at this time (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (35,'Developer joke mug - fun was unexpected at this time (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (36,'Developer joke mug - when your hammer is C++ (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (37,'Developer joke mug - when your hammer is C++ (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (38,'Developer joke mug - inheritance is the OO way to become wealthy (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (39,'Developer joke mug - inheritance is the OO way to become wealthy (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (40,'Developer joke mug - (hip, hip, array) (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (41,'Developer joke mug - (hip, hip, array) (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (42,'Developer joke mug - understanding recursion requires understanding recursion (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (43,'Developer joke mug - understanding recursion requires understanding recursion (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (44,'Developer joke mug - there are 10 types of people in the world (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (45,'Developer joke mug - there are 10 types of people in the world (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (46,'Developer joke mug - a foo walks into a bar (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (47,'Developer joke mug - a foo walks into a bar (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (48,'Developer joke mug - this code was generated by a tool (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (49,'Developer joke mug - this code was generated by a tool (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (50,'Developer joke mug - old C developers never die (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (51,'Developer joke mug - old C developers never die (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (52,'IT joke mug - keyboard not found � press F1 to continue (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (53,'IT joke mug - keyboard not found � press F1 to continue (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (54,'IT joke mug - that behavior is by design (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (55,'IT joke mug - that behavior is by design (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (56,'IT joke mug - hardware: part of the computer that can be kicked (White)', @SupplierIDGDI, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (57,'IT joke mug - hardware: part of the computer that can be kicked (Black)', @SupplierIDGDI, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL, 12, 1,0, NULL, 15, 13, 19.44,0.15, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (58,'RC toy sedan car with remote control (Black) 1/50 scale', @SupplierIDNorthwind, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,25,37.38, 1.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (59,'RC toy sedan car with remote control (Red) 1/50 scale', @SupplierIDNorthwind, @ColorIDRed, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,25,37.38, 1.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (60,'RC toy sedan car with remote control (Blue) 1/50 scale', @SupplierIDNorthwind, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,25,37.38, 1.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (61,'RC toy sedan car with remote control (Green) 1/50 scale', @SupplierIDNorthwind, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,25,37.38, 1.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (62,'RC toy sedan car with remote control (Yellow) 1/50 scale', @SupplierIDNorthwind, @ColorIDYellow, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,25,37.38, 1.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (63,'RC toy sedan car with remote control (Pink) 1/50 scale', @SupplierIDNorthwind, @ColorIDPink, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,25,37.38, 1.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (64,'RC vintage American toy coupe with remote control (Red) 1/50 scale', @SupplierIDNorthwind, @ColorIDRed, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,30,44.85, 1.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (65,'RC vintage American toy coupe with remote control (Black) 1/50 scale', @SupplierIDNorthwind, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,30,44.85, 1.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (66,'RC big wheel monster truck with remote control (Black) 1/50 scale', @SupplierIDNorthwind, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/50 scale', 14, 1,0, NULL, 15,45,67.28, 1.8, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (67,'Ride on toy sedan car (Black) 1/12 scale', @SupplierIDNorthwind, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,230,343.85, 15,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (68,'Ride on toy sedan car (Red) 1/12 scale', @SupplierIDNorthwind, @ColorIDRed, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,230,343.85, 15,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (69,'Ride on toy sedan car (Blue) 1/12 scale', @SupplierIDNorthwind, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,230,343.85, 15,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (70,'Ride on toy sedan car (Green) 1/12 scale', @SupplierIDNorthwind, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,230,343.85, 15,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (71,'Ride on toy sedan car (Yellow) 1/12 scale', @SupplierIDNorthwind, @ColorIDYellow, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,230,343.85, 15,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (72,'Ride on toy sedan car (Pink) 1/12 scale', @SupplierIDNorthwind, @ColorIDPink, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,230,343.85, 15,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (73,'Ride on vintage American toy coupe (Red) 1/12 scale', @SupplierIDNorthwind, @ColorIDRed, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,285,426.08, 18,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (74,'Ride on vintage American toy coupe (Black) 1/12 scale', @SupplierIDNorthwind, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,285,426.08, 18,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (75,'Ride on big wheel monster truck (Black) 1/12 scale', @SupplierIDNorthwind, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach,'Northwind','1/12 scale', 14, 1,0, NULL, 15,345,515.78,21,'Suits child to 20 kg', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (76,'"The Gu" red shirt XML tag t-shirt (White) 3XS', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'3XS',7, 12,0, NULL, 15, 18,26.91,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (77,'"The Gu" red shirt XML tag t-shirt (White) XXS', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XXS',7, 12,0, NULL, 15, 18,26.91,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (78,'"The Gu" red shirt XML tag t-shirt (White) XS', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XS',7, 12,0, NULL, 15, 18,26.91,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (79,'"The Gu" red shirt XML tag t-shirt (White) S', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'S',7, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (80,'"The Gu" red shirt XML tag t-shirt (White) M', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'M',7, 12,0, NULL, 15, 18,26.91,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (81,'"The Gu" red shirt XML tag t-shirt (White) L', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'L',7, 12,0, NULL, 15, 18,26.91,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (82,'"The Gu" red shirt XML tag t-shirt (White) XL', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XL',7, 12,0, NULL, 15, 18,26.91,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (83,'"The Gu" red shirt XML tag t-shirt (White) XXL', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XXL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (84,'"The Gu" red shirt XML tag t-shirt (White) 3XL', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'3XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (85,'"The Gu" red shirt XML tag t-shirt (White) 4XL', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'4XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (86,'"The Gu" red shirt XML tag t-shirt (White) 5XL', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'5XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (87,'"The Gu" red shirt XML tag t-shirt (White) 6XL', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'6XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (88,'"The Gu" red shirt XML tag t-shirt (White) 7XL', @SupplierIDFabrikam, @ColorIDWhite, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'7XL',7, 12,0, NULL, 15, 18,26.91,0.45, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (89,'"The Gu" red shirt XML tag t-shirt (Black) 3XS', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'3XS',7, 12,0, NULL, 15, 18,26.91,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (90,'"The Gu" red shirt XML tag t-shirt (Black) XXS', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XXS',7, 12,0, NULL, 15, 18,26.91,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (91,'"The Gu" red shirt XML tag t-shirt (Black) XS', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XS',7, 12,0, NULL, 15, 18,26.91,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (92,'"The Gu" red shirt XML tag t-shirt (Black) S', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'S',7, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (93,'"The Gu" red shirt XML tag t-shirt (Black) M', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'M',7, 12,0, NULL, 15, 18,26.91,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (94,'"The Gu" red shirt XML tag t-shirt (Black) L', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'L',7, 12,0, NULL, 15, 18,26.91,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (95,'"The Gu" red shirt XML tag t-shirt (Black) XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XL',7, 12,0, NULL, 15, 18,26.91,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (96,'"The Gu" red shirt XML tag t-shirt (Black) XXL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XXL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (97,'"The Gu" red shirt XML tag t-shirt (Black) 3XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'3XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (98,'"The Gu" red shirt XML tag t-shirt (Black) 4XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'4XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (99,'"The Gu" red shirt XML tag t-shirt (Black) 5XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'5XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (100,'"The Gu" red shirt XML tag t-shirt (Black) 6XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'6XL',7, 12,0, NULL, 15, 18,26.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (101,'"The Gu" red shirt XML tag t-shirt (Black) 7XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'7XL',7, 12,0, NULL, 15, 18,26.91,0.45, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (102,'Alien officer hoodie (Black) XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XL', 12, 1,0, NULL, 15,35,52.33,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (103,'Alien officer hoodie (Black) XXL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XXL', 12, 1,0, NULL, 15,35,52.33,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (104,'Alien officer hoodie (Black) 3XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'3XL', 12, 1,0, NULL, 15,35,52.33,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (105,'Alien officer hoodie (Black) 4XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'4XL', 12, 1,0, NULL, 15,35,52.33,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (106,'Alien officer hoodie (Black) 5XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'5XL', 12, 1,0, NULL, 15,35,52.33,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (107,'Superhero action jacket (Blue) 3XS', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'3XS', 12, 1,0, NULL, 15,25,37.38,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (108,'Superhero action jacket (Blue) XXS', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XXS', 12, 1,0, NULL, 15,25,37.38,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (109,'Superhero action jacket (Blue) XS', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XS', 12, 1,0, NULL, 15,25,37.38,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (110,'Superhero action jacket (Blue) S', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'S', 12, 1,0, NULL, 15,25,37.38,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (111,'Superhero action jacket (Blue) M', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'M', 12, 1,0, NULL, 15,30,44.85,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (112,'Superhero action jacket (Blue) L', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'L', 12, 1,0, NULL, 15,30,44.85,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (113,'Superhero action jacket (Blue) XL', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XL', 12, 1,0, NULL, 15,30,44.85,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (114,'Superhero action jacket (Blue) XXL', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XXL', 12, 1,0, NULL, 15,30,44.85,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (115,'Superhero action jacket (Blue) 3XL', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'3XL', 12, 1,0, NULL, 15,34,50.83,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (116,'Superhero action jacket (Blue) 4XL', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'4XL', 12, 1,0, NULL, 15,34,50.83,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (117,'Superhero action jacket (Blue) 5XL', @SupplierIDFabrikam, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'5XL', 12, 1,0, NULL, 15,34,50.83,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (118,'Dinosaur battery-powered slippers (Green) S', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'S', 12, 1,0, NULL, 15,32,47.84,0.35,'Realistic sound of undergrowth being trampled while walking', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (119,'Dinosaur battery-powered slippers (Green) M', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'M', 12, 1,0, NULL, 15,32,47.84,0.35,'Realistic sound of undergrowth being trampled while walking', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (120,'Dinosaur battery-powered slippers (Green) L', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'L', 12, 1,0, NULL, 15,32,47.84,0.35,'Realistic sound of undergrowth being trampled while walking', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (121,'Dinosaur battery-powered slippers (Green) XL', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XL', 12, 1,0, NULL, 15,32,47.84,0.4,'Realistic sound of undergrowth being trampled while walking', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (122,'Ogre battery-powered slippers (Green) S', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'S', 12, 1,0, NULL, 15,32,47.84,0.35,'Realistic heavy walking sound', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (123,'Ogre battery-powered slippers (Green) M', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'M', 12, 1,0, NULL, 15,32,47.84,0.35,'Realistic heavy walking sound', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (124,'Ogre battery-powered slippers (Green) L', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'L', 12, 1,0, NULL, 15,32,47.84,0.35,'Realistic heavy walking sound', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (125,'Ogre battery-powered slippers (Green) XL', @SupplierIDFabrikam, @ColorIDGreen, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XL', 12, 1,0, NULL, 15,32,47.84,0.4,'Realistic heavy walking sound', NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (126,'Plush shark slippers (Gray) S', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'S', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (127,'Plush shark slippers (Gray) M', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'M', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (128,'Plush shark slippers (Gray) L', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'L', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (129,'Plush shark slippers (Gray) XL', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XL', 12, 1,0, NULL, 15,32,47.84,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (130,'Furry gorilla with big eyes slippers (Black) S', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'S', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (131,'Furry gorilla with big eyes slippers (Black) M', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'M', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (132,'Furry gorilla with big eyes slippers (Black) L', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'L', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (133,'Furry gorilla with big eyes slippers (Black) XL', @SupplierIDFabrikam, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XL', 12, 1,0, NULL, 15,32,47.84,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (134,'Animal with big feet slippers (Brown) S', @SupplierIDFabrikam, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'S', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (135,'Animal with big feet slippers (Brown) M', @SupplierIDFabrikam, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'M', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (136,'Animal with big feet slippers (Brown) L', @SupplierIDFabrikam, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'L', 12, 1,0, NULL, 15,32,47.84,0.35, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (137,'Animal with big feet slippers (Brown) XL', @SupplierIDFabrikam, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'XL', 12, 1,0, NULL, 15,32,47.84,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (138,'Furry animal socks (Pink) S', @SupplierIDFabrikam, @ColorIDPink, @PackageTypeIDPair, @PackageTypeIDPacket, NULL,'S', 12, 12,0, NULL, 15,5,7.48,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (139,'Furry animal socks (Pink) M', @SupplierIDFabrikam, @ColorIDPink, @PackageTypeIDPair, @PackageTypeIDPacket, NULL,'M', 12, 12,0, NULL, 15,5,7.48,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (140,'Furry animal socks (Pink) L', @SupplierIDFabrikam, @ColorIDPink, @PackageTypeIDPair, @PackageTypeIDPacket, NULL,'L', 12, 12,0, NULL, 15,5,7.48,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (141,'Furry animal socks (Pink) XL', @SupplierIDFabrikam, @ColorIDPink, @PackageTypeIDPair, @PackageTypeIDPacket, NULL,'XL', 12, 12,0, NULL, 15,5,7.48,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (142,'Halloween zombie mask (Light Brown) S', @SupplierIDFabrikam, @ColorIDLightBrown, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'S', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (143,'Halloween zombie mask (Light Brown) M', @SupplierIDFabrikam, @ColorIDLightBrown, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'M', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (144,'Halloween zombie mask (Light Brown) L', @SupplierIDFabrikam, @ColorIDLightBrown, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'L', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (145,'Halloween zombie mask (Light Brown) XL', @SupplierIDFabrikam, @ColorIDLightBrown, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XL', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (146,'Halloween skull mask (Gray) S', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'S', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (147,'Halloween skull mask (Gray) M', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'M', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (148,'Halloween skull mask (Gray) L', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'L', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (149,'Halloween skull mask (Gray) XL', @SupplierIDFabrikam, @ColorIDGray, @PackageTypeIDEach, @PackageTypeIDCarton, NULL,'XL', 12, 12,0, NULL, 15, 18,26.91,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (150,'Pack of 12 action figures (variety)', @SupplierIDContoso, @ColorIDNone, @PackageTypeIDPacket, @PackageTypeIDPacket, NULL, NULL,2, 1,0, NULL, 15, 16,23.92,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (151,'Pack of 12 action figures (male)', @SupplierIDContoso, @ColorIDNone, @PackageTypeIDPacket, @PackageTypeIDPacket, NULL, NULL,2, 1,0, NULL, 15, 16,23.92,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (152,'Pack of 12 action figures (female)', @SupplierIDContoso, @ColorIDNone, @PackageTypeIDPacket, @PackageTypeIDPacket, NULL, NULL,2, 1,0, NULL, 15, 16,23.92,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (153,'Small sized bubblewrap roll 10m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'10m', 14, 10,0, NULL, 15,4.5,6.73,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (154,'Medium sized bubblewrap roll 20m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'20m', 14, 10,0, NULL, 15,20,29.9,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (155,'Large sized bubblewrap roll 50m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'50m', 14, 10,0, NULL, 15,24,35.88, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (156,'10 mm Double sided bubble wrap 10m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'10m', 14, 10,0, NULL, 15, 15,22.43,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (157,'10 mm Double sided bubble wrap 20m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'20m', 14, 10,0, NULL, 15,30,44.85,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (158,'10 mm Double sided bubble wrap 50m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'50m', 14, 10,0, NULL, 15, 105, 156.98, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (159,'20 mm Double sided bubble wrap 10m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'10m', 14, 10,0, NULL, 15, 18,26.91,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (160,'20 mm Double sided bubble wrap 20m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'20m', 14, 10,0, NULL, 15,33,49.34,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (161,'20 mm Double sided bubble wrap 50m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'50m', 14, 10,0, NULL, 15, 108, 161.46, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (162,'32 mm Double sided bubble wrap 10m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'10m', 14, 10,0, NULL, 15,22,32.89,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (163,'32 mm Double sided bubble wrap 20m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'20m', 14, 10,0, NULL, 15,37,55.32,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (164,'32 mm Double sided bubble wrap 50m', @SupplierIDLitware, @ColorIDNone, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'50m', 14, 10,0, NULL, 15, 112, 167.44, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (165,'10 mm Anti static bubble wrap (Blue) 10m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'10m', 14, 10,0, NULL, 15,26,38.87,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (166,'10 mm Anti static bubble wrap (Blue) 20m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'20m', 14, 10,0, NULL, 15,42,62.79,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (167,'10 mm Anti static bubble wrap (Blue) 50m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'50m', 14, 10,0, NULL, 15,99, 148.01, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (168,'20 mm Anti static bubble wrap (Blue) 10m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'10m', 14, 10,0, NULL, 15,29,43.36,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (169,'20 mm Anti static bubble wrap (Blue) 20m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'20m', 14, 10,0, NULL, 15,45,67.28,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (170,'20 mm Anti static bubble wrap (Blue) 50m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'50m', 14, 10,0, NULL, 15, 102, 152.49, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (171,'32 mm Anti static bubble wrap (Blue) 10m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'10m', 14, 10,0, NULL, 15,32,47.84,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (172,'32 mm Anti static bubble wrap (Blue) 20m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'20m', 14, 10,0, NULL, 15,48,71.76,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (173,'32 mm Anti static bubble wrap (Blue) 50m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'50m', 14, 10,0, NULL, 15, 105, 156.98, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (174,'Bubblewrap dispenser (Black) 1.5m', @SupplierIDLitware, @ColorIDBlack, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'1.5m', 14, 1,0, NULL, 15,240,358.8, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (175,'Bubblewrap dispenser (Blue) 1.5m', @SupplierIDLitware, @ColorIDBlue, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'1.5m', 14, 1,0, NULL, 15,240,358.8, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (176,'Bubblewrap dispenser (Red) 1.5m', @SupplierIDLitware, @ColorIDRed, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'1.5m', 14, 1,0, NULL, 15,240,358.8, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (177,'Shipping carton (Brown) 413x285x187mm', @SupplierIDLitware, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'413x285x187mm', 14,25,0, NULL, 15, 1.05, 1.57,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (178,'Shipping carton (Brown) 500x310x310mm', @SupplierIDLitware, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'500x310x310mm', 14,25,0, NULL, 15,2.55,3.81,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (179,'Shipping carton (Brown) 229x229x229mm', @SupplierIDLitware, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'229x229x229mm', 14,25,0, NULL, 15, 1.05, 1.57,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (180,'Shipping carton (Brown) 279x254x217mm', @SupplierIDLitware, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'279x254x217mm', 14,25,0, NULL, 15, 1.11, 1.66,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (181,'Shipping carton (Brown) 356x229x229mm', @SupplierIDLitware, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'356x229x229mm', 14,25,0, NULL, 15, 1.14, 1.7,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (182,'Shipping carton (Brown) 457x279x279mm', @SupplierIDLitware, @ColorIDBrown, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'457x279x279mm', 14,25,0, NULL, 15, 1.28, 1.91,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (183,'Shipping carton (Brown) 480x270x320mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'480x270x320mm', 14,25,0, NULL, 15,2.74,4.1,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (184,'Shipping carton (Brown) 305x305x305mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'305x305x305mm', 14,25,0, NULL, 15,3.5,5.23,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (185,'Shipping carton (Brown) 356x356x279mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'356x356x279mm', 14,25,0, NULL, 15,2.04,3.05,0.3, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (186,'Shipping carton (Brown) 457x457x457mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'457x457x457mm', 14,25,0, NULL, 15,2.1,3.14,0.4, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (187,'Express post box 5kg (White) 350x280x130mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'350x280x130mm', 14,25,0, NULL, 15,0.95, 1.42,0.2, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (188,'3 kg Courier post bag (White) 300x190x95mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'300x190x95mm', 14,25,0, NULL, 15,0.66,0.99,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (189,'Clear packaging tape 48mmx75m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx75m', 14,26,0, NULL, 15,2.9,4.34,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (190,'Clear packaging tape 48mmx100m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx100m', 14,20,0, NULL, 15,3.5,5.23,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (191,'Black and orange fragile despatch tape 48mmx75m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx75m', 14,36,0, NULL, 15,3.7,5.53,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (192,'Black and orange fragile despatch tape 48mmx100m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx100m', 14,36,0, NULL, 15,4.1,6.13,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (193,'Black and orange glass with care despatch tape 48mmx75m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx75m', 14,24,0, NULL, 15,3.7,5.53,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (194,'Black and orange glass with care despatch tape  48mmx100m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx100m', 14,24,0, NULL, 15,4.1,6.13,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (195,'Black and orange handle with care despatch tape  48mmx75m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx75m', 14,24,0, NULL, 15,3.7,5.53,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (196,'Black and orange handle with care despatch tape  48mmx100m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx100m', 14,24,0, NULL, 15,4.1,6.13,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (197,'Black and orange this way up despatch tape 48mmx75m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx75m', 14,24,0, NULL, 15,3.7,5.53,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (198,'Black and orange this way up despatch tape  48mmx100m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx100m', 14,24,0, NULL, 15,4.1,6.13,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (199,'Black and yellow heavy despatch tape  48mmx75m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx75m', 14,24,0, NULL, 15,3.7,5.53,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (200,'Black and yellow heavy despatch tape 48mmx100m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx100m', 14,24,0, NULL, 15,4.1,6.13,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (201,'Red and white urgent despatch tape 48mmx75m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx75m', 14,24,0, NULL, 15,3.7,5.53,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (202,'Red and white urgent  heavy despatch tape  48mmx100m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'48mmx100m', 14,24,0, NULL, 15,4.1,6.13,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (203,'Tape dispenser (Black)', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL,20, 10,0, NULL, 15,32,47.84, 1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (204,'Tape dispenser (Red)', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL,20, 10,0, NULL, 15,32,47.84, 1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (205,'Tape dispenser (Blue)', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL,20, 10,0, NULL, 15,32,47.84, 1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (206,'Permanent marker black 5mm nib (Black) 5mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'5mm', 14, 12,0, NULL, 15,2.7,4.04,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (207,'Permanent marker blue 5mm nib (Blue) 5mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'5mm', 14, 12,0, NULL, 15,2.7,4.04,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (208,'Permanent marker red 5mm nib (Red) 5mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'5mm', 14, 12,0, NULL, 15,2.7,4.04,0.1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (209,'Packing knife with metal insert blade (Yellow) 9mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'9mm', 14,5,0, NULL, 15, 1.89,2.83,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (210,'Packing knife with metal insert blade (Yellow) 18mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'18mm', 14,5,0, NULL, 15,2.4,3.59,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (211,'Small 9mm replacement blades 9mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'9mm', 14, 10,0, NULL, 15,4.1,6.13,0.7, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (212,'Large  replacement blades 18mm', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'18mm', 14, 10,0, NULL, 15,4.3,6.43,0.8, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (213,'Air cushion film 200mmx100mm 325m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'325m', 14, 1,0, NULL, 15,87, 130.07,5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (214,'Air cushion film 200mmx200mm 325m', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'325m', 14, 1,0, NULL, 15,90, 134.55,6, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (215,'Air cushion machine (Blue)', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL, NULL,20, 1,0, NULL, 15, 1899,2839.01, 10, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (216,'Void fill 100 L bag (White) 100L', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'100L', 14, 10,0, NULL, 15, 12.5, 18.69,0.25, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (217,'Void fill 200 L bag (White) 200L', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'200L', 14, 10,0, NULL, 15,25,37.38,0.5, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (218,'Void fill 300 L bag (White) 300L', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'300L', 14, 10,0, NULL, 15,37.5,56.06,0.75, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
, (219,'Void fill 400 L bag (White) 400L', @SupplierIDLitware, @ColorIDNull, @PackageTypeIDEach, @PackageTypeIDEach, NULL,'400L', 14, 10,0, NULL, 15,50,74.75, 1, NULL, NULL, NULL, NULL, 1, @CurrentDateTime, @EndOfTime)
GO
