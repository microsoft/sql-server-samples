-- =============================================
-- Sample Queries and Use Cases
-- Futon Manufacturing Database
-- =============================================

USE FutonManufacturing;
GO

PRINT '=============================================';
PRINT 'SAMPLE QUERIES FOR FUTON MANUFACTURING DATABASE';
PRINT '=============================================';
PRINT '';

-- =============================================
-- 1. BILL OF MATERIALS QUERIES
-- =============================================

PRINT '1. BOM Explosion - Show all materials needed for Queen Luxury Futon';
PRINT '---------------------------------------------------------------------';
SELECT
    REPLICATE('  ', Level - 1) + ComponentItemName AS Component,
    ComponentType,
    EffectiveQuantity,
    UnitCode,
    StandardCost AS UnitCost,
    ExtendedCost,
    BOMPath
FROM vw_BOMExplosion
WHERE ParentItemCode = 'FG-FUT-006'
ORDER BY Level, ComponentItemCode;
GO

PRINT '';
PRINT '2. Where Used - Find all products using Memory Foam';
PRINT '---------------------------------------------------------------------';
SELECT
    ComponentItemName AS [Component],
    ParentItemName AS [Used In],
    ParentType,
    Quantity,
    UnitCode,
    Level
FROM vw_WhereUsed
WHERE ComponentItemCode = 'RM-FILL-002'
ORDER BY Level, ParentItemCode;
GO

PRINT '';
PRINT '3. Calculate total raw material cost for each finished good';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemCode,
    ItemName,
    CalculatedMaterialCost AS MaterialCost,
    LaborAndOverhead,
    CurrentStandardCost AS TotalCost,
    ListPrice,
    GrossProfit,
    GrossMarginPercent AS [Margin %],
    ComponentCount
FROM vw_CostRollUp
WHERE ItemType = 'Finished Goods'
ORDER BY GrossMarginPercent DESC;
GO

-- =============================================
-- 2. INVENTORY MANAGEMENT QUERIES
-- =============================================

PRINT '';
PRINT '4. Current Inventory Valuation by Type';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemType,
    COUNT(DISTINCT ItemCode) AS ItemCount,
    SUM(QuantityOnHand) AS TotalQuantity,
    SUM(InventoryValue) AS TotalValue,
    AVG(StandardCost) AS AvgUnitCost
FROM vw_InventoryValuation
GROUP BY ItemType
ORDER BY TotalValue DESC;
GO

PRINT '';
PRINT '5. Items Needing Reorder (Below Reorder Point)';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemType,
    ItemCode,
    ItemName,
    QuantityAvailable AS Available,
    ReorderPoint AS [Reorder Point],
    ShortageQuantity AS Shortage,
    PreferredSupplier AS Supplier,
    PreferredPrice AS Price,
    LeadTimeDays AS [Lead Days],
    ExpectedArrival
FROM vw_ItemsBelowReorderPoint
ORDER BY ShortageQuantity DESC;
GO

PRINT '';
PRINT '6. Inventory Turnover - Identify slow moving items';
PRINT '---------------------------------------------------------------------';
SELECT TOP 10
    ItemCode,
    ItemName,
    ItemType,
    QuantityOnHand AS [On Hand],
    [Annual Usage],
    TurnoverRatio AS [Turns/Year],
    DaysOnHand AS [Days Supply],
    InventoryValue AS [Inv Value],
    MovementClass
FROM vw_InventoryTurnover
WHERE MovementClass IN ('Slow Moving', 'Non-Moving')
ORDER BY InventoryValue DESC;
GO

-- =============================================
-- 3. PRODUCTION PLANNING QUERIES
-- =============================================

PRINT '';
PRINT '7. Material Requirements for Open Production Orders';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemCode,
    ItemName,
    ItemType,
    SUM(RequiredQuantity) AS TotalRequired,
    SUM(AvailableQuantity) AS TotalAvailable,
    SUM(ShortageQuantity) AS TotalShortage,
    COUNT(DISTINCT WorkOrderNumber) AS AffectedOrders
FROM vw_MaterialRequirements
GROUP BY ItemCode, ItemName, ItemType
HAVING SUM(ShortageQuantity) > 0
ORDER BY SUM(ShortageQuantity) DESC;
GO

