declare @verbose int = 0; -- change to 1 to get more verbose comparison;

declare @source xml = '<place source XML result here>';
declare @target xml = '<place target XML result here>';

with
src as(
select property = x.v.value('name[1]', 'nvarchar(300)'),
		value = x.v.value('value[1]', 'nvarchar(300)')
from @source.nodes('//row') x(v)
UNION ALL
select property = 'DB-CONFIG:'+y.v.value('local-name(.)', 'nvarchar(300)'),
		value = y.v.value('.[1]', 'nvarchar(300)')
from @source.nodes('//db') x(v)
cross apply x.v.nodes('*') y(v)
UNION ALL
select property = 'TEMPDB:'+y.v.value('local-name(.)', 'nvarchar(300)'),
		value = y.v.value('.[1]', 'nvarchar(300)')
from @source.nodes('//tempdb') x(v)
cross apply x.v.nodes('*') y(v)
UNION ALL
select property = 'INSTANCE:'+y.v.value('local-name(.)', 'nvarchar(300)'),
		value = y.v.value('.[1]', 'nvarchar(300)')
from @source.nodes('//instance') x(v)
cross apply x.v.nodes('*') y(v)
),
tgt as(
select property = x.v.value('name[1]', 'nvarchar(300)'),
		value = x.v.value('value[1]', 'nvarchar(300)')
from @target.nodes('//row') x(v)
UNION ALL
select property = 'DB-CONFIG:'+y.v.value('local-name(.)', 'nvarchar(300)'),
		value = y.v.value('.[1]', 'nvarchar(300)')
from @target.nodes('//db') x(v)
cross apply x.v.nodes('*') y(v)
UNION ALL
select property = 'TEMPDB:'+y.v.value('local-name(.)', 'nvarchar(300)'),
		value = y.v.value('.[1]', 'nvarchar(300)')
from @target.nodes('//tempdb') x(v)
cross apply x.v.nodes('*') y(v)
UNION ALL
select property = 'INSTANCE:'+y.v.value('local-name(.)', 'nvarchar(300)'),
		value = y.v.value('.[1]', 'nvarchar(300)')
from @target.nodes('//instance') x(v)
cross apply x.v.nodes('*') y(v)
),
diff as (
select property = isnull(src.property, tgt.property),
		source = src.value, target = tgt.value,
		is_missing = (case when src.value is null or tgt.value is null then 1 else 0 end)
from src full outer join tgt on src.property = tgt.property
where (src.value <> tgt.value
or src.value is null and tgt.value is not null
or src.value is not null and tgt.value is null)
)
select property, source, [target]
from diff
where is_missing = 0 or @verbose = 1 -- in the earlier versions you had to comment out this line. Now just set the value of the flag up
order by property

