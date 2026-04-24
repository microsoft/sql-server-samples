/*============================================================================
  File:     instawdb.sql

  Summary:  Creates the AdventureWorksDW sample database. Run this on
  any version of SQL Server (2008R2 or later) to get AdventureWorksDW for your
  current version.

  Date:     October 26, 2017
  Updated:  November 14, 2025

------------------------------------------------------------------------------
  This file is part of the Microsoft SQL Server Code Samples.

  Copyright (C) Microsoft Corporation.  All rights reserved.

  This source code is intended only as a supplement to Microsoft
  Development Tools and/or on-line documentation.  See these other
  materials for detailed information regarding Microsoft code samples.

  All data in this database is ficticious.

  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
  KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

/*
 * HOW TO RUN THIS SCRIPT:
 *
 * 1. Enable full-text search on your SQL Server instance.
 *
 * 2. Open the script inside SQL Server Management Studio and enable SQLCMD mode.
 *    This option is in the Query menu.
 *
 * 3. Copy this script and the install files to C:\Samples\AdventureWorksDW, or
 *    set the following environment variable to your own data path.
 */
 :setvar SqlSamplesSourceDataPath "C:\Samples\AdventureWorksDW\"

/*
 * 4. Append the SQL Server version number to database name if you want to
 *    differentiate it from other installs of AdventureWorksDW
 */

:setvar DatabaseName "AdventureWorksDW"

/* Execute the script
 */

IF '$(SqlSamplesSourceDataPath)' IS NULL OR '$(SqlSamplesSourceDataPath)' = ''
BEGIN
	RAISERROR(N'The variable SqlSamplesSourceDataPath must be defined.', 16, 127) WITH NOWAIT
	RETURN
END;

SET NOCOUNT OFF;
GO

PRINT CONVERT(varchar(1000), @@VERSION);
GO

PRINT '';
PRINT 'Started - ' + CONVERT(varchar, GETDATE(), 121);
GO

USE [master];
GO

-- ****************************************
-- Drop Database
-- ****************************************
PRINT '';
PRINT '*** Dropping Database';
GO

IF EXISTS (SELECT [name] FROM [master].[sys].[databases] WHERE [name] = N'$(DatabaseName)')
    DROP DATABASE $(DatabaseName);

-- If the database has any other open connections close the network connection.
IF @@ERROR = 3702
    RAISERROR('$(DatabaseName) database cannot be dropped because there are still other open connections', 127, 127) WITH NOWAIT, LOG;
GO

-- ****************************************
-- Create Database
-- ****************************************
PRINT '';
PRINT '*** Creating Database';
GO

CREATE DATABASE $(DatabaseName);
GO

PRINT '';
PRINT '*** Checking for $(DatabaseName) Database';
/* CHECK FOR DATABASE IF IT DOESN'T EXISTS, DO NOT RUN THE REST OF THE SCRIPT */
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE name = N'$(DatabaseName)')
BEGIN
PRINT '*******************************************************************************************************************************************************************'
+char(10)+'********$(DatabaseName) Database does not exist.  Make sure that the script is being run in SQLCMD mode and that the variables have been correctly set.*********'
+char(10)+'*******************************************************************************************************************************************************************';
SET NOEXEC ON;
END
GO

ALTER DATABASE $(DatabaseName)
SET RECOVERY SIMPLE,
    ANSI_NULLS ON,
    ANSI_PADDING ON,
    ANSI_WARNINGS ON,
    ARITHABORT ON,
    CONCAT_NULL_YIELDS_NULL ON,
    QUOTED_IDENTIFIER ON,
    NUMERIC_ROUNDABORT OFF,
    PAGE_VERIFY CHECKSUM,
    ALLOW_SNAPSHOT_ISOLATION OFF;
GO

USE $(DatabaseName);
GO

-- ****************************************
-- Create DDL Trigger for Database
-- ****************************************
PRINT '';
PRINT '*** Creating DDL Trigger for Database';
GO

-- Create table to store database object creation messages
-- *** WARNING:  THIS TABLE IS INTENTIONALLY A HEAP - DO NOT ADD A PRIMARY KEY ***
CREATE TABLE [dbo].[DatabaseLog](
    [DatabaseLogID] [int] IDENTITY (1, 1) NOT NULL,
    [PostTime] [datetime] NOT NULL,
    [DatabaseUser] [sysname] NOT NULL,
    [Event] [sysname] NOT NULL,
    [Schema] [sysname] NULL,
    [Object] [sysname] NULL,
    [TSQL] [nvarchar](max) NOT NULL,
    [XmlEvent] [xml] NOT NULL
) ON [PRIMARY];
GO

CREATE TRIGGER [ddlDatabaseTriggerLog] ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @data XML;
    DECLARE @schema sysname;
    DECLARE @object sysname;
    DECLARE @eventType sysname;

    SET @data = EVENTDATA();
    SET @eventType = @data.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname');
    SET @schema = @data.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname');
    SET @object = @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname')

    IF @object IS NOT NULL
        PRINT '  ' + @eventType + ' - ' + @schema + '.' + @object;
    ELSE
        PRINT '  ' + @eventType + ' - ' + @schema;

    IF @eventType IS NULL
        PRINT CONVERT(nvarchar(max), @data);

    INSERT [dbo].[DatabaseLog]
        (
        [PostTime],
        [DatabaseUser],
        [Event],
        [Schema],
        [Object],
        [TSQL],
        [XmlEvent]
        )
    VALUES
        (
        GETDATE(),
        CONVERT(sysname, CURRENT_USER),
        @eventType,
        CONVERT(sysname, @schema),
        CONVERT(sysname, @object),
        @data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'nvarchar(max)'),
        @data
        );
END;
GO

-- ******************************************************
-- Create User Defined Functions
-- ******************************************************
-- Builds an ISO 8601 format date from a year, month, and day specified as integers.
-- This format of date should parse correctly regardless of SET DATEFORMAT and SET LANGUAGE.
-- See SQL Server Books Online for more details.
CREATE FUNCTION [dbo].[udfBuildISO8601Date] (@year int, @month int, @day int)
RETURNS datetime
AS
BEGIN
	RETURN cast(convert(varchar, @year) + '-' + [dbo].[udfTwoDigitZeroFill](@month)
	    + '-' + [dbo].[udfTwoDigitZeroFill](@day) + 'T00:00:00'
	    as datetime);
END;
GO

CREATE FUNCTION [dbo].[udfMinimumDate] (
    @x DATETIME,
    @y DATETIME
) RETURNS DATETIME
AS
BEGIN
    DECLARE @z DATETIME

    IF @x <= @y
        SET @z = @x
    ELSE
        SET @z = @y

    RETURN(@z)
END;
GO

-- Converts the specified integer (which should be < 100 and > -1)
-- into a two character string, zero filling from the left
-- if the number is < 10.
CREATE FUNCTION [dbo].[udfTwoDigitZeroFill] (@number int)
RETURNS char(2)
AS
BEGIN
	DECLARE @result char(2);
	IF @number > 9
		SET @result = convert(char(2), @number);
	ELSE
		SET @result = convert(char(2), '0' + convert(varchar, @number));
	RETURN @result;
