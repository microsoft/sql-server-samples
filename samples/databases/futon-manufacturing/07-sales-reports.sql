-- =============================================
-- Top 20 Sales Operations Reports
-- Futon Manufacturing Database
-- =============================================

USE FutonManufacturing;
GO

-- =============================================
-- REPORT 1: Sales Performance by Channel
-- =============================================

CREATE OR ALTER VIEW vw_Sales_ByChannel AS
SELECT
    sc.ChannelCode,
    sc.ChannelName,
    DATEPART(YEAR, so.OrderDate) AS Year,
    DATEPART(MONTH, so.OrderDate) AS Month,
    DATEPART(QUARTER, so.OrderDate) AS Quarter,
    COUNT(DISTINCT so.SalesOrderID) AS OrderCount,
    COUNT(DISTINCT so.CustomerID) AS UniqueCustomers,
    SUM(so.Subtotal) AS GrossSales,
    SUM(so.DiscountAmount) AS TotalDiscounts,
    SUM(so.NetAmount) AS NetSales,
    AVG(so.NetAmount) AS AvgOrderValue,
    SUM(CASE WHEN so.Status = 'Delivered' THEN so.NetAmount ELSE 0 END) AS DeliveredSales,
    SUM(CASE WHEN so.Status IN ('Confirmed', 'InProduction', 'Shipped') THEN so.NetAmount ELSE 0 END) AS PipelineSales,
    CAST(AVG(so.DiscountAmount * 100.0 / NULLIF(so.Subtotal, 0)) AS DECIMAL(5,2)) AS AvgDiscountPercent
FROM SalesOrder so
INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
GROUP BY
    sc.ChannelCode,
    sc.ChannelName,
    DATEPART(YEAR, so.OrderDate),
    DATEPART(MONTH, so.OrderDate),
    DATEPART(QUARTER, so.OrderDate);
GO

-- =============================================
-- REPORT 2: Store Performance Report
-- =============================================

CREATE OR ALTER VIEW vw_Sales_StorePerformance AS
SELECT
    s.StoreCode,
    s.StoreName,
    s.City,
    s.State,
    sc.ChannelName,
    s.Manager,
    COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
    COUNT(DISTINCT so.CustomerID) AS UniqueCustomers,
    SUM(so.Subtotal) AS GrossSales,
    SUM(so.DiscountAmount) AS TotalDiscounts,
    SUM(so.NetAmount) AS NetSales,
    AVG(so.NetAmount) AS AvgOrderValue,
    SUM(CASE WHEN so.Status = 'Delivered' THEN 1 ELSE 0 END) AS CompletedOrders,
    CAST(SUM(CASE WHEN so.Status = 'Delivered' THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(so.SalesOrderID), 0) AS DECIMAL(5,2)) AS CompletionRate,
    MIN(so.OrderDate) AS FirstSale,
    MAX(so.OrderDate) AS LastSale,
    DATEDIFF(DAY, MIN(so.OrderDate), MAX(so.OrderDate)) + 1 AS DaysActive,
    SUM(so.NetAmount) / NULLIF(DATEDIFF(DAY, MIN(so.OrderDate), MAX(so.OrderDate)) + 1, 0) AS AvgDailySales
FROM Store s
LEFT JOIN SalesOrder so ON s.StoreID = so.StoreID
LEFT JOIN SalesChannel sc ON s.SalesChannelID = sc.SalesChannelID
GROUP BY
    s.StoreCode,
    s.StoreName,
    s.City,
    s.State,
    sc.ChannelName,
    s.Manager;
GO

-- =============================================
-- REPORT 3: Sales Representative Performance
-- =============================================

CREATE OR ALTER VIEW vw_Sales_RepPerformance AS
SELECT
    sr.EmployeeCode,
    sr.FirstName + ' ' + sr.LastName AS SalesRepName,
    st.TerritoryName,
    st.Region,
    COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
    COUNT(DISTINCT so.CustomerID) AS UniqueCustomers,
    SUM(so.Subtotal) AS GrossSales,
    SUM(so.DiscountAmount) AS TotalDiscounts,
    SUM(so.NetAmount) AS NetSales,
    AVG(so.NetAmount) AS AvgOrderValue,
    SUM(CASE WHEN so.Status = 'Delivered' THEN so.NetAmount ELSE 0 END) AS DeliveredSales,
    CAST(AVG(DATEDIFF(DAY, so.OrderDate, so.ShipDate)) AS DECIMAL(10,1)) AS AvgDaysToShip,
    -- Quote performance
    COUNT(DISTINCT sq.QuoteID) AS QuotesCreated,
    SUM(CASE WHEN sq.Status = 'Accepted' THEN 1 ELSE 0 END) AS QuotesAccepted,
    CAST(SUM(CASE WHEN sq.Status = 'Accepted' THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(DISTINCT sq.QuoteID), 0) AS DECIMAL(5,2)) AS QuoteWinRate,
    -- Rankings
    RANK() OVER (ORDER BY SUM(so.NetAmount) DESC) AS SalesRank
FROM SalesRep sr
LEFT JOIN SalesTerritory st ON sr.TerritoryID = st.TerritoryID
LEFT JOIN SalesOrder so ON sr.SalesRepID = so.SalesRepID
LEFT JOIN SalesQuote sq ON sr.SalesRepID = sq.SalesRepID
WHERE sr.IsActive = 1
GROUP BY
    sr.EmployeeCode,
    sr.FirstName,
    sr.LastName,
    st.TerritoryName,
    st.Region;
