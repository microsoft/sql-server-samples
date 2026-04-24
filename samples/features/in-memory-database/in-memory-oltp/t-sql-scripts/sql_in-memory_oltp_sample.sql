-- The below script is used to install the AdventureWorksLT sample for In-Memory OLTP in Azure SQL Database.
-- The sample requires a new Premium database, created based on the AdventureWorksLT sample.
--
-- Last updated: 2016-07-29
--
--
--  Copyright (C) Microsoft Corporation.  All rights reserved.
--
-- This source code is intended only as a supplement to Microsoft
-- Development Tools and/or on-line documentation.
--
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
SET NOCOUNT ON
GO

/*************************** For memory-optimized tables, automatically map all lower isolation levels (including READ COMMITTED) to SNAPSHOT **********************************/

ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 130
GO

/*************************** Create Tables **********************************/

-- first drop all objects that have a schema-bound dependency on the table

DROP PROCEDURE IF EXISTS [SalesLT].usp_InsertSalesOrder_inmem
GO
DROP TABLE IF EXISTS [SalesLT].[SalesOrderHeader_inmem]
GO
CREATE TABLE [SalesLT].[SalesOrderHeader_inmem](
	[SalesOrderID] int IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT=100000),
	[RevisionNumber] [tinyint] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_RevisionNumber]  DEFAULT ((0)),
	[OrderDate] [datetime2] NOT NULL ,
	[DueDate] [datetime2] NOT NULL,
	[ShipDate] [datetime2] NULL,
	[Status] [tinyint] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_Status]  DEFAULT ((1)),
	[OnlineOrderFlag] bit NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_OnlineOrderFlag]  DEFAULT ((1)),
	[PurchaseOrderNumber] nvarchar(25) NULL,
	[AccountNumber] nvarchar(15) NULL,
	[CustomerID] [int] NOT NULL ,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[SubTotal] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_SubTotal]  DEFAULT ((0.00)),
	[TaxAmt] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_TaxAmt]  DEFAULT ((0.00)),
	[Freight] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_Freight]  DEFAULT ((0.00)),
	[Comment] [nvarchar](128) NULL,
	[ModifiedDate] [datetime2] NOT NULL ,

	INDEX IX_CustomerID HASH (CustomerID) WITH (BUCKET_COUNT=10000)
) WITH (MEMORY_OPTIMIZED=ON)
GO

DROP TABLE IF EXISTS [SalesLT].[SalesOrderDetail_inmem]
GO
CREATE TABLE [SalesLT].[SalesOrderDetail_inmem](
	[SalesOrderID] int NOT NULL INDEX IX_SalesOrderID HASH WITH (BUCKET_COUNT=100000),
	[SalesOrderDetailID] bigint IDENTITY NOT NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID HASH WITH (BUCKET_COUNT=100000),
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderDetail_UnitPriceDiscount]  DEFAULT ((0.0)),
	[ModifiedDate] [datetime2] NOT NULL ,

	CONSTRAINT [imPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY NONCLUSTERED HASH
	(	[SalesOrderID],
		[SalesOrderDetailID]
	)WITH (BUCKET_COUNT=1000000)
) WITH (MEMORY_OPTIMIZED=ON)
GO


-- type used for TVPs when creating new sales orders
DROP TYPE IF EXISTS [SalesLT].[SalesOrderDetailType_inmem]
GO
CREATE TYPE [SalesLT].[SalesOrderDetailType_inmem] AS TABLE(
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID NONCLUSTERED HASH WITH (BUCKET_COUNT=8)
) WITH (MEMORY_OPTIMIZED=ON)
GO



DROP TABLE IF EXISTS [SalesLT].[Product_inmem]
GO
CREATE TABLE [SalesLT].[Product_inmem](
	[ProductID] [int] IDENTITY NOT NULL,
	[Name] nvarchar(50) NOT NULL INDEX IX_Name,
	[ProductNumber] [nvarchar](25) NOT NULL INDEX IX_ProductNumber,
	[Color] [nvarchar](15) NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[Size] [nvarchar](5) NULL,
	[Weight] [decimal](8, 2) NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime2] NOT NULL,
	[SellEndDate] [datetime2] NULL,
	[DiscontinuedDate] [datetime2] NULL,
	[ModifiedDate] [datetime2] NOT NULL CONSTRAINT [IMDF_Product_ModifiedDate]  DEFAULT (SYSDATETIME()),

	CONSTRAINT [IMPK_Product_ProductID] PRIMARY KEY NONCLUSTERED
	( [ProductID] )
)	WITH (MEMORY_OPTIMIZED=ON)
GO

