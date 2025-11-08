-- =============================================
-- Futon Manufacturing Sample Data
-- =============================================

USE FutonManufacturing;
GO

-- =============================================
-- Reference Data
-- =============================================

-- Unit of Measure
INSERT INTO UnitOfMeasure (UnitCode, UnitName, Description) VALUES
('EA', 'Each', 'Individual unit'),
('YD', 'Yard', 'Linear yard'),
('LB', 'Pound', 'Weight in pounds'),
('FT', 'Foot', 'Linear foot'),
('PC', 'Piece', 'Piece'),
('SET', 'Set', 'Set of items'),
('BOX', 'Box', 'Box'),
('ROLL', 'Roll', 'Roll of material');

-- Item Types
INSERT INTO ItemType (TypeCode, TypeName, Description) VALUES
('RAW', 'Raw Material', 'Raw materials purchased from suppliers'),
('COMP', 'Component', 'Manufactured components used in assemblies'),
('FG', 'Finished Goods', 'Finished products ready for sale');

-- Transaction Types
INSERT INTO TransactionType (TypeCode, TypeName, Description) VALUES
('PO-RCV', 'Purchase Order Receipt', 'Receipt of purchased materials'),
('PO-RET', 'Purchase Order Return', 'Return to supplier'),
('WO-ISS', 'Work Order Issue', 'Material issued to production'),
('WO-CMP', 'Work Order Completion', 'Production completion'),
('SO-SHP', 'Sales Order Shipment', 'Shipment to customer'),
('SO-RET', 'Sales Order Return', 'Customer return'),
('ADJ-POS', 'Positive Adjustment', 'Inventory increase adjustment'),
('ADJ-NEG', 'Negative Adjustment', 'Inventory decrease adjustment'),
('CYC-CNT', 'Cycle Count', 'Cycle count adjustment');

-- =============================================
-- Items Master Data
-- =============================================

DECLARE @RawMaterialType INT = (SELECT ItemTypeID FROM ItemType WHERE TypeCode = 'RAW');
DECLARE @ComponentType INT = (SELECT ItemTypeID FROM ItemType WHERE TypeCode = 'COMP');
DECLARE @FinishedGoodType INT = (SELECT ItemTypeID FROM ItemType WHERE TypeCode = 'FG');
DECLARE @EachUnit INT = (SELECT UnitID FROM UnitOfMeasure WHERE UnitCode = 'EA');
DECLARE @YardUnit INT = (SELECT UnitID FROM UnitOfMeasure WHERE UnitCode = 'YD');
DECLARE @PoundUnit INT = (SELECT UnitID FROM UnitOfMeasure WHERE UnitCode = 'LB');
DECLARE @FootUnit INT = (SELECT UnitID FROM UnitOfMeasure WHERE UnitCode = 'FT');

-- Raw Materials: Fill Materials
INSERT INTO Items (ItemCode, ItemName, ItemTypeID, UnitID, Description, StandardCost, ListPrice, ReorderPoint, SafetyStock, LeadTimeDays) VALUES
('RM-FILL-001', 'Premium Polyester Fiber Fill', @RawMaterialType, @PoundUnit, 'High-quality polyester fiber for pillow filling', 3.50, 0, 500, 250, 14),
('RM-FILL-002', 'Memory Foam Chips', @RawMaterialType, @PoundUnit, 'Shredded memory foam for premium comfort', 8.75, 0, 300, 150, 21),
('RM-FILL-003', 'Cotton Fill', @RawMaterialType, @PoundUnit, 'Natural cotton fiber fill', 6.25, 0, 400, 200, 14),
('RM-FILL-004', 'Latex Foam Chips', @RawMaterialType, @PoundUnit, 'Natural latex foam pieces', 12.50, 0, 200, 100, 28),
('RM-FILL-005', 'Down Alternative Fill', @RawMaterialType, @PoundUnit, 'Hypoallergenic down alternative', 5.00, 0, 350, 175, 14);

