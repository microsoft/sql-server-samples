-- =============================================
-- Sample Sales Operations Queries
-- Futon Manufacturing Database
-- =============================================

USE FutonManufacturing;
GO

PRINT '=============================================';
PRINT 'SAMPLE SALES OPERATIONS QUERIES';
PRINT '=============================================';
PRINT '';

-- =============================================
-- 1. SALES BY CHANNEL
-- =============================================

PRINT '1. Sales Performance by Channel - Current Month';
PRINT '---------------------------------------------------------------------';
SELECT
    ChannelName,
    Year,
    Month,
    OrderCount,
    UniqueCustomers,
    CAST(GrossSales AS DECIMAL(18,2)) AS GrossSales,
    CAST(TotalDiscounts AS DECIMAL(18,2)) AS Discounts,
    CAST(NetSales AS DECIMAL(18,2)) AS NetSales,
    CAST(AvgOrderValue AS DECIMAL(18,2)) AS AvgOrderValue,
    AvgDiscountPercent AS [Discount %]
FROM vw_Sales_ByChannel
WHERE Year = YEAR(GETDATE()) AND Month = MONTH(GETDATE())
ORDER BY NetSales DESC;
GO

PRINT '';
PRINT '2. Channel Performance Comparison - Last 3 Months';
PRINT '---------------------------------------------------------------------';
SELECT
    ChannelName,
    SUM(OrderCount) AS TotalOrders,
    SUM(UniqueCustomers) AS TotalCustomers,
    CAST(SUM(NetSales) AS DECIMAL(18,2)) AS TotalSales,
    CAST(AVG(AvgOrderValue) AS DECIMAL(18,2)) AS AvgOrderValue