DROP TABLE IF EXISTS [SalesLT].[SalesOrderHeader_ondisk]
GO
CREATE TABLE [SalesLT].[SalesOrderHeader_ondisk](
	[SalesOrderID] int IDENTITY NOT NULL PRIMARY KEY,
	[RevisionNumber] [tinyint] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_RevisionNumber]  DEFAULT ((0)),
	[OrderDate] [datetime2] NOT NULL ,
	[DueDate] [datetime2] NOT NULL,
	[ShipDate] [datetime2] NULL,
	[Status] [tinyint] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_Status]  DEFAULT ((1)),
	[OnlineOrderFlag] bit NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_OnlineOrderFlag]  DEFAULT ((1)),
	[PurchaseOrderNumber] nvarchar(25) NULL,
	[AccountNumber] nvarchar(15) NULL,
	[CustomerID] [int] NOT NULL ,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[SubTotal] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_SubTotal]  DEFAULT ((0.00)),
	[TaxAmt] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_TaxAmt]  DEFAULT ((0.00)),
	[Freight] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_Freight]  DEFAULT ((0.00)),
	[Comment] [nvarchar](128) NULL,
	[ModifiedDate] [datetime2] NOT NULL ,

	INDEX IX_CustomerID (CustomerID) ,
	INDEX IX_OrderDate (OrderDate ASC)
)
GO

DROP TABLE IF EXISTS [SalesLT].[SalesOrderDetail_ondisk]
GO
CREATE TABLE [SalesLT].[SalesOrderDetail_ondisk](
	[SalesOrderID] int NOT NULL,
	[SalesOrderDetailID] bigint IDENTITY NOT NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID NONCLUSTERED,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderDetail_UnitPriceDiscount]  DEFAULT ((0.0)),
	[ModifiedDate] [datetime2] NOT NULL ,

	CONSTRAINT [ODPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY
	(	[SalesOrderID],	[SalesOrderDetailID])
)
GO


DROP PROCEDURE IF EXISTS SalesLT.usp_InsertSalesOrder_ondisk
GO
DROP TYPE IF EXISTS [SalesLT].[SalesOrderDetailType_ondisk]
GO
CREATE TYPE [SalesLT].[SalesOrderDetailType_ondisk] AS TABLE(
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID CLUSTERED
)
GO




DROP TABLE IF EXISTS SalesLT.[Product_ondisk]
GO
CREATE TABLE [SalesLT].[Product_ondisk](
	[ProductID] [int] IDENTITY NOT NULL,
	[Name] nvarchar(50) INDEX IX_Name,
	[ProductNumber] [nvarchar](25) NOT NULL INDEX IX_ProductNumber,
	[Color] [nvarchar](15) NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[Size] [nvarchar](5) NULL,
	[Weight] [decimal](8, 2) NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime2] NOT NULL,
	[SellEndDate] [datetime2] NULL,
	[DiscontinuedDate] [datetime2] NULL,
	[ModifiedDate] [datetime2] NOT NULL CONSTRAINT [ODDF_Product_ModifiedDate]  DEFAULT (SYSDATETIME()),
	CONSTRAINT [ODPK_Product_ProductID] PRIMARY KEY CLUSTERED ([ProductID])
)
GO

/*************************** Load data into migrated tables, as well as comparison tables **********************************/

SET IDENTITY_INSERT SalesLT.SalesOrderHeader_inmem ON
INSERT INTO SalesLT.SalesOrderHeader_inmem
	([SalesOrderID],
	[RevisionNumber],
	[OrderDate],
	[DueDate],
	[ShipDate],
	[Status],
	[OnlineOrderFlag],
	[PurchaseOrderNumber],
	[AccountNumber],
	[CustomerID],
	[BillToAddressID],
	[ShipToAddressID],
	[CreditCardApprovalCode],
	[SubTotal],
	[TaxAmt],
	[Freight],
	[Comment],
	[ModifiedDate])