GO

-- =============================================
-- REPORT 4: Customer Sales Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_CustomerAnalysis AS
WITH CustomerMetrics AS (
    SELECT
        c.CustomerID,
        c.CustomerCode,
        c.CustomerName,
        c.CustomerType,
        c.City,
        c.State,
        sr.FirstName + ' ' + sr.LastName AS SalesRep,
        st.TerritoryName,
        COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
        SUM(so.NetAmount) AS TotalSales,
        AVG(so.NetAmount) AS AvgOrderValue,
        MAX(so.OrderDate) AS LastOrderDate,
        MIN(so.OrderDate) AS FirstOrderDate,
        DATEDIFF(DAY, MIN(so.OrderDate), MAX(so.OrderDate)) AS CustomerLifespanDays,
        SUM(CASE WHEN so.Status = 'Delivered' THEN so.NetAmount ELSE 0 END) AS DeliveredSales,
        SUM(CASE WHEN so.Status IN ('Confirmed', 'InProduction') THEN so.NetAmount ELSE 0 END) AS PendingSales,
        -- Returns
        COUNT(DISTINCT sr2.ReturnID) AS TotalReturns,
        ISNULL(SUM(sr2.RefundAmount), 0) AS TotalRefunds
    FROM Customer c
    LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID
    LEFT JOIN SalesRep sr ON c.SalesRepID = sr.SalesRepID
    LEFT JOIN SalesTerritory st ON c.TerritoryID = st.TerritoryID
    LEFT JOIN SalesReturn sr2 ON c.CustomerID = sr2.CustomerID
    WHERE c.IsActive = 1
    GROUP BY
        c.CustomerID, c.CustomerCode, c.CustomerName, c.CustomerType,
        c.City, c.State, sr.FirstName, sr.LastName, st.TerritoryName
)
SELECT
    *,
    CASE
        WHEN TotalOrders = 0 THEN 'No Orders'
        WHEN TotalOrders = 1 THEN 'One-Time'
        WHEN TotalOrders BETWEEN 2 AND 5 THEN 'Occasional'
        WHEN TotalOrders BETWEEN 6 AND 10 THEN 'Regular'
        ELSE 'VIP'
    END AS CustomerSegment,
    CAST(TotalRefunds * 100.0 / NULLIF(TotalSales, 0) AS DECIMAL(5,2)) AS ReturnRate,
    DATEDIFF(DAY, LastOrderDate, GETDATE()) AS DaysSinceLastOrder,
    CASE
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 'Active'
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 90 THEN 'Recent'
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 180 THEN 'Inactive'
        ELSE 'Dormant'
    END AS CustomerStatus,
    TotalSales / NULLIF(CustomerLifespanDays / 30.0, 0) AS AvgMonthlyValue
FROM CustomerMetrics;
GO

-- =============================================
-- REPORT 5: Product Sales Performance
-- =============================================

CREATE OR ALTER VIEW vw_Sales_ProductPerformance AS
SELECT
    i.ItemCode,
    i.ItemName,
    COUNT(DISTINCT sod.SalesOrderID) AS OrderCount,
    SUM(sod.Quantity) AS TotalUnitsSold,
    SUM(sod.NetAmount) AS TotalRevenue,
    AVG(sod.UnitPrice) AS AvgSellingPrice,
    i.StandardCost AS UnitCost,
    AVG(sod.UnitPrice) - i.StandardCost AS AvgGrossProfitPerUnit,
    SUM(sod.NetAmount - (sod.Quantity * i.StandardCost)) AS TotalGrossProfit,
    CAST((AVG(sod.UnitPrice) - i.StandardCost) * 100.0 / NULLIF(AVG(sod.UnitPrice), 0)
        AS DECIMAL(5,2)) AS GrossMarginPercent,
    AVG(sod.DiscountPercent) AS AvgDiscountPercent,
    -- By Channel
    SUM(CASE WHEN sc.ChannelCode = 'RETAIL' THEN sod.Quantity ELSE 0 END) AS RetailUnits,
    SUM(CASE WHEN sc.ChannelCode = 'ONLINE' THEN sod.Quantity ELSE 0 END) AS OnlineUnits,
    SUM(CASE WHEN sc.ChannelCode = 'WHOLESALE' THEN sod.Quantity ELSE 0 END) AS WholesaleUnits,
    -- Rankings
    RANK() OVER (ORDER BY SUM(sod.Quantity) DESC) AS UnitSalesRank,
    RANK() OVER (ORDER BY SUM(sod.NetAmount) DESC) AS RevenueRank,
    RANK() OVER (ORDER BY SUM(sod.NetAmount - (sod.Quantity * i.StandardCost)) DESC) AS ProfitRank
FROM Items i
INNER JOIN ItemType it ON i.ItemTypeID = it.ItemTypeID
LEFT JOIN SalesOrderDetail sod ON i.ItemID = sod.ItemID
LEFT JOIN SalesOrder so ON sod.SalesOrderID = so.SalesOrderID
LEFT JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
WHERE it.TypeCode = 'FG' AND i.IsActive = 1
GROUP BY
    i.ItemCode,
    i.ItemName,
    i.StandardCost;
GO

