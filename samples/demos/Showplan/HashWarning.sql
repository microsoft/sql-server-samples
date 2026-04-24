-- Param Sniffing with Hash Spill

-- Setup
--USE AdventureWorks2014
USE AdventureWorks2016CTP3
GO
DROP TABLE CustomersState
GO
CREATE TABLE CustomersState (CustomerID int PRIMARY KEY, [Address] CHAR(200), [State] CHAR(2))
GO
INSERT INTO CustomersState (CustomerID, [Address])
SELECT CustomerID, 'Address' FROM Sales.Customer
GO
UPDATE CustomersState SET [State] = 'NY' WHERE CustomerID % 100 <> 1
UPDATE CustomersState SET [State] = 'WA' WHERE CustomerID % 100 = 1
GO

UPDATE STATISTICS CustomersState WITH FULLSCAN
GO

CREATE PROCEDURE CustomersByState @State CHAR(2) AS
BEGIN
	DECLARE @CustomerID int
	SELECT @CustomerID = e.CustomerID FROM Sales.Customer e
	INNER JOIN CustomersState es ON e.CustomerID = es.CustomerID
	WHERE es.[State] = @State
	OPTION (MAXDOP 1)
END
GO

-- Get Actual Execution Plan

-- Execute the stored procedure first with parameter value ‘WA’ – which will select 1% of data.
DBCC FREEPROCCACHE
GO
EXEC CustomersByState 'WA'
GO

EXEC CustomersByState 'NY'
GO

/*
Observe the type of Spill = Recursion
Occurs when the build input does not fit into available memory,
resulting in the split of input into multiple partitions that are processed separately.	

If any of these partitions still do not fit into available memory,
it is split into sub-partitions, which are also processed separately.
This splitting process continues until each partition fits into available memory
or until the maximum recursion level is reached.
In this case it stopped at level 1.
*/
