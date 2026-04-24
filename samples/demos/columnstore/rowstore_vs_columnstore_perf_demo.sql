USE [AdventureworksDW2016]
GO


DBCC DROPCLEANBUFFERS

SET STATISTICS IO ON
SELECT s.SalesTerritoryRegion,d.[CalendarYear],FirstName + ' ' + lastName as 'Employee',FORMAT(SUM(f.SalesAmount),'C') AS 'Total Sales',
SUM(f.OrderQuantity) as 'Order Quantity', COUNT(distinct f.SalesOrdernumber) as 'Number of Orders',
count(distinct f.Resellerkey) as 'Num of Resellers'
FROM FactResellerSalesXL_PageCompressed f
INNER JOIN [dbo].[DimDate] d ON f.OrderDateKey= d.Datekey
INNER JOIN [dbo].[DimSalesTerritory] s on s.SalesTerritoryKey=f.SalesTerritoryKey
INNER JOIN [dbo].[DimEmployee] e on e.EmployeeKey=f.EmployeeKey
WHERE FullDateAlternateKey between '1/1/2005' and '1/1/2007'
GROUP BY d.[CalendarYear],s.SalesTerritoryRegion,FirstName + ' ' + lastName
ORDER BY SalesTerritoryRegion,CalendarYear,[Total Sales] desc
SET STATISTICS IO OFF

DBCC DROPCLEANBUFFERS

SET STATISTICS IO ON
SELECT s.SalesTerritoryRegion,d.[CalendarYear],FirstName + ' ' + lastName as 'Employee',FORMAT(SUM(f.SalesAmount),'C') AS 'Total Sales',
SUM(f.OrderQuantity) as 'Order Quantity', COUNT(distinct f.SalesOrdernumber) as 'Number of Orders',
count(distinct f.Resellerkey) as 'Num of Resellers'
FROM FactResellerSalesXL_CCI  f
INNER JOIN [dbo].[DimDate] d ON f.OrderDateKey= d.Datekey
INNER JOIN [dbo].[DimSalesTerritory] s on s.SalesTerritoryKey=f.SalesTerritoryKey
INNER JOIN [dbo].[DimEmployee] e on e.EmployeeKey=f.EmployeeKey
WHERE FullDateAlternateKey between '1/1/2005' and '1/1/2007'
GROUP BY d.[CalendarYear],s.SalesTerritoryRegion,FirstName + ' ' + lastName
ORDER BY SalesTerritoryRegion,CalendarYear,[Total Sales] desc
SET STATISTICS IO OFF
