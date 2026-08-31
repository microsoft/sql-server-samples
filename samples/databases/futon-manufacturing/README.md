# Futon Manufacturing Database

A comprehensive SQL Server database designed for a futon manufacturing business with multi-level bill of materials (BOM), inventory management, production tracking, and sales operations.

## Overview

This database manages the complete manufacturing lifecycle for a futon manufacturer that produces finished futons from raw materials (fill, fabric, frames) through intermediate components (pillows, mattresses, frames) to finished goods.

## Features

- **Multi-Level Bill of Materials (BOM)**: Supports complex product structures with multiple levels of assembly
- **Inventory Management**: Track inventory across multiple warehouses with transaction history
- **Production Management**: Work orders, production completions, and work center capacity tracking
- **Quality Control**: Inspection tracking for incoming, in-process, and final products
- **Purchasing**: Purchase orders and supplier management
- **Sales Operations**: Multi-channel sales (Retail, Online, Wholesale) with complete order lifecycle
- **20 Manufacturing Reports**: Comprehensive reporting views for operational insights
- **20 Sales Operations Reports**: Complete sales analytics and performance metrics

## Database Structure

### Core Tables

#### Reference Tables
- `UnitOfMeasure` - Units like EA (Each), YD (Yard), LB (Pound)
- `ItemType` - Raw Material, Component, Finished Good
- `TransactionType` - Types of inventory transactions

#### Master Data
- `Items` - All products (raw materials, components, finished goods)
- `BillOfMaterials` - Multi-level product structure
- `Warehouse` - Storage locations
- `WorkCenter` - Production work centers
- `Supplier` - Vendor information
- `Customer` - Customer information

#### Operational Tables
- `Inventory` - Current inventory levels by warehouse
- `InventoryTransaction` - All inventory movements
- `PurchaseOrder` / `PurchaseOrderDetail` - Purchasing
- `ProductionOrder` / `ProductionOrderMaterial` / `ProductionCompletion` - Production
- `SalesOrder` / `SalesOrderDetail` - Sales
- `QualityInspection` - Quality control records

#### Sales Operations Tables
- `SalesChannel` - Sales channels (Retail, Online, Wholesale)
- `Store` - Retail store locations
- `SalesTerritory` - Geographic sales territories
- `SalesRep` - Sales representatives
- `SalesReturn` / `SalesReturnDetail` - Product returns and refunds
- `SalesQuote` / `SalesQuoteDetail` - Sales quotations
- `Promotion` - Promotional campaigns
- `PriceList` / `PriceListDetail` - Channel-specific pricing

## Product Hierarchy

The database includes three levels of products:

### Level 1: Raw Materials
- **Fill Materials**: Polyester fiber, memory foam, cotton, latex foam, down alternative
- **Fabrics**: Canvas (various colors), microfiber suede, linen blend, twill, velvet
- **Frame Materials**: Pine rails, hardwood slats, steel brackets, hinges, hardware
- **Finishes**: Wood stains and polyurethane

### Level 2: Components
- **Pillows**: Various fills and fabric combinations
- **Mattresses**: Twin, Full, Queen sizes with different fill types
- **Frames**: Different sizes and finishes (Natural Oak, Dark Walnut)

### Level 3: Finished Goods
- Complete futons combining mattress, frame, and pillows
- Multiple configurations from economy to luxury models
- Sizes: Twin, Full, Queen

## Installation

Run the SQL scripts in order:

```sql
-- 1. Create database and schema
:r 01-schema.sql

-- 2. Insert sample data
:r 02-sample-data.sql

-- 3. Create manufacturing reports
:r 03-manufacturing-reports.sql

-- 4. (Optional) Run manufacturing sample queries
:r 04-sample-queries.sql

-- 5. Enhance schema for sales operations
:r 05-sales-schema-enhancements.sql

-- 6. Insert sales sample data
:r 06-sales-sample-data.sql

-- 7. Create sales operations reports
:r 07-sales-reports.sql

-- 8. (Optional) Run sales sample queries
:r 08-sales-sample-queries.sql
```

