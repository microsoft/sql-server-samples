-- =============================================
-- Top 20 Manufacturing Reports
-- Futon Manufacturing Database
-- =============================================

USE FutonManufacturing;
GO

-- =============================================
-- REPORT 1: Multi-Level BOM Explosion
-- Shows complete material requirements for any item
-- =============================================

CREATE OR ALTER VIEW vw_BOMExplosion AS
WITH BOMRecursive AS (
    -- Anchor: Top level
    SELECT
        b.ParentItemID,
        p.ItemCode AS ParentItemCode,
        p.ItemName AS ParentItemName,
        b.ComponentItemID,
        c.ItemCode AS ComponentItemCode,
        c.ItemName AS ComponentItemName,
        c.ItemTypeID,
        t.TypeName AS ComponentType,
        b.Quantity,
        b.UnitID,
        u.UnitCode,
        b.ScrapRate,
        b.BOMLevel,
        CAST(b.Quantity * (1 + b.ScrapRate/100) AS DECIMAL(18,4)) AS EffectiveQuantity,
        c.StandardCost,
        CAST(b.Quantity * (1 + b.ScrapRate/100) * c.StandardCost AS DECIMAL(18,4)) AS ExtendedCost,
        1 AS Level,
        CAST(p.ItemCode + ' > ' + c.ItemCode AS NVARCHAR(MAX)) AS BOMPath
    FROM BillOfMaterials b
    INNER JOIN Items p ON b.ParentItemID = p.ItemID
    INNER JOIN Items c ON b.ComponentItemID = c.ItemID
    INNER JOIN ItemType t ON c.ItemTypeID = t.ItemTypeID
    INNER JOIN UnitOfMeasure u ON b.UnitID = u.UnitID
    WHERE b.IsActive = 1

    UNION ALL

    -- Recursive: Get sub-components
    SELECT
        br.ParentItemID,
        br.ParentItemCode,
        br.ParentItemName,
        b.ComponentItemID,
        c.ItemCode,
        c.ItemName,
        c.ItemTypeID,
        t.TypeName,
        br.EffectiveQuantity * b.Quantity AS Quantity,
        b.UnitID,
        u.UnitCode,
        b.ScrapRate,
        b.BOMLevel,
        CAST(br.EffectiveQuantity * b.Quantity * (1 + b.ScrapRate/100) AS DECIMAL(18,4)) AS EffectiveQuantity,
        c.StandardCost,
        CAST(br.EffectiveQuantity * b.Quantity * (1 + b.ScrapRate/100) * c.StandardCost AS DECIMAL(18,4)) AS ExtendedCost,
        br.Level + 1,
        CAST(br.BOMPath + ' > ' + c.ItemCode AS NVARCHAR(MAX))
    FROM BOMRecursive br
    INNER JOIN BillOfMaterials b ON br.ComponentItemID = b.ParentItemID
    INNER JOIN Items c ON b.ComponentItemID = c.ItemID
    INNER JOIN ItemType t ON c.ItemTypeID = t.ItemTypeID
    INNER JOIN UnitOfMeasure u ON b.UnitID = u.UnitID
    WHERE b.IsActive = 1
)
SELECT
    ParentItemID,
    ParentItemCode,
    ParentItemName,
    ComponentItemID,
    ComponentItemCode,
    ComponentItemName,
    ComponentType,
    Level,
    EffectiveQuantity,
    UnitCode,
    StandardCost,
    ExtendedCost,
    BOMPath
FROM BOMRecursive;
GO

-- =============================================
-- REPORT 2: Where-Used Report
-- Shows where each component is used
-- =============================================

CREATE OR ALTER VIEW vw_WhereUsed AS
WITH WhereUsedRecursive AS (
    -- Direct usage
    SELECT
        b.ComponentItemID,
        c.ItemCode AS ComponentItemCode,
        c.ItemName AS ComponentItemName,
        b.ParentItemID,
        p.ItemCode AS ParentItemCode,
        p.ItemName AS ParentItemName,
        t.TypeName AS ParentType,
        b.Quantity,
        u.UnitCode,
        1 AS Level,
        CAST(c.ItemCode + ' used in ' + p.ItemCode AS NVARCHAR(MAX)) AS UsagePath
    FROM BillOfMaterials b
    INNER JOIN Items c ON b.ComponentItemID = c.ItemID
    INNER JOIN Items p ON b.ParentItemID = p.ItemID
    INNER JOIN ItemType t ON p.ItemTypeID = t.ItemTypeID
    INNER JOIN UnitOfMeasure u ON b.UnitID = u.UnitID
    WHERE b.IsActive = 1

    UNION ALL

    -- Recursive usage
    SELECT
        wu.ComponentItemID,
        wu.ComponentItemCode,
        wu.ComponentItemName,
        b.ParentItemID,
        p.ItemCode,
        p.ItemName,
        t.TypeName,
        wu.Quantity * b.Quantity AS Quantity,
        u.UnitCode,
        wu.Level + 1,
        CAST(wu.UsagePath + ' > ' + p.ItemCode AS NVARCHAR(MAX))
    FROM WhereUsedRecursive wu
    INNER JOIN BillOfMaterials b ON wu.ParentItemID = b.ComponentItemID
    INNER JOIN Items p ON b.ParentItemID = p.ItemID
    INNER JOIN ItemType t ON p.ItemTypeID = t.ItemTypeID
    INNER JOIN UnitOfMeasure u ON b.UnitID = u.UnitID
    WHERE b.IsActive = 1
)
SELECT
    ComponentItemID,
    ComponentItemCode,
    ComponentItemName,
    ParentItemID,
    ParentItemCode,
    ParentItemName,
    ParentType,
    Level,
    Quantity,
    UnitCode,
    UsagePath