PRINT '';
PRINT '8. Work Center Capacity and Utilization';
PRINT '---------------------------------------------------------------------';
SELECT
    WorkCenterName,
    DailyCapacity,
    ActiveOrders,
    InProgressOrders,
    TotalQuantityPending AS [Qty Pending],
    DaysOfWork AS [Days Backlog],
    PercentOfTotalOrders AS [% of Orders],
    EarliestDueDate,
    LatestDueDate
FROM vw_WorkCenterCapacity
ORDER BY DaysOfWork DESC;
GO

PRINT '';
PRINT '9. Production Schedule for Next 7 Days';
PRINT '---------------------------------------------------------------------';
SELECT
    ScheduledDate,
    DayOfWeek,
    WorkCenterName,
    WorkOrderNumber,
    ItemName,
    QuantityToProduce AS Quantity,
    Priority,
    ProductionStatus AS Status
FROM vw_DailyProductionSchedule
WHERE ScheduledDate BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
ORDER BY ScheduledDate, Priority, WorkCenterName;
GO

-- =============================================
-- 4. QUALITY AND SCRAP ANALYSIS
-- =============================================

PRINT '';
PRINT '10. Scrap Analysis - Items with High Scrap Rates';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemCode,
    ItemName,
    ItemType,
    SUM(TotalCompleted) AS Completed,
    SUM(TotalScrapped) AS Scrapped,
    AVG(ScrapRate) AS [Avg Scrap %],
    SUM(ScrapValue) AS [Scrap $],
    ScrapLevel
FROM vw_ScrapWasteAnalysis
GROUP BY ItemCode, ItemName, ItemType, ScrapLevel
HAVING AVG(ScrapRate) > 5
ORDER BY SUM(ScrapValue) DESC;
GO

-- =============================================
-- 5. SUPPLIER PERFORMANCE QUERIES
-- =============================================

PRINT '';
PRINT '11. Supplier Performance Scorecard';
PRINT '---------------------------------------------------------------------';
SELECT
    SupplierName,
    SupplierRating AS Rating,
    TotalOrders AS Orders,
    TotalPurchaseValue AS [Purchase Value],
    OnTimeDeliveryRate AS [OT Delivery %],
    AvgDeliveryDays AS [Avg Days],
    PerformanceGrade AS Grade
FROM vw_SupplierPerformance
ORDER BY OnTimeDeliveryRate DESC;
GO

-- =============================================
-- 6. SALES AND CUSTOMER QUERIES
-- =============================================

PRINT '';
PRINT '12. Customer Fulfillment Performance';
PRINT '---------------------------------------------------------------------';
SELECT
    CustomerName,
    TotalOrders AS Orders,
    TotalOrderValue AS [Order Value],
    DeliveredOrders AS Delivered,
    PendingOrders AS Pending,
    FulfillmentRate AS [Fulfill %],
    OnTimeDeliveryRate AS [OnTime %],
    AvgDaysToShip AS [Avg Ship Days],
    ServiceLevel
FROM vw_CustomerFulfillmentRate
ORDER BY TotalOrderValue DESC;
GO

PRINT '';
PRINT '13. Sales Order Backlog Summary';
PRINT '---------------------------------------------------------------------';
SELECT
    FulfillmentStatus AS Status,
    COUNT(*) AS OrderCount,
    SUM(TotalQuantityOrdered) AS TotalUnits,
    SUM(QuantityBacklog) AS BacklogUnits,
    SUM(OrderValue) AS OrderValue,
    SUM(BacklogValue) AS BacklogValue,
    AVG(DaysOpen) AS AvgDaysOpen
FROM vw_SalesOrderBacklog
GROUP BY FulfillmentStatus
ORDER BY BacklogValue DESC;
GO

-- =============================================
-- 7. PRODUCTION STATUS QUERIES
-- =============================================

PRINT '';
PRINT '14. Late Production Orders - Overdue Work';
PRINT '---------------------------------------------------------------------';
SELECT
    WorkOrderNumber,
    ItemName,
    OrderQuantity,
    QuantityRemaining,
    PlannedCompletionDate,
    DaysLate,
    LatenessSeverity,
    ValueAtRisk,
    WorkCenterName
FROM vw_LateProductionOrders
ORDER BY DaysLate DESC;
GO

PRINT '';
PRINT '15. Component Shortages Affecting Production';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemCode,
    ItemName,
    RequiredQuantity,
    AvailableQuantity,
    ShortageQuantity,
    EarliestNeedDate,
    DaysUntilNeeded,
    AffectedOrders,
    UrgencyLevel,
    PreferredSupplier,
    SupplyStatus