-- =============================================
-- REPORT 6: Sales Trend Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_TrendAnalysis AS
WITH MonthlySales AS (
    SELECT
        DATEPART(YEAR, OrderDate) AS Year,
        DATEPART(MONTH, OrderDate) AS Month,
        DATEPART(QUARTER, OrderDate) AS Quarter,
        DATEFROMPARTS(DATEPART(YEAR, OrderDate), DATEPART(MONTH, OrderDate), 1) AS MonthStart,
        COUNT(DISTINCT SalesOrderID) AS OrderCount,
        COUNT(DISTINCT CustomerID) AS UniqueCustomers,
        SUM(Subtotal) AS GrossSales,
        SUM(DiscountAmount) AS Discounts,
        SUM(NetAmount) AS NetSales,
        AVG(NetAmount) AS AvgOrderValue
    FROM SalesOrder
    GROUP BY
        DATEPART(YEAR, OrderDate),
        DATEPART(MONTH, OrderDate),
        DATEPART(QUARTER, OrderDate),
        DATEFROMPARTS(DATEPART(YEAR, OrderDate), DATEPART(MONTH, OrderDate), 1)
)
SELECT
    Year,
    Month,
    Quarter,
    MonthStart,
    OrderCount,
    UniqueCustomers,
    GrossSales,
    Discounts,
    NetSales,
    AvgOrderValue,
    -- Prior month comparison
    LAG(NetSales, 1) OVER (ORDER BY Year, Month) AS PriorMonthSales,
    NetSales - LAG(NetSales, 1) OVER (ORDER BY Year, Month) AS MoMChange,
    CAST((NetSales - LAG(NetSales, 1) OVER (ORDER BY Year, Month)) * 100.0 /
        NULLIF(LAG(NetSales, 1) OVER (ORDER BY Year, Month), 0) AS DECIMAL(5,2)) AS MoMChangePercent,
    -- Prior year comparison
    LAG(NetSales, 12) OVER (ORDER BY Year, Month) AS PriorYearSales,
    NetSales - LAG(NetSales, 12) OVER (ORDER BY Year, Month) AS YoYChange,
    CAST((NetSales - LAG(NetSales, 12) OVER (ORDER BY Year, Month)) * 100.0 /
        NULLIF(LAG(NetSales, 12) OVER (ORDER BY Year, Month), 0) AS DECIMAL(5,2)) AS YoYChangePercent,
    -- Moving averages
    AVG(NetSales) OVER (ORDER BY Year, Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg,
    AVG(NetSales) OVER (ORDER BY Year, Month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS SixMonthAvg
FROM MonthlySales;
GO

-- =============================================
-- REPORT 7: Average Order Value Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_OrderValueAnalysis AS
SELECT
    sc.ChannelName,
    c.CustomerType,
    st.TerritoryName,
    st.Region,
    COUNT(DISTINCT so.SalesOrderID) AS OrderCount,
    AVG(so.Subtotal) AS AvgSubtotal,
    AVG(so.DiscountAmount) AS AvgDiscount,
    AVG(so.NetAmount) AS AvgNetAmount,
    AVG(so.TaxAmount) AS AvgTax,
    AVG(so.ShippingAmount) AS AvgShipping,
    MIN(so.NetAmount) AS MinOrderValue,
    MAX(so.NetAmount) AS MaxOrderValue,
    STDEV(so.NetAmount) AS StdDevOrderValue,
    -- Order size buckets
    SUM(CASE WHEN so.NetAmount < 500 THEN 1 ELSE 0 END) AS SmallOrders,
    SUM(CASE WHEN so.NetAmount BETWEEN 500 AND 1999 THEN 1 ELSE 0 END) AS MediumOrders,
    SUM(CASE WHEN so.NetAmount BETWEEN 2000 AND 4999 THEN 1 ELSE 0 END) AS LargeOrders,
    SUM(CASE WHEN so.NetAmount >= 5000 THEN 1 ELSE 0 END) AS EnterpriseOrders
FROM SalesOrder so
INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
INNER JOIN Customer c ON so.CustomerID = c.CustomerID
LEFT JOIN SalesRep sr ON so.SalesRepID = sr.SalesRepID
LEFT JOIN SalesTerritory st ON sr.TerritoryID = st.TerritoryID
GROUP BY
    sc.ChannelName,
    c.CustomerType,
    st.TerritoryName,
    st.Region;
GO

-- =============================================
-- REPORT 8: Sales Returns Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_ReturnsAnalysis AS
SELECT
    DATEPART(YEAR, sr.ReturnDate) AS Year,
    DATEPART(MONTH, sr.ReturnDate) AS Month,
    rr.ReasonCode,
    rr.ReasonDescription,
    c.CustomerName,
    c.CustomerType,
    sc.ChannelName,
    COUNT(DISTINCT sr.ReturnID) AS ReturnCount,
    SUM(sr.RefundAmount) AS TotalRefunds,
    AVG(sr.RefundAmount) AS AvgRefundAmount,
    SUM(sr.RestockingFee) AS TotalRestockingFees,
    -- Item details
    i.ItemCode,
    i.ItemName,
    SUM(srd.QuantityReturned) AS UnitsReturned,
    srd.Disposition,
    -- Calculate return rate
    COUNT(DISTINCT sr.ReturnID) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM SalesOrder WHERE Status = 'Delivered'), 0) AS ReturnRatePercent
