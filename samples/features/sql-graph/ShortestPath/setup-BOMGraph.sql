USE AdventureWorks2014
GO

-- create product node
CREATE TABLE dbo.Product (
	ProductID INT,
	Name NVARCHAR(50),
	ProductNumber NVARCHAR(25),
	StandardCost money,
	ListPrice money,
	DaysToManu INT,
	Weight decimal(8,2),
	SellStartDate datetime,
	SellEndDate datetime,
) AS NODE;
GO

-- populate data into product node from Production.Product table
INSERT INTO dbo.Product
SELECT
	p.ProductID,
	p.Name,
	p.ProductNumber,
	p.StandardCost,
	p.ListPrice,
	p.Weight,
	p.DaysToManufacture,
	p.SellStartDate,
	p.SellEndDate
FROM Production.Product p;
GO

-- create IsPartOf edge
CREATE TABLE IsPartOf (PerAssemblyQty decimal(8,2)) AS EDGE;
go

-- Insert into isPartOf edge BOM hierarchy links
INSERT INTO IsPartOf
(
	$from_id,
	$to_id,
	PerAssemblyQty
)
SELECT
	P.$node_id,
	PP.$node_id,
	BOM.PerAssemblyQty
FROM
	dbo.Product AS P
JOIN
	Production.BillOfMaterials AS BOM ON P.ProductId = BOM.ComponentID
JOIN
	dbo.Product AS PP ON PP.ProductID = BOM.ProductAssemblyID