-- Raw Materials: Fabric
INSERT INTO Items (ItemCode, ItemName, ItemTypeID, UnitID, Description, StandardCost, ListPrice, ReorderPoint, SafetyStock, LeadTimeDays) VALUES
('RM-FAB-001', 'Cotton Canvas - Natural', @RawMaterialType, @YardUnit, '100% cotton canvas fabric, natural color', 8.50, 0, 200, 100, 14),
('RM-FAB-002', 'Cotton Canvas - Navy Blue', @RawMaterialType, @YardUnit, '100% cotton canvas fabric, navy blue', 8.50, 0, 200, 100, 14),
('RM-FAB-003', 'Cotton Canvas - Burgundy', @RawMaterialType, @YardUnit, '100% cotton canvas fabric, burgundy', 8.50, 0, 200, 100, 14),
('RM-FAB-004', 'Microfiber Suede - Black', @RawMaterialType, @YardUnit, 'Soft microfiber suede fabric', 12.00, 0, 150, 75, 21),
('RM-FAB-005', 'Microfiber Suede - Chocolate', @RawMaterialType, @YardUnit, 'Soft microfiber suede fabric', 12.00, 0, 150, 75, 21),
('RM-FAB-006', 'Linen Blend - Beige', @RawMaterialType, @YardUnit, 'Linen cotton blend fabric', 15.00, 0, 100, 50, 21),
('RM-FAB-007', 'Twill - Khaki', @RawMaterialType, @YardUnit, 'Durable cotton twill fabric', 9.50, 0, 180, 90, 14),
('RM-FAB-008', 'Velvet - Emerald Green', @RawMaterialType, @YardUnit, 'Luxurious velvet fabric', 18.50, 0, 80, 40, 28);

-- Raw Materials: Frame Components
INSERT INTO Items (ItemCode, ItemName, ItemTypeID, UnitID, Description, StandardCost, ListPrice, ReorderPoint, SafetyStock, LeadTimeDays) VALUES
('RM-WOOD-001', 'Pine Frame Rail 6ft', @RawMaterialType, @EachUnit, 'Solid pine wood rail, 2x4x72in', 12.00, 0, 100, 50, 14),
('RM-WOOD-002', 'Pine Frame Rail 4ft', @RawMaterialType, @EachUnit, 'Solid pine wood rail, 2x4x48in', 8.50, 0, 100, 50, 14),
('RM-WOOD-003', 'Hardwood Slat 6ft', @RawMaterialType, @EachUnit, 'Hardwood support slat, 1x4x72in', 7.50, 0, 200, 100, 14),
('RM-WOOD-004', 'Hardwood Slat 4ft', @RawMaterialType, @EachUnit, 'Hardwood support slat, 1x4x48in', 5.00, 0, 200, 100, 14),
('RM-METAL-001', 'Steel Corner Bracket', @RawMaterialType, @EachUnit, 'Heavy-duty steel corner bracket', 2.75, 0, 400, 200, 7),
('RM-METAL-002', 'Steel Hinge Mechanism', @RawMaterialType, @EachUnit, 'Folding hinge for futon frame', 15.50, 0, 150, 75, 14),
('RM-HARD-001', 'Wood Screw 3in (100 pack)', @RawMaterialType, @EachUnit, 'Box of 100 3-inch wood screws', 8.00, 0, 50, 25, 7),
('RM-HARD-002', 'Bolt and Nut Kit (50 pack)', @RawMaterialType, @EachUnit, 'Box of 50 bolt and nut sets', 12.00, 0, 50, 25, 7),
('RM-FIN-001', 'Wood Stain - Dark Walnut (Quart)', @RawMaterialType, @EachUnit, 'Dark walnut wood stain', 18.00, 0, 30, 15, 7),
('RM-FIN-002', 'Wood Stain - Natural Oak (Quart)', @RawMaterialType, @EachUnit, 'Natural oak wood stain', 18.00, 0, 30, 15, 7),
('RM-FIN-003', 'Clear Polyurethane (Quart)', @RawMaterialType, @EachUnit, 'Clear protective finish', 22.00, 0, 30, 15, 7);

