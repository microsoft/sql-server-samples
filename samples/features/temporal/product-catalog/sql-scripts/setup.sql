USE master
GO

DROP DATABASE IF EXISTS ProductCatalog
GO

CREATE DATABASE ProductCatalog
GO

USE ProductCatalog
GO

CREATE SCHEMA History
GO

CREATE TABLE Product (
	ProductID int IDENTITY PRIMARY KEY,
	Name nvarchar(50) NOT NULL,
	Color nvarchar(15) NULL,
	Size nvarchar(5) NULL,
	Price money NOT NULL,
	Quantity int NULL,
	ValidFrom datetime2(0) NOT NULL,
	ValidTo datetime2(0) NOT NULL
)
GO

CREATE TABLE History.Product(
	ProductID int NOT NULL,
	Name nvarchar(50) NOT NULL,
	Color nvarchar(15) NULL,
	Size nvarchar(5) NULL,
	Price money NOT NULL,
	Quantity int NULL,
	ValidFrom datetime2(0) NOT NULL,
	ValidTo datetime2(0) NOT NULL
)
GO

SET IDENTITY_INSERT Product ON
GO

DECLARE @products NVARCHAR(MAX) = N'[{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":100.0000,"Quantity":75,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":16,"Name":"Bearing Ball","Color":"Magenta","Size":"62","Price":15.9900,"Quantity":90,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":28.9900,"Quantity":80,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":18,"Name":"Blade","Color":"Magenta","Size":"62","Price":18.0000,"Quantity":45,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":19,"Name":"Sport-100 Helmet, Red","Color":"Red","Size":"72","Price":41.9900,"Quantity":38,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":20,"Name":"Sport-100 Helmet, Black","Color":"Black","Size":"72","Price":31.4900,"Quantity":60,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":21,"Name":"Mountain Bike Socks, M","Color":"White","Size":"M","Price":560.9900,"Quantity":30,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":22,"Name":"Mountain Bike Socks, L","Color":"White","Size":"L","Price":120.9900,"Quantity":20,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":23,"Name":"Long-Sleeve Logo Jersey, XL","Color":"Multi","Size":"XL","Price":44.9900,"Quantity":60,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":24,"Name":"Road-650 Black, 52","Color":"Black","Size":"52","Price":704.6900,"Quantity":70,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":25,"Name":"Mountain-100 Silver, 38","Color":"Silver","Size":"38","Price":359.9900,"Quantity":45,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":26,"Name":"Road-250 Black, 48","Color":"Black","Size":"48","Price":299.0200,"Quantity":25,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":27,"Name":"ML Bottom Bracket","Price":101.2400,"Quantity":50,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"},{"ProductID":28,"Name":"HL Bottom Bracket","Price":121.4900,"Quantity":65,"ValidFrom":"2016-02-11T21:27:32","ValidTo":"9999-12-31T23:59:59"}]';
INSERT INTO Product(ProductID, Name, Color, Size, Price, Quantity, ValidFrom, ValidTo)
SELECT ProductID, Name, Color, Size, Price, Quantity, ValidFrom, ValidTo
FROM OPENJSON (@products) WITH(
	ProductID int,
	Name nvarchar(50),
	Color nvarchar(15),
	Size nvarchar(5),
	Price money,
	Quantity int,
	ValidFrom datetime2(0),
	ValidTo datetime2(0)
)
GO

SET IDENTITY_INSERT Product OFF
GO

