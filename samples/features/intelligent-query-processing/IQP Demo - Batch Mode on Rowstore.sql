-- ******************************************************** --
-- Batch mode on rowstore

-- See https://aka.ms/IQP for more background

-- Demo scripts: https://aka.ms/IQPDemos 

-- This demo is on SQL Server 2019 and Azure SQL DB

-- Email IntelligentQP@microsoft.com for questions\feedback
-- ******************************************************** --

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150;
GO

USE [WideWorldImportersDW];
GO

-- Row mode due to hint
SELECT [Tax Rate],
	[Lineage Key],
	[Salesperson Key],
	SUM([Quantity]) AS SUM_QTY,
	SUM([Unit Price]) AS SUM_BASE_PRICE,
	COUNT(*) AS COUNT_ORDER
FROM [Fact].[OrderHistoryExtended]
WHERE [Order Date Key] <= DATEADD(dd, -73, '2015-11-13')
GROUP BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
ORDER BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
OPTION (RECOMPILE, USE HINT('DISALLOW_BATCH_MODE'));

-- Batch mode on rowstore eligible
SELECT [Tax Rate],
	[Lineage Key],
	[Salesperson Key],
	SUM([Quantity]) AS SUM_QTY,
	SUM([Unit Price]) AS SUM_BASE_PRICE,
	COUNT(*) AS COUNT_ORDER
FROM [Fact].[OrderHistoryExtended]
WHERE [Order Date Key] <= DATEADD(dd, -73, '2015-11-13')
GROUP BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
ORDER BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
OPTION (RECOMPILE);