## Manufacturing Reports

### 1. Multi-Level BOM Explosion (`vw_BOMExplosion`)
Shows complete material requirements for any item, recursively expanding through all levels.

```sql
-- Get all materials needed to build a specific futon
SELECT * FROM vw_BOMExplosion
WHERE ParentItemCode = 'FG-FUT-001'
ORDER BY Level, ComponentItemCode;
```

### 2. Where-Used Report (`vw_WhereUsed`)
Shows where each component is used throughout the product structure.

```sql
-- Find all products that use a specific fabric
SELECT * FROM vw_WhereUsed
WHERE ComponentItemCode = 'RM-FAB-001';
```

### 3. Inventory Valuation (`vw_InventoryValuation`)
Current inventory value by warehouse and item type.

```sql
-- Total inventory value by type
SELECT ItemType, SUM(InventoryValue) AS TotalValue
FROM vw_InventoryValuation
GROUP BY ItemType;
```

### 4. Items Below Reorder Point (`vw_ItemsBelowReorderPoint`)
Items that need to be reordered with supplier information.

```sql
-- Get critical shortages
SELECT * FROM vw_ItemsBelowReorderPoint
ORDER BY ShortageQuantity DESC;
```

### 5. Production Order Status (`vw_ProductionOrderStatus`)
Track production orders with completion percentages and schedule status.

```sql
-- Active production orders with status
SELECT * FROM vw_ProductionOrderStatus
WHERE Status IN ('Planned', 'Released', 'InProgress')
ORDER BY PlannedCompletionDate;
```

### 6. Material Requirements Planning - MRP (`vw_MaterialRequirements`)
Calculate material needs for all open production orders.

```sql
-- Material shortages for production
SELECT * FROM vw_MaterialRequirements
WHERE AvailabilityStatus IN ('Out of Stock', 'Partial')
ORDER BY PlannedCompletionDate;
```

### 7. Work Center Capacity Analysis (`vw_WorkCenterCapacity`)
Analyze workload and capacity by work center.

```sql
-- Work center utilization
SELECT * FROM vw_WorkCenterCapacity
ORDER BY DaysOfWork DESC;
```

### 8. Production Completion Summary (`vw_ProductionCompletionSummary`)
Production output and scrap rates by period.

```sql
-- Monthly production summary
SELECT Year, Month, SUM(TotalCompleted) AS Units, AVG(ScrapRate) AS AvgScrapRate
FROM vw_ProductionCompletionSummary
GROUP BY Year, Month;
```

### 9. Quality Inspection Summary (`vw_QualityInspectionSummary`)
Quality metrics and acceptance rates.

```sql
-- Quality performance by inspection type
SELECT InspectionType, AVG(AcceptanceRate) AS AvgAcceptanceRate
FROM vw_QualityInspectionSummary
GROUP BY InspectionType;
```

### 10. Supplier Performance (`vw_SupplierPerformance`)
Evaluate supplier delivery performance and ratings.

```sql
-- Top performing suppliers
SELECT * FROM vw_SupplierPerformance
ORDER BY OnTimeDeliveryRate DESC;
```

### 11. Purchase Order Status (`vw_PurchaseOrderStatus`)
Track purchase orders and receiving progress.

```sql
-- Overdue purchase orders
SELECT * FROM vw_PurchaseOrderStatus
WHERE DeliveryStatus = 'Overdue';
```

### 12. Sales Order Backlog (`vw_SalesOrderBacklog`)
Monitor unfulfilled customer orders.

```sql
-- Orders due soon
SELECT * FROM vw_SalesOrderBacklog
WHERE FulfillmentStatus = 'Due Soon'
ORDER BY RequestedDeliveryDate;
```

### 13. Cost Roll-Up (`vw_CostRollUp`)
Item costs with material cost breakdown and profit margins.

