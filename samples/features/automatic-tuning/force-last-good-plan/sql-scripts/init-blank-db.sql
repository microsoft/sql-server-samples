/***************************************************************************
* Run this script on a empty database if you don't have WWI database and
* you want to use new database instead of full WWI
* If you are using SSMS, use Ctrl+Shift+M to populate parameters.
***************************************************************************/
ALTER DATABASE <database_name, sysname, flgp> MODIFY (EDITION = 'Premium', SERVICE_OBJECTIVE = '<azuredb_service_objective, varchar(6), P4>');
SELECT DATABASEPROPERTYEX('<database_name, sysname, flgp>', 'ServiceObjective');
-- Create minimal WWI schema required to run the sample:
DROP TABLE IF EXISTS [Sales].[OrderLines];
GO
DROP SEQUENCE IF EXISTS [Sequences].[OrderLineID];
GO
DROP SCHEMA IF EXISTS [Sequences];
GO
DROP SCHEMA IF EXISTS [Sequences];
GO

CREATE SCHEMA [Sequences];
GO
CREATE SEQUENCE [Sequences].[OrderLineID]
 AS [int]
 START WITH 231413
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE;
GO

CREATE TABLE Sales.OrderLines(
	OrderLineID int PRIMARY KEY,
	OrderID int NOT NULL,
	StockItemID int NOT NULL,
	Description nvarchar(100) NOT NULL,
	PackageTypeID int NOT NULL,
	Quantity int NOT NULL,
	UnitPrice decimal(18, 2) NULL,
	TaxRate decimal(18, 3) NOT NULL,
	PickedQuantity int NOT NULL,
	PickingCompletedWhen datetime2(7) NULL,
	LastEditedBy int NOT NULL,
	LastEditedWhen datetime2(7) NOT NULL
);
GO
ALTER TABLE [Sales].[OrderLines]
	ADD  CONSTRAINT [DF_Sales_OrderLines_OrderLineID]
			DEFAULT (NEXT VALUE FOR [Sequences].[OrderLineID]) FOR [OrderLineID]
GO
ALTER TABLE [Sales].[OrderLines]
	ADD  CONSTRAINT [DF_Sales_OrderLines_LastEditedWhen]
			DEFAULT (sysdatetime()) FOR [LastEditedWhen]
GO
DROP INDEX IF EXISTS [FK_Sales_OrderLines_PackageTypeID]
	ON [Sales].[OrderLines]

CREATE NONCLUSTERED INDEX [FK_Sales_OrderLines_PackageTypeID]
	ON [Sales].[OrderLines]([PackageTypeID] ASC)
GO

CREATE SCHEMA Warehouse;
GO

CREATE TABLE Warehouse.PackageType (
	PackageTypeID int,
	PackageType varchar(20),
	LastEditedBy int
);

-- Export Sales.OrderLines from WWI database using bcp:
-- bcp WideWorldImporters.Sales.OrderLines out OrderLines.dat -T -c -U <wwi_user_name, nvarchar(50), WWIUSERNAME> -P <wwi_password, nvarchar(50), WWIPASSWORD> -S <wwi server/instance, nvarchar(50), .//SQLEXPRESS>

-- Import data in new database using bcp:
-- bcp <database_name, sysname, flgp>.Sales.OrderLines in OrderLines.dat -c -U <demo_user_name, nvarchar(50), DEMOUSERNAME> -P <demo_password, nvarchar(50), DEMOPASSWORD> -S <demo server/instance, nvarchar(50), .//SQLEXPRESS>
