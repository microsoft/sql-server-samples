-- =============================================
-- Sales Operations Schema Enhancements
-- Futon Manufacturing Database
-- =============================================
-- Adds sales channel tracking, stores, and enhanced
-- sales operations capabilities
-- =============================================

USE FutonManufacturing;
GO

-- =============================================
-- Sales Channels and Stores
-- =============================================

CREATE TABLE SalesChannel (
    SalesChannelID INT IDENTITY(1,1) PRIMARY KEY,
    ChannelCode NVARCHAR(20) NOT NULL UNIQUE,
    ChannelName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    IsActive BIT NOT NULL DEFAULT 1
);

INSERT INTO SalesChannel (ChannelCode, ChannelName, Description) VALUES
('RETAIL', 'Retail Store', 'Physical retail store sales'),
('ONLINE', 'Online/E-Commerce', 'Online website and marketplace sales'),
('WHOLESALE', 'Wholesale', 'Bulk sales to retailers and distributors');

CREATE TABLE Store (
    StoreID INT IDENTITY(1,1) PRIMARY KEY,
    StoreCode NVARCHAR(20) NOT NULL UNIQUE,
    StoreName NVARCHAR(100) NOT NULL,
    SalesChannelID INT NOT NULL,
    Manager NVARCHAR(100),
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    Address NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(20),
    OpenDate DATE,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Store_SalesChannel FOREIGN KEY (SalesChannelID) REFERENCES SalesChannel(SalesChannelID)
);