FROM WhereUsedRecursive;
GO

-- =============================================
-- REPORT 3: Inventory Valuation Report
-- =============================================

CREATE OR ALTER VIEW vw_InventoryValuation AS
SELECT
    w.WarehouseCode,
    w.WarehouseName,
    t.TypeName AS ItemType,
    i.ItemCode,
    i.ItemName,
    inv.QuantityOnHand,
    inv.QuantityAllocated,
    inv.QuantityAvailable,
    u.UnitCode,
    i.StandardCost,
    inv.QuantityOnHand * i.StandardCost AS InventoryValue,
    inv.QuantityAvailable * i.StandardCost AS AvailableValue,
    inv.LastCountDate,
    DATEDIFF(DAY, inv.LastCountDate, GETDATE()) AS DaysSinceCount
FROM Inventory inv
INNER JOIN Items i ON inv.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
INNER JOIN UnitOfMeasure u ON i.UnitID = u.UnitID
INNER JOIN Warehouse w ON inv.WarehouseID = w.WarehouseID
WHERE i.IsActive = 1;
GO

-- =============================================
-- REPORT 4: Items Below Reorder Point
-- =============================================

CREATE OR ALTER VIEW vw_ItemsBelowReorderPoint AS
SELECT
    w.WarehouseCode,
    w.WarehouseName,
    t.TypeName AS ItemType,
    i.ItemCode,
    i.ItemName,
    inv.QuantityAvailable,
    i.ReorderPoint,
    i.SafetyStock,
    i.ReorderPoint - inv.QuantityAvailable AS ShortageQuantity,
    u.UnitCode,
    i.LeadTimeDays,
    s.SupplierName AS PreferredSupplier,
    si.UnitPrice AS PreferredPrice,
    DATEADD(DAY, i.LeadTimeDays, GETDATE()) AS ExpectedArrival
FROM Inventory inv
INNER JOIN Items i ON inv.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
INNER JOIN UnitOfMeasure u ON i.UnitID = u.UnitID
INNER JOIN Warehouse w ON inv.WarehouseID = w.WarehouseID
LEFT JOIN SupplierItem si ON i.ItemID = si.ItemID AND si.IsPreferred = 1
LEFT JOIN Supplier s ON si.SupplierID = s.SupplierID
WHERE i.IsActive = 1
  AND inv.QuantityAvailable < i.ReorderPoint;
GO

-- =============================================
-- REPORT 5: Production Order Status Report
-- =============================================

CREATE OR ALTER VIEW vw_ProductionOrderStatus AS
SELECT
    po.WorkOrderNumber,
    po.Status,
    i.ItemCode,
    i.ItemName,
    t.TypeName AS ItemType,
    po.OrderQuantity,
    po.QuantityCompleted,
    po.QuantityScrapped,
    po.OrderQuantity - po.QuantityCompleted - po.QuantityScrapped AS QuantityRemaining,
    CAST((po.QuantityCompleted * 100.0 / NULLIF(po.OrderQuantity, 0)) AS DECIMAL(5,2)) AS PercentComplete,
    wc.WorkCenterName,
    w.WarehouseName,
    po.StartDate,
    po.PlannedCompletionDate,
    po.ActualCompletionDate,
    CASE
        WHEN po.ActualCompletionDate IS NOT NULL THEN
            DATEDIFF(DAY, po.PlannedCompletionDate, po.ActualCompletionDate)
        ELSE
            DATEDIFF(DAY, po.PlannedCompletionDate, GETDATE())
    END AS DaysVariance,
    CASE
        WHEN po.Status = 'Completed' THEN 'On Time'
        WHEN GETDATE() > po.PlannedCompletionDate THEN 'Late'
        WHEN DATEDIFF(DAY, GETDATE(), po.PlannedCompletionDate) <= 2 THEN 'At Risk'
        ELSE 'On Track'
    END AS ScheduleStatus,
    po.Priority,
    po.CreatedBy,
    po.CreatedDate
FROM ProductionOrder po
INNER JOIN Items i ON po.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
INNER JOIN Warehouse w ON po.WarehouseID = w.WarehouseID
LEFT JOIN WorkCenter wc ON po.WorkCenterID = wc.WorkCenterID;
GO

-- =============================================
-- REPORT 6: Material Requirements Planning (MRP)
-- =============================================

