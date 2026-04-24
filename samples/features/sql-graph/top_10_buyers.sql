/*
Find the top 10 buyers who purchased a specific item ordered by how much they spent
Using graph tables
Using regular tables
*/

-- using graph tables
SELECT top (10) sum(OrderLines_StockItemsToCustomers.UnitPrice * OrderLines_StockItemsToCustomers.Quantity) AS TotalSpendingOnItem, CustomerName, Customers.CustomerID
FROM Graph.Customers, Graph.OrderLines_StockItemsToCustomers, Graph.StockItems
WHERE MATCH (StockItems - (OrderLines_StockItemsToCustomers) -> Customers)
	and StockItems.StockItemName = 'Chocolate frogs 250g'
GROUP BY Customers.CustomerID, Customers.CustomerName
ORDER BY TotalSpendingOnItem DESC, Customers.CustomerName ;
go

-- using regular tables
SELECT top (10) sum(q2.UnitPrice * q2.Quantity) AS TotalSpendingOnItem, q4.CustomerName, q4.CustomerID
FROM (SELECT StockItemID, StockItemName FROM Warehouse.StockItems) AS q1
	join (SELECT StockItemID, OrderID, Quantity, UnitPrice FROM Sales.OrderLines) AS q2 ON q1.StockItemID = q2.StockItemID
	join (SELECT OrderID, CustomerID FROM Sales.Orders) AS q3 ON q2.OrderID = q3.OrderID
	join (SELECT CustomerID, CustomerName FROM Sales.Customers) AS q4 ON q3.CustomerID = q4.CustomerID
WHERE q1.StockItemName = 'Chocolate frogs 250g'
GROUP BY q4.CustomerID, q4.CustomerName
ORDER BY TotalSpendingOnItem DESC, q4.CustomerName ;
go