FROM SalesReturn sr
INNER JOIN ReturnReason rr ON sr.ReturnReasonID = rr.ReturnReasonID
INNER JOIN Customer c ON sr.CustomerID = c.CustomerID
INNER JOIN SalesOrder so ON sr.SalesOrderID = so.SalesOrderID
INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
INNER JOIN SalesReturnDetail srd ON sr.ReturnID = srd.ReturnID
INNER JOIN Items i ON srd.ItemID = i.ItemID
GROUP BY
    DATEPART(YEAR, sr.ReturnDate),
    DATEPART(MONTH, sr.ReturnDate),
    rr.ReasonCode,
    rr.ReasonDescription,
    c.CustomerName,
    c.CustomerType,
    sc.ChannelName,
    i.ItemCode,
    i.ItemName,
    srd.Disposition;
GO

-- =============================================
-- REPORT 9: Sales Quote Conversion Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_QuoteConversion AS
SELECT
    sq.QuoteNumber,
    sq.Status AS QuoteStatus,
    c.CustomerName,
    c.CustomerType,
    sc.ChannelName,
    sr.FirstName + ' ' + sr.LastName AS SalesRep,
    st.TerritoryName,
    sq.QuoteDate,
    sq.ExpirationDate,
    DATEDIFF(DAY, sq.QuoteDate, sq.ExpirationDate) AS DaysToExpire,
    sq.TotalAmount AS QuoteAmount,
    CASE
        WHEN sq.Status = 'Accepted' AND sq.ConvertedToOrderID IS NOT NULL THEN 'Converted'
        WHEN sq.Status = 'Accepted' AND sq.ConvertedToOrderID IS NULL THEN 'Accepted - Pending'
        WHEN sq.Status = 'Declined' THEN 'Lost'
        WHEN sq.Status = 'Expired' THEN 'Expired'
        ELSE 'Open'
    END AS ConversionStatus,
    so.OrderNumber AS ConvertedOrderNumber,
    so.TotalAmount AS OrderAmount,
    sq.TotalAmount - ISNULL(so.TotalAmount, 0) AS ValueVariance,
    DATEDIFF(DAY, sq.QuoteDate, so.OrderDate) AS DaysToConvert
FROM SalesQuote sq
INNER JOIN Customer c ON sq.CustomerID = c.CustomerID
LEFT JOIN SalesChannel sc ON sq.SalesChannelID = sc.SalesChannelID
LEFT JOIN SalesRep sr ON sq.SalesRepID = sr.SalesRepID
LEFT JOIN SalesTerritory st ON sr.TerritoryID = st.TerritoryID
LEFT JOIN SalesOrder so ON sq.ConvertedToOrderID = so.SalesOrderID;
GO

-- =============================================
-- REPORT 10: Discount Analysis Report
-- =============================================

CREATE OR ALTER VIEW vw_Sales_DiscountAnalysis AS
SELECT
    DATEPART(YEAR, so.OrderDate) AS Year,
    DATEPART(MONTH, so.OrderDate) AS Month,
    sc.ChannelName,
    c.CustomerType,
    COUNT(DISTINCT so.SalesOrderID) AS OrderCount,
    SUM(so.Subtotal) AS GrossSales,
    SUM(so.DiscountAmount) AS TotalDiscounts,
    SUM(so.NetAmount) AS NetSales,
    CAST(SUM(so.DiscountAmount) * 100.0 / NULLIF(SUM(so.Subtotal), 0) AS DECIMAL(5,2)) AS DiscountPercent,
    AVG(so.DiscountAmount) AS AvgDiscountPerOrder,
    -- By discount level
    SUM(CASE WHEN so.DiscountAmount = 0 THEN 1 ELSE 0 END) AS NoDiscountOrders,
    SUM(CASE WHEN so.DiscountAmount > 0 AND so.DiscountAmount <= 100 THEN 1 ELSE 0 END) AS LowDiscountOrders,
    SUM(CASE WHEN so.DiscountAmount > 100 AND so.DiscountAmount <= 500 THEN 1 ELSE 0 END) AS MediumDiscountOrders,
    SUM(CASE WHEN so.DiscountAmount > 500 THEN 1 ELSE 0 END) AS HighDiscountOrders,
    -- Margin impact
    SUM(so.NetAmount) - SUM(sod.Quantity * i.StandardCost) AS GrossProfit,
    CAST((SUM(so.NetAmount) - SUM(sod.Quantity * i.StandardCost)) * 100.0 /
        NULLIF(SUM(so.NetAmount), 0) AS DECIMAL(5,2)) AS GrossMarginPercent
FROM SalesOrder so
INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
INNER JOIN Customer c ON so.CustomerID = c.CustomerID
LEFT JOIN SalesOrderDetail sod ON so.SalesOrderID = sod.SalesOrderID
LEFT JOIN Items i ON sod.ItemID = i.ItemID
GROUP BY
    DATEPART(YEAR, so.OrderDate),
    DATEPART(MONTH, so.OrderDate),
    sc.ChannelName,
    c.CustomerType;
GO

-- =============================================
-- REPORT 11: Top Selling Products Report
-- =============================================