CREATE OR ALTER VIEW vw_MaterialRequirements AS
WITH RequiredMaterials AS (
    SELECT
        po.WorkOrderNumber,
        po.Status,
        po.PlannedCompletionDate,
        i.ItemID,
        i.ItemCode,
        i.ItemName,
        t.TypeName AS ItemType,
        SUM(bom.EffectiveQuantity * (po.OrderQuantity - po.QuantityCompleted)) AS RequiredQuantity,
        u.UnitCode
    FROM ProductionOrder po
    INNER JOIN vw_BOMExplosion bom ON po.ItemID = bom.ParentItemID
    INNER JOIN Items i ON bom.ComponentItemID = i.ItemID
    INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
    INNER JOIN UnitOfMeasure u ON i.UnitID = u.UnitID
    WHERE po.Status IN ('Planned', 'Released', 'InProgress')
    GROUP BY
        po.WorkOrderNumber, po.Status, po.PlannedCompletionDate,
        i.ItemID, i.ItemCode, i.ItemName, t.TypeName, u.UnitCode
)
SELECT
    rm.WorkOrderNumber,
    rm.Status,
    rm.PlannedCompletionDate,
    rm.ItemCode,
    rm.ItemName,
    rm.ItemType,
    rm.RequiredQuantity,
    ISNULL(inv.QuantityAvailable, 0) AS AvailableQuantity,
    rm.RequiredQuantity - ISNULL(inv.QuantityAvailable, 0) AS ShortageQuantity,
    CASE
        WHEN ISNULL(inv.QuantityAvailable, 0) >= rm.RequiredQuantity THEN 'Sufficient'
        WHEN ISNULL(inv.QuantityAvailable, 0) > 0 THEN 'Partial'
        ELSE 'Out of Stock'
    END AS AvailabilityStatus,
    rm.UnitCode
FROM RequiredMaterials rm
LEFT JOIN (
    SELECT ItemID, SUM(QuantityAvailable) AS QuantityAvailable
    FROM Inventory
    GROUP BY ItemID
) inv ON rm.ItemID = inv.ItemID;
GO

-- =============================================
-- REPORT 7: Work Center Capacity Analysis
-- =============================================

CREATE OR ALTER VIEW vw_WorkCenterCapacity AS
SELECT
    wc.WorkCenterCode,
    wc.WorkCenterName,
    wc.Capacity AS DailyCapacity,
    COUNT(DISTINCT po.ProductionOrderID) AS ActiveOrders,
    SUM(CASE WHEN po.Status = 'InProgress' THEN 1 ELSE 0 END) AS InProgressOrders,
    SUM(po.OrderQuantity - po.QuantityCompleted) AS TotalQuantityPending,
    CAST(SUM(po.OrderQuantity - po.QuantityCompleted) / NULLIF(wc.Capacity, 0) AS DECIMAL(10,2)) AS DaysOfWork,
    CAST((COUNT(DISTINCT po.ProductionOrderID) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM ProductionOrder WHERE Status IN ('Planned', 'Released', 'InProgress')), 0))
        AS DECIMAL(5,2)) AS PercentOfTotalOrders,
    MIN(po.PlannedCompletionDate) AS EarliestDueDate,
    MAX(po.PlannedCompletionDate) AS LatestDueDate
FROM WorkCenter wc
LEFT JOIN ProductionOrder po ON wc.WorkCenterID = po.WorkCenterID
    AND po.Status IN ('Planned', 'Released', 'InProgress')
WHERE wc.IsActive = 1
GROUP BY wc.WorkCenterCode, wc.WorkCenterName, wc.Capacity;
GO

-- =============================================
-- REPORT 8: Production Completion Summary
-- =============================================

CREATE OR ALTER VIEW vw_ProductionCompletionSummary AS
SELECT
    CAST(pc.CompletionDate AS DATE) AS CompletionDate,
    DATEPART(YEAR, pc.CompletionDate) AS Year,
    DATEPART(MONTH, pc.CompletionDate) AS Month,
    DATEPART(WEEK, pc.CompletionDate) AS Week,
    wc.WorkCenterName,
    i.ItemCode,
    i.ItemName,
    t.TypeName AS ItemType,
    COUNT(DISTINCT pc.CompletionID) AS NumberOfCompletions,
    SUM(pc.QuantityCompleted) AS TotalCompleted,
    SUM(pc.QuantityScrapped) AS TotalScrapped,
    CAST((SUM(pc.QuantityScrapped) * 100.0 / NULLIF(SUM(pc.QuantityCompleted + pc.QuantityScrapped), 0))
        AS DECIMAL(5,2)) AS ScrapRate,
    SUM(pc.QuantityCompleted * i.StandardCost) AS ProductionValue
FROM ProductionCompletion pc
INNER JOIN ProductionOrder po ON pc.ProductionOrderID = po.ProductionOrderID
INNER JOIN Items i ON po.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
LEFT JOIN WorkCenter wc ON pc.WorkCenterID = wc.WorkCenterID
GROUP BY
    CAST(pc.CompletionDate AS DATE),
    DATEPART(YEAR, pc.CompletionDate),
    DATEPART(MONTH, pc.CompletionDate),
    DATEPART(WEEK, pc.CompletionDate),
    wc.WorkCenterName,
    i.ItemCode,
    i.ItemName,
    t.TypeName;
GO

-- =============================================
-- REPORT 9: Quality Inspection Summary
-- =============================================

CREATE OR ALTER VIEW vw_QualityInspectionSummary AS
SELECT
    CAST(qi.InspectionDate AS DATE) AS InspectionDate,
    DATEPART(YEAR, qi.InspectionDate) AS Year,
    DATEPART(MONTH, qi.InspectionDate) AS Month,
    qi.InspectionType,
    i.ItemCode,
    i.ItemName,
    t.TypeName AS ItemType,
    COUNT(qi.InspectionID) AS NumberOfInspections,
    SUM(qi.QuantityInspected) AS TotalInspected,
    SUM(qi.QuantityAccepted) AS TotalAccepted,
    SUM(qi.QuantityRejected) AS TotalRejected,
    CAST((SUM(qi.QuantityAccepted) * 100.0 / NULLIF(SUM(qi.QuantityInspected), 0))
        AS DECIMAL(5,2)) AS AcceptanceRate,
    CAST((SUM(qi.QuantityRejected) * 100.0 / NULLIF(SUM(qi.QuantityInspected), 0))
        AS DECIMAL(5,2)) AS RejectionRate
