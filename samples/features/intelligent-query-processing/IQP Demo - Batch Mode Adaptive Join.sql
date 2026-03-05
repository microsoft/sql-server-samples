-- ******************************************************** --
-- Batch mode Adaptive Join

-- See https://aka.ms/IQP for more background

-- Demo scripts: https://aka.ms/IQPDemos 

-- This demo is on SQL Server 2017 and Azure SQL DB

-- Email IntelligentQP@microsoft.com for questions\feedback
-- ******************************************************** --

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO

USE [WideWorldImportersDW];
GO

-- Show with Live Query Stats
SELECT [fo].[Order Key], [si].[Lead Time Days], [fo].[Quantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Quantity] = 360;
GO

-- Inserting quantity row that doesn't exist in the table yet
DELETE [Fact].[Order] 
WHERE Quantity = 361;

INSERT [Fact].[Order] 
	([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], 
	[Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], 
	[Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT TOP 5 [City Key], [Customer Key], [Stock Item Key],
	[Order Date Key], [Picked Date Key], [Salesperson Key], 
	[Picker Key], [WWI Order ID], [WWI Backorder ID], 
	Description, Package, 361, [Unit Price], [Tax Rate], 
	[Total Excluding Tax], [Tax Amount], [Total Including Tax], 
	[Lineage Key]
FROM [Fact].[Order];
GO

-- Show with Live Query Stats
SELECT [fo].[Order Key], [si].[Lead Time Days], [fo].[Quantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Quantity] = 361;
GO