-- Components: Pillows
INSERT INTO Items (ItemCode, ItemName, ItemTypeID, UnitID, Description, StandardCost, ListPrice, ReorderPoint, SafetyStock, LeadTimeDays) VALUES
('COMP-PIL-001', 'Standard Polyester Pillow', @ComponentType, @EachUnit, 'Standard pillow with polyester fill', 0, 0, 50, 25, 3),
('COMP-PIL-002', 'Premium Memory Foam Pillow', @ComponentType, @EachUnit, 'Premium pillow with memory foam', 0, 0, 40, 20, 3),
('COMP-PIL-003', 'Cotton Fill Pillow', @ComponentType, @EachUnit, 'Natural cotton filled pillow', 0, 0, 40, 20, 3),
('COMP-PIL-004', 'Latex Foam Pillow', @ComponentType, @EachUnit, 'Natural latex foam pillow', 0, 0, 30, 15, 3),
('COMP-PIL-005', 'Down Alternative Pillow', @ComponentType, @EachUnit, 'Hypoallergenic down alternative pillow', 0, 0, 45, 22, 3);

-- Components: Mattresses
INSERT INTO Items (ItemCode, ItemName, ItemTypeID, UnitID, Description, StandardCost, ListPrice, ReorderPoint, SafetyStock, LeadTimeDays) VALUES
('COMP-MAT-001', 'Twin Polyester Mattress', @ComponentType, @EachUnit, 'Twin futon mattress with polyester fill', 0, 0, 20, 10, 5),
('COMP-MAT-002', 'Full Polyester Mattress', @ComponentType, @EachUnit, 'Full futon mattress with polyester fill', 0, 0, 15, 7, 5),
('COMP-MAT-003', 'Queen Memory Foam Mattress', @ComponentType, @EachUnit, 'Queen futon mattress with memory foam', 0, 0, 12, 6, 5),
('COMP-MAT-004', 'Full Cotton Mattress', @ComponentType, @EachUnit, 'Full futon mattress with cotton fill', 0, 0, 15, 7, 5),
('COMP-MAT-005', 'Queen Cotton Mattress', @ComponentType, @EachUnit, 'Queen futon mattress with cotton fill', 0, 0, 12, 6, 5);

-- Components: Frames
INSERT INTO Items (ItemCode, ItemName, ItemTypeID, UnitID, Description, StandardCost, ListPrice, ReorderPoint, SafetyStock, LeadTimeDays) VALUES
('COMP-FRM-001', 'Twin Pine Frame - Natural Oak', @ComponentType, @EachUnit, 'Twin size pine frame, natural oak finish', 0, 0, 15, 7, 7),
('COMP-FRM-002', 'Full Pine Frame - Natural Oak', @ComponentType, @EachUnit, 'Full size pine frame, natural oak finish', 0, 0, 12, 6, 7),
('COMP-FRM-003', 'Queen Pine Frame - Natural Oak', @ComponentType, @EachUnit, 'Queen size pine frame, natural oak finish', 0, 0, 10, 5, 7),
('COMP-FRM-004', 'Full Pine Frame - Dark Walnut', @ComponentType, @EachUnit, 'Full size pine frame, dark walnut finish', 0, 0, 12, 6, 7),
('COMP-FRM-005', 'Queen Pine Frame - Dark Walnut', @ComponentType, @EachUnit, 'Queen size pine frame, dark walnut finish', 0, 0, 10, 5, 7);