FROM QualityInspection qi
INNER JOIN Items i ON qi.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
GROUP BY
    CAST(qi.InspectionDate AS DATE),
    DATEPART(YEAR, qi.InspectionDate),
    DATEPART(MONTH, qi.InspectionDate),
    qi.InspectionType,
    i.ItemCode,
    i.ItemName,
    t.TypeName;
GO

-- =============================================
-- REPORT 10: Supplier Performance Report
-- =============================================

CREATE OR ALTER VIEW vw_SupplierPerformance AS
WITH SupplierMetrics AS (
    SELECT
        s.SupplierID,
        s.SupplierCode,
        s.SupplierName,
        s.Rating,
        COUNT(DISTINCT po.PurchaseOrderID) AS TotalOrders,
        SUM(po.TotalAmount) AS TotalPurchaseValue,
        AVG(DATEDIFF(DAY, po.OrderDate, po.ActualDeliveryDate)) AS AvgDeliveryDays,
        SUM(CASE WHEN po.ActualDeliveryDate <= po.ExpectedDeliveryDate THEN 1 ELSE 0 END) AS OnTimeDeliveries,
        COUNT(CASE WHEN po.ActualDeliveryDate IS NOT NULL THEN 1 END) AS CompletedDeliveries
    FROM Supplier s
    LEFT JOIN PurchaseOrder po ON s.SupplierID = po.SupplierID
    WHERE s.IsActive = 1
    GROUP BY s.SupplierID, s.SupplierCode, s.SupplierName, s.Rating
)
SELECT
    SupplierCode,
    SupplierName,
    Rating AS SupplierRating,
    TotalOrders,
    TotalPurchaseValue,
    AvgDeliveryDays,
    OnTimeDeliveries,
    CompletedDeliveries,
    CAST((OnTimeDeliveries * 100.0 / NULLIF(CompletedDeliveries, 0)) AS DECIMAL(5,2)) AS OnTimeDeliveryRate,
    CASE
        WHEN CAST((OnTimeDeliveries * 100.0 / NULLIF(CompletedDeliveries, 0)) AS DECIMAL(5,2)) >= 95 THEN 'Excellent'
        WHEN CAST((OnTimeDeliveries * 100.0 / NULLIF(CompletedDeliveries, 0)) AS DECIMAL(5,2)) >= 85 THEN 'Good'
        WHEN CAST((OnTimeDeliveries * 100.0 / NULLIF(CompletedDeliveries, 0)) AS DECIMAL(5,2)) >= 75 THEN 'Fair'
        ELSE 'Poor'
    END AS PerformanceGrade
FROM SupplierMetrics;
GO

-- =============================================
-- REPORT 11: Purchase Order Status
-- =============================================

CREATE OR ALTER VIEW vw_PurchaseOrderStatus AS
SELECT
    po.PONumber,
    po.Status,
    s.SupplierName,
    w.WarehouseName,
    po.OrderDate,
    po.ExpectedDeliveryDate,
    po.ActualDeliveryDate,
    DATEDIFF(DAY, po.OrderDate, ISNULL(po.ActualDeliveryDate, GETDATE())) AS DaysSinceOrder,
    CASE
        WHEN po.ActualDeliveryDate IS NOT NULL THEN
            DATEDIFF(DAY, po.ExpectedDeliveryDate, po.ActualDeliveryDate)
        ELSE
            DATEDIFF(DAY, po.ExpectedDeliveryDate, GETDATE())
    END AS DaysVariance,
    COUNT(DISTINCT pod.PODetailID) AS LineItems,
    po.TotalAmount,
    SUM(pod.LineTotal) AS LinesTotal,
    SUM(pod.QuantityReceived * pod.UnitPrice) AS ReceivedValue,
    CAST((SUM(pod.QuantityReceived) * 100.0 / NULLIF(SUM(pod.Quantity), 0))
        AS DECIMAL(5,2)) AS PercentReceived,
    CASE
        WHEN po.Status = 'Received' THEN 'Complete'
        WHEN po.Status = 'Cancelled' THEN 'Cancelled'
        WHEN GETDATE() > po.ExpectedDeliveryDate AND po.Status NOT IN ('Received', 'Cancelled') THEN 'Overdue'
        WHEN DATEDIFF(DAY, GETDATE(), po.ExpectedDeliveryDate) <= 3 THEN 'Due Soon'
        ELSE 'On Track'
    END AS DeliveryStatus
FROM PurchaseOrder po
INNER JOIN Supplier s ON po.SupplierID = s.SupplierID
INNER JOIN Warehouse w ON po.WarehouseID = w.WarehouseID
LEFT JOIN PurchaseOrderDetail pod ON po.PurchaseOrderID = pod.PurchaseOrderID
GROUP BY
    po.PONumber, po.Status, s.SupplierName, w.WarehouseName,
    po.OrderDate, po.ExpectedDeliveryDate, po.ActualDeliveryDate,
    po.TotalAmount, po.PurchaseOrderID;
GO

