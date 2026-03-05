-- ******************************************************** --
-- Row mode memory grant feedback

-- See https://aka.ms/IQP for more background
-- Demo scripts: https://aka.ms/IQPDemos 

-- This demo is on SQL Server 2019 and Azure SQL DB 
-- SSMS v17.9 or higher

-- Email IntelligentQP@microsoft.com for questions\feedback
-- ******************************************************** --

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150;
GO

USE [WideWorldImportersDW];
GO

-- Simulate out-of-date stats
UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 1;
GO

-- Include actual execution plan
-- Execute once to see spills (row mode)
-- Execute a second time to see correction
SELECT fo.[Order Key], fo.Description,
	si.[Lead Time Days]
FROM Fact.OrderHistory AS fo
INNER HASH JOIN Dimension.[Stock Item] AS si 
	ON fo.[Stock Item Key] = si.[Stock Item Key]
WHERE fo.[Lineage Key] = 9
	AND si.[Lead Time Days] > 19;

-- Cleanup
UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 3702672;
GO

