DROP PROCEDURE IF EXISTS xtp.InsertProductFromJson
GO
DROP PROCEDURE IF EXISTS xtp.UpdateProductFromJson
GO
DROP TABLE IF EXISTS xtp.Product;
GO
DROP SCHEMA IF EXISTS xtp;
GO

CREATE SCHEMA xtp;
GO

CREATE TABLE xtp.Product (
	ProductID int IDENTITY PRIMARY KEY NONCLUSTERED,
	Name nvarchar(50) NOT NULL,
	Color nvarchar(15) NULL,
	Size nvarchar(5) NULL,
	Price money NOT NULL,
	Quantity int NULL,
	CompanyID int,
	Data nvarchar(4000),
	Tags nvarchar(4000),
	DateModified datetime2(0) NOT NULL DEFAULT (GETUTCDATE())
) WITH (MEMORY_OPTIMIZED=ON)
GO

DECLARE @products NVARCHAR(MAX) =
N'[{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":100.0000,"Quantity":75,"CompanyID":1,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2016-02-11T21:27:32"},{"ProductID":16,"Name":"Bearing Ball","Color":"Magenta","Size":"62","Price":15.9900,"Quantity":90,"CompanyID":2,"Data":{"ManufacturingCost":11.672700,"Type":"Part","MadeIn":"China"},"Tags":["promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":28.9900,"Quantity":80,"CompanyID":3,"Data":{"ManufacturingCost":21.162700,"Type":"Part","MadeIn":"China"},"DateModified":"2016-02-11T21:27:32"},{"ProductID":18,"Name":"Blade","Color":"Magenta","Size":"62","Price":18.0000,"Quantity":45,"CompanyID":4,"Data":{},"Tags":["new"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":19,"Name":"Sport-100 Helmet, Red","Color":"Red","Size":"72","Price":41.9900,"Quantity":38,"CompanyID":3,"Data":{"ManufacturingCost":30.652700,"Type":"Еquipment","MadeIn":"China"},"Tags":["promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":20,"Name":"Sport-100 Helmet, Black","Color":"Black","Size":"72","Price":31.4900,"Quantity":60,"CompanyID":1,"Data":{"ManufacturingCost":22.987700,"Type":"Еquipment","MadeIn":"China"},"Tags":["new","promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":21,"Name":"Mountain Bike Socks, M","Color":"White","Size":"M","Price":560.9900,"Quantity":30,"CompanyID":2,"Data":{"Type":"Clothes"},"Tags":["sales","promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":22,"Name":"Mountain Bike Socks, L","Color":"White","Size":"L","Price":120.9900,"Quantity":20,"CompanyID":3,"Data":{"ManufacturingCost":88.322700,"Type":"Clothes"},"Tags":["sales","promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":23,"Name":"Long-Sleeve Logo Jersey, XL","Color":"Multi","Size":"XL","Price":44.9900,"Quantity":60,"CompanyID":4,"Data":{"ManufacturingCost":32.842700,"Type":"Clothes"},"Tags":["sales","promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":24,"Name":"Road-650 Black, 52","Color":"Black","Size":"52","Price":704.6900,"Quantity":70,"CompanyID":5,"Data":{"Type":"Bike","MadeIn":"UK"},"DateModified":"2016-02-11T21:27:32"},{"ProductID":25,"Name":"Mountain-100 Silver, 38","Color":"Silver","Size":"38","Price":359.9900,"Quantity":45,"CompanyID":1,"Data":{"ManufacturingCost":262.792700,"Type":"Bike","MadeIn":"UK"},"Tags":["promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":26,"Name":"Road-250 Black, 48","Color":"Black","Size":"48","Price":299.0200,"Quantity":25,"CompanyID":2,"Data":{"ManufacturingCost":218.284600,"Type":"Bike","MadeIn":"UK"},"Tags":["new","promo"],"DateModified":"2016-02-11T21:27:32"},{"ProductID":27,"Name":"ML Bottom Bracket","Price":101.2400,"Quantity":50,"CompanyID":3,"Data":{"Type":"Part","MadeIn":"China"},"DateModified":"2016-02-11T21:27:32"},{"ProductID":28,"Name":"HL Bottom Bracket","Price":121.4900,"Quantity":65,"CompanyID":4,"Data":{"ManufacturingCost":88.687700,"Type":"Part","MadeIn":"China"},"DateModified":"2016-02-11T21:27:32"}]'
INSERT INTO xtp.Product (Name, Color, Size, Price, Quantity, CompanyID, Data, Tags, DateModified)
SELECT Name, Color, Size, Price, Quantity, CompanyID, Data, Tags, DateModified
FROM OPENJSON (@products) WITH(
	Name nvarchar(50),Color nvarchar(15),Size nvarchar(5),Price money,Quantity int,CompanyID int,
	Data nvarchar(MAX) AS JSON,Tags nvarchar(MAX) AS JSON,
	DateModified datetime2(0)
)
GO

CREATE PROCEDURE xtp.InsertProductFromJson(@ProductJson NVARCHAR(MAX))
WITH SCHEMABINDING, NATIVE_COMPILATION
AS BEGIN
	ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')
	INSERT INTO xtp.Product(Name,Color,Size,Price,Quantity,CompanyID,Data,Tags)
	OUTPUT  INSERTED.ProductID
	SELECT Name,Color,Size,Price,Quantity,CompanyID,Data,Tags
	FROM OPENJSON(@ProductJson)
		WITH (	Name nvarchar(100) N'strict $."Name"',
			Color nvarchar(30),
			Size nvarchar(10),
			Price money N'strict $."Price"',
			Quantity int,
			CompanyID int,
			Data nvarchar(max) AS JSON,
			Tags nvarchar(max) AS JSON) as json
END
GO

CREATE PROCEDURE xtp.UpdateProductFromJson(@ProductID int, @ProductJson NVARCHAR(MAX))
AS BEGIN

	UPDATE xtp.Product SET
		Name = json.Name,
		Color = json.Color,
		Size = json.Size,
		Price = json.Price,
		Quantity = json.Quantity,
		Data = ISNULL(json.Data, xtp.Product.Data),
		Tags = ISNULL(json.Tags, xtp.Product.Tags)
	FROM OPENJSON(@ProductJson)
		WITH (	Name nvarchar(100) N'strict $."Name"',
			Color nvarchar(30),
			Size nvarchar(10),
			Price money N'strict $."Price"',
			Quantity int,
			Data nvarchar(max) AS JSON,
			Tags nvarchar(max) AS JSON) as json
	WHERE xtp.Product.ProductID = @ProductID

END
GO