FROM vw_ComponentShortage
WHERE UrgencyLevel IN ('Urgent', 'High')
ORDER BY DaysUntilNeeded;
GO

-- =============================================
-- 8. ADVANCED ANALYTICAL QUERIES
-- =============================================

PRINT '';
PRINT '16. Product Profitability Analysis';
PRINT '---------------------------------------------------------------------';
SELECT
    i.ItemCode,
    i.ItemName,
    i.StandardCost,
    i.ListPrice,
    i.ListPrice - i.StandardCost AS GrossProfit,
    CAST(((i.ListPrice - i.StandardCost) * 100.0 / NULLIF(i.ListPrice, 0)) AS DECIMAL(5,2)) AS [Margin %],
    ISNULL(inv.QuantityOnHand, 0) AS [Stock Level],
    i.ReorderPoint,
    CASE
        WHEN ISNULL(inv.QuantityOnHand, 0) < i.ReorderPoint THEN 'Low Stock'
        WHEN ISNULL(inv.QuantityOnHand, 0) > i.ReorderPoint * 2 THEN 'Overstock'
        ELSE 'Normal'
    END AS StockStatus
FROM Items i
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
LEFT JOIN (
    SELECT ItemID, SUM(QuantityOnHand) AS QuantityOnHand
    FROM Inventory
    GROUP BY ItemID
) inv ON i.ItemID = inv.ItemID
WHERE t.TypeCode = 'FG' AND i.IsActive = 1
ORDER BY [Margin %] DESC;
GO

PRINT '';
PRINT '17. Monthly Production Trend Analysis';
PRINT '---------------------------------------------------------------------';
SELECT
    Year,
    Month,
    ItemType,
    COUNT(DISTINCT ItemCode) AS Products,
    SUM(TotalCompleted) AS UnitsProduced,
    SUM(TotalScrapped) AS UnitsScrapped,
    AVG(ScrapRate) AS [Avg Scrap %],
    SUM(ProductionValue) AS [Production Value]
FROM vw_ProductionCompletionSummary
GROUP BY Year, Month, ItemType
ORDER BY Year DESC, Month DESC, ItemType;
GO

PRINT '';
PRINT '18. Top 10 Most Used Raw Materials (by value)';
PRINT '---------------------------------------------------------------------';
SELECT TOP 10
    ItemName,
    ItemCode,
    SUM(TotalUsage) AS TotalUsageQty,
    UnitCode,
    SUM(TotalUsageValue) AS UsageValue,
    AVG(AvgUnitCost) AS AvgCost,
    COUNT(*) AS Periods
FROM vw_RawMaterialUsage
GROUP BY ItemName, ItemCode, UnitCode
ORDER BY SUM(TotalUsageValue) DESC;
GO

PRINT '';
PRINT '19. Purchase Order Aging Analysis';
PRINT '---------------------------------------------------------------------';
SELECT
    DeliveryStatus AS Status,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalValue,
    AVG(DaysSinceOrder) AS AvgDaysOpen,
    SUM(CASE WHEN Status = 'Received' THEN 0 ELSE TotalAmount END) AS OpenValue
FROM vw_PurchaseOrderStatus
GROUP BY DeliveryStatus
ORDER BY OpenValue DESC;
GO

PRINT '';
PRINT '20. ABC Inventory Classification (by value)';
PRINT '---------------------------------------------------------------------';
WITH InventoryValue AS (
    SELECT
        ItemCode,
        ItemName,
        ItemType,
        QuantityOnHand,
        InventoryValue,
        SUM(InventoryValue) OVER () AS TotalInventoryValue,
        InventoryValue * 100.0 / SUM(InventoryValue) OVER () AS PercentOfTotal,
        SUM(InventoryValue * 100.0 / SUM(InventoryValue) OVER ())
            OVER (ORDER BY InventoryValue DESC) AS CumulativePercent
    FROM vw_InventoryValuation
)
SELECT
    ItemCode,
    ItemName,
    ItemType,
    QuantityOnHand,
    InventoryValue,
    CAST(PercentOfTotal AS DECIMAL(5,2)) AS [% of Total],
    CAST(CumulativePercent AS DECIMAL(5,2)) AS [Cumulative %],
    CASE
        WHEN CumulativePercent <= 80 THEN 'A'
        WHEN CumulativePercent <= 95 THEN 'B'
        ELSE 'C'
    END AS ABCClass
