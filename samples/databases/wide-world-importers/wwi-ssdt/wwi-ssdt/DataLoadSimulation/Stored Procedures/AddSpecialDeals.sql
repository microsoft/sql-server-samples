
CREATE PROCEDURE DataLoadSimulation.AddSpecialDeals
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF CAST(@CurrentDateTime AS date) = '20211231'
    BEGIN
        BEGIN TRAN;

        INSERT Sales.SpecialDeals
            (StockItemID, CustomerID, BuyingGroupID, CustomerCategoryID, StockGroupID,
             DealDescription, StartDate, EndDate, DiscountAmount, DiscountPercentage,
             UnitPrice, LastEditedBy, LastEditedWhen)
        VALUES
            (NULL, NULL, (SELECT BuyingGroupID FROM Sales.BuyingGroups WHERE BuyingGroupName = N'Wingtip Toys'),
             NULL, (SELECT StockGroupID FROM Warehouse.StockGroups WHERE StockGroupName = N'USB Novelties'),
             N'10% 1st qtr USB Wingtip', '20220101', '20220331', NULL, 10, NULL,
             2, @StartingWhen);

        INSERT Sales.SpecialDeals
            (StockItemID, CustomerID, BuyingGroupID, CustomerCategoryID, StockGroupID,
             DealDescription, StartDate, EndDate, DiscountAmount, DiscountPercentage,
             UnitPrice, LastEditedBy, LastEditedWhen)
        VALUES
            (NULL, NULL, (SELECT BuyingGroupID FROM Sales.BuyingGroups WHERE BuyingGroupName = N'Tailspin Toys'),
             NULL, (SELECT StockGroupID FROM Warehouse.StockGroups WHERE StockGroupName = N'USB Novelties'),
             N'15% 2nd qtr USB Tailspin', '20220401', '20220630', NULL, 15, NULL,
             2, @StartingWhen);

        COMMIT;

    END;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Adding special deals for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

END;