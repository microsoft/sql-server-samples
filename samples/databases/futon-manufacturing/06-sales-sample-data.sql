-- =============================================
-- Sales Operations Sample Data
-- Futon Manufacturing Database
-- =============================================

USE FutonManufacturing;
GO

-- =============================================
-- Sales Territories
-- =============================================

INSERT INTO SalesTerritory (TerritoryCode, TerritoryName, Region) VALUES
('NW-01', 'Pacific Northwest', 'West'),
('CA-01', 'Northern California', 'West'),
('CA-02', 'Southern California', 'West'),
('MW-01', 'Upper Midwest', 'Central'),
('SE-01', 'Southeast', 'East'),
('NE-01', 'Northeast', 'East');

-- =============================================
-- Sales Representatives
-- =============================================

INSERT INTO SalesRep (EmployeeCode, FirstName, LastName, Email, Phone, TerritoryID, HireDate) VALUES
('SR-001', 'Michael', 'Johnson', 'mjohnson@futonmfg.com', '503-555-2001', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01'), '2020-03-15'),
('SR-002', 'Emily', 'Williams', 'ewilliams@futonmfg.com', '415-555-2002', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'CA-01'), '2019-06-20'),
('SR-003', 'David', 'Brown', 'dbrown@futonmfg.com', '310-555-2003', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'CA-02'), '2021-01-10'),
('SR-004', 'Sarah', 'Davis', 'sdavis@futonmfg.com', '312-555-2004', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'MW-01'), '2020-08-05'),
('SR-005', 'James', 'Miller', 'jmiller@futonmfg.com', '404-555-2005', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'SE-01'), '2018-11-12'),
('SR-006', 'Jessica', 'Wilson', 'jwilson@futonmfg.com', '617-555-2006', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NE-01'), '2019-04-18'),
('SR-007', 'Robert', 'Moore', 'rmoore@futonmfg.com', '206-555-2007', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01'), '2022-02-14'),
('SR-008', 'Amanda', 'Taylor', 'ataylor@futonmfg.com', '503-555-2008', (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01'), '2021-09-01');

-- =============================================
-- Retail Stores
-- =============================================

DECLARE @RetailChannel INT = (SELECT SalesChannelID FROM SalesChannel WHERE ChannelCode = 'RETAIL');
DECLARE @OnlineChannel INT = (SELECT SalesChannelID FROM SalesChannel WHERE ChannelCode = 'ONLINE');
DECLARE @WholesaleChannel INT = (SELECT SalesChannelID FROM SalesChannel WHERE ChannelCode = 'WHOLESALE');

INSERT INTO Store (StoreCode, StoreName, SalesChannelID, Manager, Phone, Address, City, State, ZipCode, OpenDate) VALUES
-- Retail Stores
('STR-PDX-01', 'Portland Downtown Store', @RetailChannel, 'Lisa Anderson', '503-555-3001', '450 SW Broadway', 'Portland', 'OR', '97205', '2015-03-01'),
('STR-PDX-02', 'Portland East Side', @RetailChannel, 'Mark Thompson', '503-555-3002', '2200 E Burnside St', 'Portland', 'OR', '97214', '2018-06-15'),
('STR-SEA-01', 'Seattle Capitol Hill', @RetailChannel, 'Jennifer Lee', '206-555-3003', '1500 E Pine St', 'Seattle', 'WA', '98122', '2016-09-01'),
('STR-SF-01', 'San Francisco Store', @RetailChannel, 'Brian Chen', '415-555-3004', '850 Market St', 'San Francisco', 'CA', '94102', '2017-04-20'),
('STR-LA-01', 'Los Angeles Store', @RetailChannel, 'Maria Rodriguez', '310-555-3005', '1200 Wilshire Blvd', 'Los Angeles', 'CA', '90017', '2019-11-10'),
-- Online Channel (Virtual Store)
('ONLINE-01', 'E-Commerce Platform', @OnlineChannel, 'Thomas Wright', '503-555-4001', '1200 Industrial Parkway', 'Portland', 'OR', '97201', '2016-01-01'),
-- Wholesale (Virtual Store)
('WHSL-01', 'Wholesale Division', @WholesaleChannel, 'Patricia Martinez', '503-555-5001', '1200 Industrial Parkway', 'Portland', 'OR', '97201', '2015-01-01');

-- =============================================
-- Update Existing Customers
-- =============================================

UPDATE Customer SET CustomerType = 'Retail', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01')
WHERE CustomerCode = 'CUST-001';

UPDATE Customer SET CustomerType = 'Retail', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-007'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01')
WHERE CustomerCode = 'CUST-002';

UPDATE Customer SET CustomerType = 'Retail', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-002'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'CA-01')
WHERE CustomerCode = 'CUST-003';

UPDATE Customer SET CustomerType = 'Wholesale', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01')
WHERE CustomerCode = 'CUST-004';

UPDATE Customer SET CustomerType = 'Online', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-008'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01')
WHERE CustomerCode = 'CUST-005';

UPDATE Customer SET CustomerType = 'Wholesale', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-007'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01')
WHERE CustomerCode = 'CUST-006';

UPDATE Customer SET CustomerType = 'Retail', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-002'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'CA-01')
WHERE CustomerCode = 'CUST-007';

UPDATE Customer SET CustomerType = 'Wholesale', SalesRepID = (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    TerritoryID = (SELECT TerritoryID FROM SalesTerritory WHERE TerritoryCode = 'NW-01')
WHERE CustomerCode = 'CUST-008';

-- =============================================
-- Sample Sales Orders with Channel Data
-- =============================================

-- Get IDs we'll need
DECLARE @MainWH INT = (SELECT WarehouseID FROM Warehouse WHERE WarehouseCode = 'WH-MAIN');
DECLARE @WestWH INT = (SELECT WarehouseID FROM Warehouse WHERE WarehouseCode = 'WH-WEST');
DECLARE @EastWH INT = (SELECT WarehouseID FROM Warehouse WHERE WarehouseCode = 'WH-EAST');

-- Sales Orders for October 2024
INSERT INTO SalesOrder (OrderNumber, CustomerID, WarehouseID, SalesChannelID, StoreID, SalesRepID, OrderDate, RequestedDeliveryDate, ShipDate, Status, Subtotal, TaxAmount, ShippingAmount, DiscountAmount, TotalAmount, CreatedBy) VALUES
-- Retail Store Sales
('SO-2024-1001', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-001'), @MainWH, @RetailChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'STR-PDX-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    '2024-10-01', '2024-10-05', '2024-10-04', 'Delivered', 1199.97, 95.00, 50.00, 60.00, 1284.97, 'system'),

('SO-2024-1002', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-003'), @WestWH, @RetailChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'STR-SF-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-002'),
    '2024-10-02', '2024-10-08', '2024-10-07', 'Delivered', 1599.98, 128.00, 75.00, 0, 1802.98, 'system'),

('SO-2024-1003', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-007'), @WestWH, @RetailChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'STR-LA-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-003'),
    '2024-10-03', '2024-10-10', '2024-10-09', 'Delivered', 2399.97, 192.00, 100.00, 120.00, 2571.97, 'system'),

-- Online Sales
('SO-2024-1004', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-005'), @MainWH, @OnlineChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'ONLINE-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-008'),
    '2024-10-05', '2024-10-12', '2024-10-08', 'Delivered', 799.99, 64.00, 25.00, 40.00, 848.99, 'system'),

('SO-2024-1005', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-005'), @MainWH, @OnlineChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'ONLINE-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-008'),
    '2024-10-07', '2024-10-14', '2024-10-10', 'Delivered', 599.99, 48.00, 25.00, 0, 672.99, 'system'),

-- Wholesale Orders
('SO-2024-1006', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-004'), @MainWH, @WholesaleChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'WHSL-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    '2024-10-08', '2024-10-20', '2024-10-18', 'Delivered', 9999.60, 0, 500.00, 999.96, 9499.64, 'system'),

('SO-2024-1007', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-006'), @MainWH, @WholesaleChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'WHSL-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-007'),
    '2024-10-10', '2024-10-25', '2024-10-22', 'Delivered', 7999.68, 0, 400.00, 800.00, 7599.68, 'system'),

('SO-2024-1008', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-008'), @MainWH, @WholesaleChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'WHSL-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    '2024-10-12', '2024-10-30', '2024-10-28', 'Delivered', 5999.76, 0, 300.00, 600.00, 5699.76, 'system'),

-- November Sales (Recent)
('SO-2024-1101', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-001'), @MainWH, @RetailChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'STR-PDX-02'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    '2024-11-01', '2024-11-08', '2024-11-05', 'Delivered', 899.99, 72.00, 50.00, 45.00, 976.99, 'system'),

('SO-2024-1102', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-002'), @MainWH, @RetailChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'STR-SEA-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-007'),
    '2024-11-02', '2024-11-10', NULL, 'Shipped', 1199.98, 96.00, 60.00, 0, 1355.98, 'system'),

('SO-2024-1103', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-005'), @MainWH, @OnlineChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'ONLINE-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-008'),
    '2024-11-03', '2024-11-12', NULL, 'InProduction', 1599.98, 128.00, 50.00, 80.00, 1697.98, 'system'),

('SO-2024-1104', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-004'), @MainWH, @WholesaleChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'WHSL-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    '2024-11-04', '2024-11-20', NULL, 'Confirmed', 11999.40, 0, 600.00, 1200.00, 11399.40, 'system'),

('SO-2024-1105', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-003'), @WestWH, @RetailChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'STR-SF-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-002'),
    '2024-11-05', '2024-11-15', NULL, 'Confirmed', 2399.96, 192.00, 100.00, 120.00, 2571.96, 'system'),

('SO-2024-1106', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-007'), @WestWH, @OnlineChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'ONLINE-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-008'),
    '2024-11-06', '2024-11-16', NULL, 'Confirmed', 1799.97, 144.00, 50.00, 90.00, 1903.97, 'system'),

('SO-2024-1107', (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-006'), @MainWH, @WholesaleChannel,
    (SELECT StoreID FROM Store WHERE StoreCode = 'WHSL-01'), (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-007'),
    '2024-11-07', '2024-11-25', NULL, 'Confirmed', 9599.52, 0, 500.00, 960.00, 9139.52, 'system');

-- =============================================
-- Sales Order Details
-- =============================================

-- SO-2024-1001 (Retail - PDX Downtown)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1001'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 2, 399.99, 5.0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1001'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), 1, 299.99, 0);

-- SO-2024-1002 (Retail - SF)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1002'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), 1, 599.99, 0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1002'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), 1, 899.99, 0);

-- SO-2024-1003 (Retail - LA)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1003'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), 2, 899.99, 5.0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1003'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), 1, 799.99, 0);