FROM InventoryValue
WHERE InventoryValue > 0
ORDER BY InventoryValue DESC;
GO

-- =============================================
-- 21. WHAT-IF SCENARIOS
-- =============================================

PRINT '';
PRINT '21. What-If: Material Requirements for New Sales Order';
PRINT '---------------------------------------------------------------------';
-- Example: What if we need to produce 10 Queen Luxury Futons?
DECLARE @ItemCode NVARCHAR(50) = 'FG-FUT-006';
DECLARE @Quantity DECIMAL(18,2) = 10;

WITH MaterialNeeds AS (
    SELECT
        ComponentItemCode,
        ComponentItemName,
        ComponentType,
        SUM(EffectiveQuantity * @Quantity) AS RequiredQty,
        UnitCode,
        MAX(StandardCost) AS UnitCost,
        SUM(ExtendedCost * @Quantity) AS TotalCost
    FROM vw_BOMExplosion
    WHERE ParentItemCode = @ItemCode
    GROUP BY ComponentItemCode, ComponentItemName, ComponentType, UnitCode
)
SELECT
    mn.ComponentItemName AS Material,
    mn.ComponentType AS Type,
    mn.RequiredQty AS Required,
    ISNULL(inv.QuantityAvailable, 0) AS Available,
    mn.RequiredQty - ISNULL(inv.QuantityAvailable, 0) AS Shortage,
    mn.UnitCode,
    mn.UnitCost,
    mn.TotalCost,
    CASE
        WHEN ISNULL(inv.QuantityAvailable, 0) >= mn.RequiredQty THEN 'OK'
        WHEN ISNULL(inv.QuantityAvailable, 0) > 0 THEN 'Partial'
        ELSE 'Out of Stock'
    END AS Status
FROM MaterialNeeds mn
LEFT JOIN (
    SELECT ItemID, i.ItemCode, SUM(QuantityAvailable) AS QuantityAvailable
    FROM Inventory inv
    INNER JOIN Items i ON inv.ItemID = i.ItemID
    GROUP BY ItemID, i.ItemCode
) inv ON mn.ComponentItemCode = inv.ItemCode
ORDER BY mn.ComponentType, mn.ComponentItemName;
GO

-- =============================================
-- 22. KEY PERFORMANCE INDICATORS (KPIs)
-- =============================================

PRINT '';
PRINT '22. Manufacturing KPI Dashboard';
PRINT '---------------------------------------------------------------------';
SELECT
    'Total Inventory Value' AS KPI,
    CAST(SUM(InventoryValue) AS DECIMAL(18,2)) AS Value,
    NULL AS Percent,
    'USD' AS Unit
FROM vw_InventoryValuation

UNION ALL

SELECT
    'Production Orders On Time',
    COUNT(*),
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ProductionOrder WHERE Status = 'Completed') AS DECIMAL(5,2)),
    '%'
FROM ProductionOrder
WHERE Status = 'Completed' AND ActualCompletionDate <= PlannedCompletionDate

UNION ALL

SELECT
    'Average Scrap Rate',
    NULL,
    CAST(AVG(ScrapRate) AS DECIMAL(5,2)),
    '%'
FROM vw_ScrapWasteAnalysis

UNION ALL

SELECT
    'Supplier On-Time Delivery',
    NULL,
    CAST(AVG(OnTimeDeliveryRate) AS DECIMAL(5,2)),
    '%'
FROM vw_SupplierPerformance

UNION ALL

SELECT
    'Customer Fulfillment Rate',
    NULL,
    CAST(AVG(FulfillmentRate) AS DECIMAL(5,2)),
    '%'
FROM vw_CustomerFulfillmentRate

UNION ALL

SELECT
    'Items Below Reorder Point',
    COUNT(*),
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Items WHERE IsActive = 1) AS DECIMAL(5,2)),
    '%'
FROM vw_ItemsBelowReorderPoint

UNION ALL

SELECT
    'Late Production Orders',
    COUNT(*),
    NULL,
    'orders'
FROM vw_LateProductionOrders

UNION ALL

SELECT
    'Open Sales Order Backlog Value',
    SUM(BacklogValue),
    NULL,
    'USD'
FROM vw_SalesOrderBacklog;
GO

PRINT '';
PRINT '=============================================';
PRINT 'Sample queries completed successfully!';
PRINT 'Use these as templates for your own analysis.';
PRINT '=============================================';
GO