SELECT
	[SalesOrderID],
	[RevisionNumber],
	[OrderDate],
	[DueDate],
	[ShipDate],
	[Status],
	[OnlineOrderFlag],
	[PurchaseOrderNumber],
	[AccountNumber],
	[CustomerID],
	[BillToAddressID],
	[ShipToAddressID],
	[CreditCardApprovalCode],
	[SubTotal],
	[TaxAmt],
	[Freight],
	[Comment],
	[ModifiedDate]
FROM SalesLT.SalesOrderHeader
SET IDENTITY_INSERT SalesLT.SalesOrderHeader_inmem OFF
GO

SET IDENTITY_INSERT SalesLT.SalesOrderHeader_ondisk ON
INSERT INTO SalesLT.SalesOrderHeader_ondisk
	([SalesOrderID],
	[RevisionNumber],
	[OrderDate],
	[DueDate],
	[ShipDate],
	[Status],
	[OnlineOrderFlag],
	[PurchaseOrderNumber],
	[AccountNumber],
	[CustomerID],
	[BillToAddressID],
	[ShipToAddressID],
	[CreditCardApprovalCode],
	[SubTotal],
	[TaxAmt],
	[Freight],
	[Comment],
	[ModifiedDate])
SELECT *
FROM SalesLT.SalesOrderHeader_inmem WITH (SNAPSHOT)
SET IDENTITY_INSERT SalesLT.SalesOrderHeader_ondisk OFF
GO

SET IDENTITY_INSERT SalesLT.SalesOrderDetail_inmem ON
INSERT INTO SalesLT.SalesOrderDetail_inmem
	([SalesOrderID],
	[SalesOrderDetailID],
	[OrderQty],
	[ProductID],
	[UnitPrice],
	[UnitPriceDiscount],
	[ModifiedDate])
SELECT
	[SalesOrderID],
	[SalesOrderDetailID],
	[OrderQty],
	[ProductID],
	[UnitPrice],
	[UnitPriceDiscount],
	[ModifiedDate]
FROM SalesLT.SalesOrderDetail
SET IDENTITY_INSERT SalesLT.SalesOrderDetail_inmem OFF
GO

SET IDENTITY_INSERT SalesLT.SalesOrderDetail_ondisk ON
INSERT INTO SalesLT.SalesOrderDetail_ondisk
	([SalesOrderID],
	[SalesOrderDetailID],
	[OrderQty],
	[ProductID],
	[UnitPrice],
	[UnitPriceDiscount],
	[ModifiedDate])
SELECT *
FROM SalesLT.SalesOrderDetail_inmem WITH (SNAPSHOT)
SET IDENTITY_INSERT SalesLT.SalesOrderDetail_ondisk OFF
GO





SET IDENTITY_INSERT [SalesLT].[Product_inmem] ON
INSERT INTO [SalesLT].[Product_inmem]
	([ProductID],
	[Name],
	[ProductNumber],
	[Color],
	[StandardCost],
	[ListPrice],
	[Size],
	[Weight],
	[ProductModelID],
	[SellStartDate],
	[SellEndDate],
	[DiscontinuedDate],
	[ModifiedDate])
SELECT
	[ProductID],
	[Name],
	[ProductNumber],
	[Color],
	[StandardCost],
	[ListPrice],
	[Size],
	[Weight],
	[ProductModelID],
	[SellStartDate],
	[SellEndDate],
	[DiscontinuedDate],
	[ModifiedDate]
FROM [SalesLT].[Product]
SET IDENTITY_INSERT [SalesLT].[Product_inmem] OFF
GO

SET IDENTITY_INSERT [SalesLT].[Product_ondisk] ON
INSERT INTO [SalesLT].[Product_ondisk]
	([ProductID],
	[Name],
	[ProductNumber],
	[Color],
	[StandardCost],
	[ListPrice],
	[Size],
	[Weight],
	[ProductModelID],
	[SellStartDate],
	[SellEndDate],
	[DiscontinuedDate],
	[ModifiedDate])
SELECT * FROM [SalesLT].[Product_inmem] WITH (SNAPSHOT)
SET IDENTITY_INSERT [SalesLT].[Product_ondisk] OFF
GO



/*************************** Update statistics for memory-optimized tables **********************************/