END;
GO

-- ******************************************************
-- Create tables
-- ******************************************************
PRINT '';
PRINT '*** Creating Tables';
GO

CREATE TABLE [dbo].[AdventureWorksDWBuildVersion](
	[DBVersion] [nvarchar](50) NULL,
	[VersionDate] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimAccount](
	[AccountKey] [int] IDENTITY(1,1) NOT NULL,
	[ParentAccountKey] [int] NULL,
	[AccountCodeAlternateKey] [int] NULL,
	[ParentAccountCodeAlternateKey] [int] NULL,
	[AccountDescription] [nvarchar](50) NULL,
	[AccountType] [nvarchar](50) NULL,
	[Operator] [nvarchar](50) NULL,
	[CustomMembers] [nvarchar](300) NULL,
	[ValueType] [nvarchar](50) NULL,
	[CustomMemberOptions] [nvarchar](200) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimCurrency](
	[CurrencyKey] [int] IDENTITY(1,1) NOT NULL,
	[CurrencyAlternateKey] [nchar](3) NOT NULL,
	[CurrencyName] [nvarchar](50) NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimCustomer](
	[CustomerKey] [int] IDENTITY(1,1) NOT NULL,
	[GeographyKey] [int] NULL,
	[CustomerAlternateKey] [nvarchar](15) NOT NULL,
	[Title] [nvarchar](8) NULL,
	[FirstName] [nvarchar](50) NULL,
	[MiddleName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[NameStyle] [bit] NULL,
	[BirthDate] [date] NULL,
	[MaritalStatus] [nchar](1) NULL,
	[Suffix] [nvarchar](10) NULL,
	[Gender] [nvarchar](1) NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[YearlyIncome] [money] NULL,
	[TotalChildren] [tinyint] NULL,
	[NumberChildrenAtHome] [tinyint] NULL,
	[EnglishEducation] [nvarchar](40) NULL,
	[SpanishEducation] [nvarchar](40) NULL,
	[FrenchEducation] [nvarchar](40) NULL,
	[EnglishOccupation] [nvarchar](100) NULL,
	[SpanishOccupation] [nvarchar](100) NULL,
	[FrenchOccupation] [nvarchar](100) NULL,
	[HouseOwnerFlag] [nchar](1) NULL,
	[NumberCarsOwned] [tinyint] NULL,
	[AddressLine1] [nvarchar](120) NULL,
	[AddressLine2] [nvarchar](120) NULL,
	[Phone] [nvarchar](20) NULL,
	[DateFirstPurchase] [date] NULL,
	[CommuteDistance] [nvarchar](15) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimDate](
	[DateKey] [int] NOT NULL,
	[FullDateAlternateKey] [date] NOT NULL,
	[DayNumberOfWeek] [tinyint] NOT NULL,
	[EnglishDayNameOfWeek] [nvarchar](10) NOT NULL,
	[SpanishDayNameOfWeek] [nvarchar](10) NOT NULL,
	[FrenchDayNameOfWeek] [nvarchar](10) NOT NULL,
	[DayNumberOfMonth] [tinyint] NOT NULL,
	[DayNumberOfYear] [smallint] NOT NULL,
	[WeekNumberOfYear] [tinyint] NOT NULL,
	[EnglishMonthName] [nvarchar](10) NOT NULL,
	[SpanishMonthName] [nvarchar](10) NOT NULL,
	[FrenchMonthName] [nvarchar](10) NOT NULL,
	[MonthNumberOfYear] [tinyint] NOT NULL,
	[CalendarQuarter] [tinyint] NOT NULL,
	[CalendarYear] [smallint] NOT NULL,
	[CalendarSemester] [tinyint] NOT NULL,
	[FiscalQuarter] [tinyint] NOT NULL,
	[FiscalYear] [smallint] NOT NULL,
	[FiscalSemester] [tinyint] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimDepartmentGroup](
	[DepartmentGroupKey] [int] IDENTITY(1,1) NOT NULL,
	[ParentDepartmentGroupKey] [int] NULL,
	[DepartmentGroupName] [nvarchar](50) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimEmployee](
	[EmployeeKey] [int] IDENTITY(1,1) NOT NULL,
	[ParentEmployeeKey] [int] NULL,
	[EmployeeNationalIDAlternateKey] [nvarchar](15) NULL,
	[ParentEmployeeNationalIDAlternateKey] [nvarchar](15) NULL,
	[SalesTerritoryKey] [int] NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[MiddleName] [nvarchar](50) NULL,
	[NameStyle] [bit] NOT NULL,
	[Title] [nvarchar](50) NULL,
	[HireDate] [date] NULL,
	[BirthDate] [date] NULL,
	[LoginID] [nvarchar](256) NULL,
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
	[SickLeaveHours] [smallint] NULL,
	[CurrentFlag] [bit] NOT NULL,
	[SalesPersonFlag] [bit] NOT NULL,
	[DepartmentName] [nvarchar](50) NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[Status] [nvarchar](50) NULL,
	[EmployeePhoto] [varbinary](max) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimGeography](
	[GeographyKey] [int] IDENTITY(1,1) NOT NULL,
	[City] [nvarchar](30) NULL,
	[StateProvinceCode] [nvarchar](3) NULL,
	[StateProvinceName] [nvarchar](50) NULL,
	[CountryRegionCode] [nvarchar](3) NULL,
	[EnglishCountryRegionName] [nvarchar](50) NULL,
	[SpanishCountryRegionName] [nvarchar](50) NULL,
	[FrenchCountryRegionName] [nvarchar](50) NULL,
	[PostalCode] [nvarchar](15) NULL,
	[SalesTerritoryKey] [int] NULL,
	[IpAddressLocator] [nvarchar](15) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimOrganization](
	[OrganizationKey] [int] IDENTITY(1,1) NOT NULL,
	[ParentOrganizationKey] [int] NULL,
	[PercentageOfOwnership] [nvarchar](16) NULL,
	[OrganizationName] [nvarchar](50) NULL,
	[CurrencyKey] [int] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimProduct](
	[ProductKey] [int] IDENTITY(1,1) NOT NULL,
	[ProductAlternateKey] [nvarchar](25) NULL,
	[ProductSubcategoryKey] [int] NULL,
	[WeightUnitMeasureCode] [nchar](3) NULL,
	[SizeUnitMeasureCode] [nchar](3) NULL,
	[EnglishProductName] [nvarchar](50) NOT NULL,
	[SpanishProductName] [nvarchar](50) NOT NULL,
	[FrenchProductName] [nvarchar](50) NOT NULL,
	[StandardCost] [money] NULL,
	[FinishedGoodsFlag] [bit] NOT NULL,
	[Color] [nvarchar](15) NOT NULL,
	[SafetyStockLevel] [smallint] NULL,
	[ReorderPoint] [smallint] NULL,
	[ListPrice] [money] NULL,
	[Size] [nvarchar](50) NULL,
	[SizeRange] [nvarchar](50) NULL,
	[Weight] [float] NULL,
	[DaysToManufacture] [int] NULL,
	[ProductLine] [nchar](2) NULL,
	[DealerPrice] [money] NULL,
	[Class] [nchar](2) NULL,
	[Style] [nchar](2) NULL,
	[ModelName] [nvarchar](50) NULL,
	[LargePhoto] [varbinary](max) NULL,
	[EnglishDescription] [nvarchar](400) NULL,
	[FrenchDescription] [nvarchar](400) NULL,
	[ChineseDescription] [nvarchar](400) NULL,
	[ArabicDescription] [nvarchar](400) NULL,
	[HebrewDescription] [nvarchar](400) NULL,
	[ThaiDescription] [nvarchar](400) NULL,
	[GermanDescription] [nvarchar](400) NULL,
	[JapaneseDescription] [nvarchar](400) NULL,
	[TurkishDescription] [nvarchar](400) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [nvarchar](7) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimProductCategory](
	[ProductCategoryKey] [int] IDENTITY(1,1) NOT NULL,
	[ProductCategoryAlternateKey] [int] NULL,
	[EnglishProductCategoryName] [nvarchar](50) NOT NULL,
	[SpanishProductCategoryName] [nvarchar](50) NOT NULL,
	[FrenchProductCategoryName] [nvarchar](50) NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimProductSubcategory](
	[ProductSubcategoryKey] [int] IDENTITY(1,1) NOT NULL,
	[ProductSubcategoryAlternateKey] [int] NULL,
	[EnglishProductSubcategoryName] [nvarchar](50) NOT NULL,
	[SpanishProductSubcategoryName] [nvarchar](50) NOT NULL,
	[FrenchProductSubcategoryName] [nvarchar](50) NOT NULL,
	[ProductCategoryKey] [int] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimPromotion](
	[PromotionKey] [int] IDENTITY(1,1) NOT NULL,
	[PromotionAlternateKey] [int] NULL,
	[EnglishPromotionName] [nvarchar](255) NULL,
	[SpanishPromotionName] [nvarchar](255) NULL,
	[FrenchPromotionName] [nvarchar](255) NULL,
	[DiscountPct] [float] NULL,
	[EnglishPromotionType] [nvarchar](50) NULL,
	[SpanishPromotionType] [nvarchar](50) NULL,
	[FrenchPromotionType] [nvarchar](50) NULL,
	[EnglishPromotionCategory] [nvarchar](50) NULL,
	[SpanishPromotionCategory] [nvarchar](50) NULL,
	[FrenchPromotionCategory] [nvarchar](50) NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[MinQty] [int] NULL,
	[MaxQty] [int] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimReseller](
	[ResellerKey] [int] IDENTITY(1,1) NOT NULL,
	[GeographyKey] [int] NULL,
	[ResellerAlternateKey] [nvarchar](15) NULL,
	[Phone] [nvarchar](25) NULL,
	[BusinessType] [varchar](20) NOT NULL,
	[ResellerName] [nvarchar](50) NOT NULL,
	[NumberEmployees] [int] NULL,
	[OrderFrequency] [char](1) NULL,
	[OrderMonth] [tinyint] NULL,
	[FirstOrderYear] [int] NULL,
	[LastOrderYear] [int] NULL,
	[ProductLine] [nvarchar](50) NULL,
	[AddressLine1] [nvarchar](60) NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[AnnualSales] [money] NULL,
	[BankName] [nvarchar](50) NULL,
	[MinPaymentType] [tinyint] NULL,
	[MinPaymentAmount] [money] NULL,
	[AnnualRevenue] [money] NULL,
	[YearOpened] [int] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimSalesReason](
	[SalesReasonKey] [int] IDENTITY(1,1) NOT NULL,
	[SalesReasonAlternateKey] [int] NOT NULL,
	[SalesReasonName] [nvarchar](50) NOT NULL,
	[SalesReasonReasonType] [nvarchar](50) NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimSalesTerritory](
	[SalesTerritoryKey] [int] IDENTITY(1,1) NOT NULL,
	[SalesTerritoryAlternateKey] [int] NULL,
	[SalesTerritoryRegion] [nvarchar](50) NOT NULL,
	[SalesTerritoryCountry] [nvarchar](50) NOT NULL,
	[SalesTerritoryGroup] [nvarchar](50) NULL,
	[SalesTerritoryImage] [varbinary](max) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimScenario](
	[ScenarioKey] [int] IDENTITY(1,1) NOT NULL,
	[ScenarioName] [nvarchar](50) NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactAdditionalInternationalProductDescription](
	[ProductKey] [int] NOT NULL,
	[CultureName] [nvarchar](50) NOT NULL,
	[ProductDescription] [nvarchar](max) NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactCallCenter](
	[FactCallCenterID] [int] IDENTITY(1,1) NOT NULL,
	[DateKey] [int] NOT NULL,
	[WageType] [nvarchar](15) NOT NULL,
	[Shift] [nvarchar](20) NOT NULL,
	[LevelOneOperators] [smallint] NOT NULL,
	[LevelTwoOperators] [smallint] NOT NULL,
	[TotalOperators] [smallint] NOT NULL,
	[Calls] [int] NOT NULL,
	[AutomaticResponses] [int] NOT NULL,
	[Orders] [int] NOT NULL,
	[IssuesRaised] [smallint] NOT NULL,
	[AverageTimePerIssue] [smallint] NOT NULL,
	[ServiceGrade] [float] NOT NULL,
	[Date] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactCurrencyRate](
	[CurrencyKey] [int] NOT NULL,
	[DateKey] [int] NOT NULL,
	[AverageRate] [float] NOT NULL,
	[EndOfDayRate] [float] NOT NULL,
	[Date] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactFinance](
	[FinanceKey] [int] IDENTITY(1,1) NOT NULL,
	[DateKey] [int] NOT NULL,
	[OrganizationKey] [int] NOT NULL,
	[DepartmentGroupKey] [int] NOT NULL,
	[ScenarioKey] [int] NOT NULL,
	[AccountKey] [int] NOT NULL,
	[Amount] [float] NOT NULL,
	[Date] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactInternetSales](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[CustomerKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[SalesTerritoryKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderQuantity] [smallint] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[ExtendedAmount] [money] NOT NULL,
	[UnitPriceDiscountPct] [float] NOT NULL,
	[DiscountAmount] [float] NOT NULL,
	[ProductStandardCost] [money] NOT NULL,
	[TotalProductCost] [money] NOT NULL,
	[SalesAmount] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
	[Freight] [money] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[CustomerPONumber] [nvarchar](25) NULL,
	[OrderDate] [datetime] NULL,
	[DueDate] [datetime] NULL,
	[ShipDate] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactInternetSalesReason](
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[SalesReasonKey] [int] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactProductInventory](
	[ProductKey] [int] NOT NULL,
	[DateKey] [int] NOT NULL,
	[MovementDate] [date] NOT NULL,
	[UnitCost] [money] NOT NULL,
	[UnitsIn] [int] NOT NULL,
	[UnitsOut] [int] NOT NULL,
	[UnitsBalance] [int] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactResellerSales](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[ResellerKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[SalesTerritoryKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[ExtendedAmount] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[CustomerPONumber] [nvarchar](25) NULL,
	[OrderDate] [datetime] NULL,
	[DueDate] [datetime] NULL,
	[ShipDate] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactSalesQuota](
	[SalesQuotaKey] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[DateKey] [int] NOT NULL,
	[CalendarYear] [smallint] NOT NULL,
	[CalendarQuarter] [tinyint] NOT NULL,
	[SalesAmountQuota] [money] NOT NULL,
	[Date] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactSurveyResponse](
	[SurveyResponseKey] [int] IDENTITY(1,1) NOT NULL,
	[DateKey] [int] NOT NULL,
	[CustomerKey] [int] NOT NULL,
	[ProductCategoryKey] [int] NOT NULL,
	[EnglishProductCategoryName] [nvarchar](50) NOT NULL,
	[ProductSubcategoryKey] [int] NOT NULL,
	[EnglishProductSubcategoryName] [nvarchar](50) NOT NULL,
	[Date] [datetime] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[NewFactCurrencyRate](
	[AverageRate] [real] NULL,
	[CurrencyID] [nvarchar](3) NULL,
	[CurrencyDate] [date] NULL,
	[EndOfDayRate] [real] NULL,
	[CurrencyKey] [int] NULL,
	[DateKey] [int] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[ProspectiveBuyer](
	[ProspectiveBuyerKey] [int] IDENTITY(1,1) NOT NULL,
	[ProspectAlternateKey] [nvarchar](15) NULL,
	[FirstName] [nvarchar](50) NULL,
	[MiddleName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[BirthDate] [datetime] NULL,
	[MaritalStatus] [nchar](1) NULL,
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
	[City] [nvarchar](30) NULL,
	[StateProvinceCode] [nvarchar](3) NULL,
	[PostalCode] [nvarchar](15) NULL,
	[Phone] [nvarchar](20) NULL,
	[Salutation] [nvarchar](8) NULL,
	[Unknown] [int] NULL
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[sysdiagrams](
	[name] [sysname] NOT NULL,
	[principal_id] [int] NOT NULL,
	[diagram_id] [int] IDENTITY(1,1) NOT NULL,
	[version] [int] NULL,
	[definition] [varbinary](max) NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING ON
GO

EXEC sys.sp_addextendedproperty @name=N'microsoft_database_tools_support', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'sysdiagrams'
GO

-- ******************************************************
-- Load data
-- ******************************************************
PRINT '';
PRINT '*** Loading Data';
GO

PRINT 'Loading [dbo].[AdventureWorksDWBuildVersion]';

INSERT INTO [dbo].[AdventureWorksDWBuildVersion]
VALUES
( CONVERT(nvarchar(50), SERVERPROPERTY('ProductVersion')), CONVERT(datetime, SERVERPROPERTY('ResourceLastUpdateDateTime')));

PRINT 'Loading [dbo].[DimAccount]';

BULK INSERT [dbo].[DimAccount] FROM '$(SqlSamplesSourceDataPath)DimAccount.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimCurrency]';

BULK INSERT [dbo].[DimCurrency] FROM '$(SqlSamplesSourceDataPath)DimCurrency.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimCustomer]';

BULK INSERT[dbo].[DimCustomer] FROM '$(SqlSamplesSourceDataPath)DimCustomer.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimDate]';

BULK INSERT [dbo].[DimDate] FROM '$(SqlSamplesSourceDataPath)DimDate.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimDepartmentGroup]';

BULK INSERT [dbo].[DimDepartmentGroup] FROM '$(SqlSamplesSourceDataPath)DimDepartmentGroup.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimEmployee]';

BULK INSERT [dbo].[DimEmployee] FROM '$(SqlSamplesSourceDataPath)DimEmployee.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimGeography]';

BULK INSERT [dbo].[DimGeography] FROM '$(SqlSamplesSourceDataPath)DimGeography.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimOrganization]';

BULK INSERT [dbo].[DimOrganization] FROM '$(SqlSamplesSourceDataPath)DimOrganization.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimProduct]';

BULK INSERT [dbo].[DimProduct] FROM '$(SqlSamplesSourceDataPath)DimProduct.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimProductCategory]';

BULK INSERT [dbo].[DimProductCategory] FROM '$(SqlSamplesSourceDataPath)DimProductCategory.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimProductSubcategory]';

BULK INSERT [dbo].[DimProductSubcategory] FROM '$(SqlSamplesSourceDataPath)DimProductSubcategory.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimPromotion]';

BULK INSERT [dbo].[DimPromotion] FROM '$(SqlSamplesSourceDataPath)DimPromotion.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimReseller]';

BULK INSERT [dbo].[DimReseller] FROM '$(SqlSamplesSourceDataPath)DimReseller.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimSalesReason]';

BULK INSERT [dbo].[DimSalesReason] FROM '$(SqlSamplesSourceDataPath)DimSalesReason.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimSalesTerritory]';

BULK INSERT [dbo].[DimSalesTerritory] FROM '$(SqlSamplesSourceDataPath)DimSalesTerritory.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimScenario]';

BULK INSERT [dbo].[DimScenario] FROM '$(SqlSamplesSourceDataPath)DimScenario.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactAdditionalInternationalProductDescription]';

BULK INSERT [dbo].[FactAdditionalInternationalProductDescription] FROM '$(SqlSamplesSourceDataPath)FactAdditionalInternationalProductDescription.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactCallCenter]';

BULK INSERT [dbo].[FactCallCenter] FROM '$(SqlSamplesSourceDataPath)FactCallCenter.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactCurrencyRate]';

BULK INSERT [dbo].[FactCurrencyRate] FROM '$(SqlSamplesSourceDataPath)FactCurrencyRate.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactFinance]';

BULK INSERT [dbo].[FactFinance] FROM '$(SqlSamplesSourceDataPath)FactFinance.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactInternetSales]';

BULK INSERT [dbo].[FactInternetSales] FROM '$(SqlSamplesSourceDataPath)FactInternetSales.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactInternetSalesReason] ';

BULK INSERT [dbo].[FactInternetSalesReason] FROM '$(SqlSamplesSourceDataPath)FactInternetSalesReason.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactProductInventory]';

BULK INSERT [dbo].[FactProductInventory] FROM '$(SqlSamplesSourceDataPath)FactProductInventory.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactResellerSales]';

BULK INSERT [dbo].[FactResellerSales] FROM '$(SqlSamplesSourceDataPath)FactResellerSales.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactSalesQuota]';

BULK INSERT [dbo].[FactSalesQuota] FROM '$(SqlSamplesSourceDataPath)FactSalesQuota.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactSurveyResponse]';

BULK INSERT [dbo].[FactSurveyResponse] FROM '$(SqlSamplesSourceDataPath)FactSurveyResponse.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[NewFactCurrencyRate]';

BULK INSERT [dbo].[NewFactCurrencyRate] FROM '$(SqlSamplesSourceDataPath)NewFactCurrencyRate.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[ProspectiveBuyer]';

BULK INSERT [dbo].[ProspectiveBuyer] FROM '$(SqlSamplesSourceDataPath)ProspectiveBuyer.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[sysdiagrams]';

BULK INSERT [dbo].[sysdiagrams] FROM '$(SqlSamplesSourceDataPath)sysdiagrams.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);


-- ******************************************************
-- Add Primary Keys
-- ******************************************************
PRINT '';
PRINT '*** Adding Primary Keys';
GO

SET QUOTED_IDENTIFIER ON;

ALTER TABLE [dbo].[sysdiagrams] WITH CHECK ADD
    CONSTRAINT [PK__sysdiagr__C2B05B616B24EA82] PRIMARY KEY CLUSTERED
	(
	[diagram_id]
	) ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimAccount] WITH CHECK ADD
    CONSTRAINT [PK_DimAccount] PRIMARY KEY CLUSTERED
	(
	[AccountKey]
	) ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimCurrency] WITH CHECK ADD
    CONSTRAINT [PK_DimCurrency_CurrencyKey] PRIMARY KEY CLUSTERED
    (
       [CurrencyKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimCustomer] WITH CHECK ADD
    CONSTRAINT [PK_DimCustomer_CustomerKey] PRIMARY KEY CLUSTERED
    (
        [CustomerKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimDate] WITH CHECK ADD
    CONSTRAINT [PK_DimDate_DateKey] PRIMARY KEY CLUSTERED
    (
        [DateKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimDepartmentGroup] WITH CHECK ADD
    CONSTRAINT [PK_DimDepartmentGroup] PRIMARY KEY CLUSTERED
    (
        [DepartmentGroupKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimEmployee] WITH CHECK ADD
    CONSTRAINT [PK_DimEmployee_EmployeeKey] PRIMARY KEY CLUSTERED
    (
       [EmployeeKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimGeography] WITH CHECK ADD
    CONSTRAINT [PK_DimGeography_GeographyKey] PRIMARY KEY CLUSTERED
    (
       [GeographyKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimOrganization] WITH CHECK ADD
    CONSTRAINT [PK_DimOrganization] PRIMARY KEY CLUSTERED
    (
       [OrganizationKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimProduct] WITH CHECK ADD
    CONSTRAINT [PK_DimProduct_ProductKey] PRIMARY KEY CLUSTERED
    (
        [ProductKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimProductCategory] WITH CHECK ADD
    CONSTRAINT [PK_DimProductCategory_ProductCategoryKey] PRIMARY KEY CLUSTERED
    (
        [ProductCategoryKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimProductSubcategory] WITH CHECK ADD
    CONSTRAINT [PK_DimProductSubcategory_ProductSubcategoryKey] PRIMARY KEY CLUSTERED
    (
        [ProductSubcategoryKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimPromotion] WITH CHECK ADD
    CONSTRAINT [PK_DimPromotion_PromotionKey] PRIMARY KEY CLUSTERED
    (
       [PromotionKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimReseller] WITH CHECK ADD
    CONSTRAINT [PK_DimReseller_ResellerKey] PRIMARY KEY CLUSTERED
    (
        [ResellerKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimSalesReason] WITH CHECK ADD
    CONSTRAINT [PK_DimSalesReason_SalesReasonKey] PRIMARY KEY CLUSTERED
    (
        [SalesReasonKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DatabaseLog] WITH CHECK ADD
    CONSTRAINT [PK_DatabaseLog_DatabaseLogID] PRIMARY KEY NONCLUSTERED
    (
        [DatabaseLogID]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimSalesTerritory] WITH CHECK ADD
    CONSTRAINT [PK_DimSalesTerritory_SalesTerritoryKey] PRIMARY KEY CLUSTERED
    (
        [SalesTerritoryKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[DimScenario] WITH CHECK ADD
    CONSTRAINT [PK_DimScenario] PRIMARY KEY CLUSTERED
    (
        [ScenarioKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactAdditionalInternationalProductDescription] WITH CHECK ADD
    CONSTRAINT [PK_FactAdditionalInternationalProductDescription_ProductKey_CultureName] PRIMARY KEY CLUSTERED
    (
       [ProductKey],[CultureName]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactCallCenter] WITH CHECK ADD
    CONSTRAINT [PK_FactCallCenter_FactCallCenterID] PRIMARY KEY CLUSTERED
    (
        [FactCallCenterID]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactCurrencyRate] WITH CHECK ADD
    CONSTRAINT [PK_FactCurrencyRate_CurrencyKey_DateKey] PRIMARY KEY CLUSTERED
    (
      [CurrencyKey], [DateKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactInternetSales] WITH CHECK ADD
    CONSTRAINT [PK_FactInternetSales_SalesOrderNumber_SalesOrderLineNumber] PRIMARY KEY CLUSTERED
    (
        [SalesOrderNumber], [SalesOrderLineNumber]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactInternetSalesReason] WITH CHECK ADD
    CONSTRAINT [PK_FactInternetSalesReason_SalesOrderNumber_SalesOrderLineNumber_SalesReasonKey] PRIMARY KEY CLUSTERED
    (
        [SalesOrderNumber], [SalesOrderLineNumber], [SalesReasonKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactProductInventory] WITH CHECK ADD
    CONSTRAINT [PK_FactProductInventory] PRIMARY KEY CLUSTERED
    (
        [ProductKey], [DateKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactResellerSales] WITH CHECK ADD
    CONSTRAINT [PK_FactResellerSales_SalesOrderNumber_SalesOrderLineNumber] PRIMARY KEY CLUSTERED
    (
        [SalesOrderNumber], [SalesOrderLineNumber]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactSalesQuota] WITH CHECK ADD
    CONSTRAINT [PK_FactSalesQuota_SalesQuotaKey] PRIMARY KEY CLUSTERED
    (
       [SalesQuotaKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[FactSurveyResponse] WITH CHECK ADD
    CONSTRAINT [PK_FactSurveyResponse_SurveyResponseKey] PRIMARY KEY CLUSTERED
    (
        [SurveyResponseKey]
    )  ON [PRIMARY];
GO

ALTER TABLE [dbo].[ProspectiveBuyer] WITH CHECK ADD
    CONSTRAINT [PK_ProspectiveBuyer_ProspectiveBuyerKey] PRIMARY KEY CLUSTERED
    (
        [ProspectiveBuyerKey]
    )  ON [PRIMARY];
GO

-- ******************************************************
-- Add Indexes
-- ******************************************************
PRINT '';
PRINT '*** Adding Indexes';
GO

CREATE UNIQUE NONCLUSTERED INDEX [AK_DimCurrency_CurrencyAlternateKey] ON [dbo].[DimCurrency]([CurrencyAlternateKey]) ON [PRIMARY];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_DimCustomer_CustomerAlternateKey] ON [dbo].[DimCustomer]([CustomerAlternateKey]) ON [PRIMARY];
GO

CREATE UNIQUE NONCLUSTERED INDEX [AK_DimDate_FullDateAlternateKey] ON [dbo].[DimDate]( [FullDateAlternateKey]) ON [PRIMARY];
GO

/****** Object:  Index [AK_DimProduct_ProductAlternateKey_StartDate]    Script Date: 7/8/2016 2:39:08 PM ******/
ALTER TABLE [dbo].[DimProduct] ADD  CONSTRAINT [AK_DimProduct_ProductAlternateKey_StartDate] UNIQUE NONCLUSTERED
(
	[ProductAlternateKey] ASC,
	[StartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

/****** Object:  Index [AK_DimProductCategory_ProductCategoryAlternateKey]    Script Date: 7/8/2016 2:40:13 PM ******/
ALTER TABLE [dbo].[DimProductCategory] ADD  CONSTRAINT [AK_DimProductCategory_ProductCategoryAlternateKey] UNIQUE NONCLUSTERED
(
	[ProductCategoryAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

/****** Object:  Index [AK_DimProductSubcategory_ProductSubcategoryAlternateKey]    Script Date: 7/8/2016 2:40:37 PM ******/
ALTER TABLE [dbo].[DimProductSubcategory] ADD  CONSTRAINT [AK_DimProductSubcategory_ProductSubcategoryAlternateKey] UNIQUE NONCLUSTERED
(
	[ProductSubcategoryAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

/****** Object:  Index [AK_DimPromotion_PromotionAlternateKey]    Script Date: 7/8/2016 2:41:46 PM ******/
ALTER TABLE [dbo].[DimPromotion] ADD  CONSTRAINT [AK_DimPromotion_PromotionAlternateKey] UNIQUE NONCLUSTERED
(
	[PromotionAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

/****** Object:  Index [AK_DimReseller_ResellerAlternateKey]    Script Date: 7/8/2016 2:42:07 PM ******/
ALTER TABLE [dbo].[DimReseller] ADD  CONSTRAINT [AK_DimReseller_ResellerAlternateKey] UNIQUE NONCLUSTERED
(
	[ResellerAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

/****** Object:  Index [AK_DimSalesTerritory_SalesTerritoryAlternateKey]    Script Date: 7/8/2016 2:43:13 PM ******/
ALTER TABLE [dbo].[DimSalesTerritory] ADD  CONSTRAINT [AK_DimSalesTerritory_SalesTerritoryAlternateKey] UNIQUE NONCLUSTERED
(
	[SalesTerritoryAlternateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

/****** Object:  Index [AK_FactCallCenter_DateKey_Shift]    Script Date: 7/8/2016 2:43:49 PM ******/
ALTER TABLE [dbo].[FactCallCenter] ADD  CONSTRAINT [AK_FactCallCenter_DateKey_Shift] UNIQUE NONCLUSTERED
(
	[DateKey] ASC,
	[Shift] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UK_principal_name] ON [dbo].[sysdiagrams]([principal_id],	[name]) ON [PRIMARY];
GO

-- ****************************************
-- Create Foreign key constraints
-- ****************************************
PRINT '';
PRINT '*** Creating Foreign Key Constraints';
GO

ALTER TABLE [dbo].[DimAccount] ADD
    CONSTRAINT [FK_DimAccount_DimAccount] FOREIGN KEY
    (
        [ParentAccountKey]
    ) REFERENCES [dbo].[DimAccount] ([AccountKey]);
GO

ALTER TABLE [dbo].[DimCustomer] ADD
	CONSTRAINT [FK_DimCustomer_DimGeography] FOREIGN KEY
	(
		[GeographyKey]
	)
	REFERENCES [dbo].[DimGeography] ([GeographyKey])

ALTER TABLE [dbo].[DimDepartmentGroup] ADD
    CONSTRAINT [FK_DimDepartmentGroup_DimDepartmentGroup] FOREIGN KEY
    (
        [ParentDepartmentGroupKey]
    ) REFERENCES [dbo].[DimDepartmentGroup] ([DepartmentGroupKey]);
GO

ALTER TABLE [dbo].[DimEmployee] ADD
    CONSTRAINT [FK_DimEmployee_DimSalesTerritory] FOREIGN KEY
    (
        [SalesTerritoryKey]
    ) REFERENCES [dbo].[DimSalesTerritory] ([SalesTerritoryKey]),
	CONSTRAINT [FK_DimEmployee_DimEmployee] FOREIGN KEY
    (
        [ParentEmployeeKey]
    ) REFERENCES [dbo].[DimEmployee] ([EmployeeKey]);
GO

ALTER TABLE [dbo].[DimGeography] ADD
    CONSTRAINT [FK_DimGeography_DimSalesTerritory]  FOREIGN KEY
    (
        [SalesTerritoryKey]
    ) REFERENCES [dbo].[DimSalesTerritory] ([SalesTerritoryKey]);
GO

ALTER TABLE [dbo].[DimOrganization] ADD
    CONSTRAINT [FK_DimOrganization_DimCurrency] FOREIGN KEY
    (
        [CurrencyKey]
    ) REFERENCES [dbo].[DimCurrency] ([CurrencyKey]),
    CONSTRAINT [FK_DimOrganization_DimOrganization] FOREIGN KEY
    (
        [ParentOrganizationKey]
    )REFERENCES [dbo].[DimOrganization] ([OrganizationKey]);
GO

ALTER TABLE [dbo].[DimProduct] ADD
    CONSTRAINT [FK_DimProduct_DimProductSubcategory] FOREIGN KEY
    (
        [ProductSubcategoryKey]
    ) REFERENCES [dbo].[DimProductSubcategory] ([ProductSubcategoryKey]);
GO

ALTER TABLE [dbo].[DimProductSubcategory] ADD
    CONSTRAINT [FK_DimProductSubcategory_DimProductCategory] FOREIGN KEY
    (
        [ProductCategoryKey]
    ) REFERENCES [dbo].[DimProductCategory] ([ProductCategoryKey]);
GO

ALTER TABLE [dbo].[DimReseller] ADD
	CONSTRAINT [FK_DimReseller_DimGeography] FOREIGN KEY
	(
		[GeographyKey]
	) REFERENCES [dbo].[DimGeography] ([GeographyKey]);
GO

ALTER TABLE [dbo].[FactCallCenter] ADD
    CONSTRAINT [FK_FactCallCenter_DimDate] FOREIGN KEY
    (
        [DateKey]
    ) REFERENCES [dbo].[DimDate] ([DateKey]);
GO

ALTER TABLE [dbo].[FactCurrencyRate] ADD
    CONSTRAINT [FK_FactCurrencyRate_DimDate] FOREIGN KEY
    (
       [DateKey]
    ) REFERENCES [dbo].[DimDate] ([DateKey]),
	CONSTRAINT [FK_FactCurrencyRate_DimCurrency] FOREIGN KEY
    (
       [CurrencyKey]
    ) REFERENCES [dbo].[DimCurrency] ([CurrencyKey]);
GO

ALTER TABLE [dbo].[FactFinance] ADD
    CONSTRAINT [FK_FactFinance_DimScenario] FOREIGN KEY
    (
        [ScenarioKey]
    ) REFERENCES [dbo].[DimScenario] ([ScenarioKey]),
    CONSTRAINT [FK_FactFinance_DimOrganization] FOREIGN KEY
    (
        [OrganizationKey]
    ) REFERENCES [dbo].[DimOrganization] ([OrganizationKey]),
    CONSTRAINT [FK_FactFinance_DimDepartmentGroup] FOREIGN KEY
    (
        [DepartmentGroupKey]
    ) REFERENCES [dbo].[DimDepartmentGroup] ([DepartmentGroupKey]),
	CONSTRAINT [FK_FactFinance_DimDate] FOREIGN KEY
    (
        [DateKey]
    ) REFERENCES [dbo].[DimDate] ([DateKey]),
	CONSTRAINT [FK_FactFinance_DimAccount] FOREIGN KEY
    (
        [AccountKey]
    ) REFERENCES [dbo].[DimAccount] ([AccountKey])	
	;
GO

ALTER TABLE [dbo].[FactInternetSales] ADD
    CONSTRAINT [FK_FactInternetSales_DimCurrency] FOREIGN KEY
    (
        [CurrencyKey]
    ) REFERENCES [dbo].[DimCurrency] ([CurrencyKey]),
	 CONSTRAINT [FK_FactInternetSales_DimCustomer] FOREIGN KEY
    (
        [CustomerKey]
    ) REFERENCES [dbo].[DimCustomer] ([CustomerKey]),
	 CONSTRAINT [FK_FactInternetSales_DimDate] FOREIGN KEY
    (
        [OrderDateKey]
    ) REFERENCES [dbo].[DimDate] ([DateKey]),
	 CONSTRAINT [FK_FactInternetSales_DimDate1] FOREIGN KEY
    (
        [DueDateKey]
    ) REFERENCES [dbo].[DimDate] ([DateKey]),
	 CONSTRAINT [FK_FactInternetSales_DimDate2] FOREIGN KEY
    (
        [ShipDateKey]
    ) REFERENCES [dbo].[DimDate] ([DateKey]),
	 CONSTRAINT [FK_FactInternetSales_DimProduct] FOREIGN KEY
    (
        [ProductKey]
    ) REFERENCES [dbo].[DimProduct] ([ProductKey]),
	CONSTRAINT [FK_FactInternetSales_DimPromotion] FOREIGN KEY
    (
        [PromotionKey]
    ) REFERENCES [dbo].[DimPromotion] ([PromotionKey]),
	CONSTRAINT [FK_FactInternetSales_DimSalesTerritory] FOREIGN KEY
    (
        [SalesTerritoryKey]
    ) REFERENCES [dbo].[DimSalesTerritory] ([SalesTerritoryKey]);
GO

ALTER TABLE [dbo].[FactInternetSalesReason] ADD
    CONSTRAINT [FK_FactInternetSalesReason_FactInternetSales] FOREIGN KEY
    (
        [SalesOrderNumber], [SalesOrderLineNumber]
    ) REFERENCES [dbo].[FactInternetSales] ([SalesOrderNumber], [SalesOrderLineNumber]),
	CONSTRAINT [FK_FactInternetSalesReason_DimSalesReason] FOREIGN KEY
	(
		[SalesReasonKey]
	) REFERENCES [dbo].[DimSalesReason] ([SalesReasonKey]);
GO

ALTER TABLE [dbo].[FactProductInventory] ADD
    CONSTRAINT [FK_FactProductInventory_DimDate] FOREIGN KEY
    (
        [DateKey]
    )REFERENCES [dbo].[DimDate] ([DateKey]),
	CONSTRAINT [FK_FactProductInventory_DimProduct] FOREIGN KEY
	(
		[ProductKey]
	) REFERENCES [dbo].[DimProduct] ([ProductKey]);
GO


ALTER TABLE [dbo].[FactResellerSales] ADD
    CONSTRAINT [FK_FactResellerSales_DimCurrency] FOREIGN KEY([CurrencyKey])
			REFERENCES [dbo].[DimCurrency] ([CurrencyKey]),
	CONSTRAINT [FK_FactResellerSales_DimDate] FOREIGN KEY([OrderDateKey])
			REFERENCES [dbo].[DimDate] ([DateKey]),
	CONSTRAINT [FK_FactResellerSales_DimDate1] FOREIGN KEY([DueDateKey])
			REFERENCES [dbo].[DimDate] ([DateKey]),
	CONSTRAINT [FK_FactResellerSales_DimDate2] FOREIGN KEY([ShipDateKey])
			REFERENCES [dbo].[DimDate] ([DateKey]),
	CONSTRAINT [FK_FactResellerSales_DimEmployee] FOREIGN KEY([EmployeeKey])
			REFERENCES [dbo].[DimEmployee] ([EmployeeKey]),
	CONSTRAINT [FK_FactResellerSales_DimProduct] FOREIGN KEY([ProductKey])
			REFERENCES [dbo].[DimProduct] ([ProductKey]),
	CONSTRAINT [FK_FactResellerSales_DimPromotion] FOREIGN KEY([PromotionKey])
			REFERENCES [dbo].[DimPromotion] ([PromotionKey]),
	CONSTRAINT [FK_FactResellerSales_DimReseller] FOREIGN KEY([ResellerKey])
			REFERENCES [dbo].[DimReseller] ([ResellerKey]),
	CONSTRAINT [FK_FactResellerSales_DimSalesTerritory] FOREIGN KEY([SalesTerritoryKey])
			REFERENCES [dbo].[DimSalesTerritory] ([SalesTerritoryKey]);
GO

ALTER TABLE [dbo].[FactSalesQuota] ADD
    CONSTRAINT [FK_FactSalesQuota_DimEmployee] FOREIGN KEY([EmployeeKey])
			REFERENCES [dbo].[DimEmployee] ([EmployeeKey]),
    CONSTRAINT [FK_FactSalesQuota_DimDate] FOREIGN KEY([DateKey])
			REFERENCES [dbo].[DimDate] ([DateKey]);
GO

ALTER TABLE [dbo].[FactSurveyResponse]  ADD
    CONSTRAINT [FK_FactSurveyResponse_DateKey] FOREIGN KEY([DateKey])
			REFERENCES [dbo].[DimDate] ([DateKey]),
	CONSTRAINT [FK_FactSurveyResponse_CustomerKey] FOREIGN KEY([CustomerKey])
			REFERENCES [dbo].[DimCustomer] ([CustomerKey]);
GO

-- ******************************************************
-- Add database views.
-- ******************************************************
PRINT '';
PRINT '*** Creating Table Views';
GO

-- vDMPrep will be used as a data source by the other data mining views.
-- Uses DW data at customer, product, day, etc. granularity and
-- gets region, model, year, month, etc.
CREATE VIEW [dbo].[vDMPrep]
AS
    SELECT
        pc.[EnglishProductCategoryName]
        ,Coalesce(p.[ModelName], p.[EnglishProductName]) AS [Model]
        ,c.[CustomerKey]
        ,s.[SalesTerritoryGroup] AS [Region]
        ,CASE
            WHEN Month(GetDate()) < Month(c.[BirthDate])
                THEN DateDiff(yy,c.[BirthDate],GetDate()) - 1
            WHEN Month(GetDate()) = Month(c.[BirthDate])
            AND Day(GetDate()) < Day(c.[BirthDate])
                THEN DateDiff(yy,c.[BirthDate],GetDate()) - 1
            ELSE DateDiff(yy,c.[BirthDate],GetDate())
        END AS [Age]
        ,CASE
            WHEN c.[YearlyIncome] < 40000 THEN 'Low'
            WHEN c.[YearlyIncome] > 60000 THEN 'High'
            ELSE 'Moderate'
        END AS [IncomeGroup]
        ,d.[CalendarYear]
        ,d.[FiscalYear]
        ,d.[MonthNumberOfYear] AS [Month]
        ,f.[SalesOrderNumber] AS [OrderNumber]
        ,f.SalesOrderLineNumber AS LineNumber
        ,f.OrderQuantity AS Quantity
        ,f.ExtendedAmount AS Amount
    FROM
        [dbo].[FactInternetSales] f
    INNER JOIN [dbo].[DimDate] d
        ON f.[OrderDateKey] = d.[DateKey]
    INNER JOIN [dbo].[DimProduct] p
        ON f.[ProductKey] = p.[ProductKey]
    INNER JOIN [dbo].[DimProductSubcategory] psc
        ON p.[ProductSubcategoryKey] = psc.[ProductSubcategoryKey]
    INNER JOIN [dbo].[DimProductCategory] pc
        ON psc.[ProductCategoryKey] = pc.[ProductCategoryKey]
    INNER JOIN [dbo].[DimCustomer] c
        ON f.[CustomerKey] = c.[CustomerKey]
    INNER JOIN [dbo].[DimGeography] g
        ON c.[GeographyKey] = g.[GeographyKey]
    INNER JOIN [dbo].[DimSalesTerritory] s
        ON g.[SalesTerritoryKey] = s.[SalesTerritoryKey]
;

GO
/****** Object:  View [dbo].[vTimeSeries]    Script Date: 7/8/2016 3:09:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- vTimeSeries view supports the creation of time series data mining models.
--      - Replaces earlier bike models with successor models.
--      - Abbreviates model names to improve readability in mining model viewer
--      - Concatenates model and region so that table only has one input.
--      - Creates a date field indexed to monthly reporting date for use in prediction.
CREATE VIEW [dbo].[vTimeSeries]
AS
    SELECT
        CASE [Model]
            WHEN 'Mountain-100' THEN 'M200'
            WHEN 'Road-150' THEN 'R250'
            WHEN 'Road-650' THEN 'R750'
            WHEN 'Touring-1000' THEN 'T1000'
            ELSE Left([Model], 1) + Right([Model], 3)
        END + ' ' + [Region] AS [ModelRegion]
        ,(Convert(Integer, [CalendarYear]) * 100) + Convert(Integer, [Month]) AS [TimeIndex]
        ,Sum([Quantity]) AS [Quantity]
        ,Sum([Amount]) AS [Amount]
		,CalendarYear
		,[Month]
		,[dbo].[udfBuildISO8601Date] ([CalendarYear], [Month], 25)
		as ReportingDate
    FROM
        [dbo].[vDMPrep]
    WHERE
        [Model] IN ('Mountain-100', 'Mountain-200', 'Road-150', 'Road-250',
            'Road-650', 'Road-750', 'Touring-1000')
    GROUP BY
        CASE [Model]
            WHEN 'Mountain-100' THEN 'M200'
            WHEN 'Road-150' THEN 'R250'
            WHEN 'Road-650' THEN 'R750'
            WHEN 'Touring-1000' THEN 'T1000'
            ELSE Left(Model,1) + Right(Model,3)
        END + ' ' + [Region]
        ,(Convert(Integer, [CalendarYear]) * 100) + Convert(Integer, [Month])
		,CalendarYear
		,[Month]
		,[dbo].[udfBuildISO8601Date] ([CalendarYear], [Month], 25);

GO
/****** Object:  View [dbo].[vTargetMail]    Script Date: 7/8/2016 3:09:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- vTargetMail supports targeted mailing data model
-- Uses vDMPrep to determine if a customer buys a bike and joins to DimCustomer
CREATE VIEW [dbo].[vTargetMail]
AS
    SELECT
        c.[CustomerKey],
        c.[GeographyKey],
        c.[CustomerAlternateKey],
        c.[Title],
        c.[FirstName],
        c.[MiddleName],
        c.[LastName],
        c.[NameStyle],
        c.[BirthDate],
        c.[MaritalStatus],
        c.[Suffix],
        c.[Gender],
        c.[EmailAddress],
        c.[YearlyIncome],
        c.[TotalChildren],
        c.[NumberChildrenAtHome],
        c.[EnglishEducation],
        c.[SpanishEducation],
        c.[FrenchEducation],
        c.[EnglishOccupation],
        c.[SpanishOccupation],
        c.[FrenchOccupation],
        c.[HouseOwnerFlag],
        c.[NumberCarsOwned],
        c.[AddressLine1],
        c.[AddressLine2],
        c.[Phone],
        c.[DateFirstPurchase],
        c.[CommuteDistance],
        x.[Region],
        x.[Age],
        CASE x.[Bikes]
            WHEN 0 THEN 0
            ELSE 1
        END AS [BikeBuyer]
    FROM
        [dbo].[DimCustomer] c INNER JOIN (
            SELECT
                [CustomerKey]
                ,[Region]
                ,[Age]
                ,Sum(
                    CASE [EnglishProductCategoryName]
                        WHEN 'Bikes' THEN 1
                        ELSE 0
                    END) AS [Bikes]
            FROM
                [dbo].[vDMPrep]
            GROUP BY
                [CustomerKey]
                ,[Region]
                ,[Age]
            ) AS [x]
        ON c.[CustomerKey] = x.[CustomerKey]
;

GO
/****** Object:  View [dbo].[vAssocSeqOrders]    Script Date: 7/8/2016 3:09:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* vAssocSeqOrders supports assocation and sequence clustering data mmining models.
      - Limits data to FY2004.
      - Creates order case table and line item nested table.*/
CREATE VIEW [dbo].[vAssocSeqOrders]
AS
SELECT DISTINCT OrderNumber, CustomerKey, Region, IncomeGroup
FROM         dbo.vDMPrep
WHERE     (FiscalYear = '2013')

GO
/****** Object:  View [dbo].[vAssocSeqLineItems]    Script Date: 7/8/2016 3:09:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vAssocSeqLineItems]
AS
SELECT     OrderNumber, LineNumber, Model
FROM         dbo.vDMPrep
WHERE     (FiscalYear = '2013')
GO

-- ****************************************
-- Drop DDL Trigger for Database
-- ****************************************
PRINT '';
PRINT '*** Disabling DDL Trigger for Database';
GO

DISABLE TRIGGER [ddlDatabaseTriggerLog]
ON DATABASE;
GO

USE [master];
GO

PRINT 'Finished - ' + CONVERT(varchar, GETDATE(), 121);
GO

SET NOEXEC OFF