-- SO-2024-1004 (Online)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1004'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), 1, 799.99, 5.0);

-- SO-2024-1005 (Online)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1005'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), 1, 599.99, 0);

-- SO-2024-1006 (Wholesale - Large order)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1006'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), 12, 299.99, 10.0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1006'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 15, 399.99, 10.0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1006'), 3,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-005'), 8, 499.99, 10.0);

-- SO-2024-1007 (Wholesale)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1007'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 10, 399.99, 10.0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1007'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), 10, 599.99, 10.0);

-- SO-2024-1008 (Wholesale)
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1008'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), 20, 299.99, 10.0);

-- November orders
INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1101'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), 1, 899.99, 5.0);

INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1102'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 3, 399.99, 0);

INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1103'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), 2, 799.99, 5.0);

INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1104'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 15, 399.99, 10.0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1104'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-005'), 10, 499.99, 10.0);

INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1105'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), 3, 799.99, 5.0);

INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1106'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), 3, 599.99, 5.0);

INSERT INTO SalesOrderDetail (SalesOrderID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1107'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), 16, 299.99, 10.0),
((SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1107'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 12, 399.99, 10.0);

-- Update shipped quantities for delivered orders
UPDATE SalesOrderDetail SET QuantityShipped = Quantity
WHERE SalesOrderID IN (
    SELECT SalesOrderID FROM SalesOrder
    WHERE Status IN ('Delivered', 'Shipped')
);

-- =============================================
-- Sample Sales Returns
-- =============================================

INSERT INTO SalesReturn (ReturnNumber, SalesOrderID, CustomerID, ReturnDate, ReturnReasonID, Status, RefundAmount, RestockingFee, ApprovedBy, ApprovedDate) VALUES
('RET-2024-001',
    (SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1001'),
    (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-001'),
    '2024-10-10',
    (SELECT ReturnReasonID FROM ReturnReason WHERE ReasonCode = 'CHANGE'),
    'Refunded', 399.99, 0, 'Manager1', '2024-10-10'),

('RET-2024-002',
    (SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1003'),
    (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-007'),
    '2024-10-15',
    (SELECT ReturnReasonID FROM ReturnReason WHERE ReasonCode = 'DEFECT'),
    'Refunded', 899.99, 0, 'Manager2', '2024-10-15');

INSERT INTO SalesReturnDetail (ReturnID, SODetailID, ItemID, QuantityReturned, UnitPrice, RefundAmount, Disposition) VALUES
((SELECT ReturnID FROM SalesReturn WHERE ReturnNumber = 'RET-2024-001'),
    (SELECT SODetailID FROM SalesOrderDetail WHERE SalesOrderID = (SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1001') AND LineNumber = 1),
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 1, 399.99, 399.99, 'Restock'),

((SELECT ReturnID FROM SalesReturn WHERE ReturnNumber = 'RET-2024-002'),
    (SELECT SODetailID FROM SalesOrderDetail WHERE SalesOrderID = (SELECT SalesOrderID FROM SalesOrder WHERE OrderNumber = 'SO-2024-1003') AND LineNumber = 1),
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), 1, 899.99, 899.99, 'Scrap');

-- =============================================
-- Sample Sales Quotes
-- =============================================

INSERT INTO SalesQuote (QuoteNumber, CustomerID, SalesChannelID, SalesRepID, QuoteDate, ExpirationDate, Status, Subtotal, DiscountAmount, TaxAmount, TotalAmount) VALUES
('QT-2024-001',
    (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-004'),
    @WholesaleChannel,
    (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-001'),
    '2024-11-05', '2024-12-05', 'Sent', 14999.25, 1500.00, 0, 13499.25),

('QT-2024-002',
    (SELECT CustomerID FROM Customer WHERE CustomerCode = 'CUST-006'),
    @WholesaleChannel,
    (SELECT SalesRepID FROM SalesRep WHERE EmployeeCode = 'SR-007'),
    '2024-11-06', '2024-12-06', 'Sent', 11999.40, 1200.00, 0, 10799.40);

INSERT INTO SalesQuoteDetail (QuoteID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT QuoteID FROM SalesQuote WHERE QuoteNumber = 'QT-2024-001'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-005'), 25, 499.99, 10.0),
((SELECT QuoteID FROM SalesQuote WHERE QuoteNumber = 'QT-2024-001'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), 5, 599.99, 10.0);

INSERT INTO SalesQuoteDetail (QuoteID, LineNumber, ItemID, Quantity, UnitPrice, DiscountPercent) VALUES
((SELECT QuoteID FROM SalesQuote WHERE QuoteNumber = 'QT-2024-002'), 1,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), 20, 399.99, 10.0),
((SELECT QuoteID FROM SalesQuote WHERE QuoteNumber = 'QT-2024-002'), 2,
    (SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), 10, 799.99, 10.0);

-- =============================================
-- Promotions
-- =============================================

INSERT INTO Promotion (PromotionCode, PromotionName, Description, DiscountPercent, StartDate, EndDate, IsActive, MinimumPurchase, ApplicableChannels) VALUES
('FALL2024', 'Fall Clearance Sale', 'Fall season clearance event', 15.0, '2024-09-15', '2024-11-30', 1, 500.00, 'RETAIL,ONLINE'),
('BULK10', 'Wholesale Bulk Discount', '10% off bulk wholesale orders', 10.0, '2024-01-01', '2024-12-31', 1, 5000.00, 'WHOLESALE'),
('BLACKFRI', 'Black Friday Special', 'Black Friday mega sale', 25.0, '2024-11-29', '2024-11-29', 1, 0, 'RETAIL,ONLINE'),
('HOLIDAY24', 'Holiday Season Sale', 'Holiday promotional pricing', 20.0, '2024-12-01', '2024-12-31', 1, 750.00, 'RETAIL,ONLINE');

-- =============================================
-- Price Lists
-- =============================================

INSERT INTO PriceList (PriceListCode, PriceListName, SalesChannelID, EffectiveDate, IsActive) VALUES
('PL-RETAIL', 'Retail Price List', @RetailChannel, '2024-01-01', 1),
('PL-ONLINE', 'Online Price List', @OnlineChannel, '2024-01-01', 1),
('PL-WHOLESALE', 'Wholesale Price List', @WholesaleChannel, '2024-01-01', 1);

-- Insert price list details for finished goods
INSERT INTO PriceListDetail (PriceListID, ItemID, UnitPrice, MinimumQuantity)
SELECT
    (SELECT PriceListID FROM PriceList WHERE PriceListCode = 'PL-RETAIL'),
    ItemID,
    ListPrice,
    1
FROM Items WHERE ItemTypeID = (SELECT ItemTypeID FROM ItemType WHERE TypeCode = 'FG');

INSERT INTO PriceListDetail (PriceListID, ItemID, UnitPrice, MinimumQuantity)
SELECT
    (SELECT PriceListID FROM PriceList WHERE PriceListCode = 'PL-ONLINE'),
    ItemID,
    ListPrice * 0.98, -- 2% discount for online
    1
FROM Items WHERE ItemTypeID = (SELECT ItemTypeID FROM ItemType WHERE TypeCode = 'FG');

INSERT INTO PriceListDetail (PriceListID, ItemID, UnitPrice, MinimumQuantity)
SELECT
    (SELECT PriceListID FROM PriceList WHERE PriceListCode = 'PL-WHOLESALE'),
    ItemID,
    ListPrice * 0.85, -- 15% discount for wholesale base
    10
FROM Items WHERE ItemTypeID = (SELECT ItemTypeID FROM ItemType WHERE TypeCode = 'FG');

GO

PRINT 'Sales operations sample data inserted successfully!';
GO
