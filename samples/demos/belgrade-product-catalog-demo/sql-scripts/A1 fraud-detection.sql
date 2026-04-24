USE ProductCatalogDemo
GO

with
history as (

	select ProductID, Name, Price, DateModified,
			LAG (Price, 1, 1) over (partition by ProductID order by DateModified) as PrevPrice,
			LEAD (Price, 1, 1) over (partition by ProductID order by DateModified) as NextPrice
	 from dbo.Product for system_time all
),
spikes as (

	select DateModified, ProductID, Name, PrevPrice, Price,  NextPrice
	from history
	where PrevPrice = NextPrice
	AND ABS(PrevPrice - Price)/PrevPrice >=0.5

),
logs as (

	SELECT Page, [User], Time, Origin
	FROM OPENROWSET(BULK N'c:\JSON\logANSI.txt',
					FORMATFILE = 'c:\\JSON\ldjfmt.txt',
					CODEPAGE = '65001') as log
	CROSS APPLY
		OPENJSON (log.log_entry)
			WITH ( Page varchar(30), [User] varchar(20),Time datetime2, Origin varchar(20))

)
select Page, [User], Time, Origin, PrevPrice, Price,  NextPrice
from logs JOIN spikes
	on ABS(DATEDIFF(second, Time, spikes.DateModified)) < 3000
order by Time
