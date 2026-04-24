DROP TABLE IF EXISTS History.Product
GO
DROP SCHEMA IF EXISTS History
GO
CREATE SCHEMA History
GO

CREATE TABLE History.Product(
	ProductID int NOT NULL,
	Name nvarchar(50) NOT NULL,
	Color nvarchar(15) NULL,
	Size nvarchar(5) NULL,
	Price money NOT NULL,
	Quantity int NULL,
	CompanyID int,
	Data nvarchar(4000),
	Tags nvarchar(4000),
	DateModified datetime2(0) NOT NULL,
	ValidTo datetime2(0) NOT NULL
)


DECLARE @products NVARCHAR(MAX) =
N'[{"ProductID":15,"Name":"Adjustable Race","Price":75.9900,"Quantity":50,"CompanyID":1,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2015-05-07T03:39:52","ValidTo":"2015-08-07T03:40:01"},{"ProductID":16,"Name":"Bearing Ball","Price":35.9900,"Quantity":80,"CompanyID":2,"Data":{"ManufacturingCost":11.672700,"Type":"Part","MadeIn":"China"},"Tags":["promo"],"DateModified":"2015-05-07T03:39:52","ValidTo":"2015-08-07T03:40:01"},{"ProductID":17,"Name":"BB Ball Bearing","Price":75.0000,"Quantity":20,"CompanyID":3,"Data":{"ManufacturingCost":21.162700,"Type":"Part","MadeIn":"China"},"DateModified":"2015-05-07T03:39:52","ValidTo":"2015-08-07T03:40:01"},{"ProductID":18,"Name":"Blade","Color":"Silver","Price":20.9900,"Quantity":70,"CompanyID":1,"Data":{},"Tags":["new"],"DateModified":"2015-05-07T03:40:01","ValidTo":"2015-08-07T03:40:01"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":89.9900,"Quantity":80,"CompanyID":1,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":16,"Name":"Bearing Ball","Color":"Blue","Size":"62","Price":15.9900,"Quantity":120,"CompanyID":2,"Data":{"ManufacturingCost":11.672700,"Type":"Part","MadeIn":"China"},"Tags":["promo"],"DateModified":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":25.1900,"Quantity":65,"CompanyID":3,"Data":{"ManufacturingCost":21.162700,"Type":"Part","MadeIn":"China"},"DateModified":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":18,"Name":"Blade","Color":"Silver","Size":"62","Price":20.9900,"Quantity":80,"CompanyID":1,"Data":{},"Tags":["new"],"DateModified":"2015-08-07T03:40:01","ValidTo":"2015-11-07T03:40:09"},{"ProductID":18,"Name":"Blade","Color":"Silver","Size":"62","Price":20.1500,"Quantity":95,"CompanyID":1,"Data":{},"Tags":["new"],"DateModified":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":37.9900,"Quantity":90,"CompanyID":3,"Data":{"ManufacturingCost":21.162700,"Type":"Part","MadeIn":"China"},"DateModified":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":16,"Name":"Bearing Ball","Color":"Blue","Size":"62","Price":0.0000,"Quantity":110,"CompanyID":2,"Data":{"ManufacturingCost":11.672700,"Type":"Part","MadeIn":"China"},"Tags":["promo"],"DateModified":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":105.9900,"Quantity":100,"CompanyID":1,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2015-11-07T03:40:09","ValidTo":"2016-02-07T03:40:15"},{"ProductID":26,"Name":"Road-250 Black, 48","Color":"Black","Size":"48","Price":1250.9900,"Quantity":90,"CompanyID":2,"Data":{"ManufacturingCost":218.284600,"Type":"Bike","MadeIn":"UK"},"Tags":["new","promo"],"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":25,"Name":"Mountain-100 Silver, 38","Color":"Silver","Size":"38","Price":799.9900,"Quantity":90,"CompanyID":1,"Data":{"ManufacturingCost":262.792700,"Type":"Bike","MadeIn":"UK"},"Tags":["promo"],"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":24,"Name":"Road-650 Black, 52","Color":"Black","Size":"52","Price":529.9900,"Quantity":90,"CompanyID":1,"Data":{"Type":"Bike","MadeIn":"UK"},"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":23,"Name":"Long-Sleeve Logo Jersey, XL","Color":"Multi","Size":"XL","Price":49.9900,"Quantity":90,"CompanyID":1,"Data":{"ManufacturingCost":32.842700,"Type":"Clothes"},"Tags":["sales","promo"],"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":22,"Name":"Mountain Bike Socks, L","Color":"White","Size":"L","Price":19.9900,"Quantity":90,"CompanyID":3,"Data":{"ManufacturingCost":88.322700,"Type":"Clothes"},"Tags":["sales","promo"],"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":21,"Name":"Mountain Bike Socks, M","Color":"White","Size":"M","Price":9.5000,"Quantity":90,"CompanyID":2,"Data":{"Type":"Clothes"},"Tags":["sales","promo"],"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":20,"Name":"Sport-100 Helmet, Black","Color":"Black","Price":45.9900,"Quantity":10,"CompanyID":1,"Data":{"ManufacturingCost":22.987700,"Type":"Еquipment","MadeIn":"China"},"Tags":["new","promo"],"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":19,"Name":"Sport-100 Helmet, Red","Color":"Red","Price":34.9900,"Quantity":10,"CompanyID":3,"Data":{"ManufacturingCost":30.652700,"Type":"Еquipment","MadeIn":"China"},"Tags":["promo"],"DateModified":"2015-12-28T03:40:15","ValidTo":"2016-02-07T03:40:15"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":32.9900,"Quantity":75,"CompanyID":1,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2016-02-10T21:19:20","ValidTo":"2016-02-11T21:15:48"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":100.0000,"Quantity":75,"CompanyID":1,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2016-02-11T21:15:48","ValidTo":"2016-02-11T21:24:12"},{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":120.0000,"Quantity":75,"CompanyID":1,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2016-02-11T21:24:12","ValidTo":"2016-02-11T21:27:32"}]';
INSERT INTO History.Product(ProductID, Name, Color, Size, Price, Quantity, CompanyID, Data, Tags, DateModified, ValidTo)
SELECT ProductID, Name, Color, Size, Price, Quantity, CompanyID, Data, Tags, DateModified, ValidTo
FROM OPENJSON (@products) WITH(
	ProductID int, Name nvarchar(50),Color nvarchar(15),Size nvarchar(5),Price money,Quantity int,CompanyID int,
	Data nvarchar(MAX) AS JSON,Tags nvarchar(MAX) AS JSON,
	DateModified datetime2(0),ValidTo datetime2(0)
)
GO