-- Finished Goods: Complete Futons
INSERT INTO Items (ItemCode, ItemName, ItemTypeID, UnitID, Description, StandardCost, ListPrice, ReorderPoint, SafetyStock, LeadTimeDays) VALUES
('FG-FUT-001', 'Twin Economy Futon - Natural Canvas', @FinishedGoodType, @EachUnit, 'Twin futon with polyester mattress, natural canvas, oak frame', 0, 299.99, 10, 5, 10),
('FG-FUT-002', 'Full Economy Futon - Navy Canvas', @FinishedGoodType, @EachUnit, 'Full futon with polyester mattress, navy canvas, oak frame', 0, 399.99, 8, 4, 10),
('FG-FUT-003', 'Full Deluxe Futon - Microfiber Black', @FinishedGoodType, @EachUnit, 'Full futon with memory foam mattress, microfiber suede, walnut frame', 0, 599.99, 6, 3, 10),
('FG-FUT-004', 'Queen Premium Futon - Velvet Emerald', @FinishedGoodType, @EachUnit, 'Queen futon with cotton mattress, velvet fabric, walnut frame', 0, 799.99, 5, 2, 10),
('FG-FUT-005', 'Full Comfort Futon - Chocolate Suede', @FinishedGoodType, @EachUnit, 'Full futon with cotton mattress, chocolate suede, oak frame', 0, 499.99, 7, 3, 10),
('FG-FUT-006', 'Queen Luxury Futon - Linen Beige', @FinishedGoodType, @EachUnit, 'Queen futon with memory foam mattress, linen blend, walnut frame', 0, 899.99, 4, 2, 10);

GO

-- =============================================
-- Bill of Materials - Multi-Level
-- =============================================

-- Level 1: Pillows (Components made from raw materials)
-- Standard Polyester Pillow
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-001'), 2.5, @PoundUnit, 1, 2.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-001'), 1.2, @YardUnit, 1, 5.0);

-- Premium Memory Foam Pillow
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-002'), 3.0, @PoundUnit, 1, 2.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-004'), 1.2, @YardUnit, 1, 5.0);

-- Cotton Fill Pillow
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-003'), 2.8, @PoundUnit, 1, 2.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-002'), 1.2, @YardUnit, 1, 5.0);

-- Latex Foam Pillow
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-004'), 3.5, @PoundUnit, 1, 2.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-006'), 1.2, @YardUnit, 1, 5.0);

-- Down Alternative Pillow
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-005'), 2.7, @PoundUnit, 1, 2.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-005'), 1.2, @YardUnit, 1, 5.0);

-- Level 1: Mattresses (Components made from raw materials)
-- Twin Polyester Mattress
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-001'), 15.0, @PoundUnit, 1, 3.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-001'), 6.5, @YardUnit, 1, 5.0);

-- Full Polyester Mattress
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-001'), 20.0, @PoundUnit, 1, 3.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-001'), 8.5, @YardUnit, 1, 5.0);

-- Queen Memory Foam Mattress
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-002'), 28.0, @PoundUnit, 1, 3.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-004'), 10.0, @YardUnit, 1, 5.0);

-- Full Cotton Mattress
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-003'), 22.0, @PoundUnit, 1, 3.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-003'), 8.5, @YardUnit, 1, 5.0);

-- Queen Cotton Mattress
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-003'), 26.0, @PoundUnit, 1, 3.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-006'), 10.0, @YardUnit, 1, 5.0);

-- Level 1: Frames (Components made from raw materials)
-- Twin Pine Frame - Natural Oak
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-002'), 4, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-004'), 8, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-001'), 8, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-002'), 2, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-001'), 1, @EachUnit, 1, 0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-002'), 0.5, @EachUnit, 1, 10.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-003'), 0.5, @EachUnit, 1, 10.0);

-- Full Pine Frame - Natural Oak
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-001'), 2, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-002'), 2, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-003'), 10, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-001'), 8, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-002'), 2, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-001'), 1, @EachUnit, 1, 0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-002'), 0.75, @EachUnit, 1, 10.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-003'), 0.75, @EachUnit, 1, 10.0);

-- Queen Pine Frame - Natural Oak
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-001'), 4, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-003'), 12, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-001'), 8, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-002'), 2, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-001'), 2, @EachUnit, 1, 0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-002'), 1.0, @EachUnit, 1, 10.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-003'), 1.0, @EachUnit, 1, 10.0);