-- =============================================
-- REPORT 12: Sales Order Backlog
-- =============================================

CREATE OR ALTER VIEW vw_SalesOrderBacklog AS
SELECT
    so.OrderNumber,
    so.Status,
    c.CustomerName,
    c.CustomerCode,
    w.WarehouseName,
    so.OrderDate,
    so.RequestedDeliveryDate,
    so.ShipDate,
    DATEDIFF(DAY, so.OrderDate, GETDATE()) AS DaysOpen,
    DATEDIFF(DAY, GETDATE(), so.RequestedDeliveryDate) AS DaysUntilDue,
    COUNT(DISTINCT sod.SODetailID) AS LineItems,
    SUM(sod.Quantity) AS TotalQuantityOrdered,
    SUM(sod.QuantityShipped) AS TotalQuantityShipped,
    SUM(sod.Quantity - sod.QuantityShipped) AS QuantityBacklog,
    so.TotalAmount,
    SUM(sod.LineTotal) AS OrderValue,
    SUM((sod.Quantity - sod.QuantityShipped) * sod.UnitPrice) AS BacklogValue,
    CAST((SUM(sod.QuantityShipped) * 100.0 / NULLIF(SUM(sod.Quantity), 0))
        AS DECIMAL(5,2)) AS PercentComplete,
    CASE
        WHEN so.Status = 'Delivered' THEN 'Complete'
        WHEN so.Status = 'Cancelled' THEN 'Cancelled'
        WHEN GETDATE() > so.RequestedDeliveryDate AND so.Status NOT IN ('Delivered', 'Shipped') THEN 'Overdue'
        WHEN DATEDIFF(DAY, GETDATE(), so.RequestedDeliveryDate) <= 5 THEN 'Due Soon'
        ELSE 'On Track'
    END AS FulfillmentStatus
FROM SalesOrder so
INNER JOIN Customer c ON so.CustomerID = c.CustomerID
INNER JOIN Warehouse w ON so.WarehouseID = w.WarehouseID
LEFT JOIN SalesOrderDetail sod ON so.SalesOrderID = sod.SalesOrderID
WHERE so.Status NOT IN ('Delivered', 'Cancelled')
GROUP BY
    so.OrderNumber, so.Status, c.CustomerName, c.CustomerCode, w.WarehouseName,
    so.OrderDate, so.RequestedDeliveryDate, so.ShipDate, so.TotalAmount;
GO

-- =============================================
-- REPORT 13: Cost Roll-Up by Item
-- =============================================

CREATE OR ALTER VIEW vw_CostRollUp AS
WITH ItemCosts AS (
    SELECT
        ParentItemID,
        ParentItemCode,
        ParentItemName,
        SUM(ExtendedCost) AS TotalMaterialCost,
        COUNT(DISTINCT ComponentItemID) AS NumberOfComponents
    FROM vw_BOMExplosion
    GROUP BY ParentItemID, ParentItemCode, ParentItemName
)
SELECT
    i.ItemCode,
    i.ItemName,
    t.TypeName AS ItemType,
    i.StandardCost AS CurrentStandardCost,
    ISNULL(ic.TotalMaterialCost, 0) AS CalculatedMaterialCost,
    i.StandardCost - ISNULL(ic.TotalMaterialCost, 0) AS LaborAndOverhead,
    ISNULL(ic.NumberOfComponents, 0) AS ComponentCount,
    i.ListPrice,
    i.ListPrice - i.StandardCost AS GrossProfit,
    CAST(((i.ListPrice - i.StandardCost) * 100.0 / NULLIF(i.ListPrice, 0))
        AS DECIMAL(5,2)) AS GrossMarginPercent
FROM Items i
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
LEFT JOIN ItemCosts ic ON i.ItemID = ic.ParentItemID
WHERE i.IsActive = 1;
GO

-- =============================================
-- REPORT 14: Inventory Turnover Analysis
-- =============================================

CREATE OR ALTER VIEW vw_InventoryTurnover AS
WITH TransactionSummary AS (
    SELECT
        it.ItemID,
        SUM(CASE WHEN it.Quantity < 0 THEN ABS(it.Quantity) ELSE 0 END) AS QuantityIssued,
        SUM(CASE WHEN it.Quantity > 0 THEN it.Quantity ELSE 0 END) AS QuantityReceived,
        COUNT(*) AS TransactionCount,
        MIN(it.TransactionDate) AS FirstTransaction,
        MAX(it.TransactionDate) AS LastTransaction
    FROM InventoryTransaction it
    WHERE it.TransactionDate >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY it.ItemID
)
SELECT
    i.ItemCode,
    i.ItemName,
    t.TypeName AS ItemType,
    inv.QuantityOnHand,
    inv.QuantityAvailable,
    ts.QuantityIssued AS Annual Usage,
    ts.QuantityReceived AS AnnualReceipts,
    ts.TransactionCount,
    CAST(ts.QuantityIssued / NULLIF(inv.QuantityOnHand, 0) AS DECIMAL(10,2)) AS TurnoverRatio,
    CAST((inv.QuantityOnHand * 365.0) / NULLIF(ts.QuantityIssued, 0) AS DECIMAL(10,1)) AS DaysOnHand,
    inv.QuantityOnHand * i.StandardCost AS InventoryValue,
    ts.FirstTransaction,
    ts.LastTransaction,
    DATEDIFF(DAY, ts.LastTransaction, GETDATE()) AS DaysSinceLastActivity,
    CASE
        WHEN CAST(ts.QuantityIssued / NULLIF(inv.QuantityOnHand, 0) AS DECIMAL(10,2)) >= 12 THEN 'Fast Moving'
        WHEN CAST(ts.QuantityIssued / NULLIF(inv.QuantityOnHand, 0) AS DECIMAL(10,2)) >= 4 THEN 'Normal'
        WHEN CAST(ts.QuantityIssued / NULLIF(inv.QuantityOnHand, 0) AS DECIMAL(10,2)) >= 1 THEN 'Slow Moving'
        ELSE 'Non-Moving'
    END AS MovementClass
