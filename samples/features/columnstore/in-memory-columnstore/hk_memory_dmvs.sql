USE MASTER

-- show memory DMVs
/*
SELECT name
FROM sys.system_objects
WHERE name LIKE '%xtp%memory%'
 ORDER BY name
 */


 select committed_kb, committed_target_kb
from sys.dm_os_sys_info

select pool_id,convert(char(30),  name) as Name, min_memory_percent, max_memory_percent, max_memory_kb/1024 as max_memory_in_MB, used_memory_kb/1024 as used_memory_in_MB,
target_memory_kb/1024 as target_memory_in_MB
from sys.dm_resource_governor_resource_pools


select convert(char(20), object_name(object_id)) as Name,*
from sys.dm_db_xtp_table_memory_stats
where object_id> 0

-- Memory in MB
select Sum( memory_allocated_for_indexes_kb + memory_allocated_for_table_kb)/1024 as
 memoryallocated_objects_in_mb,
 Sum( memory_used_by_indexes_kb + memory_used_by_table_kb)/1024 as
 memoryused_objects_in_mb
from sys.dm_db_xtp_table_memory_stats

-- consumer memory
select  convert(char(20), object_name(object_id)) as Name, *
from sys.dm_db_xtp_memory_consumers

select  sum(allocated_bytes)/(1024*1024) as total_allocated_MB, sum(used_bytes)/(1024*1024) as total_used_MB
from sys.dm_db_xtp_memory_consumers

select * from sys.dm_xtp_system_memory_consumers
select sum(allocated_bytes)/(1024*1024) as total_allocated_MB, sum(used_bytes)/(1024*1024) as total_used_MB
from sys.dm_xtp_system_memory_consumers


select type, name, memory_node_id, pages_kb/1024 as pages_MB
from sys.dm_os_memory_clerks
where type like '%xtp%'


select type, sum(pages_in_bytes/1024) as size_kb
from sys.dm_os_memory_objects
where type like '%xtp%'
group by type


select sum(pages_in_bytes)/(1024*1024) as pages_in_MB
from sys.dm_os_memory_objects where type like '%xtp%'
select *
from sys.dm_os_memory_objects where type like '%xtp%'


-- SUMS

select Sum( memory_allocated_for_indexes_kb + memory_allocated_for_table_kb)/1024 as
 memoryallocated_objects_in_mb,
 Sum( memory_used_by_indexes_kb + memory_used_by_table_kb)/1024 as
 memoryused_objects_in_mb
from sys.dm_db_xtp_table_memory_stats
select  sum(allocated_bytes)/(1024*1024) as total_allocated_MB, sum(used_bytes)/(1024*1024) as total_used_MB
from sys.dm_db_xtp_memory_consumers

select sum(allocated_bytes)/(1024*1024) as total_allocated_MB, sum(used_bytes)/(1024*1024) as total_used_MB
from sys.dm_xtp_system_memory_consumers
select type, name, memory_node_id, pages_kb/1024 as pages_MB
from sys.dm_os_memory_clerks
where type like '%xtp%'


select type, sum(pages_in_bytes/1024) as size_kb
from sys.dm_os_memory_objects
where type like '%xtp%'
group by type