-- Full Pine Frame - Dark Walnut
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-001'), 2, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-002'), 2, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-003'), 10, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-001'), 8, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-002'), 2, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-001'), 1, @EachUnit, 1, 0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-001'), 0.75, @EachUnit, 1, 10.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-003'), 0.75, @EachUnit, 1, 10.0);

-- Queen Pine Frame - Dark Walnut
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-001'), 4, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-003'), 12, @EachUnit, 1, 5.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-001'), 8, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-002'), 2, @EachUnit, 1, 1.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-001'), 2, @EachUnit, 1, 0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-001'), 1.0, @EachUnit, 1, 10.0),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-003'), 1.0, @EachUnit, 1, 10.0);

-- Level 0: Finished Goods (Made from components)
-- Twin Economy Futon - Natural Canvas
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-001'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-001'), 2, @EachUnit, 0, 1.0);

-- Full Economy Futon - Navy Canvas
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-002'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-003'), 2, @EachUnit, 0, 1.0);

-- Full Deluxe Futon - Microfiber Black
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-003'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-002'), 2, @EachUnit, 0, 1.0);

-- Queen Premium Futon - Velvet Emerald
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-005'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-004'), 2, @EachUnit, 0, 1.0);

-- Full Comfort Futon - Chocolate Suede
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-004'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-005'), 2, @EachUnit, 0, 1.0);

-- Queen Luxury Futon - Linen Beige
INSERT INTO BillOfMaterials (ParentItemID, ComponentItemID, Quantity, UnitID, BOMLevel, ScrapRate) VALUES
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-003'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), 1, @EachUnit, 0, 0.5),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), (SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-002'), 2, @EachUnit, 0, 1.0);

GO

-- Update Standard Costs based on BOM
UPDATE Items
SET StandardCost = (
    SELECT ISNULL(SUM(c.StandardCost * b.Quantity * (1 + b.ScrapRate/100)), 0)
    FROM BillOfMaterials b
    INNER JOIN Items c ON b.ComponentItemID = c.ItemID
    WHERE b.ParentItemID = Items.ItemID
)
WHERE ItemTypeID IN (SELECT ItemTypeID FROM ItemType WHERE TypeCode IN ('COMP', 'FG'));

GO

-- =============================================
-- Warehouses
-- =============================================

INSERT INTO Warehouse (WarehouseCode, WarehouseName, Address, City, State, ZipCode) VALUES
('WH-MAIN', 'Main Manufacturing Facility', '1200 Industrial Parkway', 'Portland', 'OR', '97201'),
('WH-WEST', 'West Coast Distribution', '450 Commerce Drive', 'Los Angeles', 'CA', '90001'),
('WH-EAST', 'East Coast Distribution', '780 Logistics Boulevard', 'Charlotte', 'NC', '28201');

-- =============================================
-- Work Centers
-- =============================================

INSERT INTO WorkCenter (WorkCenterCode, WorkCenterName, Description, Capacity) VALUES
('WC-SEW', 'Sewing Department', 'Pillow and mattress cover sewing', 50),
('WC-FILL', 'Filling Station', 'Fill pillows and mattresses', 60),
('WC-WOOD', 'Woodworking Shop', 'Frame construction and finishing', 30),
('WC-ASSY', 'Final Assembly', 'Futon final assembly and packaging', 40),
('WC-QC', 'Quality Control', 'Final inspection and testing', 50);

-- =============================================
-- Suppliers
-- =============================================