FROM Items i
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
INNER JOIN Inventory inv ON i.ItemID = inv.ItemID
LEFT JOIN TransactionSummary ts ON i.ItemID = ts.ItemID
WHERE i.IsActive = 1 AND inv.QuantityOnHand > 0;
GO

-- =============================================
-- REPORT 15: Late Production Orders
-- =============================================

CREATE OR ALTER VIEW vw_LateProductionOrders AS
SELECT
    po.WorkOrderNumber,
    po.Status,
    i.ItemCode,
    i.ItemName,
    t.TypeName AS ItemType,
    po.OrderQuantity,
    po.QuantityCompleted,
    po.OrderQuantity - po.QuantityCompleted AS QuantityRemaining,
    wc.WorkCenterName,
    po.StartDate,
    po.PlannedCompletionDate,
    DATEDIFF(DAY, po.PlannedCompletionDate, GETDATE()) AS DaysLate,
    po.Priority,
    CASE
        WHEN DATEDIFF(DAY, po.PlannedCompletionDate, GETDATE()) > 10 THEN 'Critical'
        WHEN DATEDIFF(DAY, po.PlannedCompletionDate, GETDATE()) > 5 THEN 'High'
        WHEN DATEDIFF(DAY, po.PlannedCompletionDate, GETDATE()) > 2 THEN 'Medium'
        ELSE 'Low'
    END AS LatenessSeverity,
    (po.OrderQuantity - po.QuantityCompleted) * i.StandardCost AS ValueAtRisk
FROM ProductionOrder po
INNER JOIN Items i ON po.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
LEFT JOIN WorkCenter wc ON po.WorkCenterID = wc.WorkCenterID
WHERE po.Status IN ('Planned', 'Released', 'InProgress')
  AND po.PlannedCompletionDate < CAST(GETDATE() AS DATE);
GO

-- =============================================
-- REPORT 16: Component Shortage Report
-- =============================================

CREATE OR ALTER VIEW vw_ComponentShortage AS
WITH ProductionNeeds AS (
    SELECT
        i.ItemID,
        i.ItemCode,
        i.ItemName,
        t.TypeName AS ItemType,
        SUM(bom.EffectiveQuantity * (po.OrderQuantity - po.QuantityCompleted)) AS RequiredQuantity,
        MIN(po.PlannedCompletionDate) AS EarliestNeedDate,
        COUNT(DISTINCT po.ProductionOrderID) AS AffectedOrders
    FROM ProductionOrder po
    INNER JOIN vw_BOMExplosion bom ON po.ItemID = bom.ParentItemID
    INNER JOIN Items i ON bom.ComponentItemID = i.ItemID
    INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
    WHERE po.Status IN ('Planned', 'Released', 'InProgress')
    GROUP BY i.ItemID, i.ItemCode, i.ItemName, t.TypeName
)
SELECT
    pn.ItemCode,
    pn.ItemName,
    pn.ItemType,
    pn.RequiredQuantity,
    ISNULL(inv.QuantityAvailable, 0) AS AvailableQuantity,
    pn.RequiredQuantity - ISNULL(inv.QuantityAvailable, 0) AS ShortageQuantity,
    pn.EarliestNeedDate,
    DATEDIFF(DAY, GETDATE(), pn.EarliestNeedDate) AS DaysUntilNeeded,
    pn.AffectedOrders,
    CASE
        WHEN DATEDIFF(DAY, GETDATE(), pn.EarliestNeedDate) <= 2 THEN 'Urgent'
        WHEN DATEDIFF(DAY, GETDATE(), pn.EarliestNeedDate) <= 5 THEN 'High'
        WHEN DATEDIFF(DAY, GETDATE(), pn.EarliestNeedDate) <= 10 THEN 'Medium'
        ELSE 'Low'
    END AS UrgencyLevel,
    s.SupplierName AS PreferredSupplier,
    si.LeadTimeDays,
    DATEADD(DAY, si.LeadTimeDays, GETDATE()) AS PossibleArrival,
    CASE
        WHEN DATEADD(DAY, si.LeadTimeDays, GETDATE()) <= pn.EarliestNeedDate THEN 'Can Meet'
        ELSE 'Will Be Late'
    END AS SupplyStatus
FROM ProductionNeeds pn
LEFT JOIN (
    SELECT ItemID, SUM(QuantityAvailable) AS QuantityAvailable
    FROM Inventory
    GROUP BY ItemID
) inv ON pn.ItemID = inv.ItemID
LEFT JOIN SupplierItem si ON pn.ItemID = si.ItemID AND si.IsPreferred = 1
LEFT JOIN Supplier s ON si.SupplierID = s.SupplierID
WHERE pn.RequiredQuantity > ISNULL(inv.QuantityAvailable, 0);
GO

-- =============================================
-- REPORT 17: Daily Production Schedule
-- =============================================

CREATE OR ALTER VIEW vw_DailyProductionSchedule AS
SELECT
    po.PlannedCompletionDate AS ScheduledDate,
    DATENAME(WEEKDAY, po.PlannedCompletionDate) AS DayOfWeek,
    wc.WorkCenterName,
    po.WorkOrderNumber,
    po.Status,
    i.ItemCode,
    i.ItemName,
    po.OrderQuantity - po.QuantityCompleted AS QuantityToProduce,
    po.Priority,
    CAST(((po.OrderQuantity - po.QuantityCompleted) / NULLIF(wc.Capacity, 0))
        AS DECIMAL(10,2)) AS EstimatedDays,
    (po.OrderQuantity - po.QuantityCompleted) * i.StandardCost AS ProductionValue,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM vw_ComponentShortage cs
            INNER JOIN vw_BOMExplosion bom ON cs.ItemCode = bom.ComponentItemCode
            WHERE bom.ParentItemID = po.ItemID
        ) THEN 'Material Shortage'
        WHEN po.PlannedCompletionDate < GETDATE() THEN 'Overdue'
        WHEN po.PlannedCompletionDate = CAST(GETDATE() AS DATE) THEN 'Due Today'
        ELSE 'On Schedule'
    END AS ProductionStatus
FROM ProductionOrder po
INNER JOIN Items i ON po.ItemID = i.ItemID
LEFT JOIN WorkCenter wc ON po.WorkCenterID = wc.WorkCenterID
WHERE po.Status IN ('Planned', 'Released', 'InProgress')
  AND po.PlannedCompletionDate BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 14, CAST(GETDATE() AS DATE));
GO

-- =============================================
-- REPORT 18: Scrap and Waste Analysis
-- =============================================

CREATE OR ALTER VIEW vw_ScrapWasteAnalysis AS
SELECT
    CAST(pc.CompletionDate AS DATE) AS CompletionDate,
    DATEPART(YEAR, pc.CompletionDate) AS Year,
    DATEPART(MONTH, pc.CompletionDate) AS Month,
    wc.WorkCenterName,
    i.ItemCode,
    i.ItemName,
    t.TypeName AS ItemType,
    SUM(pc.QuantityCompleted) AS TotalCompleted,
    SUM(pc.QuantityScrapped) AS TotalScrapped,
    SUM(pc.QuantityCompleted + pc.QuantityScrapped) AS TotalProduced,
    CAST((SUM(pc.QuantityScrapped) * 100.0 /
        NULLIF(SUM(pc.QuantityCompleted + pc.QuantityScrapped), 0))
        AS DECIMAL(5,2)) AS ScrapRate,
    SUM(pc.QuantityScrapped * i.StandardCost) AS ScrapValue,
    COUNT(DISTINCT pc.ProductionOrderID) AS NumberOfOrders,
    AVG(i.StandardCost) AS AvgUnitCost,
    CASE
        WHEN CAST((SUM(pc.QuantityScrapped) * 100.0 /
            NULLIF(SUM(pc.QuantityCompleted + pc.QuantityScrapped), 0))
            AS DECIMAL(5,2)) > 10 THEN 'High'
        WHEN CAST((SUM(pc.QuantityScrapped) * 100.0 /
            NULLIF(SUM(pc.QuantityCompleted + pc.QuantityScrapped), 0))
            AS DECIMAL(5,2)) > 5 THEN 'Medium'
        ELSE 'Low'
    END AS ScrapLevel
FROM ProductionCompletion pc
INNER JOIN ProductionOrder po ON pc.ProductionOrderID = po.ProductionOrderID
INNER JOIN Items i ON po.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
LEFT JOIN WorkCenter wc ON pc.WorkCenterID = wc.WorkCenterID
GROUP BY
    CAST(pc.CompletionDate AS DATE),
    DATEPART(YEAR, pc.CompletionDate),
    DATEPART(MONTH, pc.CompletionDate),
    wc.WorkCenterName,
    i.ItemCode,
    i.ItemName,
    t.TypeName;
GO

-- =============================================
-- REPORT 19: Customer Order Fulfillment Rate
-- =============================================

