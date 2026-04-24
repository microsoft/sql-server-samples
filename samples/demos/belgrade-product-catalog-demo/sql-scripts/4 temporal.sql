--Note: Run setup.sql script to create ProductCatalog database.
USE ProductCatalog
GO

-- Find the time when the first product(s) were inserted.
select min(DateModified) from History.Product;

--List of current products.
select ProductID, Name, Color, Size, Price, Quantity
from Product;

--Go back in time and show the list of products.
select ProductID, Name, Color, Size, Price, Quantity
from Product FOR SYSTEM_TIME AS OF '2015-07-28 13:20:00';

--Show the difference between current version of the product with ID 17 and version that existed in past.
select *
from dbo.diff_Product(17, '2015-07-28 13:20:00');

--Return full history of changes for product with ID 17.
select ProductID, Name, Color, Size, Price, Quantity, DateModified, ValidTo
from Product FOR SYSTEM_TIME ALL
where productid = 17
order by DateModified desc;

--Update product with ID 17.
update Product
set Color = 'Silver'
where productid = 17;

--Verify that color is changed to 'Silver'.
select ProductID, Name, Color, Size, Price, Quantity, DateModified, ValidTo
from Product
where productid = 17;

--Return history of the product. You should see one additional row in history.
select ProductID, Name, Color, Size, Price, Quantity, DateModified, ValidTo
from Product FOR SYSTEM_TIME ALL
where productid = 17
order by DateModified desc;

--Restore product. Overwrite the latest version with the verison that was valid last year.
exec RestoreProduct 17, '2015-11-07 03:40:09';

--Return history of the product with id 17 and verify that it current version and '2015-11-07 03:40:09' version are identical.
select ProductID, Name, Color, Size, Price, Quantity, DateModified, ValidTo
from Product FOR SYSTEM_TIME ALL
where productid = 17
order by DateModified desc;

-- Identify "spikes" in product price changes.
with history as (

	select ProductID, Name, Price, DateModified,
			LAG (Price, 1) over (partition by ProductID order by DateModified) as PrevPrice,
			LEAD (Price, 1) over (partition by ProductID order by DateModified) as NextPrice
	 from dbo.Product for system_time all

)
select DateModified, ProductID, Name, PrevPrice, Price,  NextPrice
from history
where PrevPrice = NextPrice
	AND ABS(NextPrice - Price)/NextPrice >=0.1