UPDATE STATISTICS SalesLT.[SalesOrderHeader_inmem]
WITH FULLSCAN, NORECOMPUTE
GO
UPDATE STATISTICS SalesLT.[SalesOrderDetail_inmem]
WITH FULLSCAN, NORECOMPUTE
GO


UPDATE STATISTICS SalesLT.Product_inmem
WITH FULLSCAN, NORECOMPUTE
GO

/*************************** Create stored procedures **********************************/

DROP PROCEDURE IF EXISTS SalesLT.usp_InsertSalesOrder_inmem
GO
CREATE PROCEDURE SalesLT.usp_InsertSalesOrder_inmem
	@SalesOrderID int OUTPUT,
	@DueDate [datetime2](7) NOT NULL,
	@CustomerID [int] NOT NULL,
	@BillToAddressID [int] NOT NULL,
	@ShipToAddressID [int] NOT NULL,
	@SalesOrderDetails SalesLT.SalesOrderDetailType_inmem READONLY,
	@Status [tinyint] NOT NULL = 1,
	@OnlineOrderFlag [bit] NOT NULL = 1,
	@PurchaseOrderNumber [nvarchar](25) = NULL,
	@AccountNumber [nvarchar](15) = NULL,
	@CreditCardApprovalCode [varchar](15) = NULL,
	@Comment nvarchar(128) = NULL
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
  (TRANSACTION ISOLATION LEVEL = SNAPSHOT,
   LANGUAGE = N'us_english')

	DECLARE @OrderDate datetime2 NOT NULL = sysdatetime()

	DECLARE @SubTotal money NOT NULL = 0

	SELECT @SubTotal = ISNULL(SUM(p.ListPrice),0)
	FROM @SalesOrderDetails od
		JOIN SalesLT.Product_inmem p on od.ProductID=p.ProductID

	INSERT INTO SalesLT.SalesOrderHeader_inmem
	(	DueDate,
		Status,
		OnlineOrderFlag,
		PurchaseOrderNumber,
		AccountNumber,
		CustomerID,
		BillToAddressID,
		ShipToAddressID,
		CreditCardApprovalCode,
		Comment,
		OrderDate,
		SubTotal,
		ModifiedDate)
	VALUES
	(	
		@DueDate,
		@Status,
		@OnlineOrderFlag,
		@PurchaseOrderNumber,
		@AccountNumber,
		@CustomerID,
		@BillToAddressID,
		@ShipToAddressID,
		@CreditCardApprovalCode,
		@Comment,
		@OrderDate,
		@SubTotal,
		@OrderDate
	)

    SET @SalesOrderID = SCOPE_IDENTITY()

	INSERT INTO SalesLT.SalesOrderDetail_inmem
	(
		SalesOrderID,
		OrderQty,
		ProductID,
		UnitPrice,
		UnitPriceDiscount,
		ModifiedDate
	)
    SELECT
		@SalesOrderID,
		od.OrderQty,
		od.ProductID,
		p.ListPrice,
		p.ListPrice,
		@OrderDate
	FROM @SalesOrderDetails od
		JOIN SalesLT.Product_inmem p on od.ProductID=p.ProductID

END
GO



DROP PROCEDURE IF EXISTS SalesLT.usp_InsertSalesOrder_ondisk
GO
CREATE PROCEDURE SalesLT.usp_InsertSalesOrder_ondisk
	@SalesOrderID int OUTPUT,
	@DueDate [datetime2](7) ,
	@CustomerID [int] ,
	@BillToAddressID [int] ,
	@ShipToAddressID [int] ,
	@SalesOrderDetails SalesLT.SalesOrderDetailType_ondisk READONLY,
	@Status [tinyint]  = 1,
	@OnlineOrderFlag [bit] = 1,
	@PurchaseOrderNumber [nvarchar](25) = NULL,
	@AccountNumber [nvarchar](15) = NULL,
	@CreditCardApprovalCode [varchar](15) = NULL,
	@Comment nvarchar(128) = NULL
