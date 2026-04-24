------------------------------------------------------------------------
-- Event:        SQL Saturday #675 Parma, November 18 2017             -
--               http://www.sqlsaturday.com/675/EventHome.aspx         -
-- Session:      SQL Server 2017 Graph Database                        -
-- Demo:         Demo2: Create and populate nodes and edges            -
-- Author:       Sergio Govoni                                         -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [WideWorldImporters];
GO

-- Create Customers node
-- This node holds the main details of the Customer

/*
DROP TABLE IF EXISTS Nodes.Customers;
GO
*/
CREATE TABLE Nodes.Customers
(
  [CustomerID] INTEGER NOT NULL
  ,[CustomerName] NVARCHAR(100) NOT NULL
  ,[WebsiteURL] NVARCHAR(256) NOT NULL
)
AS NODE;
GO

INSERT INTO Nodes.Customers
(
  [CustomerID]
  ,[CustomerName]
  ,[WebsiteURL]
)
SELECT
  [CustomerID]
  ,[CustomerName]
  ,[WebsiteURL]
FROM
  Sales.Customers;
GO


-- Create StockItems node
/*
DROP TABLE IF EXISTS Nodes.StockItems;
GO
*/
IF OBJECT_ID('Nodes.StockItems', 'U') IS NULL
  CREATE TABLE Nodes.StockItems
  (
    StockItemID INTEGER IDENTITY(1, 1) NOT NULL
    ,StockItemName NVARCHAR(100) NOT NULL
    ,Barcode NVARCHAR(50) NULL
    ,Photo VARBINARY(MAX)
    ,LastEditedBy INTEGER NOT NULL
  )
  AS NODE;
  GO


IF OBJECT_ID('Nodes.StockItems', 'U') IS NOT NULL
BEGIN
  SET IDENTITY_INSERT Nodes.StockItems ON;

  INSERT INTO Nodes.StockItems
  (
    StockItemID
    ,StockItemName
    ,LastEditedBy
  )
  SELECT
    StockItemID
    ,StockItemName
    ,LastEditedBy
  FROM
    Warehouse.StockItems;

  SET IDENTITY_INSERT Nodes.StockItems OFF;
END;

-- Create the edge from nodes Customers and StockItems
/*
DROP TABLE IF EXISTS Edges.Bought;
GO
*/
CREATE TABLE Edges.Bought
(
  [PurchasedCount] BIGINT
)
AS EDGE;
GO


INSERT INTO Edges.Bought
(
  $from_id
  ,$to_id
  ,[PurchasedCount]
)
SELECT
  -- $from_id
  C.$node_id
  -- $to_id
  ,P.$node_id
  -- PurchasedCount
  ,PurchasedCount = COUNT(OD.OrderLineID)
FROM
  Sales.OrderLines AS OD
JOIN
  Sales.Orders AS OH ON OH.OrderID = OD.OrderID
JOIN
  Nodes.Customers AS C ON C.CustomerID = OH.CustomerID
JOIN
  Nodes.StockItems AS P ON P.StockItemID = OD.StockItemID
GROUP BY
  C.$node_id
  ,P.$node_id;
GO