INSERT INTO Supplier (SupplierCode, SupplierName, ContactName, Email, Phone, Address, City, State, ZipCode, Country, PaymentTerms, Rating) VALUES
('SUP-001', 'Pacific Textile Mills', 'Sarah Johnson', 'sarah.j@pacifictextile.com', '503-555-0101', '500 Mill Street', 'Portland', 'OR', '97202', 'USA', 'Net 30', 4.5),
('SUP-002', 'Premium Fill Supply Co', 'Michael Chen', 'mchen@premiumfill.com', '206-555-0202', '1800 Manufacturing Way', 'Seattle', 'WA', '98101', 'USA', 'Net 30', 4.8),
('SUP-003', 'Northwest Lumber & Hardware', 'David Brown', 'dbrown@nwlumber.com', '503-555-0303', '2500 Timber Road', 'Eugene', 'OR', '97401', 'USA', 'Net 45', 4.3),
('SUP-004', 'Industrial Fasteners Inc', 'Lisa Martinez', 'lmartinez@indfasteners.com', '425-555-0404', '300 Industry Blvd', 'Tacoma', 'WA', '98402', 'USA', 'Net 30', 4.6),
('SUP-005', 'Luxury Fabric Imports', 'James Wilson', 'jwilson@luxuryfabric.com', '415-555-0505', '1500 Fashion Avenue', 'San Francisco', 'CA', '94102', 'USA', 'Net 60', 4.7);

-- Supplier Items
INSERT INTO SupplierItem (SupplierID, ItemID, SupplierPartNumber, UnitPrice, MinimumOrderQuantity, LeadTimeDays, IsPreferred) VALUES
-- Pacific Textile Mills - Fabrics
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-001'), 'PTM-CAN-NAT-001', 7.50, 100, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-002'), 'PTM-CAN-NVY-001', 7.50, 100, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-003'), 'PTM-CAN-BUR-001', 7.50, 100, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-001'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-007'), 'PTM-TWL-KHA-001', 8.75, 100, 14, 1),
-- Premium Fill Supply - Fill materials
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-001'), 'PFS-POLY-001', 3.25, 500, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-002'), 'PFS-MEMF-001', 8.00, 300, 21, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-003'), 'PFS-COTN-001', 5.75, 400, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-004'), 'PFS-LATX-001', 11.50, 200, 28, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-002'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-005'), 'PFS-DOWN-001', 4.50, 350, 14, 1),
-- Northwest Lumber - Wood
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-001'), 'NWL-PINE-6FT', 11.00, 50, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-002'), 'NWL-PINE-4FT', 7.75, 50, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-003'), 'NWL-SLAT-6FT', 6.90, 100, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-004'), 'NWL-SLAT-4FT', 4.60, 100, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-001'), 'NWL-STN-WAL', 16.50, 12, 7, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-002'), 'NWL-STN-OAK', 16.50, 12, 7, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-003'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-003'), 'NWL-FIN-CLR', 20.00, 12, 7, 1),
-- Industrial Fasteners - Hardware
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-001'), 'IFI-BRK-001', 2.50, 200, 7, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-002'), 'IFI-HNG-001', 14.25, 100, 14, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-001'), 'IFI-SCR-3IN', 7.25, 50, 7, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-004'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-002'), 'IFI-BLT-KIT', 11.00, 50, 7, 1),
-- Luxury Fabric Imports - Premium fabrics
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-004'), 'LFI-MIC-BLK', 11.00, 80, 21, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-005'), 'LFI-MIC-CHO', 11.00, 80, 21, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-006'), 'LFI-LIN-BEI', 13.75, 60, 21, 1),
((SELECT SupplierID FROM Supplier WHERE SupplierCode = 'SUP-005'), (SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-008'), 'LFI-VEL-EMR', 17.00, 50, 28, 1);

GO

-- =============================================
-- Initial Inventory
-- =============================================

DECLARE @MainWH INT = (SELECT WarehouseID FROM Warehouse WHERE WarehouseCode = 'WH-MAIN');

-- Raw Materials Inventory
INSERT INTO Inventory (ItemID, WarehouseID, QuantityOnHand, LastCountDate) VALUES
-- Fill materials
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-001'), @MainWH, 1500.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-002'), @MainWH, 800.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-003'), @MainWH, 1200.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-004'), @MainWH, 450.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FILL-005'), @MainWH, 900.00, '2024-11-01'),
-- Fabrics
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-001'), @MainWH, 500.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-002'), @MainWH, 450.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-003'), @MainWH, 380.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-004'), @MainWH, 300.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-005'), @MainWH, 320.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-006'), @MainWH, 180.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-007'), @MainWH, 400.00, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FAB-008'), @MainWH, 150.00, '2024-11-01'),
-- Wood
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-001'), @MainWH, 250, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-002'), @MainWH, 300, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-003'), @MainWH, 500, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-WOOD-004'), @MainWH, 600, '2024-11-01'),
-- Metal & Hardware
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-001'), @MainWH, 800, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-METAL-002'), @MainWH, 200, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-001'), @MainWH, 100, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-HARD-002'), @MainWH, 80, '2024-11-01'),
-- Finishes
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-001'), @MainWH, 45, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-002'), @MainWH, 50, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'RM-FIN-003'), @MainWH, 55, '2024-11-01'),
-- Components
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-001'), @MainWH, 120, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-002'), @MainWH, 85, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-003'), @MainWH, 95, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-004'), @MainWH, 60, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-PIL-005'), @MainWH, 110, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-001'), @MainWH, 45, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-002'), @MainWH, 38, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-003'), @MainWH, 25, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-004'), @MainWH, 32, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-MAT-005'), @MainWH, 28, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-001'), @MainWH, 35, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-002'), @MainWH, 30, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-003'), @MainWH, 25, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-004'), @MainWH, 28, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'COMP-FRM-005'), @MainWH, 22, '2024-11-01'),
-- Finished Goods
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-001'), @MainWH, 18, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-002'), @MainWH, 15, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-003'), @MainWH, 12, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-004'), @MainWH, 8, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-005'), @MainWH, 14, '2024-11-01'),
((SELECT ItemID FROM Items WHERE ItemCode = 'FG-FUT-006'), @MainWH, 7, '2024-11-01');