AS
BEGIN
	BEGIN TRAN
	
		DECLARE @OrderDate datetime2 = sysdatetime()

		DECLARE @SubTotal money = 0

		SELECT @SubTotal = ISNULL(SUM(p.ListPrice),0)
		FROM @SalesOrderDetails od
			JOIN SalesLT.Product_ondisk p on od.ProductID=p.ProductID

		INSERT INTO SalesLT.SalesOrderHeader_ondisk
		(	DueDate,
			Status,
			OnlineOrderFlag,
			PurchaseOrderNumber,
			AccountNumber,
			CustomerID,
			BillToAddressID,
			ShipToAddressID,
			CreditCardApprovalCode,
			Comment,
			OrderDate,
			SubTotal,
			ModifiedDate)
		VALUES
		(	
			@DueDate,
			@Status,
			@OnlineOrderFlag,
			@PurchaseOrderNumber,
			@AccountNumber,
			@CustomerID,
			@BillToAddressID,
			@ShipToAddressID,
			@CreditCardApprovalCode,
			@Comment,
			@OrderDate,
			@SubTotal,
			@OrderDate
		)

		SET @SalesOrderID = SCOPE_IDENTITY()

		INSERT INTO SalesLT.SalesOrderDetail_ondisk
		(
			SalesOrderID,
			OrderQty,
			ProductID,
			UnitPrice,
			UnitPriceDiscount,
			ModifiedDate
		)
		SELECT
			@SalesOrderID,
			od.OrderQty,
			od.ProductID,
			p.ListPrice,
			p.ListPrice,
			@OrderDate
		FROM @SalesOrderDetails od
			JOIN SalesLT.Product_ondisk p on od.ProductID=p.ProductID


	COMMIT
END
GO


/*************************** Demo harness **********************************/

DROP PROCEDURE IF EXISTS Demo.usp_DemoInsertSalesOrders
go
DROP PROCEDURE IF EXISTS Demo.usp_DemoInitSeed
GO
DROP TABLE IF EXISTS Demo.DemoSalesOrderDetailSeed
GO
DROP TABLE IF EXISTS Demo.DemoSalesOrderHeaderSeed
GO
DROP PROCEDURE IF EXISTS Demo.usp_DemoReset
GO
DROP SCHEMA IF EXISTS Demo
GO
CREATE SCHEMA Demo
GO

DROP TABLE IF EXISTS Demo.DemoSalesOrderDetailSeed
GO
CREATE TABLE Demo.DemoSalesOrderDetailSeed
(
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL ,
	OrderID int NOT NULL INDEX IX_OrderID NONCLUSTERED,
	LocalID int IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED	
) WITH (MEMORY_OPTIMIZED=ON)
GO

DROP TABLE IF EXISTS Demo.DemoSalesOrderHeaderSeed
GO
CREATE TABLE Demo.DemoSalesOrderHeaderSeed
(
	DueDate [datetime2](7) NOT NULL,
	CustomerID [int] NOT NULL,
	BillToAddressID [int] NOT NULL,
	ShipToAddressID [int] NOT NULL,
	LocalID int IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED	
) WITH (MEMORY_OPTIMIZED=ON)
GO

DROP PROCEDURE IF EXISTS Demo.usp_DemoInitSeed
GO
CREATE PROCEDURE Demo.usp_DemoInitSeed @items_per_order int = 5
AS
BEGIN
	DECLARE @ProductID int,
		@i int = 1
	DECLARE @seed_order_count int = (SELECT COUNT(*)/@items_per_order FROM SalesLT.Product_inmem)

	DECLARE seed_cursor CURSOR FOR
		SELECT
			ProductID
		FROM SalesLT.Product_inmem WITH (SNAPSHOT)

	OPEN seed_cursor

	FETCH NEXT FROM seed_cursor
	INTO @ProductID

	BEGIN TRAN

		DELETE FROM Demo.DemoSalesOrderHeaderSeed WITH (SNAPSHOT)

		INSERT INTO Demo.DemoSalesOrderHeaderSeed
		(
			DueDate,
			CustomerID,
			BillToAddressID,
			ShipToAddressID
		)
		SELECT
			dateadd(d, (rand(BillToAddressID*CustomerID)*10)+1,cast(sysdatetime() as date)),
			CustomerID,
			BillToAddressID,
			ShipToAddressID
		FROM SalesLT.SalesOrderHeader_inmem WITH (SNAPSHOT)


		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT Demo.DemoSalesOrderDetailSeed
			SELECT
				@i % 6 + 1,
				@ProductID,
				@i % (@seed_order_count+1)

			SET @i += 1

			FETCH NEXT FROM seed_cursor
			INTO @ProductID
		END

		CLOSE seed_cursor
		DEALLOCATE seed_cursor
	COMMIT

	UPDATE STATISTICS Demo.DemoSalesOrderDetailSeed
	WITH FULLSCAN, NORECOMPUTE

	CHECKPOINT
