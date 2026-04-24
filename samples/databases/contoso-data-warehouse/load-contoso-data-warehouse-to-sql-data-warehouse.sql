
-- Use PolyBase to load public data from Azure Blob Storage into the Contoso Retail Data Warehouse schema.
--
-- This script:
--
-- 1. Configures PolyBase for loading from a public blob storage container.
-- 2. Loads the data into columnstore indexes
-- 3. Performs optimizations after the load is finished.
--
-- Before you begin:
-- To run this tutorial, you need an Azure account that already has a SQL Data Warehouse database.
-- If you don't already have this, see
-- http://azure.microsoft.com/documentation/articles/sql-data-warehouse-get-started-provision.md
--
-- For more explanation about the loading process, this article on azure.microsoft.com
-- loads a small set of the Contoso data and explains the process in more detail.
-- http://azure.microsoft.com/documentation/articles/sql-data-warehouse-load-from-azure-blob-storage-with-polybase.md


-- Create an external data source
-- TYPE: HADOOP - PolyBase uses Hadoop APIs to access data in Azure Blob Storage.
-- LOCATION: Provide Azure storage account name and blob container name.
-- CREDENTIAL: Provide the credential created in the previous step.

CREATE EXTERNAL DATA SOURCE AzureStorage_west_public
WITH
(
    TYPE = Hadoop
,   LOCATION = 'wasbs://contosoretaildw-tables@contosoretaildw.blob.core.windows.net/'
);
GO

-- The data is stored in text files in Azure Blob Storage, and each field is separated with a delimiter.
-- Run this [CREATE EXTERNAL FILE FORMAT][] command to specify the format of the data in the text files.
-- he Contoso data is uncompressed and pipe delimited.

CREATE EXTERNAL FILE FORMAT TextFileFormat
WITH
(   FORMAT_TYPE = DELIMITEDTEXT
,	FORMAT_OPTIONS	(   FIELD_TERMINATOR = '|'
					,	STRING_DELIMITER = ''
					,	DATE_FORMAT		 = 'yyyy-MM-dd HH:mm:ss.fff'
					,	USE_TYPE_DEFAULT = FALSE
					)
);
GO

-- To create a place to store the Contoso data in your database, create a schema.

CREATE SCHEMA [asb];
GO


-- Now let's create the external tables. All we are doing here is defining column names and data types,
-- and binding them to the location and format of the Azure Blob Storage files. The location is the folder
-- under the root directory of the Azure Storage Blob.

