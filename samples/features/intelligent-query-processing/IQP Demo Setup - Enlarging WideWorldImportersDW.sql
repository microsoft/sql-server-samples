-- ***************************************************** --
-- Purpose of this script: make WideWorldImportersDW
-- bigger - so you can see more impactful 
-- Intelligent QP demonstrations (aka.ms/iqp)
--
-- Script last updated 05/03/2019
--
-- Database backup source: aka.ms/wwibak
-- 
-- Initial database file to restore before beginning this script: 
--		WideWorldImportersDW-Full.bak
-- ***************************************************** --

USE WideWorldImportersDW;
GO

/*
	Assumes a fresh restore of WideWorldImportersDW
*/

IF OBJECT_ID('Fact.OrderHistory') IS NULL 
BEGIN
    SELECT [Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
    INTO Fact.OrderHistory
    FROM Fact.[Order];
END;

ALTER TABLE Fact.OrderHistory
ADD CONSTRAINT PK_Fact_OrderHistory PRIMARY KEY NONCLUSTERED([Order Key] ASC, [Order Date Key] ASC) WITH (DATA_COMPRESSION = PAGE);
GO

CREATE INDEX IX_Stock_Item_Key
ON Fact.OrderHistory([Stock Item Key])
INCLUDE(Quantity)
WITH (DATA_COMPRESSION = PAGE);
GO

CREATE INDEX IX_OrderHistory_Quantity
ON Fact.OrderHistory([Quantity])
INCLUDE([Order Key])
WITH (DATA_COMPRESSION = PAGE);
GO

CREATE INDEX IX_OrderHistory_CustomerKey
ON Fact.OrderHistory([Customer Key])
INCLUDE ([Total Including Tax])
WITH (DATA_COMPRESSION = PAGE);
GO

/*
	Reality check... Starting count should be 231,412
*/
SELECT COUNT(*) FROM Fact.OrderHistory;
GO

/*
	Make this table bigger (exec as desired)
	Notice the "GO 4"
*/
INSERT Fact.OrderHistory([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
FROM Fact.OrderHistory;
GO 4

/*
	Should be 3,702,592
*/
SELECT COUNT(*) FROM Fact.OrderHistory;
GO

IF OBJECT_ID('Fact.OrderHistoryExtended') IS NULL 
BEGIN
    SELECT [Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
    INTO Fact.OrderHistoryExtended
    FROM Fact.[OrderHistory];
END;

ALTER TABLE Fact.OrderHistoryExtended
ADD CONSTRAINT PK_Fact_OrderHistoryExtended PRIMARY KEY NONCLUSTERED([Order Key] ASC, [Order Date Key] ASC)
WITH(DATA_COMPRESSION=PAGE);
GO

CREATE INDEX IX_Stock_Item_Key
ON Fact.OrderHistoryExtended([Stock Item Key])
INCLUDE(Quantity);
GO

/*
	Should be 3,702,592
*/
SELECT COUNT(*) FROM Fact.OrderHistoryExtended;
GO

/*
	Make this table bigger (exec as desired)
	Notice the "GO 3"
*/
INSERT Fact.OrderHistoryExtended([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
FROM Fact.OrderHistoryExtended;
GO 3

/*
	Should be 29,620,736
*/
SELECT COUNT(*) FROM Fact.OrderHistoryExtended;
GO

UPDATE Fact.OrderHistoryExtended
SET [WWI Order ID] = [Order Key];
GO

-- Repeat the following until log shrinks. These demos don't require much log space
CHECKPOINT
GO
DBCC SHRINKFILE (N'WWI_Log' , 0, TRUNCATEONLY)
GO
SELECT * FROM sys.dm_db_log_space_usage
GO