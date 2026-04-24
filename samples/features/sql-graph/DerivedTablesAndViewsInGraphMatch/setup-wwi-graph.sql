-- Create StockItems node

DROP TABLE IF EXISTS StockItems;
GO
DROP TABLE IF EXISTS Customers;
GO
DROP TABLE IF EXISTS Bought;
GO
DROP TABLE IF EXISTS FriendOf;
GO


CREATE TABLE StockItems
(
  StockItemID INTEGER IDENTITY(1, 1) NOT NULL,
  StockItemName NVARCHAR(100) NOT NULL,
  Barcode NVARCHAR(50) NULL,
  Photo VARBINARY(MAX),
  LastEditedBy INTEGER NOT NULL
) AS NODE
GO

-- Create the Customers node
-- This node holds the main details of the Customer
CREATE TABLE Customers
(
  [CustomerID] INTEGER NOT NULL,
  [CustomerName] NVARCHAR(100) NOT NULL,
  [WebsiteURL] NVARCHAR(256) NOT NULL,
  [CustomerCategory] NVARCHAR(50) NOT NULL,
  [ValidFrom] datetime2(7) NOT NULL,
  [ValidTo] datetime2(7) NOT NULL
) AS NODE
GO


-- Create the edge from nodes Customers and StockItems
CREATE TABLE Bought
(
  [PurchasedCount] BIGINT
)
AS EDGE;
GO


-- Create FriendOf edge, which connects each customer
-- to 3 other customers as 'friends'
CREATE TABLE FriendOf AS EDGE
GO



-------------------------------------------------------------------------------------
---- Populate StockItems table.
-------------------------------------------------------------------------------------
SET IDENTITY_INSERT StockItems ON;
GO
INSERT INTO StockItems
(
  StockItemID,
  StockItemName,
  LastEditedBy
) SELECT
  StockItemID,
  StockItemName,
  LastEditedBy
FROM
  Warehouse.StockItems;
GO
SET IDENTITY_INSERT StockItems OFF;
GO


-------------------------------------------------------------------------------------
---- Populate Customers table.
-------------------------------------------------------------------------------------
INSERT INTO Customers
(
  [CustomerID],
  [CustomerName],
  [WebsiteURL],
  [CustomerCategory],
  [ValidFrom],
  [ValidTo]
) SELECT
  [CustomerID],
  [CustomerName],
  [WebsiteURL],
  [CustomerCategoryName],
  C.[ValidFrom],
  C.[ValidTo]
FROM
  Sales.Customers AS C,
  Sales.CustomerCategories AS SC
WHERE C.CustomerCategoryID = SC.CustomerCategoryID;
GO

-------------------------------------------------------------------------------------
---- Create Supplier Table
-------------------------------------------------------------------------------------
drop table if exists supplier;
drop table if exists city;
drop table if exists locatedIn;
drop table if exists deliveryIn;


CREATE TABLE Supplier (
	SupplierID integer not null,
	SupplierName nvarchar(100) not null,
	PhoneNumber nvarchar(20),
	SupplierCategory nvarchar(50),
	ValidFrom datetime2(7) not null,
	ValidTo datetime2(7) not null
) AS NODE
GO

CREATE TABLE City(
	CityID integer,
	CityName nvarchar(50),
	StateProvinceID integer,
	StateProvinceName nvarchar(50)
) AS NODE
GO

CREATE TABLE locatedIn AS EDGE
GO

CREATE TABLE deliveryIn AS EDGE
GO


-------------------------------------------------------------------------------------
---- Populate Supplier table.
-------------------------------------------------------------------------------------
INSERT INTO Supplier
(
  [SupplierID],
  [SupplierName],
  [PhoneNumber],
  [SupplierCategory],
  [ValidFrom],
  [ValidTo]
) SELECT
  [SupplierID],
  [SupplierName],
  [PhoneNumber],
  [SupplierCategoryName],
  S.[ValidFrom],
  S.[ValidTo]
FROM
  Purchasing.Suppliers S,
  Purchasing.SupplierCategories SC
WHERE
	S.SupplierCategoryID = SC.SupplierCategoryID
GO

-------------------------------------------------------------------------------------
---- Populate City table.
-------------------------------------------------------------------------------------
INSERT INTO City
(
  [CityID],
  [CityName],
  [StateProvinceID],
  [StateProvinceName]
) SELECT
  [CityID],
  [CityName],
  C.StateProvinceID,
  S.StateProvinceName
FROM
  Application.Cities C,
  Application.StateProvinces S
WHERE C.StateProvinceID = S.StateProvinceID;
GO

-------------------------------------------------------------------------------------
---- Populate Bought edge table.
-------------------------------------------------------------------------------------
-- Insert Customers-bought->StockItems data in the bought edge.
INSERT INTO Bought
(
  $from_id,
  $to_id,
  [PurchasedCount]
)
SELECT
  C.$node_id,
  P.$node_id,
  PurchasedCount = COUNT(OD.OrderLineID)
FROM
  Sales.OrderLines AS OD
JOIN
  Sales.Orders AS OH ON OH.OrderID = OD.OrderID
JOIN
  Customers AS C ON C.CustomerID = OH.CustomerID