--DimAccount
CREATE EXTERNAL TABLE [asb].DimAccount
(
	[AccountKey] [int] NOT NULL,
	[ParentAccountKey] [int] NULL,
	[AccountLabel] [nvarchar](100) NULL,
	[AccountName] [nvarchar](50) NULL,
	[AccountDescription] [nvarchar](50) NULL,
	[AccountType] [nvarchar](50) NULL,
	[Operator] [nvarchar](50) NULL,
	[CustomMembers] [nvarchar](300) NULL,
	[ValueType] [nvarchar](50) NULL,
	[CustomMemberOptions] [nvarchar](200) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimAccount/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimChannel
CREATE EXTERNAL TABLE [asb].DimChannel
(
	[ChannelKey] [int] NOT NULL,
	[ChannelLabel] [nvarchar](100) NOT NULL,
	[ChannelName] [nvarchar](20) NULL,
	[ChannelDescription] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimChannel/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimCurrency
CREATE EXTERNAL TABLE [asb].DimCurrency
(
	[CurrencyKey] [int] NOT NULL,
	[CurrencyLabel] [nvarchar](10) NOT NULL,
	[CurrencyName] [nvarchar](20) NOT NULL,
	[CurrencyDescription] [nvarchar](50) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimCurrency/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimCustomer
CREATE EXTERNAL TABLE [asb].DimCustomer
(
	[CustomerKey] [int]  NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[CustomerLabel] [nvarchar](100) NOT NULL,
	[Title] [nvarchar](8) NULL,
	[FirstName] [nvarchar](50) NULL,
	[MiddleName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[NameStyle] [bit] NULL,
	[BirthDate] [datetime] NULL,
	[MaritalStatus] [nchar](1) NULL,
	[Suffix] [nvarchar](10) NULL,
	[Gender] [nvarchar](1) NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[YearlyIncome] [money] NULL,
	[TotalChildren] [tinyint] NULL,
	[NumberChildrenAtHome] [tinyint] NULL,
	[Education] [nvarchar](40) NULL,
	[Occupation] [nvarchar](100) NULL,
	[HouseOwnerFlag] [nchar](1) NULL,
	[NumberCarsOwned] [tinyint] NULL,
	[AddressLine1] [nvarchar](120) NULL,
	[AddressLine2] [nvarchar](120) NULL,
	[Phone] [nvarchar](20) NULL,
	[DateFirstPurchase] [datetime] NULL,
	[CustomerType] [nvarchar](15) NULL,
	[CompanyName] [nvarchar](100) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimCustomer/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimDate
CREATE EXTERNAL TABLE [asb].DimDate
(
	[Datekey] [datetime] NOT NULL,
	[FullDateLabel] [nvarchar](20) NOT NULL,
	[DateDescription] [nvarchar](20) NOT NULL,
	[CalendarYear] [int] NOT NULL,
	[CalendarYearLabel] [nvarchar](20) NOT NULL,
	[CalendarHalfYear] [int] NOT NULL,
	[CalendarHalfYearLabel] [nvarchar](20) NOT NULL,
	[CalendarQuarter] [int] NOT NULL,
	[CalendarQuarterLabel] [nvarchar](20) NULL,
	[CalendarMonth] [int] NOT NULL,
	[CalendarMonthLabel] [nvarchar](20) NOT NULL,
	[CalendarWeek] [int] NOT NULL,
	[CalendarWeekLabel] [nvarchar](20) NOT NULL,
	[CalendarDayOfWeek] [int] NOT NULL,
	[CalendarDayOfWeekLabel] [nvarchar](10) NOT NULL,
	[FiscalYear] [int] NOT NULL,
	[FiscalYearLabel] [nvarchar](20) NOT NULL,
	[FiscalHalfYear] [int] NOT NULL,
	[FiscalHalfYearLabel] [nvarchar](20) NOT NULL,
	[FiscalQuarter] [int] NOT NULL,
	[FiscalQuarterLabel] [nvarchar](20) NOT NULL,
	[FiscalMonth] [int] NOT NULL,
	[FiscalMonthLabel] [nvarchar](20) NOT NULL,
	[IsWorkDay] [nvarchar](20) NOT NULL,
	[IsHoliday] [int] NOT NULL,
	[HolidayName] [nvarchar](20) NOT NULL,
	[EuropeSeason] [nvarchar](50) NULL,
	[NorthAmericaSeason] [nvarchar](50) NULL,
	[AsiaSeason] [nvarchar](50) NULL
)
WITH
(
    LOCATION='/DimDate/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimEmployee
CREATE EXTERNAL TABLE [asb].DimEmployee
(
	[EmployeeKey] [int]  NOT NULL,
	[ParentEmployeeKey] [int] NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[MiddleName] [nvarchar](50) NULL,
	[Title] [nvarchar](50) NULL,
	[HireDate] [datetime] NULL,
	[BirthDate] [datetime] NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[Phone] [nvarchar](25) NULL,
	[MaritalStatus] [nchar](1) NULL,
	[EmergencyContactName] [nvarchar](50) NULL,
	[EmergencyContactPhone] [nvarchar](25) NULL,
	[SalariedFlag] [bit] NULL,
	[Gender] [nchar](1) NULL,
	[PayFrequency] [tinyint] NULL,
	[BaseRate] [money] NULL,
	[VacationHours] [smallint] NULL,
	[CurrentFlag] [bit] NOT NULL,
	[SalesPersonFlag] [bit] NOT NULL,
	[DepartmentName] [nvarchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimEmployee/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimEntity
CREATE EXTERNAL TABLE [asb].DimEntity
(
	[EntityKey] [int] NOT NULL,
	[EntityLabel] [nvarchar](100) NULL,
	[ParentEntityKey] [int] NULL,
	[ParentEntityLabel] [nvarchar](100) NULL,
	[EntityName] [nvarchar](50) NULL,
	[EntityDescription] [nvarchar](100) NULL,
	[EntityType] [nvarchar](100) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimEntity/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimGeography
CREATE EXTERNAL TABLE [asb].DimGeography
(
	[GeographyKey] [int] NOT NULL,
	[GeographyType] [nvarchar](50) NOT NULL,
	[ContinentName] [nvarchar](50) NOT NULL,
	[CityName] [nvarchar](100) NULL,
	[StateProvinceName] [nvarchar](100) NULL,
	[RegionCountryName] [nvarchar](100) NULL,
--	[Geometry] [geometry] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimGeography/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimMachine
CREATE EXTERNAL TABLE [asb].DimMachine
(
	[MachineKey] [int] NOT NULL,
	[MachineLabel] [nvarchar](100) NULL,
	[StoreKey] [int] NOT NULL,
	[MachineType] [nvarchar](50) NOT NULL,
	[MachineName] [nvarchar](100) NOT NULL,
	[MachineDescription] [nvarchar](200) NOT NULL,
	[VendorName] [nvarchar](50) NOT NULL,
	[MachineOS] [nvarchar](50) NOT NULL,
	[MachineSource] [nvarchar](100) NOT NULL,
	[MachineHardware] [nvarchar](100) NULL,
	[MachineSoftware] [nvarchar](100) NOT NULL,
	[Status] [nvarchar](50) NOT NULL,
	[ServiceStartDate] [datetime] NOT NULL,
	[DecommissionDate] [datetime] NULL,
	[LastModifiedDate] [datetime] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimMachine/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimOutage
CREATE EXTERNAL TABLE [asb].DimOutage (
	[OutageKey] [int]  NOT NULL,
	[OutageLabel] [nvarchar](100) NOT NULL,
	[OutageName] [nvarchar](50) NOT NULL,
	[OutageDescription] [nvarchar](200) NOT NULL,
	[OutageType] [nvarchar](50) NOT NULL,
	[OutageTypeDescription] [nvarchar](200) NOT NULL,
	[OutageSubType] [nvarchar](50) NOT NULL,
	[OutageSubTypeDescription] [nvarchar](200) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimOutage/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimProduct
CREATE EXTERNAL TABLE [asb].DimProduct (
	[ProductKey] [int] NOT NULL,
	[ProductLabel] [nvarchar](255) NULL,
	[ProductName] [nvarchar](500) NULL,
	[ProductDescription] [nvarchar](400) NULL,
	[ProductSubcategoryKey] [int] NULL,
	[Manufacturer] [nvarchar](50) NULL,
	[BrandName] [nvarchar](50) NULL,
	[ClassID] [nvarchar](10) NULL,
	[ClassName] [nvarchar](20) NULL,
	[StyleID] [nvarchar](10) NULL,
	[StyleName] [nvarchar](20) NULL,
	[ColorID] [nvarchar](10) NULL,
	[ColorName] [nvarchar](20) NOT NULL,
	[Size] [nvarchar](50) NULL,
	[SizeRange] [nvarchar](50) NULL,
	[SizeUnitMeasureID] [nvarchar](20) NULL,
	[Weight] [float] NULL,
	[WeightUnitMeasureID] [nvarchar](20) NULL,
	[UnitOfMeasureID] [nvarchar](10) NULL,
	[UnitOfMeasureName] [nvarchar](40) NULL,
	[StockTypeID] [nvarchar](10) NULL,
	[StockTypeName] [nvarchar](40) NULL,
	[UnitCost] [money] NULL,
	[UnitPrice] [money] NULL,
	[AvailableForSaleDate] [datetime] NULL,
	[StopSaleDate] [datetime] NULL,
	[Status] [nvarchar](7) NULL,
	[ImageURL] [nvarchar](150) NULL,
	[ProductURL] [nvarchar](150) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimProduct/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimProductCategory
CREATE EXTERNAL TABLE [asb].DimProductCategory (
	[ProductCategoryKey] [int]  NOT NULL,
	[ProductCategoryLabel] [nvarchar](100) NULL,
	[ProductCategoryName] [nvarchar](30) NOT NULL,
	[ProductCategoryDescription] [nvarchar](50) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimProductCategory/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimProductSubcategory
CREATE EXTERNAL TABLE [asb].DimProductSubcategory (
	[ProductSubcategoryKey] [int]  NOT NULL,
	[ProductSubcategoryLabel] [nvarchar](100) NULL,
	[ProductSubcategoryName] [nvarchar](50) NOT NULL,
	[ProductSubcategoryDescription] [nvarchar](100) NULL,
	[ProductCategoryKey] [int] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimProductSubcategory/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimPromotion
CREATE EXTERNAL TABLE [asb].DimPromotion (
	[PromotionKey] [int]  NOT NULL,
	[PromotionLabel] [nvarchar](100) NULL,
	[PromotionName] [nvarchar](100) NULL,
	[PromotionDescription] [nvarchar](255) NULL,
	[DiscountPercent] [float] NULL,
	[PromotionType] [nvarchar](50) NULL,
	[PromotionCategory] [nvarchar](50) NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[MinQuantity] [int] NULL,
	[MaxQuantity] [int] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimPromotion/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;


--DimSalesTerritory
CREATE EXTERNAL TABLE [asb].DimSalesTerritory (
	[SalesTerritoryKey] [int]  NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[SalesTerritoryLabel] [nvarchar](100) NULL,
	[SalesTerritoryName] [nvarchar](50) NOT NULL,
	[SalesTerritoryRegion] [nvarchar](50) NOT NULL,
	[SalesTerritoryCountry] [nvarchar](50) NOT NULL,
	[SalesTerritoryGroup] [nvarchar](50) NULL,
	[SalesTerritoryLevel] [nvarchar](10) NULL,
	[SalesTerritoryManager] [int] NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimSalesTerritory/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimScenario
CREATE EXTERNAL TABLE [asb].DimScenario (
	[ScenarioKey] [int] NOT NULL,
	[ScenarioLabel] [nvarchar](100) NOT NULL,
	[ScenarioName] [nvarchar](20) NULL,
	[ScenarioDescription] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimScenario/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--DimStore
CREATE EXTERNAL TABLE [asb].DimStore
(
	[StoreKey] [int] NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[StoreManager] [int] NULL,
	[StoreType] [nvarchar](15) NULL,
	[StoreName] [nvarchar](100) NOT NULL,
	[StoreDescription] [nvarchar](300) NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
	[OpenDate] [datetime] NOT NULL,
	[CloseDate] [datetime] NULL,
	[EntityKey] [int] NULL,
	[ZipCode] [nvarchar](20) NULL,
	[ZipCodeExtension] [nvarchar](10) NULL,
	[StorePhone] [nvarchar](15) NULL,
	[StoreFax] [nvarchar](14) NULL,
	[AddressLine1] [nvarchar](100) NULL,
	[AddressLine2] [nvarchar](100) NULL,
	[CloseReason] [nvarchar](20) NULL,
	[EmployeeCount] [int] NULL,
	[SellingAreaSize] [float] NULL,
	[LastRemodelDate] [datetime] NULL,
	[GeoLocation]	NVARCHAR(50)  NULL,
	[Geometry]		NVARCHAR(50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimStore/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--FactExchangeRate
CREATE EXTERNAL TABLE [asb].FactExchangeRate
(
	[ExchangeRateKey] [int]  NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[AverageRate] [float] NOT NULL,
	[EndOfDayRate] [float] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactExchangeRate/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--FactInventory
CREATE EXTERNAL TABLE [asb].FactInventory (
	[InventoryKey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[OnHandQuantity] [int] NOT NULL,
	[OnOrderQuantity] [int] NOT NULL,
	[SafetyStockQuantity] [int] NULL,
	[UnitCost] [money] NOT NULL,
	[DaysInStock] [int] NULL,
	[MinDayInStock] [int] NULL,
	[MaxDayInStock] [int] NULL,
	[Aging] [int] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactInventory/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--FactITMachine
CREATE EXTERNAL TABLE [asb].FactITMachine (
	[ITMachinekey] [int] NOT NULL,
	[MachineKey] [int] NOT NULL,
	[Datekey] [datetime] NOT NULL,
	[CostAmount] [money] NULL,
	[CostType] [nvarchar](200) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactITMachine/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;


--FactITSLA
CREATE EXTERNAL TABLE [asb].FactITSLA
(
	[ITSLAkey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[MachineKey] [int] NOT NULL,
	[OutageKey] [int] NOT NULL,
	[OutageStartTime] [datetime] NOT NULL,
	[OutageEndTime] [datetime] NOT NULL,
	[DownTime] [int] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactITSLA/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--FactOnlineSales
CREATE EXTERNAL TABLE [asb].FactOnlineSales
(
	[OnlineSalesKey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[CustomerKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [int] NULL,
	[SalesQuantity] [int] NOT NULL,
	[SalesAmount] [money] NOT NULL,
	[ReturnQuantity] [int] NOT NULL,
	[ReturnAmount] [money] NULL,
	[DiscountQuantity] [int] NULL,
	[DiscountAmount] [money] NULL,
	[TotalCost] [money] NOT NULL,
	[UnitCost] [money] NULL,
	[UnitPrice] [money] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactOnlineSales/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--FactSales
CREATE EXTERNAL TABLE [asb].FactSales
(
	[SalesKey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[channelKey] [int] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[UnitCost] [money] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[SalesQuantity] [int] NOT NULL,
	[ReturnQuantity] [int] NOT NULL,
	[ReturnAmount] [money] NULL,
	[DiscountQuantity] [int] NULL,
	[DiscountAmount] [money] NULL,
	[TotalCost] [money] NOT NULL,
	[SalesAmount] [money] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactSales/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--FactSalesQuota
CREATE EXTERNAL TABLE [asb].FactSalesQuota (
	[SalesQuotaKey] [int]  NOT NULL,
	[ChannelKey] [int] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[ScenarioKey] [int] NOT NULL,
	[SalesQuantityQuota] [money] NOT NULL,
	[SalesAmountQuota] [money] NOT NULL,
	[GrossMarginQuota] [money] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactSalesQuota/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;

--FactStrategyPlan
CREATE EXTERNAL TABLE [asb].FactStrategyPlan
(
	[StrategyPlanKey] [int]  NOT NULL,
	[Datekey] [datetime] NOT NULL,
	[EntityKey] [int] NOT NULL,
	[ScenarioKey] [int] NOT NULL,
	[AccountKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[ProductCategoryKey] [int] NULL,
	[Amount] [money] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactStrategyPlan/'
,   DATA_SOURCE = AzureStorage_west_public
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
;


-- Load the data with CTAS
--
-- The easiest and most efficient way to load data from Azure Blob Storage is to usu
-- Create Table As Select (CTAS). Loading with CTAS leverages the strongly typed
-- external tables you have just created.

-- Create a new schema

CREATE SCHEMA [cso];
GO


-- Load the data
-- To load the data we use one CTAS statement per table.

SELECT GETDATE();
GO
CREATE TABLE [cso].[DimAccount]            WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimAccount]             OPTION (LABEL = 'CTAS : Load [cso].[DimAccount]             ');
CREATE TABLE [cso].[DimChannel]            WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimChannel]             OPTION (LABEL = 'CTAS : Load [cso].[DimChannel]             ');
CREATE TABLE [cso].[DimCurrency]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimCurrency]            OPTION (LABEL = 'CTAS : Load [cso].[DimCurrency]            ');
CREATE TABLE [cso].[DimCustomer]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimCustomer]            OPTION (LABEL = 'CTAS : Load [cso].[DimCustomer]            ');
CREATE TABLE [cso].[DimDate]               WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimDate]                OPTION (LABEL = 'CTAS : Load [cso].[DimDate]                ');
CREATE TABLE [cso].[DimEmployee]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimEmployee]            OPTION (LABEL = 'CTAS : Load [cso].[DimEmployee]            ');
CREATE TABLE [cso].[DimEntity]             WITH (DISTRIBUTION = HASH([EntityKey]   ) ) AS SELECT * FROM [asb].[DimEntity]              OPTION (LABEL = 'CTAS : Load [cso].[DimEntity]              ');
CREATE TABLE [cso].[DimGeography]          WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimGeography]           OPTION (LABEL = 'CTAS : Load [cso].[DimGeography]           ');
CREATE TABLE [cso].[DimMachine]            WITH (DISTRIBUTION = HASH([MachineKey]  ) ) AS SELECT * FROM [asb].[DimMachine]             OPTION (LABEL = 'CTAS : Load [cso].[DimMachine]             ');
CREATE TABLE [cso].[DimOutage]             WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimOutage]              OPTION (LABEL = 'CTAS : Load [cso].[DimOutage]              ');
CREATE TABLE [cso].[DimProduct]            WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[DimProduct]             OPTION (LABEL = 'CTAS : Load [cso].[DimProduct]             ');
CREATE TABLE [cso].[DimProductCategory]    WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimProductCategory]     OPTION (LABEL = 'CTAS : Load [cso].[DimProductCategory]     ');
CREATE TABLE [cso].[DimScenario]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimScenario]            OPTION (LABEL = 'CTAS : Load [cso].[DimScenario]            ');
CREATE TABLE [cso].[DimPromotion]          WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimPromotion]           OPTION (LABEL = 'CTAS : Load [cso].[DimPromotion]           ');
CREATE TABLE [cso].[DimProductSubcategory] WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimProductSubcategory]  OPTION (LABEL = 'CTAS : Load [cso].[DimProductSubcategory]  ');
CREATE TABLE [cso].[DimSalesTerritory]     WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimSalesTerritory]      OPTION (LABEL = 'CTAS : Load [cso].[DimSalesTerritory]      ');
CREATE TABLE [cso].[DimStore]              WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimStore]               OPTION (LABEL = 'CTAS : Load [cso].[DimStore]               ');
CREATE TABLE [cso].[FactITMachine]         WITH (DISTRIBUTION = HASH([MachineKey]  ) ) AS SELECT * FROM [asb].[FactITMachine]          OPTION (LABEL = 'CTAS : Load [cso].[FactITMachine]          ');
CREATE TABLE [cso].[FactITSLA]             WITH (DISTRIBUTION = HASH([MachineKey]  ) ) AS SELECT * FROM [asb].[FactITSLA]              OPTION (LABEL = 'CTAS : Load [cso].[FactITSLA]              ');
CREATE TABLE [cso].[FactInventory]         WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactInventory]          OPTION (LABEL = 'CTAS : Load [cso].[FactInventory]          ');
CREATE TABLE [cso].[FactOnlineSales]       WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactOnlineSales]        OPTION (LABEL = 'CTAS : Load [cso].[FactOnlineSales]        ');
CREATE TABLE [cso].[FactSales]             WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactSales]              OPTION (LABEL = 'CTAS : Load [cso].[FactSales]              ');
CREATE TABLE [cso].[FactSalesQuota]        WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactSalesQuota]         OPTION (LABEL = 'CTAS : Load [cso].[FactSalesQuota]         ');
CREATE TABLE [cso].[FactStrategyPlan]      WITH (DISTRIBUTION = HASH([EntityKey])  )   AS SELECT * FROM [asb].[FactStrategyPlan]       OPTION (LABEL = 'CTAS : Load [cso].[FactStrategyPlan]       ');
CREATE TABLE [cso].[FactExchangeRate]      WITH (DISTRIBUTION = HASH([ExchangeRateKey])  ) AS SELECT * FROM [asb].[FactExchangeRate]    OPTION (LABEL = 'CTAS : Load [cso].[FactExchangeRate]       ');


-- Track the load progress
--
-- You can track the progress of your load using the `[sys].[dm_pdw_exec_requests]` dynamic management view (DMV).
-- To see all requests
-- SELECT * FROM sys.dm_pdw_exec_requests;
--
-- To see a particular request identified by its lable
--   SELECT * FROM sys.dm_pdw_exec_requests as r;
--   WHERE r.label = "FactSales";
--
-- Optimize columnstore compression
-- By default, SQL Data Warehouse stores the table as a clustered columnstore index.
-- After a load completes, some of the data rows might not be compressed into the columnstore.
-- There's a variety of reasons why this can happen. To learn more, see ... .
--
-- To optimize query performance and columnstore compression after a load, rebuild the table to force
-- the columnstore index to compress all the rows.

SELECT GETDATE();
GO
ALTER INDEX ALL ON [cso].[FactStrategyPlan]         REBUILD;
ALTER INDEX ALL ON [cso].[DimAccount]               REBUILD;
ALTER INDEX ALL ON [cso].[DimChannel]               REBUILD;
ALTER INDEX ALL ON [cso].[DimCurrency]              REBUILD;
ALTER INDEX ALL ON [cso].[DimCustomer]              REBUILD;
ALTER INDEX ALL ON [cso].[DimDate]                  REBUILD;
ALTER INDEX ALL ON [cso].[DimEmployee]              REBUILD;
ALTER INDEX ALL ON [cso].[DimEntity]                REBUILD;
ALTER INDEX ALL ON [cso].[DimGeography]             REBUILD;
ALTER INDEX ALL ON [cso].[DimMachine]               REBUILD;
ALTER INDEX ALL ON [cso].[DimOutage]                REBUILD;
ALTER INDEX ALL ON [cso].[DimProduct]               REBUILD;
ALTER INDEX ALL ON [cso].[DimProductCategory]       REBUILD;
ALTER INDEX ALL ON [cso].[DimScenario]              REBUILD;
ALTER INDEX ALL ON [cso].[DimPromotion]             REBUILD;
ALTER INDEX ALL ON [cso].[DimProductSubcategory]    REBUILD;
ALTER INDEX ALL ON [cso].[DimSalesTerritory]        REBUILD;
ALTER INDEX ALL ON [cso].[DimStore]                 REBUILD;
ALTER INDEX ALL ON [cso].[FactITMachine]            REBUILD;
ALTER INDEX ALL ON [cso].[FactITSLA]                REBUILD;
ALTER INDEX ALL ON [cso].[FactInventory]            REBUILD;
ALTER INDEX ALL ON [cso].[FactOnlineSales]          REBUILD;
ALTER INDEX ALL ON [cso].[FactSales]                REBUILD;
ALTER INDEX ALL ON [cso].[FactSalesQuota]           REBUILD;
ALTER INDEX ALL ON [cso].[FactExchangeRate]         REBUILD;


-- Optimize statistics
-- It is best to create single-column statistics immediately after a load. There are some choices for statistics. -- For example, if you create single-column statistics on every column it might take a long time to rebuild
-- statistics. If you know certain columns are not going to be in query predicates, you could skip creating
-- statistics on those columns.
--
-- If you decide to create single-column statistics on every column, you can use stored procedure code
-- sample `prc_sqldw_create_stats` in the [statistics][] article.
--
-- This example is a good starting point for creating statistics. It creates single-column statistics on each
-- column in the dimension table, and on each joining column in the fact tables. You can always add single or
-- multi-column statistics to other fact table columns later on.
--

CREATE STATISTICS [stat_cso_DimMachine_DecommissionDate] ON [cso].[DimMachine]([DecommissionDate]);
CREATE STATISTICS [stat_cso_DimMachine_ETLLoadID] ON [cso].[DimMachine]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimMachine_LastModifiedDate] ON [cso].[DimMachine]([LastModifiedDate]);
CREATE STATISTICS [stat_cso_DimMachine_LoadDate] ON [cso].[DimMachine]([LoadDate]);
CREATE STATISTICS [stat_cso_DimMachine_MachineDescription] ON [cso].[DimMachine]([MachineDescription]);
CREATE STATISTICS [stat_cso_DimMachine_MachineHardware] ON [cso].[DimMachine]([MachineHardware]);
CREATE STATISTICS [stat_cso_DimMachine_MachineKey] ON [cso].[DimMachine]([MachineKey]);
CREATE STATISTICS [stat_cso_DimMachine_MachineLabel] ON [cso].[DimMachine]([MachineLabel]);
CREATE STATISTICS [stat_cso_DimMachine_MachineName] ON [cso].[DimMachine]([MachineName]);
CREATE STATISTICS [stat_cso_DimMachine_MachineOS] ON [cso].[DimMachine]([MachineOS]);
CREATE STATISTICS [stat_cso_DimMachine_MachineSoftware] ON [cso].[DimMachine]([MachineSoftware]);
CREATE STATISTICS [stat_cso_DimMachine_MachineSource] ON [cso].[DimMachine]([MachineSource]);
CREATE STATISTICS [stat_cso_DimMachine_MachineType] ON [cso].[DimMachine]([MachineType]);
CREATE STATISTICS [stat_cso_DimMachine_ServiceStartDate] ON [cso].[DimMachine]([ServiceStartDate]);
CREATE STATISTICS [stat_cso_DimMachine_Status] ON [cso].[DimMachine]([Status]);
CREATE STATISTICS [stat_cso_DimMachine_StoreKey] ON [cso].[DimMachine]([StoreKey]);
CREATE STATISTICS [stat_cso_DimMachine_UpdateDate] ON [cso].[DimMachine]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimMachine_VendorName] ON [cso].[DimMachine]([VendorName]);
CREATE STATISTICS [stat_cso_DimOutage_ETLLoadID] ON [cso].[DimOutage]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimOutage_LoadDate] ON [cso].[DimOutage]([LoadDate]);
CREATE STATISTICS [stat_cso_DimOutage_OutageDescription] ON [cso].[DimOutage]([OutageDescription]);
CREATE STATISTICS [stat_cso_DimOutage_OutageKey] ON [cso].[DimOutage]([OutageKey]);
CREATE STATISTICS [stat_cso_DimOutage_OutageLabel] ON [cso].[DimOutage]([OutageLabel]);
CREATE STATISTICS [stat_cso_DimOutage_OutageName] ON [cso].[DimOutage]([OutageName]);
CREATE STATISTICS [stat_cso_DimOutage_OutageSubType] ON [cso].[DimOutage]([OutageSubType]);
CREATE STATISTICS [stat_cso_DimOutage_OutageSubTypeDescription] ON [cso].[DimOutage]([OutageSubTypeDescription]);
CREATE STATISTICS [stat_cso_DimOutage_OutageType] ON [cso].[DimOutage]([OutageType]);
CREATE STATISTICS [stat_cso_DimOutage_OutageTypeDescription] ON [cso].[DimOutage]([OutageTypeDescription]);
CREATE STATISTICS [stat_cso_DimOutage_UpdateDate] ON [cso].[DimOutage]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimProductCategory_ETLLoadID] ON [cso].[DimProductCategory]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimProductCategory_LoadDate] ON [cso].[DimProductCategory]([LoadDate]);
CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryDescription] ON [cso].[DimProductCategory]([ProductCategoryDescription]);
CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryKey] ON [cso].[DimProductCategory]([ProductCategoryKey]);
CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryLabel] ON [cso].[DimProductCategory]([ProductCategoryLabel]);
CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryName] ON [cso].[DimProductCategory]([ProductCategoryName]);
CREATE STATISTICS [stat_cso_DimProductCategory_UpdateDate] ON [cso].[DimProductCategory]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimScenario_ETLLoadID] ON [cso].[DimScenario]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimScenario_LoadDate] ON [cso].[DimScenario]([LoadDate]);
CREATE STATISTICS [stat_cso_DimScenario_ScenarioDescription] ON [cso].[DimScenario]([ScenarioDescription]);
CREATE STATISTICS [stat_cso_DimScenario_ScenarioKey] ON [cso].[DimScenario]([ScenarioKey]);
CREATE STATISTICS [stat_cso_DimScenario_ScenarioLabel] ON [cso].[DimScenario]([ScenarioLabel]);
CREATE STATISTICS [stat_cso_DimScenario_ScenarioName] ON [cso].[DimScenario]([ScenarioName]);
CREATE STATISTICS [stat_cso_DimScenario_UpdateDate] ON [cso].[DimScenario]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimPromotion_DiscountPercent] ON [cso].[DimPromotion]([DiscountPercent]);
CREATE STATISTICS [stat_cso_DimPromotion_EndDate] ON [cso].[DimPromotion]([EndDate]);
CREATE STATISTICS [stat_cso_DimPromotion_ETLLoadID] ON [cso].[DimPromotion]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimPromotion_LoadDate] ON [cso].[DimPromotion]([LoadDate]);
CREATE STATISTICS [stat_cso_DimPromotion_MaxQuantity] ON [cso].[DimPromotion]([MaxQuantity]);
CREATE STATISTICS [stat_cso_DimPromotion_MinQuantity] ON [cso].[DimPromotion]([MinQuantity]);
CREATE STATISTICS [stat_cso_DimPromotion_PromotionCategory] ON [cso].[DimPromotion]([PromotionCategory]);
CREATE STATISTICS [stat_cso_DimPromotion_PromotionDescription] ON [cso].[DimPromotion]([PromotionDescription]);
CREATE STATISTICS [stat_cso_DimPromotion_PromotionKey] ON [cso].[DimPromotion]([PromotionKey]);
CREATE STATISTICS [stat_cso_DimPromotion_PromotionLabel] ON [cso].[DimPromotion]([PromotionLabel]);
CREATE STATISTICS [stat_cso_DimPromotion_PromotionName] ON [cso].[DimPromotion]([PromotionName]);
CREATE STATISTICS [stat_cso_DimPromotion_PromotionType] ON [cso].[DimPromotion]([PromotionType]);
CREATE STATISTICS [stat_cso_DimPromotion_StartDate] ON [cso].[DimPromotion]([StartDate]);
CREATE STATISTICS [stat_cso_DimPromotion_UpdateDate] ON [cso].[DimPromotion]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_EndDate] ON [cso].[DimSalesTerritory]([EndDate]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_ETLLoadID] ON [cso].[DimSalesTerritory]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_GeographyKey] ON [cso].[DimSalesTerritory]([GeographyKey]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_LoadDate] ON [cso].[DimSalesTerritory]([LoadDate]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryCountry] ON [cso].[DimSalesTerritory]([SalesTerritoryCountry]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryGroup] ON [cso].[DimSalesTerritory]([SalesTerritoryGroup]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryKey] ON [cso].[DimSalesTerritory]([SalesTerritoryKey]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryLabel] ON [cso].[DimSalesTerritory]([SalesTerritoryLabel]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryLevel] ON [cso].[DimSalesTerritory]([SalesTerritoryLevel]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryManager] ON [cso].[DimSalesTerritory]([SalesTerritoryManager]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryName] ON [cso].[DimSalesTerritory]([SalesTerritoryName]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryRegion] ON [cso].[DimSalesTerritory]([SalesTerritoryRegion]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_StartDate] ON [cso].[DimSalesTerritory]([StartDate]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_Status] ON [cso].[DimSalesTerritory]([Status]);
CREATE STATISTICS [stat_cso_DimSalesTerritory_UpdateDate] ON [cso].[DimSalesTerritory]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_ETLLoadID] ON [cso].[DimProductSubcategory]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_LoadDate] ON [cso].[DimProductSubcategory]([LoadDate]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductCategoryKey] ON [cso].[DimProductSubcategory]([ProductCategoryKey]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryDescription] ON [cso].[DimProductSubcategory]([ProductSubcategoryDescription]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryKey] ON [cso].[DimProductSubcategory]([ProductSubcategoryKey]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryLabel] ON [cso].[DimProductSubcategory]([ProductSubcategoryLabel]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryName] ON [cso].[DimProductSubcategory]([ProductSubcategoryName]);
CREATE STATISTICS [stat_cso_DimProductSubcategory_UpdateDate] ON [cso].[DimProductSubcategory]([UpdateDate]);
CREATE STATISTICS [stat_cso_FactITMachine_Datekey] ON [cso].[FactITMachine]([Datekey]);
CREATE STATISTICS [stat_cso_FactITMachine_ITMachinekey] ON [cso].[FactITMachine]([ITMachinekey]);
CREATE STATISTICS [stat_cso_FactITMachine_MachineKey] ON [cso].[FactITMachine]([MachineKey]);
CREATE STATISTICS [stat_cso_FactInventory_CurrencyKey] ON [cso].[FactInventory]([CurrencyKey]);
CREATE STATISTICS [stat_cso_FactInventory_DateKey] ON [cso].[FactInventory]([DateKey]);
CREATE STATISTICS [stat_cso_FactInventory_InventoryKey] ON [cso].[FactInventory]([InventoryKey]);
CREATE STATISTICS [stat_cso_FactInventory_ProductKey] ON [cso].[FactInventory]([ProductKey]);
CREATE STATISTICS [stat_cso_FactInventory_StoreKey] ON [cso].[FactInventory]([StoreKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_AccountKey] ON [cso].[FactStrategyPlan]([AccountKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_CurrencyKey] ON [cso].[FactStrategyPlan]([CurrencyKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_Datekey] ON [cso].[FactStrategyPlan]([Datekey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_EntityKey] ON [cso].[FactStrategyPlan]([EntityKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_ProductCategoryKey] ON [cso].[FactStrategyPlan]([ProductCategoryKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_ScenarioKey] ON [cso].[FactStrategyPlan]([ScenarioKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_StrategyPlanKey] ON [cso].[FactStrategyPlan]([StrategyPlanKey]);
CREATE STATISTICS [stat_cso_FactSalesQuota_ChannelKey] ON [cso].[FactSalesQuota]([ChannelKey]);
CREATE STATISTICS [stat_cso_FactSalesQuota_CurrencyKey] ON [cso].[FactSalesQuota]([CurrencyKey]);
CREATE STATISTICS [stat_cso_FactSalesQuota_DateKey] ON [cso].[FactSalesQuota]([DateKey]);
CREATE STATISTICS [stat_cso_FactSalesQuota_ProductKey] ON [cso].[FactSalesQuota]([ProductKey]);
CREATE STATISTICS [stat_cso_FactSalesQuota_SalesQuotaKey] ON [cso].[FactSalesQuota]([SalesQuotaKey]);
CREATE STATISTICS [stat_cso_FactSalesQuota_ScenarioKey] ON [cso].[FactSalesQuota]([ScenarioKey]);
CREATE STATISTICS [stat_cso_FactSalesQuota_StoreKey] ON [cso].[FactSalesQuota]([StoreKey]);
CREATE STATISTICS [stat_cso_FactSales_channelKey] ON [cso].[FactSales]([channelKey]);
CREATE STATISTICS [stat_cso_FactSales_CurrencyKey] ON [cso].[FactSales]([CurrencyKey]);
CREATE STATISTICS [stat_cso_FactSales_DateKey] ON [cso].[FactSales]([DateKey]);
CREATE STATISTICS [stat_cso_FactSales_ProductKey] ON [cso].[FactSales]([ProductKey]);
CREATE STATISTICS [stat_cso_FactSales_PromotionKey] ON [cso].[FactSales]([PromotionKey]);
CREATE STATISTICS [stat_cso_FactSales_SalesKey] ON [cso].[FactSales]([SalesKey]);
CREATE STATISTICS [stat_cso_FactSales_StoreKey] ON [cso].[FactSales]([StoreKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_CurrencyKey] ON [cso].[FactOnlineSales]([CurrencyKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_CustomerKey] ON [cso].[FactOnlineSales]([CustomerKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_DateKey] ON [cso].[FactOnlineSales]([DateKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_OnlineSalesKey] ON [cso].[FactOnlineSales]([OnlineSalesKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_ProductKey] ON [cso].[FactOnlineSales]([ProductKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_PromotionKey] ON [cso].[FactOnlineSales]([PromotionKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_StoreKey] ON [cso].[FactOnlineSales]([StoreKey]);
CREATE STATISTICS [stat_cso_DimCustomer_AddressLine1] ON [cso].[DimCustomer]([AddressLine1]);
CREATE STATISTICS [stat_cso_DimCustomer_AddressLine2] ON [cso].[DimCustomer]([AddressLine2]);
CREATE STATISTICS [stat_cso_DimCustomer_BirthDate] ON [cso].[DimCustomer]([BirthDate]);
CREATE STATISTICS [stat_cso_DimCustomer_CompanyName] ON [cso].[DimCustomer]([CompanyName]);
CREATE STATISTICS [stat_cso_DimCustomer_CustomerKey] ON [cso].[DimCustomer]([CustomerKey]);
CREATE STATISTICS [stat_cso_DimCustomer_CustomerLabel] ON [cso].[DimCustomer]([CustomerLabel]);
CREATE STATISTICS [stat_cso_DimCustomer_CustomerType] ON [cso].[DimCustomer]([CustomerType]);
CREATE STATISTICS [stat_cso_DimCustomer_DateFirstPurchase] ON [cso].[DimCustomer]([DateFirstPurchase]);
CREATE STATISTICS [stat_cso_DimCustomer_Education] ON [cso].[DimCustomer]([Education]);
CREATE STATISTICS [stat_cso_DimCustomer_EmailAddress] ON [cso].[DimCustomer]([EmailAddress]);
CREATE STATISTICS [stat_cso_DimCustomer_ETLLoadID] ON [cso].[DimCustomer]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimCustomer_FirstName] ON [cso].[DimCustomer]([FirstName]);
CREATE STATISTICS [stat_cso_DimCustomer_Gender] ON [cso].[DimCustomer]([Gender]);
CREATE STATISTICS [stat_cso_DimCustomer_GeographyKey] ON [cso].[DimCustomer]([GeographyKey]);
CREATE STATISTICS [stat_cso_DimCustomer_HouseOwnerFlag] ON [cso].[DimCustomer]([HouseOwnerFlag]);
CREATE STATISTICS [stat_cso_DimCustomer_LastName] ON [cso].[DimCustomer]([LastName]);
CREATE STATISTICS [stat_cso_DimCustomer_LoadDate] ON [cso].[DimCustomer]([LoadDate]);
CREATE STATISTICS [stat_cso_DimCustomer_MaritalStatus] ON [cso].[DimCustomer]([MaritalStatus]);
CREATE STATISTICS [stat_cso_DimCustomer_MiddleName] ON [cso].[DimCustomer]([MiddleName]);
CREATE STATISTICS [stat_cso_DimCustomer_NameStyle] ON [cso].[DimCustomer]([NameStyle]);
CREATE STATISTICS [stat_cso_DimCustomer_NumberCarsOwned] ON [cso].[DimCustomer]([NumberCarsOwned]);
CREATE STATISTICS [stat_cso_DimCustomer_NumberChildrenAtHome] ON [cso].[DimCustomer]([NumberChildrenAtHome]);
CREATE STATISTICS [stat_cso_DimCustomer_Occupation] ON [cso].[DimCustomer]([Occupation]);
CREATE STATISTICS [stat_cso_DimCustomer_Phone] ON [cso].[DimCustomer]([Phone]);
CREATE STATISTICS [stat_cso_DimCustomer_Suffix] ON [cso].[DimCustomer]([Suffix]);
CREATE STATISTICS [stat_cso_DimCustomer_Title] ON [cso].[DimCustomer]([Title]);
CREATE STATISTICS [stat_cso_DimCustomer_TotalChildren] ON [cso].[DimCustomer]([TotalChildren]);
CREATE STATISTICS [stat_cso_DimCustomer_UpdateDate] ON [cso].[DimCustomer]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimCustomer_YearlyIncome] ON [cso].[DimCustomer]([YearlyIncome]);
CREATE STATISTICS [stat_cso_DimEmployee_BaseRate] ON [cso].[DimEmployee]([BaseRate]);
CREATE STATISTICS [stat_cso_DimEmployee_BirthDate] ON [cso].[DimEmployee]([BirthDate]);
CREATE STATISTICS [stat_cso_DimEmployee_CurrentFlag] ON [cso].[DimEmployee]([CurrentFlag]);
CREATE STATISTICS [stat_cso_DimEmployee_DepartmentName] ON [cso].[DimEmployee]([DepartmentName]);
CREATE STATISTICS [stat_cso_DimEmployee_EmailAddress] ON [cso].[DimEmployee]([EmailAddress]);
CREATE STATISTICS [stat_cso_DimEmployee_EmergencyContactName] ON [cso].[DimEmployee]([EmergencyContactName]);
CREATE STATISTICS [stat_cso_DimEmployee_EmergencyContactPhone] ON [cso].[DimEmployee]([EmergencyContactPhone]);
CREATE STATISTICS [stat_cso_DimEmployee_EmployeeKey] ON [cso].[DimEmployee]([EmployeeKey]);
CREATE STATISTICS [stat_cso_DimEmployee_EndDate] ON [cso].[DimEmployee]([EndDate]);
CREATE STATISTICS [stat_cso_DimEmployee_ETLLoadID] ON [cso].[DimEmployee]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimEmployee_FirstName] ON [cso].[DimEmployee]([FirstName]);
CREATE STATISTICS [stat_cso_DimEmployee_Gender] ON [cso].[DimEmployee]([Gender]);
CREATE STATISTICS [stat_cso_DimEmployee_HireDate] ON [cso].[DimEmployee]([HireDate]);
CREATE STATISTICS [stat_cso_DimEmployee_LastName] ON [cso].[DimEmployee]([LastName]);
CREATE STATISTICS [stat_cso_DimEmployee_LoadDate] ON [cso].[DimEmployee]([LoadDate]);
CREATE STATISTICS [stat_cso_DimEmployee_MaritalStatus] ON [cso].[DimEmployee]([MaritalStatus]);
CREATE STATISTICS [stat_cso_DimEmployee_MiddleName] ON [cso].[DimEmployee]([MiddleName]);
CREATE STATISTICS [stat_cso_DimEmployee_ParentEmployeeKey] ON [cso].[DimEmployee]([ParentEmployeeKey]);
CREATE STATISTICS [stat_cso_DimEmployee_PayFrequency] ON [cso].[DimEmployee]([PayFrequency]);
CREATE STATISTICS [stat_cso_DimEmployee_Phone] ON [cso].[DimEmployee]([Phone]);
CREATE STATISTICS [stat_cso_DimEmployee_SalariedFlag] ON [cso].[DimEmployee]([SalariedFlag]);
CREATE STATISTICS [stat_cso_DimEmployee_SalesPersonFlag] ON [cso].[DimEmployee]([SalesPersonFlag]);
CREATE STATISTICS [stat_cso_DimEmployee_StartDate] ON [cso].[DimEmployee]([StartDate]);
CREATE STATISTICS [stat_cso_DimEmployee_Status] ON [cso].[DimEmployee]([Status]);
CREATE STATISTICS [stat_cso_DimEmployee_Title] ON [cso].[DimEmployee]([Title]);
CREATE STATISTICS [stat_cso_DimEmployee_UpdateDate] ON [cso].[DimEmployee]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimEmployee_VacationHours] ON [cso].[DimEmployee]([VacationHours]);
CREATE STATISTICS [stat_cso_DimEntity_EndDate] ON [cso].[DimEntity]([EndDate]);
CREATE STATISTICS [stat_cso_DimEntity_EntityDescription] ON [cso].[DimEntity]([EntityDescription]);
CREATE STATISTICS [stat_cso_DimEntity_EntityKey] ON [cso].[DimEntity]([EntityKey]);
CREATE STATISTICS [stat_cso_DimEntity_EntityLabel] ON [cso].[DimEntity]([EntityLabel]);
CREATE STATISTICS [stat_cso_DimEntity_EntityName] ON [cso].[DimEntity]([EntityName]);
CREATE STATISTICS [stat_cso_DimEntity_EntityType] ON [cso].[DimEntity]([EntityType]);
CREATE STATISTICS [stat_cso_DimEntity_ETLLoadID] ON [cso].[DimEntity]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimEntity_LoadDate] ON [cso].[DimEntity]([LoadDate]);
CREATE STATISTICS [stat_cso_DimEntity_ParentEntityKey] ON [cso].[DimEntity]([ParentEntityKey]);
CREATE STATISTICS [stat_cso_DimEntity_ParentEntityLabel] ON [cso].[DimEntity]([ParentEntityLabel]);
CREATE STATISTICS [stat_cso_DimEntity_StartDate] ON [cso].[DimEntity]([StartDate]);
CREATE STATISTICS [stat_cso_DimEntity_Status] ON [cso].[DimEntity]([Status]);
CREATE STATISTICS [stat_cso_DimEntity_UpdateDate] ON [cso].[DimEntity]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimProduct_AvailableForSaleDate] ON [cso].[DimProduct]([AvailableForSaleDate]);
CREATE STATISTICS [stat_cso_DimProduct_BrandName] ON [cso].[DimProduct]([BrandName]);
CREATE STATISTICS [stat_cso_DimProduct_ClassID] ON [cso].[DimProduct]([ClassID]);
CREATE STATISTICS [stat_cso_DimProduct_ClassName] ON [cso].[DimProduct]([ClassName]);
CREATE STATISTICS [stat_cso_DimProduct_ColorID] ON [cso].[DimProduct]([ColorID]);
CREATE STATISTICS [stat_cso_DimProduct_ColorName] ON [cso].[DimProduct]([ColorName]);
CREATE STATISTICS [stat_cso_DimProduct_ETLLoadID] ON [cso].[DimProduct]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimProduct_ImageURL] ON [cso].[DimProduct]([ImageURL]);
CREATE STATISTICS [stat_cso_DimProduct_LoadDate] ON [cso].[DimProduct]([LoadDate]);
CREATE STATISTICS [stat_cso_DimProduct_Manufacturer] ON [cso].[DimProduct]([Manufacturer]);
CREATE STATISTICS [stat_cso_DimProduct_ProductDescription] ON [cso].[DimProduct]([ProductDescription]);
CREATE STATISTICS [stat_cso_DimProduct_ProductKey] ON [cso].[DimProduct]([ProductKey]);
CREATE STATISTICS [stat_cso_DimProduct_ProductLabel] ON [cso].[DimProduct]([ProductLabel]);
CREATE STATISTICS [stat_cso_DimProduct_ProductName] ON [cso].[DimProduct]([ProductName]);
CREATE STATISTICS [stat_cso_DimProduct_ProductSubcategoryKey] ON [cso].[DimProduct]([ProductSubcategoryKey]);
CREATE STATISTICS [stat_cso_DimProduct_ProductURL] ON [cso].[DimProduct]([ProductURL]);
CREATE STATISTICS [stat_cso_DimProduct_Size] ON [cso].[DimProduct]([Size]);
CREATE STATISTICS [stat_cso_DimProduct_SizeRange] ON [cso].[DimProduct]([SizeRange]);
CREATE STATISTICS [stat_cso_DimProduct_SizeUnitMeasureID] ON [cso].[DimProduct]([SizeUnitMeasureID]);
CREATE STATISTICS [stat_cso_DimProduct_Status] ON [cso].[DimProduct]([Status]);
CREATE STATISTICS [stat_cso_DimProduct_StockTypeID] ON [cso].[DimProduct]([StockTypeID]);
CREATE STATISTICS [stat_cso_DimProduct_StockTypeName] ON [cso].[DimProduct]([StockTypeName]);
CREATE STATISTICS [stat_cso_DimProduct_StopSaleDate] ON [cso].[DimProduct]([StopSaleDate]);
CREATE STATISTICS [stat_cso_DimProduct_StyleID] ON [cso].[DimProduct]([StyleID]);
CREATE STATISTICS [stat_cso_DimProduct_StyleName] ON [cso].[DimProduct]([StyleName]);
CREATE STATISTICS [stat_cso_DimProduct_UnitCost] ON [cso].[DimProduct]([UnitCost]);
CREATE STATISTICS [stat_cso_DimProduct_UnitOfMeasureID] ON [cso].[DimProduct]([UnitOfMeasureID]);
CREATE STATISTICS [stat_cso_DimProduct_UnitOfMeasureName] ON [cso].[DimProduct]([UnitOfMeasureName]);
CREATE STATISTICS [stat_cso_DimProduct_UnitPrice] ON [cso].[DimProduct]([UnitPrice]);
CREATE STATISTICS [stat_cso_DimProduct_UpdateDate] ON [cso].[DimProduct]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimProduct_Weight] ON [cso].[DimProduct]([Weight]);
CREATE STATISTICS [stat_cso_DimProduct_WeightUnitMeasureID] ON [cso].[DimProduct]([WeightUnitMeasureID]);
CREATE STATISTICS [stat_cso_DimAccount_AccountDescription] ON [cso].[DimAccount]([AccountDescription]);
CREATE STATISTICS [stat_cso_DimAccount_AccountKey] ON [cso].[DimAccount]([AccountKey]);
CREATE STATISTICS [stat_cso_DimAccount_AccountLabel] ON [cso].[DimAccount]([AccountLabel]);
CREATE STATISTICS [stat_cso_DimAccount_AccountName] ON [cso].[DimAccount]([AccountName]);
CREATE STATISTICS [stat_cso_DimAccount_AccountType] ON [cso].[DimAccount]([AccountType]);
CREATE STATISTICS [stat_cso_DimAccount_CustomMemberOptions] ON [cso].[DimAccount]([CustomMemberOptions]);
CREATE STATISTICS [stat_cso_DimAccount_CustomMembers] ON [cso].[DimAccount]([CustomMembers]);
CREATE STATISTICS [stat_cso_DimAccount_ETLLoadID] ON [cso].[DimAccount]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimAccount_LoadDate] ON [cso].[DimAccount]([LoadDate]);
CREATE STATISTICS [stat_cso_DimAccount_Operator] ON [cso].[DimAccount]([Operator]);
CREATE STATISTICS [stat_cso_DimAccount_ParentAccountKey] ON [cso].[DimAccount]([ParentAccountKey]);
CREATE STATISTICS [stat_cso_DimAccount_UpdateDate] ON [cso].[DimAccount]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimAccount_ValueType] ON [cso].[DimAccount]([ValueType]);
CREATE STATISTICS [stat_cso_DimChannel_ChannelDescription] ON [cso].[DimChannel]([ChannelDescription]);
CREATE STATISTICS [stat_cso_DimChannel_ChannelKey] ON [cso].[DimChannel]([ChannelKey]);
CREATE STATISTICS [stat_cso_DimChannel_ChannelLabel] ON [cso].[DimChannel]([ChannelLabel]);
CREATE STATISTICS [stat_cso_DimChannel_ChannelName] ON [cso].[DimChannel]([ChannelName]);
CREATE STATISTICS [stat_cso_DimChannel_ETLLoadID] ON [cso].[DimChannel]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimChannel_LoadDate] ON [cso].[DimChannel]([LoadDate]);
CREATE STATISTICS [stat_cso_DimChannel_UpdateDate] ON [cso].[DimChannel]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimCurrency_CurrencyDescription] ON [cso].[DimCurrency]([CurrencyDescription]);
CREATE STATISTICS [stat_cso_DimCurrency_CurrencyKey] ON [cso].[DimCurrency]([CurrencyKey]);
CREATE STATISTICS [stat_cso_DimCurrency_CurrencyLabel] ON [cso].[DimCurrency]([CurrencyLabel]);
CREATE STATISTICS [stat_cso_DimCurrency_CurrencyName] ON [cso].[DimCurrency]([CurrencyName]);
CREATE STATISTICS [stat_cso_DimCurrency_ETLLoadID] ON [cso].[DimCurrency]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimCurrency_LoadDate] ON [cso].[DimCurrency]([LoadDate]);
CREATE STATISTICS [stat_cso_DimCurrency_UpdateDate] ON [cso].[DimCurrency]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimDate_AsiaSeason] ON [cso].[DimDate]([AsiaSeason]);
CREATE STATISTICS [stat_cso_DimDate_CalendarDayOfWeek] ON [cso].[DimDate]([CalendarDayOfWeek]);
CREATE STATISTICS [stat_cso_DimDate_CalendarDayOfWeekLabel] ON [cso].[DimDate]([CalendarDayOfWeekLabel]);
CREATE STATISTICS [stat_cso_DimDate_CalendarHalfYear] ON [cso].[DimDate]([CalendarHalfYear]);
CREATE STATISTICS [stat_cso_DimDate_CalendarHalfYearLabel] ON [cso].[DimDate]([CalendarHalfYearLabel]);
CREATE STATISTICS [stat_cso_DimDate_CalendarMonth] ON [cso].[DimDate]([CalendarMonth]);
CREATE STATISTICS [stat_cso_DimDate_CalendarMonthLabel] ON [cso].[DimDate]([CalendarMonthLabel]);
CREATE STATISTICS [stat_cso_DimDate_CalendarQuarter] ON [cso].[DimDate]([CalendarQuarter]);
CREATE STATISTICS [stat_cso_DimDate_CalendarQuarterLabel] ON [cso].[DimDate]([CalendarQuarterLabel]);
CREATE STATISTICS [stat_cso_DimDate_CalendarWeek] ON [cso].[DimDate]([CalendarWeek]);
CREATE STATISTICS [stat_cso_DimDate_CalendarWeekLabel] ON [cso].[DimDate]([CalendarWeekLabel]);
CREATE STATISTICS [stat_cso_DimDate_CalendarYear] ON [cso].[DimDate]([CalendarYear]);
CREATE STATISTICS [stat_cso_DimDate_CalendarYearLabel] ON [cso].[DimDate]([CalendarYearLabel]);
CREATE STATISTICS [stat_cso_DimDate_DateDescription] ON [cso].[DimDate]([DateDescription]);
CREATE STATISTICS [stat_cso_DimDate_Datekey] ON [cso].[DimDate]([Datekey]);
CREATE STATISTICS [stat_cso_DimDate_EuropeSeason] ON [cso].[DimDate]([EuropeSeason]);
CREATE STATISTICS [stat_cso_DimDate_FiscalHalfYear] ON [cso].[DimDate]([FiscalHalfYear]);
CREATE STATISTICS [stat_cso_DimDate_FiscalHalfYearLabel] ON [cso].[DimDate]([FiscalHalfYearLabel]);
CREATE STATISTICS [stat_cso_DimDate_FiscalMonth] ON [cso].[DimDate]([FiscalMonth]);
CREATE STATISTICS [stat_cso_DimDate_FiscalMonthLabel] ON [cso].[DimDate]([FiscalMonthLabel]);
CREATE STATISTICS [stat_cso_DimDate_FiscalQuarter] ON [cso].[DimDate]([FiscalQuarter]);
CREATE STATISTICS [stat_cso_DimDate_FiscalQuarterLabel] ON [cso].[DimDate]([FiscalQuarterLabel]);
CREATE STATISTICS [stat_cso_DimDate_FiscalYear] ON [cso].[DimDate]([FiscalYear]);
CREATE STATISTICS [stat_cso_DimDate_FiscalYearLabel] ON [cso].[DimDate]([FiscalYearLabel]);
CREATE STATISTICS [stat_cso_DimDate_FullDateLabel] ON [cso].[DimDate]([FullDateLabel]);
CREATE STATISTICS [stat_cso_DimDate_HolidayName] ON [cso].[DimDate]([HolidayName]);
CREATE STATISTICS [stat_cso_DimDate_IsHoliday] ON [cso].[DimDate]([IsHoliday]);
CREATE STATISTICS [stat_cso_DimDate_IsWorkDay] ON [cso].[DimDate]([IsWorkDay]);
CREATE STATISTICS [stat_cso_DimDate_NorthAmericaSeason] ON [cso].[DimDate]([NorthAmericaSeason]);
CREATE STATISTICS [stat_cso_DimStore_AddressLine1] ON [cso].[DimStore]([AddressLine1]);
CREATE STATISTICS [stat_cso_DimStore_AddressLine2] ON [cso].[DimStore]([AddressLine2]);
CREATE STATISTICS [stat_cso_DimStore_CloseDate] ON [cso].[DimStore]([CloseDate]);
CREATE STATISTICS [stat_cso_DimStore_CloseReason] ON [cso].[DimStore]([CloseReason]);
CREATE STATISTICS [stat_cso_DimStore_EmployeeCount] ON [cso].[DimStore]([EmployeeCount]);
CREATE STATISTICS [stat_cso_DimStore_EntityKey] ON [cso].[DimStore]([EntityKey]);
CREATE STATISTICS [stat_cso_DimStore_ETLLoadID] ON [cso].[DimStore]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimStore_GeographyKey] ON [cso].[DimStore]([GeographyKey]);
CREATE STATISTICS [stat_cso_DimStore_GeoLocation] ON [cso].[DimStore]([GeoLocation]);
CREATE STATISTICS [stat_cso_DimStore_Geometry] ON [cso].[DimStore]([Geometry]);
CREATE STATISTICS [stat_cso_DimStore_LastRemodelDate] ON [cso].[DimStore]([LastRemodelDate]);
CREATE STATISTICS [stat_cso_DimStore_LoadDate] ON [cso].[DimStore]([LoadDate]);
CREATE STATISTICS [stat_cso_DimStore_OpenDate] ON [cso].[DimStore]([OpenDate]);
CREATE STATISTICS [stat_cso_DimStore_SellingAreaSize] ON [cso].[DimStore]([SellingAreaSize]);
CREATE STATISTICS [stat_cso_DimStore_Status] ON [cso].[DimStore]([Status]);
CREATE STATISTICS [stat_cso_DimStore_StoreDescription] ON [cso].[DimStore]([StoreDescription]);
CREATE STATISTICS [stat_cso_DimStore_StoreFax] ON [cso].[DimStore]([StoreFax]);
CREATE STATISTICS [stat_cso_DimStore_StoreKey] ON [cso].[DimStore]([StoreKey]);
CREATE STATISTICS [stat_cso_DimStore_StoreManager] ON [cso].[DimStore]([StoreManager]);
CREATE STATISTICS [stat_cso_DimStore_StoreName] ON [cso].[DimStore]([StoreName]);
CREATE STATISTICS [stat_cso_DimStore_StorePhone] ON [cso].[DimStore]([StorePhone]);
CREATE STATISTICS [stat_cso_DimStore_StoreType] ON [cso].[DimStore]([StoreType]);
CREATE STATISTICS [stat_cso_DimStore_UpdateDate] ON [cso].[DimStore]([UpdateDate]);
CREATE STATISTICS [stat_cso_DimStore_ZipCode] ON [cso].[DimStore]([ZipCode]);
CREATE STATISTICS [stat_cso_DimStore_ZipCodeExtension] ON [cso].[DimStore]([ZipCodeExtension]);
CREATE STATISTICS [stat_cso_DimGeography_CityName] ON [cso].[DimGeography]([CityName]);
CREATE STATISTICS [stat_cso_DimGeography_ContinentName] ON [cso].[DimGeography]([ContinentName]);
CREATE STATISTICS [stat_cso_DimGeography_ETLLoadID] ON [cso].[DimGeography]([ETLLoadID]);
CREATE STATISTICS [stat_cso_DimGeography_GeographyKey] ON [cso].[DimGeography]([GeographyKey]);
CREATE STATISTICS [stat_cso_DimGeography_GeographyType] ON [cso].[DimGeography]([GeographyType]);
CREATE STATISTICS [stat_cso_DimGeography_LoadDate] ON [cso].[DimGeography]([LoadDate]);
CREATE STATISTICS [stat_cso_DimGeography_RegionCountryName] ON [cso].[DimGeography]([RegionCountryName]);
CREATE STATISTICS [stat_cso_DimGeography_StateProvinceName] ON [cso].[DimGeography]([StateProvinceName]);
CREATE STATISTICS [stat_cso_DimGeography_UpdateDate] ON [cso].[DimGeography]([UpdateDate]);
CREATE STATISTICS [stat_cso_FactOnlineSales_CurrencyKey] ON [cso].[FactOnlineSales]([CurrencyKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_CustomerKey] ON [cso].[FactOnlineSales]([CustomerKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_DateKey] ON [cso].[FactOnlineSales]([DateKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_OnlineSalesKey] ON [cso].[FactOnlineSales]([OnlineSalesKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_ProductKey] ON [cso].[FactOnlineSales]([ProductKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_PromotionKey] ON [cso].[FactOnlineSales]([PromotionKey]);
CREATE STATISTICS [stat_cso_FactOnlineSales_StoreKey] ON [cso].[FactOnlineSales]([StoreKey]);

-- Achievement unlocked!
--
-- You now have all the public data loaded into Azure SQL Data Warehouse. Great job!
--
--You can now start querying the tables using queries like this. :

SELECT  SUM(f.[SalesAmount]) AS [sales_by_brand_amount]
,       p.[BrandName]
FROM    [cso].[FactOnlineSales] AS f
JOIN    [cso].[DimProduct]      AS p ON f.[ProductKey] = p.[ProductKey]
GROUP BY p.[BrandName]
--
-- Enjoy exploring with SQL Data Warehouse.
