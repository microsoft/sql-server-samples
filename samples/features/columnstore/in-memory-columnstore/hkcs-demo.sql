
USE [master]
GO

DROP DATABASE IF EXISTS [imoltp]
GO

CREATE DATABASE [imoltp]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'imoltp_data', FILENAME = N'C:\data\imoltp_Data.mdf' , SIZE = 102400KB , MAXSIZE = 5GB, FILEGROWTH = 1024000KB )
 LOG ON
( NAME = N'imoltp_log', FILENAME = N'C:\data\imoltp_Log.ldf ' , SIZE = 52400KB , MAXSIZE = 5GB , FILEGROWTH = 102400KB )
GO


ALTER DATABASE imoltp ADD FILEGROUP imoltp_mod CONTAINS MEMORY_OPTIMIZED_DATA
ALTER DATABASE imoltp ADD FILE (name='imoltp_mod', filename='c:\data\imoltp_mod') TO FILEGROUP imoltp_mod
GO


-- drop the database with
-- pool management
DROP RESOURCE POOL  Poolimoltp
go


ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- create the resoure pool
CREATE RESOURCE POOL Poolimoltp WITH (MAX_MEMORY_PERCENT = 80);
ALTER RESOURCE GOVERNOR RECONFIGURE;
go

-- bind the database to the pool
EXEC sp_xtp_bind_db_resource_pool 'imoltp', 'Poolimoltp'
go

-- take database offline/online to associate the pool
use master
go

alter database imoltp set offline WITH ROLLBACK IMMEDIATE
go
alter database imoltp set online
go


use imoltp
go

drop table if exists dbo.t_colstor_hk

-- create a memopt table
CREATE TABLE dbo.t_colstor_hk (
		accountkey			int not null,
		accountdescription	nvarchar (50),
		accounttype			nvarchar(50),
		unitsold		    int,
       CONSTRAINT [pk_t_colstor_hk] PRIMARY KEY NONCLUSTERED HASH (accountkey) WITH (BUCKET_COUNT = 10000000)--,
--	  index t_colstor_hk_cci clustered columnstore with (compression_delay=70)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
go

--you can add index after creating HK table (New in SQL 2016)
alter table t_colstor_hk add index t_colstor_hk_cci clustered columnstore with (compression_delay=0)

--this is not supported
-- alter table t_colstor_hk alter index t_colstor_hk_cci set compression_delay=60

--look at index definition
select name, index_id, type_desc, compression_delay from sys.indexes where object_id = object_id('t_colstor_hk')


set nocount on
go

set statistics time off
go

set statistics IO Off
go
--insert 4 million rows
declare @outerloop int = 0
declare @i int = 0
while (@outerloop < 4000000)
begin
	Select @i = 0

	begin tran
	while (@i < 2000)
	begin
			insert t_colstor_hk values (@i + @outerloop, 'test1', 'test2', @i)
			set @i += 1;
	end
	commit

	set @outerloop = @outerloop + @i
	set @i = 0
end

go
select count(*) from t_colstor_hk

-- look at the rowgroups
select object_name(object_id), index_id, row_group_id, delta_store_hobt_id, state_desc, total_rows, size_in_bytes, trim_reason, trim_reason_desc, transition_to_compressed_state_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('t_colstor_hk')

-- run spec proc to move rows from delta tail
-- The procedure takes two arguements: object_id and bit indicating whether migration policy should be evaluated.
-- If you set migration policy to 0, as above, migration happens regardless of policy (ie. whether or not data is cold).
declare @oid int = object_id('t_colstor_hk')
exec sp_memory_optimized_cs_migration @oid
go




set statistics time on
go


set transaction isolation level read committed

use imoltp
go


--compare the query performance
select avg (convert (bigint, unitsold))
from t_colstor_hk


select avg (convert (bigint, unitsold))
from t_colstor_hk with (index = [pk_t_colstor_hk])

