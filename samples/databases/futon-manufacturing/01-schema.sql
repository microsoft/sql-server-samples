-- =============================================
-- Futon Manufacturing Database Schema
-- =============================================
-- This database manages a futon manufacturing business with multi-level
-- bill of materials, inventory, production, and sales tracking.
-- =============================================

USE master;
GO

-- Drop database if exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'FutonManufacturing')
BEGIN
    ALTER DATABASE FutonManufacturing SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FutonManufacturing;
END
GO

CREATE DATABASE FutonManufacturing;
GO

USE FutonManufacturing;
GO

-- =============================================
-- Reference Tables
-- =============================================

-- Unit of Measure
CREATE TABLE UnitOfMeasure (
    UnitID INT IDENTITY(1,1) PRIMARY KEY,
    UnitCode NVARCHAR(10) NOT NULL UNIQUE,
    UnitName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255)
);

-- Item Types (Raw Material, Component, Finished Good)
CREATE TABLE ItemType (
    ItemTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeCode NVARCHAR(20) NOT NULL UNIQUE,
    TypeName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255)
);

-- =============================================
-- Items Master Table
-- =============================================

CREATE TABLE Items (
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    ItemCode NVARCHAR(50) NOT NULL UNIQUE,
    ItemName NVARCHAR(255) NOT NULL,
    ItemTypeID INT NOT NULL,
    UnitID INT NOT NULL,
    Description NVARCHAR(MAX),
    StandardCost DECIMAL(18,4) NOT NULL DEFAULT 0,
    ListPrice DECIMAL(18,4) NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    LeadTimeDays INT DEFAULT 0,
    ReorderPoint DECIMAL(18,2) DEFAULT 0,
    SafetyStock DECIMAL(18,2) DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Items_ItemType FOREIGN KEY (ItemTypeID) REFERENCES ItemType(ItemTypeID),
    CONSTRAINT FK_Items_UnitOfMeasure FOREIGN KEY (UnitID) REFERENCES UnitOfMeasure(UnitID)
);

-- =============================================
-- Bill of Materials (Multi-Level)
-- =============================================

CREATE TABLE BillOfMaterials (
    BOMID INT IDENTITY(1,1) PRIMARY KEY,
    ParentItemID INT NOT NULL,
    ComponentItemID INT NOT NULL,
    Quantity DECIMAL(18,4) NOT NULL,
    UnitID INT NOT NULL,
    ScrapRate DECIMAL(5,2) DEFAULT 0, -- Percentage
    EffectiveDate DATE DEFAULT CAST(GETDATE() AS DATE),
    EndDate DATE NULL,
    BOMLevel INT NOT NULL DEFAULT 0, -- 0 = top level, increases for sub-components
    IsActive BIT NOT NULL DEFAULT 1,
    Notes NVARCHAR(MAX),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_BOM_ParentItem FOREIGN KEY (ParentItemID) REFERENCES Items(ItemID),
    CONSTRAINT FK_BOM_ComponentItem FOREIGN KEY (ComponentItemID) REFERENCES Items(ItemID),
    CONSTRAINT FK_BOM_Unit FOREIGN KEY (UnitID) REFERENCES UnitOfMeasure(UnitID),
    CONSTRAINT CHK_BOM_NotSelf CHECK (ParentItemID <> ComponentItemID)
);

-- Index for BOM queries
CREATE NONCLUSTERED INDEX IX_BOM_Parent ON BillOfMaterials(ParentItemID) INCLUDE (ComponentItemID, Quantity);
CREATE NONCLUSTERED INDEX IX_BOM_Component ON BillOfMaterials(ComponentItemID);

-- =============================================
-- Inventory Management
-- =============================================

CREATE TABLE Warehouse (
    WarehouseID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseCode NVARCHAR(20) NOT NULL UNIQUE,
    WarehouseName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(20),
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Inventory (
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    ItemID INT NOT NULL,
    WarehouseID INT NOT NULL,
    QuantityOnHand DECIMAL(18,2) NOT NULL DEFAULT 0,
    QuantityAllocated DECIMAL(18,2) NOT NULL DEFAULT 0,
    QuantityAvailable AS (QuantityOnHand - QuantityAllocated) PERSISTED,
    LastCountDate DATETIME2,
    LastUpdated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Inventory_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID),
    CONSTRAINT FK_Inventory_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID),
    CONSTRAINT UQ_Inventory_Item_Warehouse UNIQUE (ItemID, WarehouseID)
);

CREATE TABLE TransactionType (
    TransactionTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeCode NVARCHAR(20) NOT NULL UNIQUE,
    TypeName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255)
);

