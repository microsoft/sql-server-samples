--Combine standard columns with JSON columns.
select Name,Color,Size,Price,Quantity,Data,Tags
from Product

/* Basic Demo */


-- Get List of products
select ProductID, Name,Color,Size,Price,Quantity,
		JSON_VALUE(Data, '$.MadeIn') as MadeIn,
		JSON_QUERY(Tags) as Tags
from Product
FOR JSON PATH

-- Get Product details
select Name,Color,Size,Price,Quantity
from Product
where ProductID = 17
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER

-- Insert new product
declare @p nvarchar(4000) =
N'{"Name":"NEW","Color":"Magenta","Size":"62",
   "Price":28.9900,"Quantity":80}'
EXEC dbo.InsertProductFromJson @p

-- Update product
declare @p nvarchar(4000) =
N'{"Name":"HL Bottom Bracket","Price":121.4900,"Quantity":65}'

EXEC dbo.UpdateProductFromJson 28, @p

/* End Basic Demo */

/* Detailed Demo */

--Use JSON Data in queries
select ProductID, Name, Color, Size, Price, Quantity, Data, Tags,
		JSON_VALUE(Data, '$.MadeIn') as MadeIn
from Product
where JSON_VALUE(Data, '$.Type') = 'part'

--Use JSON data in any part of query
select JSON_VALUE(Data, '$.Type') as Type, Color,
		AVG( cast(JSON_VALUE(Data, '$.ManufacturingCost') as float) ) as Cost
from Product
group by JSON_VALUE(Data, '$.Type'), Color
having JSON_VALUE(Data, '$.Type') is not null
order by JSON_VALUE(Data, '$.Type')

--Update JSON Data
--Current values in row:
select Data,Tags
from Product
where ProductID = 16

--Update values in JSON columns:
update Product set
	Data = JSON_MODIFY(Data, '$.ManufacturingCost', 10),
	Tags = JSON_MODIFY(Tags, 'append $', 'new')
where ProductID = 16

--Verify changes.
select Data,Tags
from Product
where ProductID = 16

GO

--Convert JSON object to row.
declare @product nvarchar(4000) =
N'{"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":28.9900,"Quantity":80}'

SELECT *
FROM OPENJSON (@product)
	WITH (Name nvarchar(50),Color nvarchar(15),Size nvarchar(5),Price money,Quantity int)

GO