CREATE OR ALTER VIEW vw_CustomerFulfillmentRate AS
WITH CustomerMetrics AS (
    SELECT
        c.CustomerID,
        c.CustomerCode,
        c.CustomerName,
        COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
        SUM(so.TotalAmount) AS TotalOrderValue,
        SUM(CASE WHEN so.Status = 'Delivered' THEN 1 ELSE 0 END) AS DeliveredOrders,
        SUM(CASE WHEN so.Status = 'Delivered' AND so.ShipDate <= so.RequestedDeliveryDate
            THEN 1 ELSE 0 END) AS OnTimeDeliveries,
        SUM(CASE WHEN so.Status = 'Delivered' THEN so.TotalAmount ELSE 0 END) AS DeliveredValue,
        AVG(CASE WHEN so.ShipDate IS NOT NULL
            THEN DATEDIFF(DAY, so.OrderDate, so.ShipDate) END) AS AvgDaysToShip,
        AVG(CASE WHEN so.Status = 'Delivered'
            THEN DATEDIFF(DAY, so.RequestedDeliveryDate, so.ShipDate) END) AS AvgDeliveryVariance
    FROM Customer c
    LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID
    WHERE c.IsActive = 1
    GROUP BY c.CustomerID, c.CustomerCode, c.CustomerName
)
SELECT
    CustomerCode,
    CustomerName,
    TotalOrders,
    TotalOrderValue,
    DeliveredOrders,
    OnTimeDeliveries,
    DeliveredValue,
    TotalOrders - DeliveredOrders AS PendingOrders,
    TotalOrderValue - DeliveredValue AS PendingValue,
    CAST((DeliveredOrders * 100.0 / NULLIF(TotalOrders, 0))
        AS DECIMAL(5,2)) AS FulfillmentRate,
    CAST((OnTimeDeliveries * 100.0 / NULLIF(DeliveredOrders, 0))
        AS DECIMAL(5,2)) AS OnTimeDeliveryRate,
    AvgDaysToShip,
    AvgDeliveryVariance,
    CASE
        WHEN CAST((OnTimeDeliveries * 100.0 / NULLIF(DeliveredOrders, 0)) AS DECIMAL(5,2)) >= 95 THEN 'Excellent'
        WHEN CAST((OnTimeDeliveries * 100.0 / NULLIF(DeliveredOrders, 0)) AS DECIMAL(5,2)) >= 85 THEN 'Good'
        WHEN CAST((OnTimeDeliveries * 100.0 / NULLIF(DeliveredOrders, 0)) AS DECIMAL(5,2)) >= 75 THEN 'Fair'
        ELSE 'Poor'
    END AS ServiceLevel
FROM CustomerMetrics
WHERE TotalOrders > 0;
GO

-- =============================================
-- REPORT 20: Raw Material Usage by Period
-- =============================================

CREATE OR ALTER VIEW vw_RawMaterialUsage AS
SELECT
    DATEPART(YEAR, it.TransactionDate) AS Year,
    DATEPART(MONTH, it.TransactionDate) AS Month,
    DATEPART(QUARTER, it.TransactionDate) AS Quarter,
    t.TypeName AS ItemType,
    i.ItemCode,
    i.ItemName,
    u.UnitCode,
    SUM(CASE WHEN it.Quantity < 0 THEN ABS(it.Quantity) ELSE 0 END) AS TotalUsage,
    SUM(CASE WHEN it.Quantity > 0 THEN it.Quantity ELSE 0 END) AS TotalReceipts,
    COUNT(CASE WHEN it.Quantity < 0 THEN 1 END) AS NumberOfIssues,
    AVG(CASE WHEN it.Quantity < 0 THEN ABS(it.Quantity) END) AS AvgIssueQuantity,
    SUM(CASE WHEN it.Quantity < 0 THEN ABS(it.Quantity) * ISNULL(it.UnitCost, i.StandardCost)
        ELSE 0 END) AS TotalUsageValue,
    AVG(CASE WHEN it.Quantity < 0 THEN ISNULL(it.UnitCost, i.StandardCost) END) AS AvgUnitCost
FROM InventoryTransaction it
INNER JOIN Items i ON it.ItemID = i.ItemID
INNER JOIN ItemType t ON i.ItemTypeID = t.ItemTypeID
INNER JOIN UnitOfMeasure u ON i.UnitID = u.UnitID
WHERE t.TypeCode = 'RAW'
  AND it.TransactionDate >= DATEADD(MONTH, -12, GETDATE())
GROUP BY
    DATEPART(YEAR, it.TransactionDate),
    DATEPART(MONTH, it.TransactionDate),
    DATEPART(QUARTER, it.TransactionDate),
    t.TypeName,
    i.ItemCode,
    i.ItemName,
    u.UnitCode;
GO

PRINT 'All 20 manufacturing reports created successfully!';
PRINT '';
PRINT 'Available Reports:';
PRINT '1.  vw_BOMExplosion - Multi-Level BOM Explosion';
PRINT '2.  vw_WhereUsed - Where-Used Report';
PRINT '3.  vw_InventoryValuation - Inventory Valuation';
PRINT '4.  vw_ItemsBelowReorderPoint - Items Below Reorder Point';
PRINT '5.  vw_ProductionOrderStatus - Production Order Status';
PRINT '6.  vw_MaterialRequirements - Material Requirements Planning';
PRINT '7.  vw_WorkCenterCapacity - Work Center Capacity Analysis';
PRINT '8.  vw_ProductionCompletionSummary - Production Completion Summary';
PRINT '9.  vw_QualityInspectionSummary - Quality Inspection Summary';
PRINT '10. vw_SupplierPerformance - Supplier Performance';
PRINT '11. vw_PurchaseOrderStatus - Purchase Order Status';
PRINT '12. vw_SalesOrderBacklog - Sales Order Backlog';
PRINT '13. vw_CostRollUp - Cost Roll-Up by Item';
PRINT '14. vw_InventoryTurnover - Inventory Turnover Analysis';
PRINT '15. vw_LateProductionOrders - Late Production Orders';
PRINT '16. vw_ComponentShortage - Component Shortage Report';
PRINT '17. vw_DailyProductionSchedule - Daily Production Schedule';
PRINT '18. vw_ScrapWasteAnalysis - Scrap and Waste Analysis';
PRINT '19. vw_CustomerFulfillmentRate - Customer Order Fulfillment Rate';
PRINT '20. vw_RawMaterialUsage - Raw Material Usage by Period';
GO