CREATE TABLE InventoryTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    ItemID INT NOT NULL,
    WarehouseID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    Quantity DECIMAL(18,2) NOT NULL,
    UnitCost DECIMAL(18,4),
    ReferenceNumber NVARCHAR(50),
    ReferenceType NVARCHAR(50), -- PO, SO, WO, ADJ, etc.
    Notes NVARCHAR(MAX),
    TransactionDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy NVARCHAR(100),
    CONSTRAINT FK_InvTrans_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID),
    CONSTRAINT FK_InvTrans_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID),
    CONSTRAINT FK_InvTrans_Type FOREIGN KEY (TransactionTypeID) REFERENCES TransactionType(TransactionTypeID)
);

CREATE NONCLUSTERED INDEX IX_InvTrans_Date ON InventoryTransaction(TransactionDate DESC);
CREATE NONCLUSTERED INDEX IX_InvTrans_Item ON InventoryTransaction(ItemID, TransactionDate);

-- =============================================
-- Supplier Management
-- =============================================

CREATE TABLE Supplier (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierCode NVARCHAR(20) NOT NULL UNIQUE,
    SupplierName NVARCHAR(255) NOT NULL,
    ContactName NVARCHAR(100),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    Address NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(20),
    Country NVARCHAR(50),
    PaymentTerms NVARCHAR(50),
    Rating DECIMAL(3,2), -- 0.00 to 5.00
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE SupplierItem (
    SupplierItemID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID INT NOT NULL,
    ItemID INT NOT NULL,
    SupplierPartNumber NVARCHAR(50),
    UnitPrice DECIMAL(18,4) NOT NULL,
    MinimumOrderQuantity DECIMAL(18,2) DEFAULT 1,
    LeadTimeDays INT DEFAULT 0,
    IsPreferred BIT NOT NULL DEFAULT 0,
    EffectiveDate DATE DEFAULT CAST(GETDATE() AS DATE),
    EndDate DATE NULL,
    CONSTRAINT FK_SupplierItem_Supplier FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID),
    CONSTRAINT FK_SupplierItem_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

CREATE TABLE PurchaseOrder (
    PurchaseOrderID INT IDENTITY(1,1) PRIMARY KEY,
    PONumber NVARCHAR(50) NOT NULL UNIQUE,
    SupplierID INT NOT NULL,
    WarehouseID INT NOT NULL,
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ExpectedDeliveryDate DATE,
    ActualDeliveryDate DATE,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Draft', -- Draft, Submitted, Confirmed, Shipped, Received, Cancelled
    Subtotal DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,
    ShippingAmount DECIMAL(18,2) DEFAULT 0,
    TotalAmount DECIMAL(18,2) DEFAULT 0,
    Notes NVARCHAR(MAX),
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_PO_Supplier FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID),
    CONSTRAINT FK_PO_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

CREATE TABLE PurchaseOrderDetail (
    PODetailID INT IDENTITY(1,1) PRIMARY KEY,
    PurchaseOrderID INT NOT NULL,
    LineNumber INT NOT NULL,
    ItemID INT NOT NULL,
    Quantity DECIMAL(18,2) NOT NULL,
    UnitPrice DECIMAL(18,4) NOT NULL,
    QuantityReceived DECIMAL(18,2) DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_PODetail_PO FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrder(PurchaseOrderID),
    CONSTRAINT FK_PODetail_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- =============================================
-- Production Management
-- =============================================

CREATE TABLE WorkCenter (
    WorkCenterID INT IDENTITY(1,1) PRIMARY KEY,
    WorkCenterCode NVARCHAR(20) NOT NULL UNIQUE,
    WorkCenterName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    Capacity DECIMAL(18,2), -- Units per day
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE ProductionOrder (
    ProductionOrderID INT IDENTITY(1,1) PRIMARY KEY,
    WorkOrderNumber NVARCHAR(50) NOT NULL UNIQUE,
    ItemID INT NOT NULL, -- What we're producing
    WarehouseID INT NOT NULL,
    WorkCenterID INT,
    OrderQuantity DECIMAL(18,2) NOT NULL,
    QuantityCompleted DECIMAL(18,2) DEFAULT 0,
    QuantityScrapped DECIMAL(18,2) DEFAULT 0,
    StartDate DATE,
    PlannedCompletionDate DATE,
    ActualCompletionDate DATE,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Planned', -- Planned, Released, InProgress, Completed, Cancelled
    Priority INT DEFAULT 5, -- 1 = Highest, 10 = Lowest
    Notes NVARCHAR(MAX),
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_ProdOrder_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID),
    CONSTRAINT FK_ProdOrder_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID),
    CONSTRAINT FK_ProdOrder_WorkCenter FOREIGN KEY (WorkCenterID) REFERENCES WorkCenter(WorkCenterID)
);

CREATE TABLE ProductionOrderMaterial (
    ProdOrderMaterialID INT IDENTITY(1,1) PRIMARY KEY,
    ProductionOrderID INT NOT NULL,
    ItemID INT NOT NULL,
    RequiredQuantity DECIMAL(18,2) NOT NULL,
    IssuedQuantity DECIMAL(18,2) DEFAULT 0,
    CONSTRAINT FK_ProdMaterial_ProdOrder FOREIGN KEY (ProductionOrderID) REFERENCES ProductionOrder(ProductionOrderID),
    CONSTRAINT FK_ProdMaterial_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

CREATE TABLE ProductionCompletion (
    CompletionID INT IDENTITY(1,1) PRIMARY KEY,
    ProductionOrderID INT NOT NULL,
    QuantityCompleted DECIMAL(18,2) NOT NULL,
    QuantityScrapped DECIMAL(18,2) DEFAULT 0,
    CompletionDate DATETIME2 DEFAULT GETDATE(),
    WorkCenterID INT,
    Notes NVARCHAR(MAX),
    CompletedBy NVARCHAR(100),
    CONSTRAINT FK_Completion_ProdOrder FOREIGN KEY (ProductionOrderID) REFERENCES ProductionOrder(ProductionOrderID),
    CONSTRAINT FK_Completion_WorkCenter FOREIGN KEY (WorkCenterID) REFERENCES WorkCenter(WorkCenterID)
);

-- =============================================
-- Quality Control
-- =============================================

CREATE TABLE QualityInspection (
    InspectionID INT IDENTITY(1,1) PRIMARY KEY,
    ItemID INT NOT NULL,
    InspectionType NVARCHAR(50) NOT NULL, -- Incoming, In-Process, Final
    ReferenceType NVARCHAR(50), -- PO, WO, etc.
    ReferenceNumber NVARCHAR(50),
    QuantityInspected DECIMAL(18,2) NOT NULL,
    QuantityAccepted DECIMAL(18,2) NOT NULL,
    QuantityRejected DECIMAL(18,2) NOT NULL,
    InspectionDate DATETIME2 DEFAULT GETDATE(),
    InspectedBy NVARCHAR(100),
    Notes NVARCHAR(MAX),
    CONSTRAINT FK_Quality_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- =============================================
-- Customer and Sales Management
-- =============================================

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode NVARCHAR(20) NOT NULL UNIQUE,
    CustomerName NVARCHAR(255) NOT NULL,
    ContactName NVARCHAR(100),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    Address NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(20),
    Country NVARCHAR(50),
    CreditLimit DECIMAL(18,2),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE SalesOrder (
    SalesOrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber NVARCHAR(50) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    WarehouseID INT NOT NULL,
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    RequestedDeliveryDate DATE,
    ShipDate DATE,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Draft', -- Draft, Confirmed, InProduction, Shipped, Delivered, Cancelled
    Subtotal DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,
    ShippingAmount DECIMAL(18,2) DEFAULT 0,
    TotalAmount DECIMAL(18,2) DEFAULT 0,
    Notes NVARCHAR(MAX),
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_SO_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT FK_SO_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

CREATE TABLE SalesOrderDetail (
    SODetailID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    LineNumber INT NOT NULL,
    ItemID INT NOT NULL,
    Quantity DECIMAL(18,2) NOT NULL,
    UnitPrice DECIMAL(18,4) NOT NULL,
    QuantityShipped DECIMAL(18,2) DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_SODetail_SO FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder(SalesOrderID),
    CONSTRAINT FK_SODetail_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- =============================================
-- Indexes for Performance
-- =============================================

CREATE NONCLUSTERED INDEX IX_Items_Type ON Items(ItemTypeID) INCLUDE (ItemCode, ItemName);
CREATE NONCLUSTERED INDEX IX_Items_Active ON Items(IsActive) WHERE IsActive = 1;
CREATE NONCLUSTERED INDEX IX_PO_Status ON PurchaseOrder(Status, OrderDate);
CREATE NONCLUSTERED INDEX IX_SO_Status ON SalesOrder(Status, OrderDate);
CREATE NONCLUSTERED INDEX IX_ProdOrder_Status ON ProductionOrder(Status, PlannedCompletionDate);

GO

PRINT 'Futon Manufacturing Database Schema created successfully!';
GO
