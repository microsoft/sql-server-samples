USE master
GO

DROP DATABASE IF EXISTS ProductCatalog
GO

CREATE DATABASE ProductCatalog
GO

USE ProductCatalog
GO

DROP TABLE IF EXISTS Product
GO

CREATE TABLE Product (
	ProductID int IDENTITY PRIMARY KEY,
	Name nvarchar(50) NOT NULL,
	Color nvarchar(15) NULL,
	Size nvarchar(5) NULL,
	Price money NOT NULL,
	Quantity int NULL,
	Data nvarchar(4000),
	Tags nvarchar(4000)
)
GO

SET IDENTITY_INSERT Product ON
GO

DECLARE @products NVARCHAR(MAX) =
N'[{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":100.0000,"Quantity":75,"Data":{"Type":"Part","MadeIn":"China"}},{"ProductID":16,"Name":"Bearing Ball","Color":"Magenta","Size":"62","Price":15.9900,"Quantity":90,"Data":{"ManufacturingCost":11.672700,"Type":"Part","MadeIn":"China"},"Tags":["promo"]},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":28.9900,"Quantity":80,"Data":{"ManufacturingCost":21.162700,"Type":"Part","MadeIn":"China"}},{"ProductID":18,"Name":"Blade","Color":"Magenta","Size":"62","Price":18.0000,"Quantity":45,"Data":{},"Tags":["new"]},{"ProductID":19,"Name":"Sport-100 Helmet, Red","Color":"Red","Size":"72","Price":41.9900,"Quantity":38,"Data":{"ManufacturingCost":30.652700,"Type":"Еquipment","MadeIn":"China"},"Tags":["promo"]},{"ProductID":20,"Name":"Sport-100 Helmet, Black","Color":"Black","Size":"72","Price":31.4900,"Quantity":60,"Data":{"ManufacturingCost":22.987700,"Type":"Еquipment","MadeIn":"China"},"Tags":["new","promo"]},{"ProductID":21,"Name":"Mountain Bike Socks, M","Color":"White","Size":"M","Price":560.9900,"Quantity":30,"Data":{"Type":"Clothes"},"Tags":["sales","promo"]},{"ProductID":22,"Name":"Mountain Bike Socks, L","Color":"White","Size":"L","Price":120.9900,"Quantity":20,"Data":{"ManufacturingCost":88.322700,"Type":"Clothes"},"Tags":["sales","promo"]},{"ProductID":23,"Name":"Long-Sleeve Logo Jersey, XL","Color":"Multi","Size":"XL","Price":44.9900,"Quantity":60,"Data":{"ManufacturingCost":32.842700,"Type":"Clothes"},"Tags":["sales","promo"]},{"ProductID":24,"Name":"Road-650 Black, 52","Color":"Black","Size":"52","Price":704.6900,"Quantity":70,"Data":{"Type":"Bike","MadeIn":"UK"}},{"ProductID":25,"Name":"Mountain-100 Silver, 38","Color":"Silver","Size":"38","Price":359.9900,"Quantity":45,"Data":{"ManufacturingCost":262.792700,"Type":"Bike","MadeIn":"UK"},"Tags":["promo"]},{"ProductID":26,"Name":"Road-250 Black, 48","Color":"Black","Size":"48","Price":299.0200,"Quantity":25,"Data":{"ManufacturingCost":218.284600,"Type":"Bike","MadeIn":"UK"},"Tags":["new","promo"]},{"ProductID":27,"Name":"ML Bottom Bracket","Price":101.2400,"Quantity":50,"Data":{"Type":"Part","MadeIn":"China"}},{"ProductID":28,"Name":"HL Bottom Bracket","Price":121.4900,"Quantity":65,"Data":{"ManufacturingCost":88.687700,"Type":"Part","MadeIn":"China"}}]'
INSERT INTO Product (ProductID, Name, Color, Size, Price, Quantity, Data, Tags)
SELECT ProductID, Name, Color, Size, Price, Quantity, Data, Tags
FROM OPENJSON (@products) WITH(
	ProductID int,
	Name nvarchar(50),
	Color nvarchar(15),
	Size nvarchar(5),
	Price money,
	Quantity int,
	Data nvarchar(MAX) AS JSON,
	Tags nvarchar(MAX) AS JSON
)
GO

SET IDENTITY_INSERT Product OFF
GO

CREATE PROCEDURE dbo.InsertProductFromJson(@ProductJson NVARCHAR(MAX))
AS BEGIN

	INSERT INTO dbo.Product(Name,Color,Size,Price,Quantity,Data,Tags)
	OUTPUT  INSERTED.ProductID
	SELECT Name,Color,Size,Price,Quantity,Data,Tags
	FROM OPENJSON(@ProductJson)
		WITH (	Name nvarchar(100) N'strict $."Name"',
				Color nvarchar(30),
				Size nvarchar(10),
				Price money N'strict $."Price"',
				Quantity int,
				Data nvarchar(max) AS JSON,
				Tags nvarchar(max) AS JSON) as json
END
GO

CREATE PROCEDURE dbo.UpdateProductFromJson(@ProductID int, @ProductJson NVARCHAR(MAX))
AS BEGIN

	UPDATE dbo.Product SET
		Name = json.Name,
		Color = json.Color,
		Size = json.Size,
		Price = json.Price,
		Quantity = json.Quantity,
		Data = ISNULL(json.Data, dbo.Product.Data),
		Tags = ISNULL(json.Tags,dbo.Product.Tags)
	FROM OPENJSON(@ProductJson)
		WITH (	Name nvarchar(100) N'strict $."Name"',
				Color nvarchar(30),
				Size nvarchar(10),
				Price money N'strict $."Price"',
				Quantity int,
				Data nvarchar(max) AS JSON,
				Tags nvarchar(max) AS JSON) as json
	WHERE dbo.Product.ProductID = @ProductID

END
GO

CREATE PROCEDURE dbo.UpsertProductFromJson(@ProductID int, @ProductJson NVARCHAR(MAX))
AS BEGIN

	MERGE INTO dbo.Product
	USING ( SELECT Name,Color,Size,Price,Quantity,Data,Tags
			FROM OPENJSON(@ProductJson)
				WITH (
					Name nvarchar(100) N'strict $."Name"',
					Color nvarchar(30),
					Size nvarchar(10),
					Price money N'strict $."Price"',
					Quantity int,
					Data nvarchar(max) AS JSON,
					Tags nvarchar(max) AS JSON)) as json
	ON (dbo.Product.ProductID = @ProductID)
	WHEN MATCHED THEN
		UPDATE SET
			Name = json.Name,
			Color = json.Color,
			Size = json.Size,
			Price = json.Price,
			Quantity = json.Quantity,
			Data = json.Data,
			Tags = json.Tags
	WHEN NOT MATCHED THEN
		INSERT (Name,Color,Size,Price,Quantity,Data,Tags)
		VALUES (json.Name,json.Color,json.Size,json.Price,json.Quantity,json.Data,json.Tags);
END
GO