ALTER TABLE Product
	DROP COLUMN IF EXISTS ValidTo

ALTER TABLE Product
	ADD ValidTo datetime2(0) NOT NULL
		CONSTRAINT Product_ValidTo_EndTime DEFAULT ('9999-12-31 23:59:59')

GO

ALTER TABLE Product
	ADD PERIOD FOR SYSTEM_TIME (DateModified, ValidTo)

GO

ALTER TABLE Product
	SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.Product))

GO

drop function if exists dbo.diff_Product
go
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


drop procedure if exists dbo.GetProducts
go
create procedure dbo.GetProducts as
begin

	select Product.ProductID, Product.Name, Product.Color, Product.Price, Product.Quantity,
			JSON_VALUE(Product.Data, '$.MadeIn') as MadeIn, JSON_QUERY(Product.Tags) as Tags,
			ProductHistory.*
	from Product
		left join History.Product as ProductHistory
			on Product.ProductID = ProductHistory.ProductID
	order by Product.ProductID asc, ProductHistory.DateModified desc
	FOR JSON AUTO, ROOT('data')

end
GO

drop procedure if exists dbo.GetProductsAsOf
go
create procedure dbo.GetProductsAsOf (@date datetime2) as
begin

	select Product.ProductID, Product.Name, Product.Color, Product.Price, Product.Quantity,
			JSON_VALUE(Product.Data, '$.MadeIn') as MadeIn, JSON_QUERY(Product.Tags) as Tags,
			Product.DateModified,
			ProductDifferences.*
	from Product FOR SYSTEM_TIME AS OF @date
		outer apply dbo.diff_Product(Product.ProductID, @date) as ProductDifferences
	order by Product.ProductID asc
	FOR JSON AUTO, ROOT('data')

end
GO

GO
drop procedure if exists dbo.RestoreProduct
GO
create procedure dbo.RestoreProduct (@productid int, @date datetime2) as
begin

	MERGE Product
	USING (
		select ProductID, Name, Color, Size, Price, Quantity, CompanyID, Tags, Data
		from Product FOR SYSTEM_TIME AS OF @date
		where ProductID = @productid)
		AS Restored (ProductID, Name, Color, Size, Price, Quantity, CompanyID, Tags, Data)
	ON (Product.ProductID = Restored.ProductID)
	WHEN MATCHED THEN
		update set
				Name = restored.Name,
				Color = restored.Color,
				Size = restored.Size,
				Price = restored.Price,
				Quantity = restored.Quantity,
				CompanyId = restored.CompanyID,
				Data = restored.Data,
				Tags = restored.Tags
	WHEN NOT MATCHED THEN
		insert (ProductID, Name, Color, Size, Price, Quantity, CompanyID, Data, Tags)
		values (ProductID, Name, Color, Size, Price, Quantity, CompanyID, Data, Tags);
end
GO