drop view if exists OperatesIn, CUstomer, Novelty_supplier, Novelty_customer
go

----------------------------------------------------------------------------
-- Querying heterogeneous edges
----------------------------------------------------------------------------
CREATE VIEW OperatesIn  AS
SELECT *, 'located' AS relation FROM locatedIn
UNION ALL
SELECT *, 'delivery' FROM deliveryIn
GO

SELECT SupplierID, SupplierName, PhoneNumber, relation
  FROM Supplier,
  City,
  OperatesIn
 WHERE MATCH(Supplier-(OperatesIn)->City)
   AND City.CityName = 'San Francisco'

----------------------------------------------------------------------------
-- Querying heterogeneous nodes
----------------------------------------------------------------------------

CREATE VIEW Customer AS
SELECT SupplierID AS ID,
  SupplierName AS NAME,
  SupplierCategory AS CATEGORY
  FROM Supplier
UNION ALL
SELECT CustomerID,
  CustomerName,
  CustomerCategory
  FROM Customers
GO


SELECT Customer.ID, Customer.NAME, Customer.CATEGORY
  FROM Customer,
  City,
  locatedIn
 WHERE MATCH(Customer-(locatedIn)->City)
             AND City.CityName = 'San Francisco'

 SELECT Customer.ID, Customer.NAME, Customer.CATEGORY
  FROM Customer,
  City,
  OperatesIn
 WHERE MATCH(Customer-(OperatesIn)->City)
   AND City.CityName = 'San Francisco'


----------------------------------------------------------------------------
-- Querying heterogeneous nodes and edges
----------------------------------------------------------------------------


CREATE VIEW Novelty_Supplier AS
SELECT SupplierID,
	SupplierName ,
	SupplierCategory ,
	ValidTo
	FROM Supplier
	WHERE SupplierCategory LIKE '%Novelty%' OR SupplierCategory LIKE '%Toy%'
GO

CREATE VIEW Novelty_Customer AS
	SELECT CustomerID,
		CustomerName,
		CustomerCategory,
		ValidTo
	  FROM Customers
	 WHERE CustomerCategory LIKE '%Novelty%' OR CustomerCategory LIKE '%Gift%'
GO

SELECT Name, ID, Category
  FROM
(SELECT SupplierID AS ID, SupplierName AS Name,
 SupplierCategory AS   Category, ValidTo
   FROM Novelty_Supplier WHERE ValidTo > getdate()
UNION ALL
 SELECT CustomerID, CustomerName, CustomerCategory, ValidTo
   FROM Novelty_Customer WHERE ValidTo > getdate()) AS NoveltyCust,
StockItems,
bought,
OperatesIn,
City
 WHERE MATCH(City<-(OperatesIn)-NoveltyCust-(bought)->Stockitems)
   AND StockItemName = 'White chocolate snow balls 250g'
   AND city.cityname = 'San Francisco'
GO
