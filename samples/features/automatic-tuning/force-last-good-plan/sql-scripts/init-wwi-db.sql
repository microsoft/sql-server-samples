-- Insert one OrderLine that with PackageTypeID=(0) will cause regression
INSERT INTO Warehouse.PackageTypes (PackageTypeID, PackageTypeName, LastEditedBy)
VALUES (0, 'FLGP', 1);

INSERT INTO Sales.OrderLines(OrderId, StockItemID, Description, PAckageTypeID, quantity, unitprice, taxrate, PickedQuantity,LastEditedBy)
SELECT TOP 1 OrderID, StockItemID, Description, PackageTypeID = 0, Quantity, UnitPrice, taxrate , PickedQuantity,LastEditedBy
FROM Sales.OrderLines;

-- Add PackageTypeID column into the NCCI index on Sales.OrderLines table
DROP INDEX IF EXISTS [NCCX_Sales_OrderLines] ON [Sales].[OrderLines]

CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCX_Sales_OrderLines] ON [Sales].[OrderLines]
(
	[OrderID],
	[StockItemID],
	[Description],
	[Quantity],
	[UnitPrice],
	[PickedQuantity],
	[PackageTypeID] -- adding package type id for demo purpose
)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)
GO

CREATE OR ALTER PROCEDURE [dbo].[initialize]
AS BEGIN

	ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
	ALTER DATABASE current SET QUERY_STORE CLEAR ALL;

END
GO


CREATE OR ALTER PROCEDURE [dbo].[report] (@packagetypeid int)
AS BEGIN

EXEC sp_executesql N'select avg([UnitPrice]*[Quantity])
						from Sales.OrderLines
						where PackageTypeID = @packagetypeid', N'@packagetypeid int', @packagetypeid;

END
GO


CREATE OR ALTER PROCEDURE [dbo].[regression]
AS BEGIN

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN
       declare @packagetypeid int = 0;
       exec report @packagetypeid;
END

END
GO

CREATE OR ALTER PROCEDURE [dbo].[auto_tuning_on]
AS BEGIN

	ALTER DATABASE current SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON);
	ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
	ALTER DATABASE current SET QUERY_STORE CLEAR ALL;

END
GO


CREATE OR ALTER PROCEDURE [dbo].[auto_tuning_off]
AS BEGIN

	ALTER DATABASE current SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF);
	ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
	ALTER DATABASE current SET QUERY_STORE CLEAR ALL;

END
GO
/*

CREATE EVENT SESSION [APC - plans that are not corrected] ON DATABASE
ADD EVENT qds.automatic_tuning_plan_regression_detection_check_completed(
WHERE ((([is_regression_detected]=(1))
  AND ([is_regression_corrected]=(0)))
  AND ([option_id]=(0))))
-- Use file target only on SQL Server 2017:
-- ADD TARGET package0.event_file(SET filename=N'plans_that_are_not_corrected')
ADD TARGET package0.ring_buffer (SET max_memory = 1000)
WITH (STARTUP_STATE=ON);
GO

ALTER EVENT SESSION [APC - plans that are not corrected] ON SERVER STATE = start;
*/