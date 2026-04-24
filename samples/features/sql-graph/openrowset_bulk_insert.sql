/*
Bulk insert using OPENROWSET
SQL Server only
*/

/* SETUP. Download [WideWorldImporters-Standard].Sales.Customers as a csv file and create the related format file
:: From a windows command line, run the following commands
bcp [WideWorldImporters-Standard].Sales.Customers out "E:\Graph Examples\Graph.Customers.csv" -w -U {userName}@{serverName} -S tcp:{serverName}.database.windows.net -P {password}
bcp [WideWorldImporters-Standard].Sales.Customers format nul -x -f "E:\Graph Examples\Graph.Customers_format.xml" -w -U {userName}@{serverName} -S tcp:{serverName}.database.windows.net -P {password}
*/

-- create node table
DROP TABLE IF EXISTS Graph.Customers;
GO

CREATE TABLE Graph.Customers(
	CustomerID int,
	CustomerName nvarchar(100) not null,
	BillToCustomerID int not null,
	CustomerCategoryID int not null,
	BuyingGroupID int null,
	PrimaryContactPersonID int not null,
	AlternateContactPersonID int null,
	DeliveryMethodID int not null,
	DeliveryCityID int not null,
	PostalCityID int not null,
	CreditLimit decimal(18, 2) null,
	AccountOpenedDate date not null,
	StandardDiscountPercentage decimal(18, 3) not null,
	IsStatementSent bit not null,
	IsOnCreditHold bit not null,
	PaymentDays int not null,
	PhoneNumber nvarchar(20) not null,
	FaxNumber nvarchar(20) null,
	DeliveryRun nvarchar(5) null,
	RunPosition nvarchar(5) null,
	WebsiteURL nvarchar(256) not null,
	DeliveryAddressLine1 nvarchar(60) not null,
	DeliveryAddressLine2 nvarchar(60) null,
	DeliveryPostalCode nvarchar(10) not null,
	DeliveryLocation geography null,
	PostalAddressLine1 nvarchar(60) not null,
	PostalAddressLine2 nvarchar(60) null,
	PostalPostalCode nvarchar(10) not null,
	LastEditedBy int not null,
	ValidFrom datetime2(7) not null,
	ValidTo datetime2(7) not null
) AS NODE;
GO

-- to improve performance, disable default indexes and SET the recovery mode to bulk_logged
ALTER INDEX ALL ON Graph.Customers disable;
GO

USE master;
GO

ALTER DATABASE [WideWorldImporters-Standard]
SET recovery bulk_logged;
GO

USE [WideWorldImporters-Standard];
GO

INSERT INTO Graph.Customers (
	CustomerID,
	CustomerName,
	BillToCustomerID,
	CustomerCategoryID,
	BuyingGroupID,
	PrimaryContactPersonID,
	AlternateContactPersonID,
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	CreditLimit,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	FaxNumber,
	DeliveryRun,
	RunPosition,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryAddressLine2,
	DeliveryPostalCode,
	DeliveryLocation,
	PostalAddressLine1,
	PostalAddressLine2,
	PostalPostalCode,
	LastEditedBy,
	ValidFrom,
	ValidTo
)
SELECT
	CustomerID,
	CustomerName,
	BillToCustomerID,
	CustomerCategoryID,
	BuyingGroupID,
	PrimaryContactPersonID,
	AlternateContactPersonID,
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	CreditLimit,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	FaxNumber,
	DeliveryRun,
	RunPosition,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryAddressLine2,
	DeliveryPostalCode,
	DeliveryLocation,
	PostalAddressLine1,
	PostalAddressLine2,
	PostalPostalCode,
	LastEditedBy,
	ValidFrom,
	ValidTo
FROM OPENROWSET (
	bulk 'E:\Graph Examples\Graph.Customers.csv', formatfile = 'E:\Graph Examples\Graph.Customers_format.xml'
) as temp;

USE master;
GO

ALTER DATABASE [WideWorldImporters-Standard]
SET RECOVERY FULL;
GO

USE [WideWorldImporters-Standard];
GO

ALTER INDEX ALL ON Graph.Customers rebuild;
GO

SELECT * FROM Graph.Customers;
GO