CREATE OR ALTER VIEW vw_Sales_TopProducts AS
WITH ProductSales AS (
    SELECT
        i.ItemCode,
        i.ItemName,
        sc.ChannelName,
        DATEPART(YEAR, so.OrderDate) AS Year,
        DATEPART(MONTH, so.OrderDate) AS Month,
        SUM(sod.Quantity) AS UnitsSold,
        SUM(sod.NetAmount) AS Revenue,
        SUM(sod.NetAmount - (sod.Quantity * i.StandardCost)) AS GrossProfit,
        COUNT(DISTINCT so.CustomerID) AS UniqueCustomers
    FROM Items i
    INNER JOIN ItemType it ON i.ItemTypeID = it.ItemTypeID
    INNER JOIN SalesOrderDetail sod ON i.ItemID = sod.ItemID
    INNER JOIN SalesOrder so ON sod.SalesOrderID = so.SalesOrderID
    INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
    WHERE it.TypeCode = 'FG'
    GROUP BY
        i.ItemCode,
        i.ItemName,
        sc.ChannelName,
        DATEPART(YEAR, so.OrderDate),
        DATEPART(MONTH, so.OrderDate)
)
SELECT
    *,
    RANK() OVER (PARTITION BY ChannelName, Year, Month ORDER BY UnitsSold DESC) AS UnitRank,
    RANK() OVER (PARTITION BY ChannelName, Year, Month ORDER BY Revenue DESC) AS RevenueRank,
    RANK() OVER (PARTITION BY ChannelName, Year, Month ORDER BY GrossProfit DESC) AS ProfitRank
FROM ProductSales;
GO

-- =============================================
-- REPORT 12: Sales by Territory Report
-- =============================================

CREATE OR ALTER VIEW vw_Sales_ByTerritory AS
SELECT
    st.TerritoryCode,
    st.TerritoryName,
    st.Region,
    COUNT(DISTINCT sr.SalesRepID) AS SalesReps,
    COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
    COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
    SUM(so.Subtotal) AS GrossSales,
    SUM(so.DiscountAmount) AS Discounts,
    SUM(so.NetAmount) AS NetSales,
    AVG(so.NetAmount) AS AvgOrderValue,
    SUM(so.NetAmount) / NULLIF(COUNT(DISTINCT sr.SalesRepID), 0) AS SalesPerRep,
    SUM(so.NetAmount) / NULLIF(COUNT(DISTINCT c.CustomerID), 0) AS SalesPerCustomer,
    -- Top products in territory
    (SELECT TOP 1 i.ItemName
     FROM SalesOrder so2
     INNER JOIN SalesOrderDetail sod ON so2.SalesOrderID = sod.SalesOrderID
     INNER JOIN Items i ON sod.ItemID = i.ItemID
     INNER JOIN Customer c2 ON so2.CustomerID = c2.CustomerID
     WHERE c2.TerritoryID = st.TerritoryID
     GROUP BY i.ItemName
     ORDER BY SUM(sod.Quantity) DESC) AS TopProduct
FROM SalesTerritory st
LEFT JOIN SalesRep sr ON st.TerritoryID = sr.TerritoryID
LEFT JOIN Customer c ON st.TerritoryID = c.TerritoryID
LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID
WHERE st.IsActive = 1
GROUP BY
    st.TerritoryCode,
    st.TerritoryName,
    st.Region,
    st.TerritoryID;
GO

-- =============================================
-- REPORT 13: Channel Profitability Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_ChannelProfitability AS
WITH ChannelMetrics AS (
    SELECT
        sc.ChannelCode,
        sc.ChannelName,
        COUNT(DISTINCT so.SalesOrderID) AS OrderCount,
        SUM(sod.Quantity) AS TotalUnits,
        SUM(so.Subtotal) AS GrossSales,
        SUM(so.DiscountAmount) AS Discounts,
        SUM(so.NetAmount) AS NetSales,
        SUM(so.ShippingAmount) AS ShippingRevenue,
        SUM(sod.Quantity * i.StandardCost) AS COGS,
        SUM(so.NetAmount - (sod.Quantity * i.StandardCost)) AS GrossProfit,
        AVG(so.NetAmount) AS AvgOrderValue
    FROM SalesChannel sc
    LEFT JOIN SalesOrder so ON sc.SalesChannelID = so.SalesChannelID
    LEFT JOIN SalesOrderDetail sod ON so.SalesOrderID = sod.SalesOrderID
    LEFT JOIN Items i ON sod.ItemID = i.ItemID
    GROUP BY sc.ChannelCode, sc.ChannelName
)
SELECT
    ChannelCode,
    ChannelName,
    OrderCount,
    TotalUnits,
    GrossSales,
    Discounts,
    NetSales,
    ShippingRevenue,
    COGS,
    GrossProfit,
    AvgOrderValue,
    CAST(GrossProfit * 100.0 / NULLIF(NetSales, 0) AS DECIMAL(5,2)) AS GrossMarginPercent,
    CAST(Discounts * 100.0 / NULLIF(GrossSales, 0) AS DECIMAL(5,2)) AS DiscountPercent,
    GrossProfit / NULLIF(OrderCount, 0) AS ProfitPerOrder,
    GrossProfit / NULLIF(TotalUnits, 0) AS ProfitPerUnit,
    RANK() OVER (ORDER BY GrossProfit DESC) AS ProfitabilityRank
FROM ChannelMetrics;
GO

-- =============================================
-- REPORT 14: Customer Lifetime Value
-- =============================================