CREATE TABLE SalesTerritory (
    TerritoryID INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryCode NVARCHAR(20) NOT NULL UNIQUE,
    TerritoryName NVARCHAR(100) NOT NULL,
    Region NVARCHAR(50),
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE SalesRep (
    SalesRepID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeCode NVARCHAR(20) NOT NULL UNIQUE,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    TerritoryID INT,
    HireDate DATE,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_SalesRep_Territory FOREIGN KEY (TerritoryID) REFERENCES SalesTerritory(TerritoryID)
);

-- =============================================
-- Enhance Existing Tables
-- =============================================

-- Add sales channel tracking to SalesOrder
ALTER TABLE SalesOrder ADD SalesChannelID INT NULL;
ALTER TABLE SalesOrder ADD StoreID INT NULL;
ALTER TABLE SalesOrder ADD SalesRepID INT NULL;
ALTER TABLE SalesOrder ADD DiscountAmount DECIMAL(18,2) DEFAULT 0;
ALTER TABLE SalesOrder ADD NetAmount AS (TotalAmount - DiscountAmount) PERSISTED;

ALTER TABLE SalesOrder ADD CONSTRAINT FK_SalesOrder_SalesChannel
    FOREIGN KEY (SalesChannelID) REFERENCES SalesChannel(SalesChannelID);
ALTER TABLE SalesOrder ADD CONSTRAINT FK_SalesOrder_Store
    FOREIGN KEY (StoreID) REFERENCES Store(StoreID);
ALTER TABLE SalesOrder ADD CONSTRAINT FK_SalesOrder_SalesRep
    FOREIGN KEY (SalesRepID) REFERENCES SalesRep(SalesRepID);

-- Add discount tracking to SalesOrderDetail
ALTER TABLE SalesOrderDetail ADD DiscountPercent DECIMAL(5,2) DEFAULT 0;
ALTER TABLE SalesOrderDetail ADD DiscountAmount AS (LineTotal * DiscountPercent / 100) PERSISTED;
ALTER TABLE SalesOrderDetail ADD NetAmount AS (LineTotal - (LineTotal * DiscountPercent / 100)) PERSISTED;

-- Add customer segmentation
ALTER TABLE Customer ADD CustomerType NVARCHAR(20) DEFAULT 'Retail'; -- Retail, Wholesale, Online
ALTER TABLE Customer ADD SalesRepID INT NULL;
ALTER TABLE Customer ADD TerritoryID INT NULL;

ALTER TABLE Customer ADD CONSTRAINT FK_Customer_SalesRep
    FOREIGN KEY (SalesRepID) REFERENCES SalesRep(SalesRepID);
ALTER TABLE Customer ADD CONSTRAINT FK_Customer_Territory
    FOREIGN KEY (TerritoryID) REFERENCES SalesTerritory(TerritoryID);

-- =============================================
-- Sales Returns and Exchanges
-- =============================================

CREATE TABLE ReturnReason (
    ReturnReasonID INT IDENTITY(1,1) PRIMARY KEY,
    ReasonCode NVARCHAR(20) NOT NULL UNIQUE,
    ReasonDescription NVARCHAR(255) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

INSERT INTO ReturnReason (ReasonCode, ReasonDescription) VALUES
('DEFECT', 'Product defect or quality issue'),
('DAMAGE', 'Damaged during shipping'),
('WRONG', 'Wrong item received'),
('NOFIT', 'Does not fit/wrong size'),
('EXPECT', 'Did not meet expectations'),
('CHANGE', 'Customer changed mind'),
('LATE', 'Delivery too late'),
('OTHER', 'Other reason');

CREATE TABLE SalesReturn (
    ReturnID INT IDENTITY(1,1) PRIMARY KEY,
    ReturnNumber NVARCHAR(50) NOT NULL UNIQUE,
    SalesOrderID INT NOT NULL,
    CustomerID INT NOT NULL,
    ReturnDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ReturnReasonID INT NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending', -- Pending, Approved, Received, Refunded, Denied
    RefundAmount DECIMAL(18,2) DEFAULT 0,
    RestockingFee DECIMAL(18,2) DEFAULT 0,
    Notes NVARCHAR(MAX),
    ApprovedBy NVARCHAR(100),
    ApprovedDate DATETIME2,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Return_SalesOrder FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder(SalesOrderID),
    CONSTRAINT FK_Return_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT FK_Return_Reason FOREIGN KEY (ReturnReasonID) REFERENCES ReturnReason(ReturnReasonID)
);

CREATE TABLE SalesReturnDetail (
    ReturnDetailID INT IDENTITY(1,1) PRIMARY KEY,
    ReturnID INT NOT NULL,
    SODetailID INT NOT NULL,
    ItemID INT NOT NULL,
    QuantityReturned DECIMAL(18,2) NOT NULL,
    UnitPrice DECIMAL(18,4) NOT NULL,
    RefundAmount DECIMAL(18,2) NOT NULL,
    Disposition NVARCHAR(50), -- Restock, Scrap, Repair, RMA
    CONSTRAINT FK_ReturnDetail_Return FOREIGN KEY (ReturnID) REFERENCES SalesReturn(ReturnID),
    CONSTRAINT FK_ReturnDetail_SODetail FOREIGN KEY (SODetailID) REFERENCES SalesOrderDetail(SODetailID),
    CONSTRAINT FK_ReturnDetail_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- =============================================
-- Sales Quotations
-- =============================================

CREATE TABLE SalesQuote (
    QuoteID INT IDENTITY(1,1) PRIMARY KEY,
    QuoteNumber NVARCHAR(50) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    SalesChannelID INT,
    SalesRepID INT,
    QuoteDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ExpirationDate DATE,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Draft', -- Draft, Sent, Accepted, Declined, Expired
    Subtotal DECIMAL(18,2) DEFAULT 0,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,
    TotalAmount DECIMAL(18,2) DEFAULT 0,
    ConvertedToOrderID INT NULL,
    Notes NVARCHAR(MAX),
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Quote_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT FK_Quote_SalesChannel FOREIGN KEY (SalesChannelID) REFERENCES SalesChannel(SalesChannelID),
    CONSTRAINT FK_Quote_SalesRep FOREIGN KEY (SalesRepID) REFERENCES SalesRep(SalesRepID),
    CONSTRAINT FK_Quote_ConvertedOrder FOREIGN KEY (ConvertedToOrderID) REFERENCES SalesOrder(SalesOrderID)
);

CREATE TABLE SalesQuoteDetail (
    QuoteDetailID INT IDENTITY(1,1) PRIMARY KEY,
    QuoteID INT NOT NULL,
    LineNumber INT NOT NULL,
    ItemID INT NOT NULL,
    Quantity DECIMAL(18,2) NOT NULL,
    UnitPrice DECIMAL(18,4) NOT NULL,
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice * (1 - DiscountPercent/100)) PERSISTED,
    CONSTRAINT FK_QuoteDetail_Quote FOREIGN KEY (QuoteID) REFERENCES SalesQuote(QuoteID),
    CONSTRAINT FK_QuoteDetail_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- =============================================
-- Promotions and Pricing
-- =============================================

CREATE TABLE Promotion (
    PromotionID INT IDENTITY(1,1) PRIMARY KEY,
    PromotionCode NVARCHAR(50) NOT NULL UNIQUE,
    PromotionName NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    DiscountPercent DECIMAL(5,2),
    DiscountAmount DECIMAL(18,2),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    MinimumPurchase DECIMAL(18,2) DEFAULT 0,
    ApplicableChannels NVARCHAR(255) -- CSV: RETAIL,ONLINE,WHOLESALE
);

CREATE TABLE PriceList (
    PriceListID INT IDENTITY(1,1) PRIMARY KEY,
    PriceListCode NVARCHAR(20) NOT NULL UNIQUE,
    PriceListName NVARCHAR(100) NOT NULL,
    SalesChannelID INT,
    EffectiveDate DATE NOT NULL,
    EndDate DATE,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_PriceList_SalesChannel FOREIGN KEY (SalesChannelID) REFERENCES SalesChannel(SalesChannelID)
);

CREATE TABLE PriceListDetail (
    PriceListDetailID INT IDENTITY(1,1) PRIMARY KEY,
    PriceListID INT NOT NULL,
    ItemID INT NOT NULL,
    UnitPrice DECIMAL(18,4) NOT NULL,
    MinimumQuantity DECIMAL(18,2) DEFAULT 1,
    CONSTRAINT FK_PriceListDetail_PriceList FOREIGN KEY (PriceListID) REFERENCES PriceList(PriceListID),
    CONSTRAINT FK_PriceListDetail_Item FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- =============================================
-- Indexes for Performance
-- =============================================

CREATE NONCLUSTERED INDEX IX_SalesOrder_Channel ON SalesOrder(SalesChannelID, OrderDate);
CREATE NONCLUSTERED INDEX IX_SalesOrder_Store ON SalesOrder(StoreID, OrderDate);
CREATE NONCLUSTERED INDEX IX_SalesOrder_SalesRep ON SalesOrder(SalesRepID, OrderDate);
CREATE NONCLUSTERED INDEX IX_Customer_Type ON Customer(CustomerType);
CREATE NONCLUSTERED INDEX IX_SalesReturn_Date ON SalesReturn(ReturnDate);
CREATE NONCLUSTERED INDEX IX_SalesQuote_Status ON SalesQuote(Status, QuoteDate);

GO

PRINT 'Sales operations schema enhancements completed successfully!';
GO