END
GO


DROP PROCEDURE IF EXISTS Demo.usp_DemoReset
GO
CREATE PROCEDURE Demo.usp_DemoReset
AS
BEGIN
	truncate table SalesLT.SalesOrderDetail_ondisk
	delete from SalesLT.SalesOrderDetail_inmem
	truncate table SalesLT.SalesOrderHeader_ondisk
	delete from SalesLT.SalesOrderHeader_inmem
	
	CHECKPOINT

	SET IDENTITY_INSERT SalesLT.SalesOrderHeader_inmem ON
	INSERT INTO SalesLT.SalesOrderHeader_inmem
		([SalesOrderID],
		[RevisionNumber],
		[OrderDate],
		[DueDate],
		[ShipDate],
		[Status],
		[OnlineOrderFlag],
		[PurchaseOrderNumber],
		[AccountNumber],
		[CustomerID],
		[BillToAddressID],
		[ShipToAddressID],
		[CreditCardApprovalCode],
		[SubTotal],
		[TaxAmt],
		[Freight],
		[Comment],
		[ModifiedDate])
	SELECT
		[SalesOrderID],
		[RevisionNumber],
		[OrderDate],
		[DueDate],
		[ShipDate],
		[Status],
		[OnlineOrderFlag],
		[PurchaseOrderNumber],
		[AccountNumber],
		[CustomerID],
		[BillToAddressID],
		[ShipToAddressID],
		[CreditCardApprovalCode],
		[SubTotal],
		[TaxAmt],
		[Freight],
		[Comment],
		[ModifiedDate]
	FROM SalesLT.SalesOrderHeader
	SET IDENTITY_INSERT SalesLT.SalesOrderHeader_inmem OFF


	SET IDENTITY_INSERT SalesLT.SalesOrderHeader_ondisk ON
	INSERT INTO SalesLT.SalesOrderHeader_ondisk
		([SalesOrderID],
		[RevisionNumber],
		[OrderDate],
		[DueDate],
		[ShipDate],
		[Status],
		[OnlineOrderFlag],
		[PurchaseOrderNumber],
		[AccountNumber],
		[CustomerID],
		[BillToAddressID],
		[ShipToAddressID],
		[CreditCardApprovalCode],
		[SubTotal],
		[TaxAmt],
		[Freight],
		[Comment],
		[ModifiedDate])
	SELECT *
	FROM SalesLT.SalesOrderHeader_inmem WITH (SNAPSHOT)
	SET IDENTITY_INSERT SalesLT.SalesOrderHeader_ondisk OFF


	SET IDENTITY_INSERT SalesLT.SalesOrderDetail_inmem ON
	INSERT INTO SalesLT.SalesOrderDetail_inmem
		([SalesOrderID],
		[SalesOrderDetailID],
		[OrderQty],
		[ProductID],
		[UnitPrice],
		[UnitPriceDiscount],
		[ModifiedDate])
	SELECT
		[SalesOrderID],
		[SalesOrderDetailID],
		[OrderQty],
		[ProductID],
		[UnitPrice],
		[UnitPriceDiscount],
		[ModifiedDate]
	FROM SalesLT.SalesOrderDetail
	SET IDENTITY_INSERT SalesLT.SalesOrderDetail_inmem OFF


	SET IDENTITY_INSERT SalesLT.SalesOrderDetail_ondisk ON
	INSERT INTO SalesLT.SalesOrderDetail_ondisk
		([SalesOrderID],
		[SalesOrderDetailID],
		[OrderQty],
		[ProductID],
		[UnitPrice],
		[UnitPriceDiscount],
		[ModifiedDate])
	SELECT *
	FROM SalesLT.SalesOrderDetail_inmem WITH (SNAPSHOT)
	SET IDENTITY_INSERT SalesLT.SalesOrderDetail_ondisk OFF

	CHECKPOINT
END
GO
/*************************************  Initialize Demo seed table ********************************************/

EXEC Demo.usp_DemoInitSeed
GO
