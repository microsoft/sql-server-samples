-- ******************************************************** --
-- Table variable deferred compilation

-- See https://aka.ms/IQP for more background

-- Demo scripts: https://aka.ms/IQPDemos 

-- This demo is on SQL Server 2019 and Azure SQL DB

-- Email IntelligentQP@microsoft.com for questions\feedback
-- ******************************************************** --

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO

USE [WideWorldImportersDW];
GO

DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE  [Quantity] > 99;

-- Look at estimated rows, speed, join algorithm
SELECT oh.[Order Key], oh.[Order Date Key],
   oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
	ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC;
GO

USE [master]
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150
GO

USE [WideWorldImportersDW]
GO

DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE [Quantity] > 99;

-- Look at estimated rows, speed, join algorithm
SELECT oh.[Order Key], oh.[Order Date Key],
	oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
	ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC;
GO
