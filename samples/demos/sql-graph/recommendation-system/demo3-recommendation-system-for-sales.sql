------------------------------------------------------------------------
-- Event:        SQL Saturday #675 Parma, November 18 2017             -
--               http://www.sqlsaturday.com/675/EventHome.aspx         -
-- Session:      SQL Server 2017 Graph Database                        -
-- Demo:         Recommendation system                                 -
-- Author:       Sergio Govoni                                         -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [WideWorldImporters];
GO


------------------------------------------------------------------------
-- Recommended items for sales with Graph Database                     -
------------------------------------------------------------------------

-- Supposing to have a user connected to your e-commerce, this user is
-- looking for the product "USB food flash drive - pizza slice"
-- or he/she has just bought that product

-- Our goal is finding the similar products to the one he/she is
-- looking at based on the behavior of other customers

-- We will use the counts to prioritize the recommendations
-- that is the simplest possible algorithm for a recommendation service
-- In reality more complex filters are applied on top, for example text
-- analysis of the product reviews to arrive at similarly measures


-- Find the top 5 products that are recommended for "USB food flash drive - pizza slice"
-- using MATCH clause
SELECT
  TOP 5
  RecommendedItem.StockItemName
  ,COUNT(*)
FROM
  Nodes.StockItems AS Item
  ,Nodes.Customers AS Customers
  ,Edges.Bought AS BoughtOther
  ,Edges.Bought AS BoughtThis
  ,Nodes.StockItems AS RecommendedItem
WHERE
  MATCH(RecommendedItem<-(BoughtOther)-Customers-(BoughtThis)->Item)


  AND (Item.StockItemName LIKE 'USB food flash drive - pizza slice') -- Current product
  AND (Customers.CustomerID <> 18) -- Current user
  AND (Item.StockItemName <> RecommendedItem.StockItemName)
GROUP BY
  RecommendedItem.StockItemName
ORDER BY COUNT(*) DESC;
GO






------------------------------------------------------------------------
-- Recommended items for sales in the relational database              -
------------------------------------------------------------------------

-- Find products that are recommended for 'USB food flash drive - pizza slice'
-- using common JOIN operations

-- Identify the user and the product he/she is purchasing
WITH Current_Usr AS
(
  SELECT
    CustomerID = 18
	,StockItemID = 7  -- USB food flash drive - pizza slice
	,PurchasedCount = 1
  /*
  SELECT
    C.CustomerID
	,P.StockItemID
	,PurchasedCount = COUNT(*)
  FROM
    Sales.OrderLines AS OD
  JOIN
    Sales.Orders AS OH ON OH.OrderID=OD.OrderID
  JOIN
    Sales.Customers AS C ON OH.CustomerID=C.CustomerID
  JOIN
    Warehouse.StockItems AS P ON P.StockItemID=OD.StockItemID
  WHERE
    C.CustomerID=18
    AND P.StockItemName='USB food flash drive - pizza slice'
  GROUP BY
    C.CustomerID
	,P.StockItemID
  */
),
-- Identify the other users who have also purchased the item he/she is looking for
Other_Usr AS
(
  SELECT
    C.CustomerID
	,P.StockItemID
	,Purchased_by_others = COUNT(*)
  FROM
    Sales.OrderLines AS OD
  JOIN
    Sales.Orders AS OH ON OH.OrderID=OD.OrderID
  JOIN
    Nodes.Customers AS C ON OH.CustomerID=C.CustomerID
  JOIN
    --Warehouse.StockItems AS P ON P.StockItemID=OD.StockItemID
	Current_Usr AS P ON P.StockItemID=OD.StockItemID
  WHERE
    C.CustomerID<>P.CustomerID
    --C.CustomerID<>18
    --AND P.StockItemName='USB food flash drive - pizza slice'
  GROUP BY
    C.CustomerID
	,P.StockItemID
),
-- Find the other items which those other customers have also purchased
Other_Items AS
(
SELECT
    C.CustomerID
	,P.StockItemID
	,Other_purchased = COUNT(*)
  FROM
    Sales.OrderLines AS OD
  JOIN
    Sales.Orders AS OH ON OH.OrderID=OD.OrderID
  JOIN
    Other_Usr AS C ON OH.CustomerID=C.CustomerID
  JOIN
    Nodes.StockItems AS P ON P.StockItemID=OD.StockItemID
  WHERE
    P.StockItemName<>'USB food flash drive - pizza slice'
  GROUP BY
    C.CustomerID
	,P.StockItemID
)
-- Outer query
-- Recommend to the current user to the top items from those other items,
-- ordered by the number of times they were purchased
SELECT
  TOP 5
  P.StockItemName
  ,COUNT(Other_purchased)
FROM
  Other_Items
JOIN
  Nodes.StockItems AS P ON P.StockItemID=Other_Items.StockItemID
GROUP BY
  P.StockItemName
ORDER BY
  COUNT(Other_purchased) DESC;
GO