```sql
-- Profit analysis for finished goods
SELECT * FROM vw_CostRollUp
WHERE ItemType = 'Finished Goods'
ORDER BY GrossMarginPercent DESC;
```

### 14. Inventory Turnover Analysis (`vw_InventoryTurnover`)
Analyze inventory movement and identify slow-moving items.

```sql
-- Slow and non-moving inventory
SELECT * FROM vw_InventoryTurnover
WHERE MovementClass IN ('Slow Moving', 'Non-Moving');
```

### 15. Late Production Orders (`vw_LateProductionOrders`)
Production orders past their due date.

```sql
-- Critical late orders
SELECT * FROM vw_LateProductionOrders
WHERE LatenessSeverity IN ('Critical', 'High')
ORDER BY DaysLate DESC;
```

### 16. Component Shortage Report (`vw_ComponentShortage`)
Identify component shortages affecting production.

```sql
-- Urgent shortages
SELECT * FROM vw_ComponentShortage
WHERE UrgencyLevel = 'Urgent'
ORDER BY DaysUntilNeeded;
```

### 17. Daily Production Schedule (`vw_DailyProductionSchedule`)
2-week production schedule by work center.

```sql
-- This week's production schedule
SELECT * FROM vw_DailyProductionSchedule
WHERE ScheduledDate BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
ORDER BY ScheduledDate, Priority;
```

### 18. Scrap and Waste Analysis (`vw_ScrapWasteAnalysis`)
Track scrap rates and waste costs.

```sql
-- High scrap items
SELECT * FROM vw_ScrapWasteAnalysis
WHERE ScrapLevel = 'High'
ORDER BY ScrapValue DESC;
```

### 19. Customer Order Fulfillment Rate (`vw_CustomerFulfillmentRate`)
Customer service levels and on-time delivery.

```sql
-- Customer service performance
SELECT * FROM vw_CustomerFulfillmentRate
ORDER BY TotalOrderValue DESC;
```

### 20. Raw Material Usage by Period (`vw_RawMaterialUsage`)
Material consumption trends over time.

```sql
-- Monthly material usage trends
SELECT Year, Month, ItemName, SUM(TotalUsage) AS Usage
FROM vw_RawMaterialUsage
GROUP BY Year, Month, ItemName
ORDER BY Year, Month, ItemName;
```

## Sales Operations Reports

### 1. Sales Performance by Channel (`vw_Sales_ByChannel`)
Analyze sales across Retail, Online, and Wholesale channels with trends.

```sql
-- Monthly sales by channel
SELECT * FROM vw_Sales_ByChannel
WHERE Year = 2024
ORDER BY Year, Month, NetSales DESC;
```

### 2. Store Performance Report (`vw_Sales_StorePerformance`)
Track individual retail store performance metrics.

```sql
-- Top performing stores
SELECT * FROM vw_Sales_StorePerformance
ORDER BY NetSales DESC;
```

### 3. Sales Representative Performance (`vw_Sales_RepPerformance`)
Evaluate sales rep performance, territories, and quote conversion.

```sql
-- Sales rep leaderboard
SELECT * FROM vw_Sales_RepPerformance
ORDER BY SalesRank;
```

### 4. Customer Sales Analysis (`vw_Sales_CustomerAnalysis`)
Comprehensive customer metrics with segmentation and status.

```sql
-- High-value customers
SELECT * FROM vw_Sales_CustomerAnalysis
WHERE CustomerSegment IN ('VIP', 'Regular')
ORDER BY TotalSales DESC;
```

### 5. Product Sales Performance (`vw_Sales_ProductPerformance`)
Product-level sales metrics by channel with profitability.

```sql
-- Best selling products
SELECT * FROM vw_Sales_ProductPerformance
ORDER BY TotalUnitsSold DESC;
```

### 6. Sales Trend Analysis (`vw_Sales_TrendAnalysis`)
Month-over-month and year-over-year growth analysis.