JOIN
  StockItems AS P ON P.StockItemID = OD.StockItemID
GROUP BY
  C.$node_id, P.$node_id
GO

-- Insert Supplier-bought->StockItems data in the bought edge.
INSERT INTO Bought
(
  $from_id,
  $to_id,
  [PurchasedCount]
)
SELECT
  S.$node_id,
  P.$node_id,
  PurchasedCount = COUNT(OD.OrderLineID)
FROM
  Sales.OrderLines AS OD
JOIN
  Sales.Orders AS OH ON OH.OrderID = OD.OrderID
JOIN
  Supplier AS S ON S.SupplierID = OH.CustomerID
JOIN
  StockItems AS P ON P.StockItemID = OD.StockItemID
GROUP BY
  S.$node_id, P.$node_id
GO


-------------------------------------------------------------------------------------
---- Populate FriendOf edge table.
-------------------------------------------------------------------------------------
DECLARE @j INTEGER;
DECLARE @lower INTEGER;
DECLARE @upper INTEGER;
DECLARE @i INTEGER;
DECLARE @random INTEGER;

SET @upper = 1061
SET @i = 1
WHILE (@i <= @upper)
BEGIN
       SET @j = 0
       WHILE (@j < 3)
       BEGIN
              SELECT @random = ROUND(((@Upper - @i) * RAND() + @j), 0)
			
			  INSERT FriendOf($from_id, $to_id)
              SELECT C1.$node_id, C2.$node_id
                FROM Customers AS C1, Customers AS C2
               WHERE C2.CustomerID = @random --$to_id
                 AND C1.CustomerID = @i		 --$from_id
			     SET @j = @j + 1
       END
       SET @i = @i + 1
END;
GO


-- Insert some fixed records in FriendOf table,
-- to be used later in shortest path query
INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1037
and C2.customerID = 1040
GO

INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1040
and C2.customerID = 1042
GO

INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1042
and C2.customerID = 1028
GO

INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1028
and C2.customerID = 1054
GO




-------------------------------------------------------------------------------------
---- Populate locatedIn edge table.
-------------------------------------------------------------------------------------
INSERT INTO locatedIn
(
  $from_id,
  $to_id
)
SELECT
  S.$node_id,
  C.$node_id
FROM
	Purchasing.Suppliers AS PS
JOIN
	Application.Cities AS AC ON PS.PostalCityID = AC.CityID
JOIN
	Supplier AS S ON S.SupplierID = PS.SupplierID
JOIN
	City AS C ON C.CityID = AC.CityID


-- Insert customer - city data
INSERT INTO locatedIn
(
  $from_id,
  $to_id
)
SELECT
  CUS.$node_id,
  C.$node_id
FROM
	Sales.Customers AS SC
JOIN
	Application.Cities AS AC ON SC.PostalCityID = AC.CityID
JOIN
	Customers AS CUS ON CUS.CustomerID = SC.CustomerID
JOIN
	City AS C ON C.CityID = AC.CityID


-- Insert customer locatedIn San Francisco.
-- We will use this data later in queries.
INSERT INTO locatedIn
(
	$from_id,
	$to_id
)
SELECT
	CUS.$node_id,
	C.$node_id
FROM
	Customers AS CUS, City AS C
WHERE
	CUS.CustomerID IN (5,1059,1060,1061,908)
  AND
	C.cityid = 30378


INSERT INTO locatedIn
(
	$from_id,
	$to_id
)
SELECT
	S.$node_id,
	C.$node_id
FROM
	Supplier AS S, City AS C
WHERE
	S.SupplierID = 2
AND
	C.CityID = 30378



-------------------------------------------------------------------------------------
---- Populate deliveryIN edge table.
-------------------------------------------------------------------------------------
INSERT INTO deliveryIn
(
  $from_id,
  $to_id
)
SELECT
  S.$node_id,
  C.$node_id
FROM
	Purchasing.Suppliers AS PS
JOIN
	Application.Cities AS AC ON PS.DeliveryCityID = AC.CityID
JOIN
	Supplier AS S ON S.SupplierID = PS.SupplierID
JOIN
	City AS C ON C.CityID = AC.CityID


-- Insert customer - city data
INSERT INTO deliveryIn
(
  $from_id,
  $to_id
)
SELECT
  CUS.$node_id,
  C.$node_id
FROM
	Sales.Customers AS SC
JOIN
	Application.Cities AS AC ON SC.DeliveryCityID = AC.CityID
JOIN
	Customers AS CUS ON CUS.CustomerID = SC.CustomerID
JOIN
	City AS C ON C.CityID = AC.CityID


-- Insert customer deliveryIn San Francisco.
-- We will use this data later in queries.
INSERT INTO deliveryIn
(
	$from_id,
	$to_id
)
SELECT
	CUS.$node_id,
	C.$node_id
FROM
	Customers AS CUS, City AS C
WHERE
	CUS.CustomerID IN (5,1059,1060,1061,908)
  AND
	C.cityid = 30378


INSERT INTO deliveryIn
(
	$from_id,
	$to_id
)
SELECT
	S.$node_id,
	C.$node_id
FROM
	Supplier AS S, City AS C
WHERE
	S.SupplierID = 2
AND
	C.CityID = 30378
GO

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------