DECLARE @products NVARCHAR(MAX) = N'[{"ProductID":15,"Name":"Adjustable Race","Price":75.9900,"Quantity":50,"ValidFrom":"2015-05-07T03:39:52","ValidTo":"2015-08-07T03:40:01"},{"ProductID":16,"Name":"Bearing Ball","Price":35.9900,"Quantity":80,"ValidFrom":"2015-05-07T03:39:52","ValidTo":"2015-08-07T03:40:01"},{"ProductID":17,"Name":"BB Ball Bearing","Price":75.0000,"Quantity":20,"ValidFrom":"2015-05-07T03:39:52","ValidTo":"2015-08-07T03:40:01"},{"ProductID":18,"Name":"Blade","Color":"Silver","Price":20.9900,"Quantity":70,"ValidFrom":"2015-05-07T03:40:01","ValidTo":"2015-08-07T03:40:01"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":89.9900,"Quantity":80,"ValidFrom":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":16,"Name":"Bearing Ball","Color":"Blue","Size":"62","Price":15.9900,"Quantity":120,"ValidFrom":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":25.1900,"Quantity":65,"ValidFrom":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":18,"Name":"Blade","Color":"Silver","Size":"62","Price":20.9900,"Quantity":80,"ValidFrom":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":18,"Name":"Blade","Color":"Silver","Size":"62","Price":20.1500,"Quantity":95,"ValidFrom":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":37.9900,"Quantity":90,"ValidFrom":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":16,"Name":"Bearing Ball","Color":"Blue","Size":"62","Price":45.9900,"Quantity":110,"ValidFrom":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":105.9900,"Quantity":100,"ValidFrom":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":26,"Name":"Road-250 Black, 48","Color":"Black","Size":"48","Price":1250.9900,"Quantity":90,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":25,"Name":"Mountain-100 Silver, 38","Color":"Silver","Size":"38","Price":799.9900,"Quantity":90,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":24,"Name":"Road-650 Black, 52","Color":"Black","Size":"52","Price":529.9900,"Quantity":90,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":23,"Name":"Long-Sleeve Logo Jersey, XL","Color":"Multi","Size":"XL","Price":49.9900,"Quantity":90,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":22,"Name":"Mountain Bike Socks, L","Color":"White","Size":"L","Price":19.9900,"Quantity":90,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":21,"Name":"Mountain Bike Socks, M","Color":"White","Size":"M","Price":9.5000,"Quantity":90,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":20,"Name":"Sport-100 Helmet, Black","Color":"Black","Price":45.9900,"Quantity":10,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":19,"Name":"Sport-100 Helmet, Red","Color":"Red","Price":34.9900,"Quantity":10,"ValidFrom":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":32.9900,"Quantity":75,"ValidFrom":"2016-02-10T21:19:20","ValidTo":"2016-02-11T21:15:48"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":100.0000,"Quantity":75,"ValidFrom":"2016-02-11T21:15:48","ValidTo":"2016-02-11T21:24:12"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":120.0000,"Quantity":75,"ValidFrom":"2016-02-11T21:24:12","ValidTo":"2016-02-11T21:27:32"}]';
INSERT INTO History.Product(ProductID, Name, Color, Size, Price, Quantity, ValidFrom, ValidTo)
SELECT ProductID, Name, Color, Size, Price, Quantity, ValidFrom, ValidTo
FROM OPENJSON (@products) WITH(
	ProductID int,
	Name nvarchar(50),
	Color nvarchar(15),
	Size nvarchar(5),
	Price money,
	Quantity int,
	ValidFrom datetime2(0),
	ValidTo datetime2(0)
)
GO

ALTER TABLE Product
	ADD PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)

ALTER TABLE Product
	SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.Product))

GO

create function dbo.diff_Product (@id int, @date datetime2(0))
returns table
as
return (
	select v1.[key] as [Column], v1.value as v1, v2.value as v2
	from OPENJSON(
			(select * from Product where ProductID = @id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) v1
		join OPENJSON(
			(select * from Product for system_time as of @date where ProductID = @id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) v2
		on v1.[key] = v2.[key]
	where v1.value <> v2.value
)
GO

create procedure dbo.GetProducts as
begin

	select * from Product
		left join Product FOR SYSTEM_TIME ALL as ProductHistory
			on Product.ProductID = ProductHistory.ProductID
			and Product.ValidFrom <> ProductHistory.ValidFrom
	order by Product.ProductID asc, ProductHistory.ValidFrom desc
	FOR JSON AUTO, ROOT('data')

end
GO

create procedure dbo.GetProductsAsOf (@date datetime2) as
begin

	select * from Product FOR SYSTEM_TIME AS OF @date
		outer apply dbo.diff_Product(Product.ProductID, @date) as ProductDifferences
	order by Product.ProductID asc
	FOR JSON AUTO, ROOT('data')

end
GO

create procedure dbo.RestoreProduct (@productid int, @date datetime2) as
begin

	with restored as (
		select ProductID, Name, Color, Size, Price, Quantity
		from Product FOR SYSTEM_TIME AS OF @date
		where ProductID = @productid)
	update Product set
			Name = restored.Name,
			Color = restored.Color,
			Size = restored.Size,
			Price = restored.Price,
			Quantity = restored.Quantity
	from Product join restored on Product.ProductID = restored.productid
	where Product.ProductID = @productid

end
GO