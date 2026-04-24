
CREATE PROCEDURE DataLoadSimulation.PlaceSupplierOrders
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Placing supplier orders for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @ContactPersonID INT --= (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());
    DECLARE @SupplierPersonID INT

    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @ContactPersonID OUTPUT
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @SupplierPersonID OUTPUT

    DECLARE @Orders TABLE
    (
        SupplierID int,
        PurchaseOrderID int NULL,
        DeliveryMethodID int,
        ContactPersonID int,
        SupplierReference nvarchar(20) NULL
    );

    DECLARE @OrderLines TABLE
    (
        StockItemID int,
        [Description] nvarchar(100),
        SupplierID int,
        QuantityOfOuters int,
        LeadTimeDays int,
        OuterPackageID int,
        LastOuterCostPrice decimal(18,2)
    );

    BEGIN TRAN;

    WITH StockItemsToCheck
    AS
    (
        SELECT si.StockItemID,
               si.StockItemName AS [Description],
               si.SupplierID,
               sih.TargetStockLevel,
               sih.ReorderLevel,
               si.QuantityPerOuter,
               si.LeadTimeDays,
               si.OuterPackageID,
               sih.QuantityOnHand,
               sih.LastCostPrice,
               COALESCE((SELECT SUM(ol.Quantity)
                         FROM Sales.OrderLines AS ol
                         WHERE ol.StockItemID = si.StockItemID
                         AND ol.PickingCompletedWhen IS NULL), 0) AS StockNeededForOrders,
               COALESCE((SELECT si.QuantityPerOuter * SUM(pol.OrderedOuters - pol.ReceivedOuters)
                         FROM Purchasing.PurchaseOrderLines AS pol
                         WHERE pol.StockItemID = si.StockItemID
                         AND pol.IsOrderLineFinalized = 0), 0) AS StockOnOrder
        FROM Warehouse.StockItems AS si
        INNER JOIN Warehouse.StockItemHoldings AS sih
        ON si.StockItemID = sih.StockItemID
    ),
    StockItemsToOrder
    AS
    (
        SELECT sitc.StockItemID,
               sitc.[Description],
               sitc.SupplierID,
               (sitc.QuantityOnHand + sitc.StockOnOrder - sitc.StockNeededForOrders) AS EffectiveStockLevel,
               sitc.TargetStockLevel,
               sitc.QuantityPerOuter,
               sitc.LeadTimeDays,
               sitc.OuterPackageID,
               sitc.LastCostPrice
        FROM StockItemsToCheck AS sitc
        WHERE (sitc.QuantityOnHand + sitc.StockOnOrder - sitc.StockNeededForOrders) < sitc.ReorderLevel
        AND sitc.QuantityPerOuter <> 0
    )
    INSERT @OrderLines (StockItemID, [Description], SupplierID, QuantityOfOuters, LeadTimeDays, OuterPackageID, LastOuterCostPrice)
    SELECT sito.StockItemID,
           sito.[Description],
           sito.SupplierID,
           CEILING((sito.TargetStockLevel - sito.EffectiveStockLevel) / sito.QuantityPerOuter) AS OutersRequired,
           sito.LeadTimeDays,
           sito.OuterPackageID,
           ROUND(sito.LastCostPrice * sito.QuantityPerOuter, 2) AS LastOuterCostPrice
    FROM StockItemsToOrder AS sito;

    INSERT @Orders (SupplierID, PurchaseOrderID, DeliveryMethodID, ContactPersonID, SupplierReference)
    SELECT s.SupplierID
         , NEXT VALUE FOR Sequences.PurchaseOrderID
         , s.DeliveryMethodID
         , @SupplierPersonID
         , s.SupplierReference
    FROM Purchasing.Suppliers AS s
    WHERE s.SupplierID IN (SELECT SupplierID FROM @OrderLines);

    INSERT Purchasing.PurchaseOrders
        (PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID, ContactPersonID,
         ExpectedDeliveryDate, SupplierReference, IsOrderFinalized, Comments,
         InternalComments, LastEditedBy, LastEditedWhen)
    SELECT o.PurchaseOrderID, o.SupplierID, CAST(@StartingWhen AS date), o.DeliveryMethodID, o.ContactPersonID,
           DATEADD(day, (SELECT MAX(LeadTimeDays) FROM @OrderLines), CAST(@StartingWhen AS date)),
           o.SupplierReference, 0, NULL,
           NULL, 1, @StartingWhen
    FROM @Orders AS o;

    INSERT Purchasing.PurchaseOrderLines
        (PurchaseOrderID, StockItemID, OrderedOuters, [Description],
         ReceivedOuters, PackageTypeID, ExpectedUnitPricePerOuter, LastReceiptDate,
         IsOrderLineFinalized, LastEditedBy, LastEditedWhen)
    SELECT o.PurchaseOrderID, ol.StockItemID, ol.QuantityOfOuters, ol.[Description],
           0, ol.OuterPackageID, ol.LastOuterCostPrice, NULL,
           0, @ContactPersonID, @StartingWhen
    FROM @OrderLines AS ol
    INNER JOIN @Orders AS o
    ON ol.SupplierID = o.SupplierID;

    COMMIT;
END;