CREATE OR ALTER VIEW vw_Sales_CustomerLifetimeValue AS
WITH CustomerValue AS (
    SELECT
        c.CustomerID,
        c.CustomerCode,
        c.CustomerName,
        c.CustomerType,
        sr.FirstName + ' ' + sr.LastName AS SalesRep,
        MIN(so.OrderDate) AS FirstPurchaseDate,
        MAX(so.OrderDate) AS LastPurchaseDate,
        DATEDIFF(MONTH, MIN(so.OrderDate), MAX(so.OrderDate)) + 1 AS CustomerLifetimeMonths,
        COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
        SUM(so.NetAmount) AS TotalRevenue,
        SUM(so.NetAmount - ISNULL(sod.Quantity * i.StandardCost, 0)) AS TotalProfit,
        AVG(so.NetAmount) AS AvgOrderValue,
        SUM(so.NetAmount) / NULLIF(DATEDIFF(MONTH, MIN(so.OrderDate), MAX(so.OrderDate)) + 1, 0) AS AvgMonthlyRevenue
    FROM Customer c
    LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID
    LEFT JOIN SalesOrderDetail sod ON so.SalesOrderID = sod.SalesOrderID
    LEFT JOIN Items i ON sod.ItemID = i.ItemID
    LEFT JOIN SalesRep sr ON c.SalesRepID = sr.SalesRepID
    GROUP BY
        c.CustomerID, c.CustomerCode, c.CustomerName, c.CustomerType,
        sr.FirstName, sr.LastName
)
SELECT
    *,
    CASE
        WHEN TotalRevenue >= 20000 THEN 'Platinum'
        WHEN TotalRevenue >= 10000 THEN 'Gold'
        WHEN TotalRevenue >= 5000 THEN 'Silver'
        WHEN TotalRevenue >= 1000 THEN 'Bronze'
        ELSE 'Standard'
    END AS CustomerTier,
    DATEDIFF(DAY, LastPurchaseDate, GETDATE()) AS DaysSinceLastPurchase,
    CASE
        WHEN DATEDIFF(DAY, LastPurchaseDate, GETDATE()) <= 30 THEN 'Highly Active'
        WHEN DATEDIFF(DAY, LastPurchaseDate, GETDATE()) <= 90 THEN 'Active'
        WHEN DATEDIFF(DAY, LastPurchaseDate, GETDATE()) <= 180 THEN 'At Risk'
        ELSE 'Churned'
    END AS ActivityStatus,
    -- Projected annual value
    AvgMonthlyRevenue * 12 AS ProjectedAnnualRevenue,
    RANK() OVER (ORDER BY TotalRevenue DESC) AS ValueRank
FROM CustomerValue
WHERE TotalOrders > 0;
GO

-- =============================================
-- REPORT 15: Sales Growth Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_GrowthAnalysis AS
WITH MonthlyGrowth AS (
    SELECT
        DATEPART(YEAR, OrderDate) AS Year,
        DATEPART(MONTH, OrderDate) AS Month,
        sc.ChannelName,
        COUNT(DISTINCT SalesOrderID) AS Orders,
        COUNT(DISTINCT CustomerID) AS Customers,
        SUM(NetAmount) AS Revenue
    FROM SalesOrder so
    INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
    GROUP BY
        DATEPART(YEAR, OrderDate),
        DATEPART(MONTH, OrderDate),
        sc.ChannelName
)
SELECT
    Year,
    Month,
    ChannelName,
    Orders,
    Customers,
    Revenue,
    -- Growth metrics
    LAG(Revenue) OVER (PARTITION BY ChannelName ORDER BY Year, Month) AS PriorMonthRevenue,
    Revenue - LAG(Revenue) OVER (PARTITION BY ChannelName ORDER BY Year, Month) AS RevenueGrowth,
    CAST((Revenue - LAG(Revenue) OVER (PARTITION BY ChannelName ORDER BY Year, Month)) * 100.0 /
        NULLIF(LAG(Revenue) OVER (PARTITION BY ChannelName ORDER BY Year, Month), 0) AS DECIMAL(5,2)) AS GrowthPercent,
    LAG(Customers) OVER (PARTITION BY ChannelName ORDER BY Year, Month) AS PriorMonthCustomers,
    Customers - LAG(Customers) OVER (PARTITION BY ChannelName ORDER BY Year, Month) AS CustomerGrowth,
    -- Cumulative
    SUM(Revenue) OVER (PARTITION BY ChannelName ORDER BY Year, Month) AS CumulativeRevenue,
    -- Moving average
    AVG(Revenue) OVER (PARTITION BY ChannelName ORDER BY Year, Month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg
FROM MonthlyGrowth;
GO

-- =============================================
-- REPORT 16: Order Size Distribution
-- =============================================

CREATE OR ALTER VIEW vw_Sales_OrderSizeDistribution AS
WITH OrderBuckets AS (
    SELECT
        so.SalesOrderID,
        sc.ChannelName,
        c.CustomerType,
        so.NetAmount,
        COUNT(DISTINCT sod.SODetailID) AS LineItems,
        SUM(sod.Quantity) AS TotalUnits,
        CASE
            WHEN so.NetAmount < 500 THEN 'Small (< $500)'
            WHEN so.NetAmount < 1500 THEN 'Medium ($500-$1,499)'
            WHEN so.NetAmount < 5000 THEN 'Large ($1,500-$4,999)'
            ELSE 'Enterprise (>= $5,000)'
        END AS OrderSizeBucket,
        CASE
            WHEN COUNT(DISTINCT sod.SODetailID) = 1 THEN 'Single Item'
            WHEN COUNT(DISTINCT sod.SODetailID) BETWEEN 2 AND 3 THEN 'Small Basket'
            WHEN COUNT(DISTINCT sod.SODetailID) BETWEEN 4 AND 6 THEN 'Medium Basket'
            ELSE 'Large Basket'
        END AS BasketSize
    FROM SalesOrder so
    INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
    INNER JOIN Customer c ON so.CustomerID = c.CustomerID
    LEFT JOIN SalesOrderDetail sod ON so.SalesOrderID = sod.SalesOrderID
    GROUP BY
        so.SalesOrderID,
        sc.ChannelName,
        c.CustomerType,
        so.NetAmount
)
SELECT
    ChannelName,
    CustomerType,
    OrderSizeBucket,
    BasketSize,
    COUNT(*) AS OrderCount,
    SUM(NetAmount) AS TotalRevenue,
    AVG(NetAmount) AS AvgOrderValue,
    AVG(TotalUnits) AS AvgUnitsPerOrder,
    AVG(LineItems) AS AvgLineItems,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ChannelName) AS DECIMAL(5,2)) AS PercentOfChannelOrders