```sql
-- Recent trends with growth rates
SELECT * FROM vw_Sales_TrendAnalysis
ORDER BY Year DESC, Month DESC;
```

### 7. Average Order Value Analysis (`vw_Sales_OrderValueAnalysis`)
Order size distribution and metrics by channel and customer type.

```sql
-- AOV by channel
SELECT ChannelName, AvgNetAmount, OrderCount
FROM vw_Sales_OrderValueAnalysis
GROUP BY ChannelName, AvgNetAmount, OrderCount;
```

### 8. Sales Returns Analysis (`vw_Sales_ReturnsAnalysis`)
Track returns by reason, product, and channel.

```sql
-- Top return reasons
SELECT ReasonDescription, SUM(TotalRefunds) AS Refunds
FROM vw_Sales_ReturnsAnalysis
GROUP BY ReasonDescription
ORDER BY Refunds DESC;
```

### 9. Sales Quote Conversion Analysis (`vw_Sales_QuoteConversion`)
Monitor quote-to-order conversion rates and pipeline.

```sql
-- Quote conversion rates
SELECT ConversionStatus, COUNT(*) AS Quotes, AVG(QuoteAmount) AS AvgValue
FROM vw_Sales_QuoteConversion
GROUP BY ConversionStatus;
```

### 10. Discount Analysis Report (`vw_Sales_DiscountAnalysis`)
Analyze discount impact on margins and profitability.

```sql
-- Discount effectiveness by channel
SELECT * FROM vw_Sales_DiscountAnalysis
ORDER BY Year DESC, Month DESC;
```

### 11. Top Selling Products Report (`vw_Sales_TopProducts`)
Ranked product performance by channel and time period.

```sql
-- Top 10 products this month
SELECT * FROM vw_Sales_TopProducts
WHERE Year = YEAR(GETDATE()) AND Month = MONTH(GETDATE())
  AND UnitRank <= 10
ORDER BY ChannelName, UnitRank;
```

### 12. Sales by Territory Report (`vw_Sales_ByTerritory`)
Geographic territory performance and sales rep efficiency.

```sql
-- Territory comparison
SELECT * FROM vw_Sales_ByTerritory
ORDER BY NetSales DESC;
```

### 13. Channel Profitability Analysis (`vw_Sales_ChannelProfitability`)
Full profitability analysis including COGS and margins by channel.

```sql
-- Most profitable channels
SELECT * FROM vw_Sales_ChannelProfitability
ORDER BY GrossProfit DESC;
```

### 14. Customer Lifetime Value (`vw_Sales_CustomerLifetimeValue`)
Calculate CLV with customer tiers and activity status.

```sql
-- Top customers by lifetime value
SELECT * FROM vw_Sales_CustomerLifetimeValue
WHERE CustomerTier IN ('Platinum', 'Gold')
ORDER BY TotalRevenue DESC;
```

### 15. Sales Growth Analysis (`vw_Sales_GrowthAnalysis`)
Track revenue and customer growth by channel over time.

```sql
-- Recent growth trends
SELECT * FROM vw_Sales_GrowthAnalysis
WHERE Year >= YEAR(DATEADD(MONTH, -6, GETDATE()))
ORDER BY Year DESC, Month DESC;
```

### 16. Order Size Distribution (`vw_Sales_OrderSizeDistribution`)
Analyze order patterns and basket sizes.

```sql
-- Order size breakdown
SELECT * FROM vw_Sales_OrderSizeDistribution
ORDER BY ChannelName, OrderSizeBucket;
```

### 17. Product Mix Analysis (`vw_Sales_ProductMixAnalysis`)
Identify popular product combinations and cross-sell opportunities.

```sql
-- Most common product combinations
SELECT * FROM vw_Sales_ProductMixAnalysis
WHERE UniqueProducts > 1
ORDER BY OrderCount DESC;
```

### 18. Day of Week / Time-Based Analysis (`vw_Sales_TimeBasedAnalysis`)
Understand sales patterns by day of week and time of day.

