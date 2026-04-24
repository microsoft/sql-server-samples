create database columnstore
go

use columnstore
go

drop table staging
go

-- create staging table
 Create table staging (
	accountkey			int not null,
	accountdescription		nvarchar (50),
	accounttype			nvarchar(50),
	AccountCodeAlternatekey 	int)


set nocount ON
go

-- load data into staging table
 declare @loop int
 declare @accountdescription varchar(50)
 declare @accountkey int
 declare @accounttype varchar(50)
 declare @accountcode int


 select @loop = 0
 begin tran
	 while (@loop < 100000)
	 begin
		select @accountkey = @loop
		select @accountdescription = 'accountdesc ' + convert(varchar(20), @accountkey)
		select @accounttype = 'accounttype ' + convert(varchar(20), @accountkey)
		select @accountcode =  cast (rand()*10000000 as int)


		insert into  staging values (@accountkey, @accountdescription, @accounttype, @AccountCode)

		select @loop = @loop + 1
	 end
 commit


select count(*) from staging
go

drop table ncci_target, ncci_target_delay
go

dbcc tracestatus

create table ncci_target (
	accountkey			int not null,
	accountdescription		nvarchar (50),
	accounttype			nvarchar(50),
	AccountCodeAlternatekey 	int)

create clustered index idx_ci_ncci_target on  ncci_target (accountkey)
create nonclustered columnstore index idxncci_ncci_target on
		ncci_target (accountkey, accountdescription, accounttype, accountcodealternatekey)
		with (compression_delay= 0)



-- create another table with the delay of 30 seconds
create table ncci_target_delay (
	accountkey			int not null,
	accountdescription		nvarchar (50),
	accounttype			nvarchar(50),
	AccountCodeAlternatekey 	int)

create clustered index idx_ci_ncci_target_delay on  ncci_target_delay (accountkey)
create nonclustered columnstore index idxncci_ncci_target_delay on
		ncci_target_delay (accountkey, accountdescription, accounttype, accountcodealternatekey)
		with (compression_delay= 30)



--look at catalog view
select object_name(object_id),  name, type_desc, has_filter, compression_delay
from sys.indexes where object_id = object_id ('ncci_target') or object_id=object_id('ncci_target_delay')

--load data into NCCI
-- takes around 2 minute
insert into ncci_target select * from staging
insert into ncci_target_delay select * from staging
go 12


-- look at rowgroups
select object_name(object_id), *
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id ('ncci_target') or object_id=object_id('ncci_target_delay')

-- manual
alter index idxncci_ncci_target on ncci_target reorganize with (COMPRESS_ALL_ROW_GROUPS = ON)

-- Note, you can change compression delay just as a metadata operation
alter index idxncci_ncci_target on ncci_target set (compression_delay=30)

--++++++++++++++++++++++++++++++++++
-- Memory Optimized Table
--++++++++++++++++++++++++++

drop table dbo.t_colstor_hk

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
alter table t_colstor_hk add index t_colstor_hk_cci clustered columnstore with (compression_delay=60)

select object_name(object_id),  name, type_desc, has_filter, compression_delay
from sys.indexes where object_id = object_id ('t_colstor_hk')