FROM OrderBuckets
GROUP BY
    ChannelName,
    CustomerType,
    OrderSizeBucket,
    BasketSize;
GO

-- =============================================
-- REPORT 17: Product Mix Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_ProductMixAnalysis AS
WITH ProductMix AS (
    SELECT
        so.SalesOrderID,
        so.OrderNumber,
        sc.ChannelName,
        c.CustomerType,
        STRING_AGG(i.ItemCode, ', ') WITHIN GROUP (ORDER BY i.ItemCode) AS ProductMix,
        COUNT(DISTINCT i.ItemID) AS UniqueProducts,
        SUM(sod.Quantity) AS TotalUnits,
        SUM(sod.NetAmount) AS OrderValue
    FROM SalesOrder so
    INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
    INNER JOIN Customer c ON so.CustomerID = c.CustomerID
    INNER JOIN SalesOrderDetail sod ON so.SalesOrderID = sod.SalesOrderID
    INNER JOIN Items i ON sod.ItemID = i.ItemID
    GROUP BY
        so.SalesOrderID,
        so.OrderNumber,
        sc.ChannelName,
        c.CustomerType
)
SELECT
    ChannelName,
    CustomerType,
    ProductMix,
    COUNT(*) AS OrderCount,
    SUM(OrderValue) AS TotalRevenue,
    AVG(OrderValue) AS AvgOrderValue,
    AVG(TotalUnits) AS AvgUnits,
    RANK() OVER (PARTITION BY ChannelName ORDER BY COUNT(*) DESC) AS PopularityRank
FROM ProductMix
GROUP BY
    ChannelName,
    CustomerType,
    ProductMix;
GO

-- =============================================
-- REPORT 18: Day of Week / Time-Based Analysis
-- =============================================

CREATE OR ALTER VIEW vw_Sales_TimeBasedAnalysis AS
SELECT
    DATENAME(WEEKDAY, so.OrderDate) AS DayOfWeek,
    DATEPART(WEEKDAY, so.OrderDate) AS DayNumber,
    DATEPART(HOUR, so.CreatedDate) AS HourOfDay,
    CASE
        WHEN DATEPART(HOUR, so.CreatedDate) BETWEEN 6 AND 11 THEN 'Morning (6-11)'
        WHEN DATEPART(HOUR, so.CreatedDate) BETWEEN 12 AND 17 THEN 'Afternoon (12-17)'
        WHEN DATEPART(HOUR, so.CreatedDate) BETWEEN 18 AND 21 THEN 'Evening (18-21)'
        ELSE 'Night (22-5)'
    END AS TimeOfDay,
    sc.ChannelName,
    COUNT(DISTINCT so.SalesOrderID) AS OrderCount,
    SUM(so.NetAmount) AS TotalRevenue,
    AVG(so.NetAmount) AS AvgOrderValue,
    COUNT(DISTINCT so.CustomerID) AS UniqueCustomers
FROM SalesOrder so
INNER JOIN SalesChannel sc ON so.SalesChannelID = sc.SalesChannelID
GROUP BY
    DATENAME(WEEKDAY, so.OrderDate),
    DATEPART(WEEKDAY, so.OrderDate),
    DATEPART(HOUR, so.CreatedDate),
    CASE
        WHEN DATEPART(HOUR, so.CreatedDate) BETWEEN 6 AND 11 THEN 'Morning (6-11)'
        WHEN DATEPART(HOUR, so.CreatedDate) BETWEEN 12 AND 17 THEN 'Afternoon (12-17)'
        WHEN DATEPART(HOUR, so.CreatedDate) BETWEEN 18 AND 21 THEN 'Evening (18-21)'
        ELSE 'Night (22-5)'
    END,
    sc.ChannelName;
GO

-- =============================================
-- REPORT 19: Sales Pipeline (Quotes to Orders)
-- =============================================

