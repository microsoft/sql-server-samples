USE <database_name, , > --> put the database name here like WideWorldImporters

begin
declare @result NVARCHAR(MAX);
set @result = (select database_name = name, compatibility_level, recovery_model_desc, snapshot_isolation_state_desc, is_read_committed_snapshot_on,
					is_auto_update_stats_on, is_auto_update_stats_async_on, delayed_durability_desc,
					is_encrypted, is_auto_create_stats_incremental_on, is_arithabort_on, is_ansi_warnings_on, is_parameterization_forced
from sys.databases
where name = db_name()
for xml raw('db'), elements);
set @result += (select compatibility_level, snapshot_isolation_state_desc, is_read_committed_snapshot_on,
					is_auto_update_stats_on, is_auto_update_stats_async_on, delayed_durability_desc,
					is_encrypted, is_auto_create_stats_incremental_on, is_arithabort_on, is_ansi_warnings_on, is_parameterization_forced,
					number_of_files = (select count(*) from master.sys.master_files where database_id = db_id('tempdb'))
from sys.databases
where name = 'tempdb'
for xml raw('tempdb'), elements);
set @result += ISNULL((
select name = CONCAT('DB-CONFIG:',name), value
from sys.database_scoped_configurations
for xml raw, elements ),'');
declare @tf table (TraceFlag smallint, status bit,global bit, session bit)
insert into @tf execute('DBCC TRACESTATUS(-1)');
set @result += ISNULL((
select name=CONCAT('TF:',TraceFlag), value=status from @tf
where global=1 and session=0
and (TraceFlag in (8690 -- https://blogs.msdn.microsoft.com/psssql/2015/12/15/spool-operator-and-trace-flag-8690/
, 8744, 9347, 9349, 9471, 9476, 9488 -- Plan affecting TFs include others such as
, 9453, 9495 -- Execution related TFs
, 4199, 9481 /*force legacy CE*/, 2312 /* force default CE */
--https://kohera.be/blog/sql-server/trace-flags-sql-servers-transformer-like-tuning/
, 1118, 2371, 610, 1117, 8048, 1236, 8015, 834, 1224, 2335,
	-- Taking care of Query-Hint-Hell
4136, 8602, 8722, 8755,
-- random trace flags aka.ms/traceflags
634, 3459, 3468, 3505, 9495,
9347, 9349, 9389, 9398, 9453 -- batch mode related

)
or TraceFlag between 4100 and 4120
)
for xml raw, elements
),'');
set @result += (
select name = CONCAT('CONFIG:',name), value from sys.configurations
where name in ('cost threshold for parallelism','cursor threshold','fill factor (%)'
,'index create memory (KB)','lightweight pooling'
,'locks','max degree of parallelism','max full-text crawl range','max text repl size (B)'
,'max worker threads','min memory per query (KB)','nested triggers'
,'network packet size (B)','optimize for ad hoc workloads'
,'priority boost','query governor cost limit','query wait (s)','recovery interval (min)'
,'set working set size','user connections')
for xml raw, elements
);
set @result += (select name = 'version', value = @@VERSION for xml raw, elements)
set @result += (select name = 'script version', value = '1.0' for xml raw, elements)
set @result += (select name = 'date', value = GETUTCDATE() for xml raw, elements)

set @result += isnull
((SELECT scheduler_count, scheduler_total_count FROM sys.dm_os_sys_info
   for xml raw('instance'), elements),''
);

set @result +=
isnull((SELECT name = REPLACE([type], 'MEMORYCLERK_', 'MEMORY:')
     , value = CAST(sum(pages_kb)/1024.1/1024 AS NUMERIC(6,1))
   FROM sys.dm_os_memory_clerks
   GROUP BY type
   HAVING sum(pages_kb) /1024. /1024 > 1
   for xml raw, elements),'');

set @result +=
isnull((
	select name = 'INDEX:'+schema_name(schema_id)+'.'+object_name(t.object_id)+'.'+ix.name,
		value = concat(ix.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS,
		'/disabled:',is_disabled,'/row_locks:',allow_row_locks,'/page_locks:',allow_page_locks,'/filter:',filter_definition,'/compression_delay:',compression_delay)
	from sys.indexes ix
		join sys.tables t on t.object_id = ix.object_id
	where ix.type <> 0
for xml raw, elements),'');

set @result +=
isnull((
	select	name = 'JOB::'+j.name + '/' + s.step_name,
			value = subsystem
	from msdb.dbo.sysjobs j
		join msdb.dbo.sysjobsteps s on j.job_id = s.job_id
for xml raw, elements),'');


select cast(@result as xml);

end;