```sql
-- Sales by day of week
SELECT DayOfWeek, SUM(OrderCount) AS Orders, SUM(TotalRevenue) AS Revenue
FROM vw_Sales_TimeBasedAnalysis
GROUP BY DayOfWeek, DayNumber
ORDER BY DayNumber;
```

### 19. Sales Pipeline (`vw_Sales_Pipeline`)
Track conversion rates from quotes through delivery.

```sql
-- Pipeline funnel analysis
SELECT * FROM vw_Sales_Pipeline
ORDER BY StageOrder;
```

### 20. Customer Segmentation RFM Analysis (`vw_Sales_CustomerSegmentation`)
RFM (Recency, Frequency, Monetary) segmentation with actionable recommendations.

```sql
-- Customer segments with recommended actions
SELECT CustomerSegment, COUNT(*) AS Customers, SUM(Monetary) AS TotalValue
FROM vw_Sales_CustomerSegmentation
GROUP BY CustomerSegment
ORDER BY TotalValue DESC;
```

## Sample Data

The database includes sample data for:
- 21 Raw materials (fills, fabrics, wood, metal, hardware, finishes)
- 15 Components (5 pillow types, 5 mattress types, 5 frame types)
- 6 Finished futon products
- 5 Suppliers with pricing
- 8 Customers with various types (Retail, Wholesale, Online)
- 3 Warehouses
- 5 Work centers
- Initial inventory levels
- 7 Retail stores across multiple cities
- 6 Sales territories with regions
- 8 Sales representatives
- 15 Sales orders across all channels (Retail, Online, Wholesale)
- Sales returns and quotations
- Promotions and price lists by channel

## Use Cases

### Manufacturing Operations
1. **BOM Management**: Maintain multi-level product structures
2. **Production Planning**: Schedule work orders based on capacity
3. **Material Planning**: Calculate material requirements (MRP)
4. **Inventory Control**: Track materials, WIP, and finished goods
5. **Quality Management**: Monitor inspection results and defect rates

### Cost Accounting
1. **Cost Roll-Up**: Calculate product costs from component costs
2. **Scrap Analysis**: Track waste and its financial impact
3. **Inventory Valuation**: Value inventory using standard costs
4. **Variance Analysis**: Compare actual vs. standard costs

### Supply Chain
1. **Supplier Management**: Track supplier performance
2. **Purchase Planning**: Identify reorder needs
3. **Receiving**: Process incoming materials
4. **Lead Time Management**: Monitor delivery performance

### Sales & Distribution
1. **Order Management**: Process customer orders
2. **Fulfillment**: Track order completion and shipping
3. **Customer Service**: Monitor service levels
4. **Backlog Management**: Manage unfulfilled orders

## Schema Highlights

### Multi-Level BOM
The `BillOfMaterials` table supports unlimited BOM levels with:
- Recursive relationships
- Scrap rate tracking
- Effective dating
- Unit of measure flexibility

### Inventory Tracking
- Real-time available quantity (on-hand minus allocated)
- Complete transaction history
- Multi-warehouse support
- Cycle counting capabilities

### Production Control
- Work order management
- Material issue tracking
- Production completion recording
- Work center capacity planning

## Performance Considerations

The database includes indexes on:
- BOM parent and component lookups
- Inventory transactions by item and date
- Order status and date ranges
- Item type filtering

## Future Enhancements

Potential areas for expansion:
- Routing (labor operations per work center)
- Shop floor data collection
- Advanced planning and scheduling
- Lot/serial number tracking
- Multi-currency support
- Cost variance tracking
- Demand forecasting

## License

This sample database is provided as-is for educational and demonstration purposes.

## Author

Created as part of SQL Server Samples repository for demonstrating manufacturing database design patterns.

## Version History

- 2.0.0 - Added sales operations with 20 sales reports, multi-channel support, returns, quotes, and territories
- 1.0.0 - Initial release with complete schema, sample data, and 20 manufacturing reports