FROM vw_Sales_ByChannel
WHERE DATEFROMPARTS(Year, Month, 1) >= DATEADD(MONTH, -3, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
GROUP BY ChannelName
ORDER BY TotalSales DESC;
GO

-- =============================================
-- 2. STORE PERFORMANCE
-- =============================================

PRINT '';
PRINT '3. Top Performing Stores by Sales';
PRINT '---------------------------------------------------------------------';
SELECT
    StoreCode,
    StoreName,
    City,
    State,
    Manager,
    TotalOrders,
    CAST(NetSales AS DECIMAL(18,2)) AS NetSales,
    CAST(AvgOrderValue AS DECIMAL(18,2)) AS AvgOrderValue,
    CAST(AvgDailySales AS DECIMAL(18,2)) AS AvgDailySales,
    CompletionRate AS [Completion %]
FROM vw_Sales_StorePerformance
WHERE TotalOrders > 0
ORDER BY NetSales DESC;
GO

-- =============================================
-- 3. SALES REP PERFORMANCE
-- =============================================

PRINT '';
PRINT '4. Sales Rep Leaderboard';
PRINT '---------------------------------------------------------------------';
SELECT
    SalesRepName,
    TerritoryName,
    Region,
    TotalOrders,
    UniqueCustomers,
    CAST(NetSales AS DECIMAL(18,2)) AS NetSales,
    CAST(AvgOrderValue AS DECIMAL(18,2)) AS AvgOrderValue,
    QuotesCreated,
    QuotesAccepted,
    QuoteWinRate AS [Win Rate %],
    SalesRank
FROM vw_Sales_RepPerformance
ORDER BY SalesRank;
GO

-- =============================================
-- 4. CUSTOMER ANALYSIS
-- =============================================

PRINT '';
PRINT '5. Top 10 Customers by Total Sales';
PRINT '---------------------------------------------------------------------';
SELECT TOP 10
    CustomerCode,
    CustomerName,
    CustomerType,
    City,
    State,
    TotalOrders,
    CAST(TotalSales AS DECIMAL(18,2)) AS TotalSales,
    CAST(AvgOrderValue AS DECIMAL(18,2)) AS AvgOrderValue,
    CustomerSegment,
    CustomerStatus,
    DaysSinceLastOrder
FROM vw_Sales_CustomerAnalysis
ORDER BY TotalSales DESC;
GO

PRINT '';
PRINT '6. At-Risk Customers (Inactive or Dormant)';
PRINT '---------------------------------------------------------------------';
SELECT
    CustomerName,
    CustomerType,
    TotalOrders,
    CAST(TotalSales AS DECIMAL(18,2)) AS TotalSales,
    LastOrderDate,
    DaysSinceLastOrder,
    CustomerStatus,
    SalesRep
FROM vw_Sales_CustomerAnalysis
WHERE CustomerStatus IN ('Inactive', 'Dormant')
ORDER BY TotalSales DESC;
GO

-- =============================================
-- 5. PRODUCT PERFORMANCE
-- =============================================

PRINT '';
PRINT '7. Top Selling Products - All Time';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemCode,
    ItemName,
    OrderCount,
    TotalUnitsSold,
    CAST(TotalRevenue AS DECIMAL(18,2)) AS Revenue,
    CAST(AvgSellingPrice AS DECIMAL(18,2)) AS AvgPrice,
    CAST(TotalGrossProfit AS DECIMAL(18,2)) AS GrossProfit,
    GrossMarginPercent AS [Margin %],
    UnitSalesRank,
    RevenueRank
FROM vw_Sales_ProductPerformance
ORDER BY TotalUnitsSold DESC;
GO

PRINT '';
PRINT '8. Product Performance by Channel';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemName,
    RetailUnits,
    OnlineUnits,
    WholesaleUnits,
    TotalUnitsSold,
    CAST(TotalRevenue AS DECIMAL(18,2)) AS Revenue
FROM vw_Sales_ProductPerformance
ORDER BY TotalUnitsSold DESC;
GO

-- =============================================
-- 6. SALES TRENDS
-- =============================================

PRINT '';
PRINT '9. Monthly Sales Trend';
PRINT '---------------------------------------------------------------------';
SELECT
    Year,
    Month,
    OrderCount,
    UniqueCustomers,
    CAST(NetSales AS DECIMAL(18,2)) AS NetSales,
    CAST(AvgOrderValue AS DECIMAL(18,2)) AS AvgOrderValue,
    CAST(PriorMonthSales AS DECIMAL(18,2)) AS PriorMonthSales,
    CAST(MoMChange AS DECIMAL(18,2)) AS MoMChange,
    MoMChangePercent AS [MoM %],
    CAST(ThreeMonthAvg AS DECIMAL(18,2)) AS [3-Month Avg]
FROM vw_Sales_TrendAnalysis
ORDER BY Year DESC, Month DESC;
GO

-- =============================================
-- 7. RETURNS ANALYSIS
-- =============================================

PRINT '';
PRINT '10. Sales Returns Summary by Reason';
PRINT '---------------------------------------------------------------------';
SELECT
    ReasonDescription,
    COUNT(DISTINCT ReturnID) AS ReturnCount,
    CAST(SUM(TotalRefunds) AS DECIMAL(18,2)) AS TotalRefunds,
    CAST(AVG(AvgRefundAmount) AS DECIMAL(18,2)) AS AvgRefundAmount,
    STRING_AGG(ItemName, ', ') AS ProductsReturned
FROM vw_Sales_ReturnsAnalysis
GROUP BY ReasonDescription
ORDER BY SUM(TotalRefunds) DESC;
GO

PRINT '';
PRINT '11. Returns by Product';
PRINT '---------------------------------------------------------------------';
SELECT
    ItemName,
    SUM(UnitsReturned) AS TotalReturned,
    CAST(SUM(TotalRefunds) AS DECIMAL(18,2)) AS RefundAmount,
    STRING_AGG(DISTINCT ReasonDescription, ', ') AS ReturnReasons
FROM vw_Sales_ReturnsAnalysis
GROUP BY ItemName
ORDER BY SUM(UnitsReturned) DESC;
GO

-- =============================================
-- 8. QUOTE CONVERSION
-- =============================================

PRINT '';
PRINT '12. Sales Quote Conversion Rates';
PRINT '---------------------------------------------------------------------';
SELECT
    QuoteStatus,
    ConversionStatus,
    COUNT(*) AS QuoteCount,
    CAST(AVG(QuoteAmount) AS DECIMAL(18,2)) AS AvgQuoteAmount,
    CAST(AVG(DaysToConvert) AS DECIMAL(10,1)) AS AvgDaysToConvert
FROM vw_Sales_QuoteConversion
GROUP BY QuoteStatus, ConversionStatus
ORDER BY QuoteCount DESC;
GO

PRINT '';
PRINT '13. Open Quotes Requiring Follow-Up';
PRINT '---------------------------------------------------------------------';
SELECT
    QuoteNumber,
    CustomerName,
    SalesRep,
    QuoteDate,
    ExpirationDate,
    DATEDIFF(DAY, GETDATE(), ExpirationDate) AS DaysUntilExpiration,
    CAST(QuoteAmount AS DECIMAL(18,2)) AS QuoteAmount,
    QuoteStatus
FROM vw_Sales_QuoteConversion
WHERE QuoteStatus IN ('Draft', 'Sent')
  AND ExpirationDate >= GETDATE()
ORDER BY ExpirationDate;
GO

-- =============================================
-- 9. DISCOUNT ANALYSIS
-- =============================================

PRINT '';
PRINT '14. Discount Impact by Channel';
PRINT '---------------------------------------------------------------------';
SELECT
    ChannelName,
    OrderCount,
    CAST(GrossSales AS DECIMAL(18,2)) AS GrossSales,
    CAST(TotalDiscounts AS DECIMAL(18,2)) AS TotalDiscounts,
    DiscountPercent AS [Discount %],
    CAST(GrossProfit AS DECIMAL(18,2)) AS GrossProfit,
    GrossMarginPercent AS [Margin %],
    NoDiscountOrders,
    LowDiscountOrders,
    MediumDiscountOrders,
    HighDiscountOrders
FROM vw_Sales_DiscountAnalysis
WHERE Year = YEAR(GETDATE())
GROUP BY ChannelName, OrderCount, GrossSales, TotalDiscounts, DiscountPercent,
    GrossProfit, GrossMarginPercent, NoDiscountOrders, LowDiscountOrders,
    MediumDiscountOrders, HighDiscountOrders
ORDER BY DiscountPercent DESC;
GO

-- =============================================
-- 10. TOP PRODUCTS
-- =============================================

PRINT '';
PRINT '15. Top 5 Products per Channel - Current Month';
PRINT '---------------------------------------------------------------------';
SELECT
    ChannelName,
    ItemName,
    UnitsSold,
    CAST(Revenue AS DECIMAL(18,2)) AS Revenue,
    CAST(GrossProfit AS DECIMAL(18,2)) AS GrossProfit,
    UnitRank
FROM vw_Sales_TopProducts
WHERE Year = YEAR(GETDATE())
  AND Month = MONTH(GETDATE())
  AND UnitRank <= 5
ORDER BY ChannelName, UnitRank;
GO

-- =============================================
-- 11. TERRITORY ANALYSIS
-- =============================================

PRINT '';
PRINT '16. Territory Performance Summary';
PRINT '---------------------------------------------------------------------';
SELECT
    TerritoryName,
    Region,
    SalesReps,
    TotalCustomers,
    TotalOrders,
    CAST(NetSales AS DECIMAL(18,2)) AS NetSales,
    CAST(SalesPerRep AS DECIMAL(18,2)) AS SalesPerRep,
    CAST(SalesPerCustomer AS DECIMAL(18,2)) AS SalesPerCustomer,
    TopProduct
FROM vw_Sales_ByTerritory
ORDER BY NetSales DESC;
GO

-- =============================================
-- 12. CHANNEL PROFITABILITY
-- =============================================

PRINT '';
PRINT '17. Channel Profitability Comparison';
PRINT '---------------------------------------------------------------------';
SELECT
    ChannelName,
    OrderCount,
    TotalUnits,
    CAST(GrossSales AS DECIMAL(18,2)) AS GrossSales,
    CAST(Discounts AS DECIMAL(18,2)) AS Discounts,
    CAST(NetSales AS DECIMAL(18,2)) AS NetSales,
    CAST(COGS AS DECIMAL(18,2)) AS COGS,
    CAST(GrossProfit AS DECIMAL(18,2)) AS GrossProfit,
    GrossMarginPercent AS [Margin %],
    CAST(ProfitPerOrder AS DECIMAL(18,2)) AS ProfitPerOrder,
    ProfitabilityRank
FROM vw_Sales_ChannelProfitability
ORDER BY ProfitabilityRank;
GO

-- =============================================
-- 13. CUSTOMER LIFETIME VALUE
-- =============================================

PRINT '';
PRINT '18. Top 10 Customers by Lifetime Value';
PRINT '---------------------------------------------------------------------';
SELECT TOP 10
    CustomerCode,
    CustomerName,
    CustomerType,
    TotalOrders,
    CAST(TotalRevenue AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(TotalProfit AS DECIMAL(18,2)) AS TotalProfit,
    CustomerLifetimeMonths,
    CAST(AvgMonthlyRevenue AS DECIMAL(18,2)) AS AvgMonthlyRevenue,
    CustomerTier,
    ActivityStatus,
    ValueRank
FROM vw_Sales_CustomerLifetimeValue
ORDER BY ValueRank;
GO

-- =============================================
-- 14. GROWTH ANALYSIS
-- =============================================

PRINT '';
PRINT '19. Sales Growth by Channel - Last 6 Months';
PRINT '---------------------------------------------------------------------';
SELECT
    Year,
    Month,
    ChannelName,
    Orders,
    Customers,
    CAST(Revenue AS DECIMAL(18,2)) AS Revenue,
    CAST(PriorMonthRevenue AS DECIMAL(18,2)) AS PriorMonthRevenue,
    CAST(RevenueGrowth AS DECIMAL(18,2)) AS Growth,
    GrowthPercent AS [Growth %],
    CAST(ThreeMonthAvg AS DECIMAL(18,2)) AS [3-Mo Avg]
FROM vw_Sales_GrowthAnalysis
WHERE DATEFROMPARTS(Year, Month, 1) >= DATEADD(MONTH, -6, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
ORDER BY Year DESC, Month DESC, ChannelName;
GO

-- =============================================
-- 15. ORDER SIZE DISTRIBUTION
-- =============================================

PRINT '';
PRINT '20. Order Size Distribution by Channel';
PRINT '---------------------------------------------------------------------';
SELECT
    ChannelName,
    OrderSizeBucket,
    OrderCount,
    CAST(TotalRevenue AS DECIMAL(18,2)) AS Revenue,
    CAST(AvgOrderValue AS DECIMAL(18,2)) AS AvgOrderValue,
    CAST(AvgUnitsPerOrder AS DECIMAL(10,1)) AS AvgUnits,
    PercentOfChannelOrders AS [% of Orders]
FROM vw_Sales_OrderSizeDistribution
GROUP BY ChannelName, OrderSizeBucket, OrderCount, TotalRevenue,
    AvgOrderValue, AvgUnitsPerOrder, PercentOfChannelOrders
ORDER BY ChannelName, OrderSizeBucket;
GO

-- =============================================
-- 16. TIME-BASED ANALYSIS
-- =============================================

PRINT '';
PRINT '21. Sales by Day of Week';
PRINT '---------------------------------------------------------------------';
SELECT
    DayOfWeek,
    SUM(OrderCount) AS TotalOrders,
    CAST(SUM(TotalRevenue) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(AVG(AvgOrderValue) AS DECIMAL(18,2)) AS AvgOrderValue,
    SUM(UniqueCustomers) AS TotalCustomers
FROM vw_Sales_TimeBasedAnalysis
GROUP BY DayOfWeek, DayNumber
ORDER BY DayNumber;
GO

PRINT '';
PRINT '22. Sales by Time of Day';
PRINT '---------------------------------------------------------------------';
SELECT
    TimeOfDay,
    SUM(OrderCount) AS TotalOrders,
    CAST(SUM(TotalRevenue) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(AVG(AvgOrderValue) AS DECIMAL(18,2)) AS AvgOrderValue
FROM vw_Sales_TimeBasedAnalysis
GROUP BY TimeOfDay
ORDER BY TotalOrders DESC;
GO

-- =============================================
-- 17. SALES PIPELINE
-- =============================================

PRINT '';
PRINT '23. Sales Pipeline Funnel';
PRINT '---------------------------------------------------------------------';
SELECT
    Stage,
    Count,
    CAST(Value AS DECIMAL(18,2)) AS Value,
    PriorStageCount,
    CAST(PriorStageValue AS DECIMAL(18,2)) AS PriorStageValue,
    ConversionRate AS [Conversion %],
    ValueRetentionRate AS [Value Retention %]
FROM vw_Sales_Pipeline
ORDER BY StageOrder;
GO

-- =============================================
-- 18. CUSTOMER SEGMENTATION
-- =============================================

PRINT '';
PRINT '24. Customer Segmentation - RFM Analysis';
PRINT '---------------------------------------------------------------------';
SELECT
    CustomerSegment,
    COUNT(*) AS CustomerCount,
    CAST(AVG(Monetary) AS DECIMAL(18,2)) AS AvgSpend,
    CAST(AVG(Frequency) AS DECIMAL(10,1)) AS AvgOrders,
    CAST(AVG(Recency) AS DECIMAL(10,1)) AS AvgDaysSinceOrder,
    CAST(SUM(Monetary) AS DECIMAL(18,2)) AS TotalRevenue
FROM vw_Sales_CustomerSegmentation
GROUP BY CustomerSegment
ORDER BY TotalRevenue DESC;
GO

PRINT '';
PRINT '25. Champions and At-Risk Customers';
PRINT '---------------------------------------------------------------------';
SELECT
    CustomerName,
    CustomerType,
    Frequency AS Orders,
    CAST(Monetary AS DECIMAL(18,2)) AS TotalSpend,
    Recency AS DaysSinceLastOrder,
    CustomerSegment,
    RecommendedAction
FROM vw_Sales_CustomerSegmentation
WHERE CustomerSegment IN ('Champions', 'At Risk', 'Lost')
ORDER BY CustomerSegment, Monetary DESC;
GO

-- =============================================
-- 19. ADVANCED ANALYTICS
-- =============================================

PRINT '';
PRINT '26. Cross-Sell Opportunities - Popular Product Combinations';
PRINT '---------------------------------------------------------------------';
SELECT TOP 10
    ProductMix,
    OrderCount,
    CAST(TotalRevenue AS DECIMAL(18,2)) AS Revenue,
    ChannelName,
    PopularityRank
FROM vw_Sales_ProductMixAnalysis
WHERE UniqueProducts > 1
ORDER BY OrderCount DESC;
GO

PRINT '';
PRINT '27. Sales KPI Dashboard - Current Month vs Prior Month';
PRINT '---------------------------------------------------------------------';
WITH CurrentMonth AS (
    SELECT
        SUM(OrderCount) AS Orders,
        SUM(UniqueCustomers) AS Customers,
        SUM(NetSales) AS Revenue
    FROM vw_Sales_ByChannel
    WHERE Year = YEAR(GETDATE()) AND Month = MONTH(GETDATE())
),
PriorMonth AS (
    SELECT
        SUM(OrderCount) AS Orders,
        SUM(UniqueCustomers) AS Customers,
        SUM(NetSales) AS Revenue
    FROM vw_Sales_ByChannel
    WHERE Year = YEAR(DATEADD(MONTH, -1, GETDATE()))
      AND Month = MONTH(DATEADD(MONTH, -1, GETDATE()))
)
SELECT
    'Orders' AS Metric,
    cm.Orders AS CurrentMonth,
    pm.Orders AS PriorMonth,
    cm.Orders - pm.Orders AS Change,
    CAST((cm.Orders - pm.Orders) * 100.0 / NULLIF(pm.Orders, 0) AS DECIMAL(5,2)) AS [Change %]
FROM CurrentMonth cm, PriorMonth pm

UNION ALL

SELECT
    'Customers',
    cm.Customers,
    pm.Customers,
    cm.Customers - pm.Customers,
    CAST((cm.Customers - pm.Customers) * 100.0 / NULLIF(pm.Customers, 0) AS DECIMAL(5,2))
FROM CurrentMonth cm, PriorMonth pm

UNION ALL

SELECT
    'Revenue',
    CAST(cm.Revenue AS INT),
    CAST(pm.Revenue AS INT),
    CAST(cm.Revenue - pm.Revenue AS INT),
    CAST((cm.Revenue - pm.Revenue) * 100.0 / NULLIF(pm.Revenue, 0) AS DECIMAL(5,2))
FROM CurrentMonth cm, PriorMonth pm;
GO

PRINT '';
PRINT '28. Channel Performance Summary - All Time';
PRINT '---------------------------------------------------------------------';
SELECT
    ChannelName,
    SUM(OrderCount) AS TotalOrders,
    SUM(UniqueCustomers) AS TotalCustomers,
    CAST(SUM(NetSales) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(AVG(AvgOrderValue) AS DECIMAL(18,2)) AS AvgOrderValue,
    CAST(AVG(AvgDiscountPercent) AS DECIMAL(5,2)) AS [Avg Discount %]
FROM vw_Sales_ByChannel
GROUP BY ChannelName
ORDER BY TotalRevenue DESC;
GO

PRINT '';
PRINT '=============================================';
PRINT 'Sales operations sample queries completed!';
PRINT 'Use these as templates for your sales analysis.';
PRINT '=============================================';
GO
