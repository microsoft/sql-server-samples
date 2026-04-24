-- The below script is used to install the sample for In-Memory Analytics in Azure SQL Database.
-- The sample requires a new Premium database, created based on the AdventureWorksLT sample.
--

-- Check edition.
/****** Object:  Table [dbo].[DimGeography]    Script Date: 10/23/2015 1:38:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL=130
GO
If object_id('dbo.DimGeography') is not null
	DROP TABLE [dbo].[DimGeography]
GO
CREATE TABLE [dbo].[DimGeography](
	[GeographyKey] [int] IDENTITY(1,1) NOT NULL,
	[GeographyAlternateKey] [int] NULL,
	[City] [nvarchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StateProvinceName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CountryRegionName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PostalCode] [nvarchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_DimGeography_GeographyKey] PRIMARY KEY CLUSTERED
(
	[GeographyKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO
-- Populate Data
insert into DimGeography
select distinct AddressID,City,StateProvince,CountryRegion,PostalCode
from SalesLT.Address

-- select * from DimGeography

/****** Object:  Table [dbo].[DimCustomer]    Script Date: 10/23/2015 1:38:34 PM ******/
If object_id('dbo.DimCustomer') is not null
	DROP TABLE [dbo].[DimCustomer]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimCustomer](
	[CustomerKey] [int] IDENTITY(1,1) NOT NULL,
	[GeographyKey] [int] NULL,
	[CustomerAlternateKey] [nvarchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[FirstName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MiddleName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LastName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Suffix] [nvarchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EmailAddress] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
 CONSTRAINT [PK_DimCustomer_CustomerKey] PRIMARY KEY CLUSTERED
(
	[CustomerKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
-- Indexes
/****** Object:  Index [IX_DimCustomer_CustomerAlternateKey]    Script Date: 10/23/2015 1:38:34 PM ******/
CREATE NONCLUSTERED INDEX [IX_DimCustomer_CustomerAlternateKey] ON [dbo].[DimCustomer]
(
	[CustomerAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

-- Populate Customer Dimension
insert into [DimCustomer]
select GeographyKey,a.CustomerID,a.FirstName,a.MiddleName,a.LastName,a.Suffix,a.EmailAddress
from SalesLT.Customer a
inner join SalesLT.CustomerAddress b on a.CustomerID = b.CustomerID
inner join DimGeography c on c.GeographyAlternateKey = b.AddressID


/****** Object:  Table [dbo].[DimDate]    Script Date: 10/23/2015 1:38:34 PM ******/
If object_id('dbo.DimDate') is not null
	DROP TABLE [dbo].[DimDate]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimDate](
	[DateKey] [int] NOT NULL,
	[FullDateAlternateKey] [date] NOT NULL,
	[DayNumberOfWeek] [tinyint] NOT NULL,
	[EnglishDayNameOfWeek] [nvarchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DayNumberOfMonth] [tinyint] NOT NULL,
	[DayNumberOfYear] [smallint] NOT NULL,
	[WeekNumberOfYear] [tinyint] NOT NULL,
	[MonthNumberOfYear] [tinyint] NOT NULL,
	[EnglishMonthName] [nvarchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Year] [smallint] NOT NULL
 CONSTRAINT [PK_DimDate_DateKey] PRIMARY KEY CLUSTERED
(
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- Procedure to Populate Date Dimension
If object_id('dbo.spGenerateDateDimension') is not null
	DROP PROCEDURE [dbo].[spGenerateDateDimension]
GO
Create Procedure [dbo].[spGenerateDateDimension]
@StartDate Date
, @EndDate Date
AS
;WITH DateList AS (
	SELECT @StartDate AS [DateKey]
	UNION ALL
	SELECT	DATEADD(DAY,1,[DateKey])
	FROM	DateList
	WHERE	DATEADD(DAY,1,[DateKey]) <= @EndDate
)
Insert into DimDate
select
	  [DateKey]= Cast(CONVERT(VARCHAR,[DateKey],112) as int) --YYYYMMDD
	 ,[FullDateAlternateKey] = [DateKey]
	  -- week
	 ,[DayNumberOfWeek] =DATEPART(WEEKDAY, [DateKey])
	 ,[EnglishDayNameOfWeek] = DATENAME(WEEKDAY, [DateKey])
	 -- Month
	 ,[DayNumberOfMonth] = DAY([DateKey])
	 --year
	 ,[DayNumberOfYear] =DATEPART(DAYOFYEAR, [DateKey])
	 ,[WeekNumberOfYear] = DATEPART(WEEK, [DateKey])
	-- Year
	 , [MonthNumberOfYear] = DATEPART(MONTH, [DateKey])
	 , [EnglishMonthName] = DATENAME(MONTH, [DateKey])


	 ,[Year] = YEAR([DateKey])
	 --into tbltest
 from DateList
 OPTION (MAXRECURSION 0)
GO
-- Populate Date Dimension
[spGenerateDateDimension] '1/1/2010', '1/1/2017'
GO


/****** Object:  Index [AK_DimDate_FullDateAlternateKey]    Script Date: 10/23/2015 1:38:34 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [AK_DimDate_FullDateAlternateKey] ON [dbo].[DimDate]
(
	[FullDateAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

-- select * from DimDate

/****** Object:  Table [dbo].[DimProductCategory]    Script Date: 10/23/2015 1:38:34 PM ******/
If object_id('dbo.DimProductCategory') is not null
	DROP TABLE [dbo].[DimProductCategory]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimProductCategory](
	[ProductCategoryKey] [int] IDENTITY(1,1) NOT NULL,
	[ProductCategoryAlternateKey] [int] NULL,
	[EnglishProductCategoryName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_DimProductCategory_ProductCategoryKey] PRIMARY KEY CLUSTERED
(
	[ProductCategoryKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
 CONSTRAINT [AK_DimProductCategory_ProductCategoryAlternateKey] UNIQUE NONCLUSTERED
(
	[ProductCategoryAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- Populate
insert into DimProductCategory
SELECT  [ProductCategoryID] ,[Name] FROM [SalesLT].[ProductCategory]
Where ParentProductCategoryID is NULL


/****** Object:  Table [dbo].[DimProductSubcategory]    Script Date: 10/23/2015 1:38:34 PM ******/
If object_id('dbo.DimProductSubcategory') is not null
	DROP TABLE [dbo].[DimProductSubcategory]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimProductSubcategory](
	[ProductSubcategoryKey] [int] IDENTITY(1,1) NOT NULL,
	[ProductSubcategoryAlternateKey] [int] NULL,
	[EnglishProductSubcategoryName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductCategoryKey] [int] NULL,
 CONSTRAINT [PK_DimProductSubcategory_ProductSubcategoryKey] PRIMARY KEY CLUSTERED
(
	[ProductSubcategoryKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
 CONSTRAINT [AK_DimProductSubcategory_ProductSubcategoryAlternateKey] UNIQUE NONCLUSTERED
(
	[ProductSubcategoryAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- Populate
insert into DimProductSubcategory
SELECT  a.[ProductCategoryID] ,a.[Name],b.[ProductCategoryKey]
FROM [SalesLT].[ProductCategory] a
inner join DimProductCategory b on b.[ProductCategoryAlternateKey] = a.[ParentProductCategoryID]

-- select * from DimProductSubcategory


/****** Object:  Table [dbo].[DimProduct]    Script Date: 10/23/2015 1:38:34 PM ******/
If object_id('dbo.DimProduct') is not null
	DROP TABLE [dbo].[DimProduct]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DimProduct](
	[ProductKey] [int] IDENTITY(1,1) NOT NULL,
	[ProductAlternateKey] [int] NULL,
	[ProductSubcategoryKey] [int] NULL,
	[EnglishProductName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductNumber] [nvarchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Color] [nvarchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
	[StandardCost] [money] NULL,
	[ListPrice] [money] NULL,
	[Size] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Weight] [float] NULL,
	[ProductModel] [nvarchar](400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL
 CONSTRAINT [PK_DimProduct_ProductKey] PRIMARY KEY CLUSTERED
(
	[ProductKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
 CONSTRAINT [AK_DimProduct_ProductAlternateKey_StartDate] UNIQUE NONCLUSTERED
(
	[ProductAlternateKey] ASC,
	[StartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

-- Populate DimProduct
insert into [DimProduct]
SELECT  [ProductID],a.ProductCategoryID ,a.[Name],[ProductNumber],[Color],[StandardCost],[ListPrice],[Size],[Weight]
		, b.[Name],[SellStartDate],[SellEndDate]
from SalesLT.Product a
inner join SalesLT.ProductModel b  on a.ProductModelID = b.ProductModelID
inner join DimProductSubCategory c on c.ProductSubcategoryAlternateKey = a.ProductCategoryID

-- select * from DimProduct

-- Fact Table
  /****** Object:  Table [dbo].[FactResellerSalesXL_CCI]    Script Date: 10/23/2015 1:38:34 PM ******/
 IF object_id('dbo.[FactResellerSalesXL_CCI]') is not null
	DROP TABLE [dbo].[FactResellerSalesXL_CCI]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactResellerSalesXL_CCI](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[CustomerKey] [int] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[LineTotal] numeric(38,6) NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CustomerPONumber] [nvarchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OrderDate] [smalldatetime] NULL,
	[DueDate] [smalldatetime] NULL,
	[ShipDate] [smalldatetime] NULL
)
GO

-- Create a Page Compressed Fact Table for performance comparisons
IF object_id('dbo.[FactResellerSalesXL_PageCompressed]') is not null
	DROP TABLE [dbo].[FactResellerSalesXL_PageCompressed]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactResellerSalesXL_PageCompressed](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[CustomerKey] [int] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[LineTotal] numeric(38,6) NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CustomerPONumber] [nvarchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OrderDate] [smalldatetime] NULL,
	[DueDate] [smalldatetime] NULL,
	[ShipDate] [smalldatetime] NULL
)
GO
ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed]  WITH CHECK ADD
	CONSTRAINT [PK_FactResellerSalesXL_PageCompressed_SalesOrderNumber_SalesOrderLineNumber] PRIMARY KEY CLUSTERED
	(
		[SalesOrderNumber] ASC,
		[SalesOrderLineNumber] ASC
	)WITH (PAD_INDEX = OFF, DATA_COMPRESSION = PAGE,STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

Select 'Created Tables.. Please wait Populating Data' as Status
GO

-- Number of rows distributed by date.
-- This script will take around 15 minutes to populate couple million rows in the fact table.
Select 'Please wait..FactResellerSalesXL_CCI being populated, may take 10-15 mins' as Status
GO
SET NOCOUNT ON
go
if object_id('tempdb..#temp') is not null
	drop table #temp
SELECT ABS( DateKey - 20150000 ) % 500 as NumOrdersPerDay,DateKey,FullDateAlternateKey
into #temp
FROM DimDate
where datekey > 20120101 and datekey < 20151026
order by DateKey asc

-- Initialization
Declare @SalesOrder int = 5000
--select sum(ordersperDateKey) from #temp
-- Constant Fields per order
Declare	@OrderDateKey int,
		@DueDateKey int,
		@ShipDateKey int,
		@NumOrderLineItems int, -- manufactured.
		@OrderDate datetime ,
		@DueDate datetime ,
		@ShipDate datetime,
		@SalesOrderNumber nvarchar(25),
		@NumOrdersPerDateKey int,
	    @NumSalesLineItems int

Declare @CustomerPONumber nvarchar(25),@CarrierTrackingNumber nvarchar(25)

-- Loop through each Date Key to insert that many rows.
DECLARE mycursor  CURSOR
FOR SELECT NumOrdersPerDay,DateKey,FullDateAlternateKey from #temp

OPEN mycursor
FETCH NEXT FROM mycursor
INTO @NumOrdersPerDateKey, @OrderDateKey,@OrderDate

WHILE @@FETCH_STATUS = 0
BEGIN

	-- Ship date is 6 days after, due date is 12 days after order for simplicity.
	SELECT @ShipDate = dateadd(day,6,@OrderDate), @DueDate= dateadd(day,12,@OrderDate)
	SELECT @ShipDateKey = DateKey from DimDate
	where FullDateAlternateKey = @ShipDate
	SELECT @DueDateKey = DateKey from DimDate
	where FullDateAlternateKey = @DueDate

	select @NumOrderLineItems = @NumOrdersPerDateKey %12 + 3

	
BEGIN TRAN
	Declare @OrdersPerDateKey int = 0, @SalesOrderLineNumber int = 1, @i int = 1
	while ( @OrdersPerDateKey < @NumOrdersPerDateKey )
	BEGIN
	
			select @SalesOrderNumber = N'SO' + cast(@SalesOrder as nvarchar(20))
					,@CustomerPONumber='PO' + cast(@SalesOrder + 1234  as nvarchar(20))
					,@CarrierTrackingNumber = Substring(cast(newid() as nvarchar(50)),0,14)
			SET @SalesOrder = @SalesOrder + 1
				
			;WITH Ordered AS (
				SELECT ROW_NUMBER() OVER (ORDER BY SalesOrderDetailID) AS RowNumber,
				SalesOrderID,OrderQty,ProductID,UnitPrice,UnitPriceDiscount,LineTotal
				FROM SalesLT.SalesOrderDetail)
			, OrderedDetails AS ( SELECT Rownumber,SalesOrderID,OrderQty,ProductID,UnitPrice,UnitPriceDiscount,LineTotal
				FROM Ordered
				WHERE RowNumber between @i and @i + @NumOrderLineItems)
			insert into FactResellerSalesXL_CCI
			select c.ProductKey, @OrderDateKey as OrderDateKey ,@DueDateKey as DueDateKey ,@ShipDateKey as ShipDateKey, @SalesOrderNumber as SalesOrderNumber
			,RowNumber - @i+1 as SalesOrderLineNumber ,b.RevisionNumber,d.CustomerKey
			, a.OrderQty as OrderQuantity,a.UnitPrice,a.UnitPriceDiscount as UnitPriceDiscountPct
			, DiscountAmount = a.UnitPriceDiscount *c.ListPrice * a.OrderQty
			,c.StandardCost as ProductStandardCost,TotalProductCost = a.OrderQty*c.StandardCost,b.SubTotal as SalesAmount,b.TaxAmt
			,a.LineTotal, b.Freight
			,@CarrierTrackingNumber as CarrierTrackingNumber,@CustomerPONumber as CustomerPONumber
			,@OrderDate as OrderDate,@DueDate as DueDate,@ShipDate as ShipDate
			From OrderedDetails a
			inner join SalesLT.SalesOrderHeader b on a.SalesOrderID = b.SalesOrderID
			inner join DimProduct c on a.ProductID = c.ProductAlternateKey
			inner join DimCustomer d on d.CustomerAlternateKey = b.CustomerID
			
			 set @i = @i + @NumOrderLineItems
			 if @i > 542
				 set @i = 1
			
		SET @OrdersPerDateKey = @OrdersPerDateKey + 1
	END
COMMIT

FETCH NEXT FROM mycursor
INTO @NumOrdersPerDateKey, @OrderDateKey,@OrderDate
END

Close mycursor
deallocate mycursor
GO

Select 'FactResellerSalesXL_CCI Populated' as Status
GO

-- Create Index
/****** Object:  Index [IndFactResellerSales_CCI]    Script Date: 10/23/2015 1:38:34 PM ******/
CREATE CLUSTERED COLUMNSTORE INDEX [IndFactResellerSales_CCI] ON [dbo].[FactResellerSalesXL_CCI] WITH (MAXDOP = 1)
GO

-- Create Constraints
ALTER TABLE [dbo].[FactResellerSalesXL_CCI]  WITH CHECK ADD
	CONSTRAINT [PK_FactResellerSalesXL_CCI_SalesOrderNumber_SalesOrderLineNumber] PRIMARY KEY
	(
		[SalesOrderNumber] ASC,
		[SalesOrderLineNumber] ASC
	)WITH (PAD_INDEX = OFF, DATA_COMPRESSION = PAGE,STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

ALTER TABLE [dbo].[FactResellerSalesXL_CCI]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_CCI_DimDate] FOREIGN KEY([OrderDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
ALTER TABLE [dbo].[FactResellerSalesXL_CCI] CHECK CONSTRAINT [FK_FactResellerSalesXL_CCI_DimDate]

ALTER TABLE [dbo].[FactResellerSalesXL_CCI]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_CCI_DimDate1] FOREIGN KEY([DueDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
ALTER TABLE [dbo].[FactResellerSalesXL_CCI] CHECK CONSTRAINT [FK_FactResellerSalesXL_CCI_DimDate1]
ALTER TABLE [dbo].[FactResellerSalesXL_CCI]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_CCI_DimDate2] FOREIGN KEY([ShipDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
ALTER TABLE [dbo].[FactResellerSalesXL_CCI] CHECK CONSTRAINT [FK_FactResellerSalesXL_CCI_DimDate2]

ALTER TABLE [dbo].[FactResellerSalesXL_CCI]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_CCI_DimProduct] FOREIGN KEY([ProductKey])
REFERENCES [dbo].[DimProduct] ([ProductKey])
ALTER TABLE [dbo].[FactResellerSalesXL_CCI] CHECK CONSTRAINT [FK_FactResellerSalesXL_CCI_DimProduct]
GO

Select 'FactResellerSalesXL_CCI Clustered Columnstore index created ' as Status
GO

-- Populate Page Compressed Table
insert into [FactResellerSalesXL_PageCompressed] WITH (TABLOCK) SELECT * from  [FactResellerSalesXL_CCI]
GO

-- Create Constraints on the Page Compressed table
ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_PageCompressed_DimDate] FOREIGN KEY([OrderDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
ALTER TABLE [dbo].[FactResellerSalesXL_CCI] CHECK CONSTRAINT [FK_FactResellerSalesXL_CCI_DimDate]

ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_PageCompressed_DimDate1] FOREIGN KEY([DueDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed] CHECK CONSTRAINT [FK_FactResellerSalesXL_PageCompressed_DimDate1]
ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_PageCompressed_DimDate2] FOREIGN KEY([ShipDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed] CHECK CONSTRAINT [FK_FactResellerSalesXL_PageCompressed_DimDate2]
GO
ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSalesXL_PageCompressed_DimProduct] FOREIGN KEY([ProductKey])
REFERENCES [dbo].[DimProduct] ([ProductKey])
ALTER TABLE [dbo].[FactResellerSalesXL_PageCompressed] CHECK CONSTRAINT [FK_FactResellerSalesXL_PageCompressed_DimProduct]
GO

Select 'FactResellerSalesXL_PageCompressed Populated' as Status
GO