--Convert JSON array to set of rows.
DECLARE @products NVARCHAR(4000) =
N'[
{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":100.0000,"Quantity":75,"Data":{"Type":"Part","MadeIn":"China"}},
{"ProductID":16,"Name":"Bearing Ball","Color":"Magenta","Size":"62","Price":15.9900,"Quantity":90,"Data":{"ManufacturingCost":11.672700,"Type":"Part","MadeIn":"China"},"Tags":["promo"]},
{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":28.9900,"Quantity":80,"Data":{"ManufacturingCost":21.162700,"Type":"Part","MadeIn":"China"}},
{"ProductID":18,"Name":"Blade","Color":"Magenta","Size":"62","Price":18.0000,"Quantity":45,"Data":{},"Tags":["new"]},
{"ProductID":19,"Name":"Sport-100 Helmet, Red","Color":"Red","Size":"72","Price":41.9900,"Quantity":38,"Data":{"ManufacturingCost":30.652700,"Type":"Еquipment","MadeIn":"China"},"Tags":["promo"]},
{"ProductID":20,"Name":"Sport-100 Helmet, Black","Color":"Black","Size":"72","Price":31.4900,"Quantity":60,"Data":{"ManufacturingCost":22.987700,"Type":"Еquipment","MadeIn":"China"},"Tags":["new","promo"]}
]'

SELECT *
FROM OPENJSON (@products)
	WITH (	Name nvarchar(50),Color nvarchar(15),Size nvarchar(5),Price money,Quantity int,
			Type nvarchar(20) '$.Data.Type',
			Data nvarchar(max) AS JSON)

GO

--Query and analyze JSON array.
DECLARE @products NVARCHAR(MAX) =
N'[{"ProductID":15,"Name":"Adjustable Race","Color":"Magenta","Size":"62","Price":100.0000,"Quantity":75,"Data":{"Type":"Part","MadeIn":"China"}},{"ProductID":16,"Name":"Bearing Ball","Color":"Magenta","Size":"62","Price":15.9900,"Quantity":90,"Data":{"ManufacturingCost":11.672700,"Type":"Part","MadeIn":"China"},"Tags":["promo"]},{"ProductID":17,"Name":"BB Ball Bearing","Color":"Magenta","Size":"62","Price":28.9900,"Quantity":80,"Data":{"ManufacturingCost":21.162700,"Type":"Part","MadeIn":"China"}},{"ProductID":18,"Name":"Blade","Color":"Magenta","Size":"62","Price":18.0000,"Quantity":45,"Data":{},"Tags":["new"]},{"ProductID":19,"Name":"Sport-100 Helmet, Red","Color":"Red","Size":"72","Price":41.9900,"Quantity":38,"Data":{"ManufacturingCost":30.652700,"Type":"Еquipment","MadeIn":"China"},"Tags":["promo"]},{"ProductID":20,"Name":"Sport-100 Helmet, Black","Color":"Black","Size":"72","Price":31.4900,"Quantity":60,"Data":{"ManufacturingCost":22.987700,"Type":"Еquipment","MadeIn":"China"},"Tags":["new","promo"]},{"ProductID":21,"Name":"Mountain Bike Socks, M","Color":"White","Size":"M","Price":560.9900,"Quantity":30,"Data":{"Type":"Clothes"},"Tags":["sales","promo"]},{"ProductID":22,"Name":"Mountain Bike Socks, L","Color":"White","Size":"L","Price":120.9900,"Quantity":20,"Data":{"ManufacturingCost":88.322700,"Type":"Clothes"},"Tags":["sales","promo"]},{"ProductID":23,"Name":"Long-Sleeve Logo Jersey, XL","Color":"Multi","Size":"XL","Price":44.9900,"Quantity":60,"Data":{"ManufacturingCost":32.842700,"Type":"Clothes"},"Tags":["sales","promo"]},{"ProductID":24,"Name":"Road-650 Black, 52","Color":"Black","Size":"52","Price":704.6900,"Quantity":70,"Data":{"Type":"Bike","MadeIn":"UK"}},{"ProductID":25,"Name":"Mountain-100 Silver, 38","Color":"Silver","Size":"38","Price":359.9900,"Quantity":45,"Data":{"ManufacturingCost":262.792700,"Type":"Bike","MadeIn":"UK"},"Tags":["promo"]},{"ProductID":26,"Name":"Road-250 Black, 48","Color":"Black","Size":"48","Price":299.0200,"Quantity":25,"Data":{"ManufacturingCost":218.284600,"Type":"Bike","MadeIn":"UK"},"Tags":["new","promo"]},{"ProductID":27,"Name":"ML Bottom Bracket","Price":101.2400,"Quantity":50,"Data":{"Type":"Part","MadeIn":"China"}},{"ProductID":28,"Name":"HL Bottom Bracket","Price":121.4900,"Quantity":65,"Data":{"ManufacturingCost":88.687700,"Type":"Part","MadeIn":"China"}}]'

SELECT ISNULL(Color, 'N/A') Color, AVG(Price) AvgPrice, MIN(Quantity) MinQuantity
FROM OPENJSON (@products)
	WITH (Name nvarchar(50),Color nvarchar(15),Size nvarchar(5),Price money,Quantity int)
group by Color
having MIN(Quantity) > 10
order by Color

GO

--Find rows that contain some value in JSON array.
select ProductID, Name, Color, Size, Price, Quantity, Tags
from Product
	 CROSS APPLY OPENJSON(Tags)
where value = 'promo'

GO

--Format query results as JSON (with error).
select Name,Color,Size,Price,Quantity,Data,Tags
from Product
FOR JSON PATH

--Format query results as JSON.
select Name,Color,Size,Price,Quantity,JSON_QUERY(Data) as Data, JSON_QUERY(Tags) as Tags
from Product
FOR JSON PATH

--Export single row as JSON.
select Name,Color,Size,Price,Quantity,JSON_QUERY(Data) as Data, JSON_QUERY(Tags) as Tags
from Product
where ProductID = 17
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER