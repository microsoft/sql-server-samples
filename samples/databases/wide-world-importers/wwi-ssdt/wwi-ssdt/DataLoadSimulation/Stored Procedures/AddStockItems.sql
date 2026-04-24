-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.AddStockItems;
GO

CREATE PROCEDURE DataLoadSimulation.AddStockItems
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NumberOfStockItems int = 0;

    IF CAST(@CurrentDateTime AS date) = '20220101'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (220,'Novelty chilli chocolates 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8302039293929',10,8.55,12.23,0.25,'Watch your friends faces when they eat these',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (221,'Novelty chilli chocolates 500g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'500g',3,12,1,'8302039293647',10,14.5,20.74,0.5,'Watch your friends faces when they eat these',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (220,360,'CH-1',360,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (221,12,'CH-2',12,8.75,120,250,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 220, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 221, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;

    END ELSE IF CAST(@CurrentDateTime AS date) = '20220102'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (222,'Chocolate beetles 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293820',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (223,'Chocolate echidnas 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293728',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (222,120,'CH-3',120,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (223,120,'CH-4',120,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 222, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 223, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;

    END ELSE IF CAST(@CurrentDateTime AS date) = '20220104'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (224,'Chocolate frogs 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293987',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (225,'Chocolate sharks 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293234',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (224,144,'CH-5',144,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (225,160,'CH-6',160,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 224, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 225, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;

    END ELSE IF CAST (@CurrentDateTime AS date) = '20220105'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (226,'White chocolate snow balls 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293236',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (227,'White chocolate moon rocks 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293289',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (226,24,'CH-7',24,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (227,48,'CH-8',48,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 226, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 227, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;
    END;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Adding ' + CAST(@NumberOfStockItems AS nvarchar(20)) + N' stock items for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

END;
GO