CREATE OR ALTER VIEW vw_Sales_Pipeline AS
WITH PipelineMetrics AS (
    SELECT
        'Quotes' AS Stage,
        1 AS StageOrder,
        COUNT(*) AS Count,
        SUM(TotalAmount) AS Value
    FROM SalesQuote
    WHERE Status NOT IN ('Expired', 'Declined')

    UNION ALL

    SELECT
        'Quotes - Accepted' AS Stage,
        2 AS StageOrder,
        COUNT(*) AS Count,
        SUM(TotalAmount) AS Value
    FROM SalesQuote
    WHERE Status = 'Accepted'

    UNION ALL

    SELECT
        'Orders - Confirmed' AS Stage,
        3 AS StageOrder,
        COUNT(*) AS Count,
        SUM(NetAmount) AS Value
    FROM SalesOrder
    WHERE Status = 'Confirmed'

    UNION ALL

    SELECT
        'Orders - In Production' AS Stage,
        4 AS StageOrder,
        COUNT(*) AS Count,
        SUM(NetAmount) AS Value
    FROM SalesOrder
    WHERE Status = 'InProduction'

    UNION ALL

    SELECT
        'Orders - Shipped' AS Stage,
        5 AS StageOrder,
        COUNT(*) AS Count,
        SUM(NetAmount) AS Value
    FROM SalesOrder
    WHERE Status = 'Shipped'

    UNION ALL

    SELECT
        'Orders - Delivered' AS Stage,
        6 AS StageOrder,
        COUNT(*) AS Count,
        SUM(NetAmount) AS Value
    FROM SalesOrder
    WHERE Status = 'Delivered'
)
SELECT
    Stage,
    StageOrder,
    Count,
    Value,
    LAG(Count) OVER (ORDER BY StageOrder) AS PriorStageCount,
    LAG(Value) OVER (ORDER BY StageOrder) AS PriorStageValue,
    CAST(Count * 100.0 / NULLIF(LAG(Count) OVER (ORDER BY StageOrder), 0) AS DECIMAL(5,2)) AS ConversionRate,
    CAST(Value * 100.0 / NULLIF(LAG(Value) OVER (ORDER BY StageOrder), 0) AS DECIMAL(5,2)) AS ValueRetentionRate
FROM PipelineMetrics;
GO

-- =============================================
-- REPORT 20: Customer Segmentation RFM Analysis
-- (Recency, Frequency, Monetary)
-- =============================================

CREATE OR ALTER VIEW vw_Sales_CustomerSegmentation AS
WITH RFMScores AS (
    SELECT
        c.CustomerID,
        c.CustomerCode,
        c.CustomerName,
        c.CustomerType,
        DATEDIFF(DAY, MAX(so.OrderDate), GETDATE()) AS Recency,
        COUNT(DISTINCT so.SalesOrderID) AS Frequency,
        SUM(so.NetAmount) AS Monetary,
        NTILE(5) OVER (ORDER BY DATEDIFF(DAY, MAX(so.OrderDate), GETDATE())) AS R_Score,
        NTILE(5) OVER (ORDER BY COUNT(DISTINCT so.SalesOrderID) DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY SUM(so.NetAmount) DESC) AS M_Score
    FROM Customer c
    LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID
    WHERE so.Status = 'Delivered'
    GROUP BY c.CustomerID, c.CustomerCode, c.CustomerName, c.CustomerType
)
SELECT
    *,
    (R_Score + F_Score + M_Score) / 3.0 AS RFM_Score,
    CASE
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
        WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Loyal Customers'
        WHEN R_Score >= 4 AND F_Score <= 2 THEN 'New Customers'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk'
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Lost'
        WHEN M_Score >= 4 THEN 'Big Spenders'
        ELSE 'Others'
    END AS CustomerSegment,
    CASE
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Maintain relationship, offer loyalty rewards'
        WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Upsell higher value products'
        WHEN R_Score >= 4 AND F_Score <= 2 THEN 'Build relationship, increase frequency'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'Win back campaign, special offers'
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Reactivation campaign'
        WHEN M_Score >= 4 THEN 'Focus on satisfaction and retention'
        ELSE 'Increase engagement'
    END AS RecommendedAction
FROM RFMScores;
GO

PRINT 'All 20 sales operations reports created successfully!';
PRINT '';
PRINT 'Available Sales Reports:';
PRINT '1.  vw_Sales_ByChannel - Sales Performance by Channel';
PRINT '2.  vw_Sales_StorePerformance - Store Performance Report';
PRINT '3.  vw_Sales_RepPerformance - Sales Representative Performance';
PRINT '4.  vw_Sales_CustomerAnalysis - Customer Sales Analysis';
PRINT '5.  vw_Sales_ProductPerformance - Product Sales Performance';
PRINT '6.  vw_Sales_TrendAnalysis - Sales Trend Analysis';
PRINT '7.  vw_Sales_OrderValueAnalysis - Average Order Value Analysis';
PRINT '8.  vw_Sales_ReturnsAnalysis - Sales Returns Analysis';
PRINT '9.  vw_Sales_QuoteConversion - Sales Quote Conversion Analysis';
PRINT '10. vw_Sales_DiscountAnalysis - Discount Analysis Report';
PRINT '11. vw_Sales_TopProducts - Top Selling Products Report';
PRINT '12. vw_Sales_ByTerritory - Sales by Territory Report';
PRINT '13. vw_Sales_ChannelProfitability - Channel Profitability Analysis';
PRINT '14. vw_Sales_CustomerLifetimeValue - Customer Lifetime Value';
PRINT '15. vw_Sales_GrowthAnalysis - Sales Growth Analysis';
PRINT '16. vw_Sales_OrderSizeDistribution - Order Size Distribution';
PRINT '17. vw_Sales_ProductMixAnalysis - Product Mix Analysis';
PRINT '18. vw_Sales_TimeBasedAnalysis - Day of Week / Time-Based Analysis';
PRINT '19. vw_Sales_Pipeline - Sales Pipeline (Quotes to Orders)';
PRINT '20. vw_Sales_CustomerSegmentation - Customer Segmentation RFM Analysis';
GO
