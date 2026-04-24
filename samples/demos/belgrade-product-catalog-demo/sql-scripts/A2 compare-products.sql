select * from Product where ProductID = 17
--FOR JSON PATH, WITHOUT_ARRAY_WRAPPER

select [key] as [Column], value
from OPENJSON(
		(select * from Product where ProductID = 17
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER))


select [key] as [Column], value
from OPENJSON(
		(select * from Product FOR SYSTEM_TIME AS OF '2015-07-28 13:20:00'
		where ProductID = 17
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER))


select v1.[key] as [Column], v1.value as v1, v2.value as v2
from OPENJSON(
		(select * from Product where ProductID = 17 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) v1
	join OPENJSON(
		(select * from Product for system_time as of '2015-07-28 13:20:00' where ProductID = 17 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) v2
	on v1.[key] = v2.[key]
where v1.value <> v2.value