GO

-- =============================================
-- Customers
-- =============================================

INSERT INTO Customer (CustomerCode, CustomerName, ContactName, Email, Phone, Address, City, State, ZipCode, Country, CreditLimit) VALUES
('CUST-001', 'Home Comfort Retailers', 'Jennifer Adams', 'jadams@homecomfort.com', '503-555-1001', '450 Retail Plaza', 'Portland', 'OR', '97210', 'USA', 50000),
('CUST-002', 'Furniture Warehouse Direct', 'Robert Taylor', 'rtaylor@furniturewd.com', '206-555-1002', '2200 Commerce Street', 'Seattle', 'WA', '98115', 'USA', 75000),
('CUST-003', 'Coastal Living Stores', 'Maria Garcia', 'mgarcia@coastalliving.com', '415-555-1003', '1800 Bay Avenue', 'San Francisco', 'CA', '94103', 'USA', 60000),
('CUST-004', 'University Dorm Supplies', 'Kevin Lee', 'klee@univdorm.com', '541-555-1004', '300 Campus Drive', 'Eugene', 'OR', '97403', 'USA', 40000),
('CUST-005', 'Modern Home Boutique', 'Amanda White', 'awhite@modernhome.com', '503-555-1005', '950 Design District', 'Portland', 'OR', '97209', 'USA', 35000),
('CUST-006', 'Budget Furniture Outlet', 'Chris Martinez', 'cmartinez@budgetfurniture.com', '360-555-1006', '500 Outlet Way', 'Vancouver', 'WA', '98660', 'USA', 45000),
('CUST-007', 'Luxury Living Inc', 'Patricia Johnson', 'pjohnson@luxuryliving.com', '425-555-1007', '1200 Elite Boulevard', 'Bellevue', 'WA', '98004', 'USA', 100000),
('CUST-008', 'College Town Furnishings', 'Daniel Kim', 'dkim@collegetown.com', '541-555-1008', '780 Student Lane', 'Corvallis', 'OR', '97330', 'USA', 30000);

GO

PRINT 'Sample data inserted successfully!';
GO
