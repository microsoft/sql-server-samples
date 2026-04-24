-- Sort Spill

-- Get Actual Execution Plan

USE AdventureWorks2014
--USE AdventureWorks2016CTP3
GO
--Execute
DBCC FREEPROCCACHE
GO
SELECT *
FROM Sales.SalesOrderDetail SOD
INNER JOIN Production.Product P ON SOD.ProductID = P.ProductID
ORDER BY Style
OPTION (QUERYTRACEON 9481)
GO

/*
Observe the type of Spill = 1
Means one pass over the data was enough to complete the sort in the Worktable
*/
