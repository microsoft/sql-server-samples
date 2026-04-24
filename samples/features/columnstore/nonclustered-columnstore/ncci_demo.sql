

use master
go

drop database if exists ncci
go



CREATE DATABASE [ncci]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'ncci_data', FILENAME = N'C:\data\ncci_Data.mdf' , SIZE = 102400KB , MAXSIZE = 5GB, FILEGROWTH = 1024000KB )
 LOG ON
( NAME = N'ncci_log', FILENAME = N'C:\data\ncci_Log.ldf ' , SIZE = 52400KB , MAXSIZE = 5GB , FILEGROWTH = 102400KB )
GO

use ncci
go

drop table if exists orders
go

-- create the table
create table orders (
	AccountKey			int not null,
	customername		nvarchar (50),
	OrderNumber			bigint,
	PurchasePrice		decimal (9,2),
	OrderStatus			smallint not NULL,
	OrderStatusDesc		nvarchar (50))

-- OrderStatusDesc
-- 0 => 'Order Started'
-- 1 => 'Order Closed'
-- 2 => 'Order Paid'
-- 3 => 'Order Fullfillment Wait'
-- 4 => 'Order Shipped'
-- 5 => 'Order Received'

create clustered index orders_ci on orders(OrderStatus)

set nocount on
go

set statistics time off
go
set statistics IO Off
go

-- insert into the main table load 3 million rows
-- took 55 seconds (IO bound)
declare @outerloop int = 0
declare @i int = 0
declare @purchaseprice decimal (9,2)
declare @customername nvarchar (50)
declare @accountkey int
declare @orderstatus smallint
declare @orderstatusdesc nvarchar(50)
declare @ordernumber bigint
while (@outerloop < 3000000)
begin
	Select @i = 0
	begin tran
	while (@i < 2000)
	begin
			set @ordernumber = @outerloop + @i
			set @purchaseprice = rand() * 1000.0
			set @accountkey = convert (int, RAND ()*1000)
			set @orderstatus = 5
			
			set @orderstatusdesc  =
			case @orderstatus
				WHEN 0 THEN  'Order Started'
				WHEN 1 THEN  'Order Closed'
				WHEN 2 THEN  'Order Paid'
				WHEN 3 THEN 'Order Fullfillment'
				WHEN 4 THEN  'Order Shipped'
				WHEN 5 THEN 'Order Received'
			END

			insert orders values (@accountkey,(convert(varchar(6), @accountkey) + 'firstname'),
								  @ordernumber, @purchaseprice, @orderstatus, @orderstatusdesc)
			set @i += 1;
	end
	commit

	set @outerloop = @outerloop + 2000
	set @i = 0
end
go

checkpoint
go

select count(*), OrderStatusDesc from orders group by OrderStatusDesc

--create NCCI (note, not including PK column)
-- took 14 secs
CREATE NONCLUSTERED COLUMNSTORE INDEX orders_ncci ON orders  (accountkey, customername, purchaseprice, orderstatus)

-- look at the rowgroups
select object_name(object_id), index_id, row_group_id, delta_store_hobt_id, state_desc, total_rows, trim_reason_desc, transition_to_compressed_state_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('orders')


-- set stats off
set statistics time off
go
set statistics IO Off
go

--insert additional 200k rows
declare @outerloop int = 3000000
declare @i int = 0
declare @purchaseprice decimal (9,2)
declare @customername nvarchar (50)
declare @accountkey int
declare @orderstatus smallint
declare @orderstatusdesc nvarchar(50)
declare @ordernumber bigint
while (@outerloop < 3200000)
begin
	Select @i = 0
	begin tran
	while (@i < 2000)
	begin
			set @ordernumber = @outerloop + @i
			set @purchaseprice = rand() * 1000.0
			set @accountkey = convert (int, RAND ()*1000)
			set @orderstatus = convert (smallint, RAND()*5)
			if (@orderstatus = 5) set @orderstatus = 4

			set @orderstatusdesc  =
			case @orderstatus
				WHEN 0 THEN  'Order Started'
				WHEN 1 THEN  'Order Closed'
				WHEN 2 THEN  'Order Paid'
				WHEN 3 THEN 'Order Fullfillment'
				WHEN 4 THEN  'Order Shipped'
				WHEN 5 THEN 'Order Received'
			END

			insert orders values (@accountkey,(convert(varchar(6), @accountkey) + 'firstname'),
								  @ordernumber, @purchaseprice, @orderstatus, @orderstatusdesc)
			set @i += 1;
	end
	commit

	set @outerloop = @outerloop + 2000
	set @i = 0
end
go



-- START the demo here
select count(*) from orders


-- look at the rowgroups
select object_name(object_id), index_id, row_group_id, delta_store_hobt_id, state_desc, total_rows, trim_reason_desc, transition_to_compressed_state_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('orders')


-- show the index columns
select * from sys.index_columns  where object_id = object_id('orders')

-- analytics query performance
set statistics time on
go

-- a complex query
select top 5 customername, sum (PurchasePrice), Avg (PurchasePrice)
from orders
where purchaseprice > 90.0 and OrderStatus=5
group by customername

 -- a complex query without NCCI
select top 5 customername, sum (PurchasePrice), Avg (PurchasePrice)
from orders
where purchaseprice > 90.0 and OrderStatus = 5
group by customername
option (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX)


--+++++++++++++++++++++++++
--CASE - Filtered Index
-- Create Filtered NCCI
-- ++++++++++++++++++++++++++
drop table if exists orders_filtered
go

-- create the table
create table orders_filtered (
	AccountKey			int not null,
	customername		nvarchar (50),
	OrderNumber			bigint,
	PurchasePrice		decimal (9,2),
	OrderStatus			smallint,
	OrderStatusDesc		nvarchar (50))

-- OrderStatusDesc
-- 0 => 'Order Started'
-- 1 => 'Order Closed'
-- 2 => 'Order Paid'
-- 3 => 'Order Fullfillment Wait'
-- 4 => 'Order Shipped'
-- 5 => 'Order Received'

create clustered index orders_ci on orders_filtered(OrderStatus)

set nocount on
go

set statistics time off
go
set statistics IO Off
go

-- insert into the main table load 3 million rows
declare @outerloop int = 0
declare @i int = 0
declare @purchaseprice decimal (9,2)
declare @customername nvarchar (50)
declare @accountkey int
declare @orderstatus smallint
declare @orderstatusdesc nvarchar(50)
declare @ordernumber bigint
while (@outerloop < 3000000)
begin
	Select @i = 0
	begin tran
		while (@i < 2000)
		begin
				set @ordernumber = @outerloop + @i
				set @purchaseprice = rand() * 1000.0
				set @accountkey = convert (int, RAND ()*1000000)
				set @orderstatus = 5
					
				set @orderstatusdesc  =
				case @orderstatus
					WHEN 0 THEN  'Order Started'
					WHEN 1 THEN  'Order Closed'
					WHEN 2 THEN  'Order Paid'
					WHEN 3 THEN 'Order Fullfillment'
					WHEN 4 THEN  'Order Shipped'
					WHEN 5 THEN 'Order Received'
				END

				insert orders_filtered values (@accountkey,(convert(varchar(6), @accountkey) + 'firstname'),
									  @ordernumber, @purchaseprice, @orderstatus, @orderstatusdesc)
				set @i += 1;
		end
	commit

	set @outerloop = @outerloop + 2000
	set @i = 0
end
go


CREATE NONCLUSTERED COLUMNSTORE INDEX orders_filtered_ncci
ON orders_filtered  (accountkey, customername, purchaseprice, orderstatus)
where orderstatus = 5

select * from sys.indexes where object_id=object_id('orders_filtered')

-- look at the rowgroups
select object_name(object_id), index_id, row_group_id, delta_store_hobt_id, state_desc, total_rows, trim_reason_desc, transition_to_compressed_state_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('orders_filtered')


select sum (total_rows)
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('orders_filtered')

-- set stats off
set statistics time off
go
set statistics IO Off
go


--insert additional 200k rows
declare @outerloop int = 3000000
declare @i int = 0
declare @purchaseprice decimal (9,2)
declare @customername nvarchar (50)
declare @accountkey int
declare @orderstatus smallint
declare @orderstatusdesc nvarchar(50)
declare @ordernumber bigint
while (@outerloop < 3200000)
begin
	Select @i = 0
	begin tran
	while (@i < 2000)
	begin
			set @ordernumber = @outerloop + @i
			set @purchaseprice = rand() * 1000.0
			set @accountkey = convert (int, RAND ()*1000000)
			set @orderstatus = convert (smallint, RAND()*5)
			if (@orderstatus = 5) set @orderstatus = 4
			
			set @orderstatusdesc  =
			case @orderstatus
				WHEN 0 THEN  'Order Started'
				WHEN 1 THEN  'Order Closed'
				WHEN 2 THEN  'Order Paid'
				WHEN 3 THEN 'Order Fullfillment'
				WHEN 4 THEN  'Order Shipped'
				WHEN 5 THEN 'Order Received'
			END

			insert orders_filtered values (@accountkey,(convert(varchar(6), @accountkey) + 'firstname'),
								  @ordernumber, @purchaseprice, @orderstatus, @orderstatusdesc)
			set @i += 1;
	end
	commit

	set @outerloop = @outerloop + 2000
	set @i = 0
end
go



-- START the demo here
select count(*) As [Total Rows] from orders_filtered
select count(*) AS [Closed Orders] from orders_filtered where OrderStatus = 5

select sum (total_rows)
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('orders_filtered')

-- look at the rowgroups
select object_name(object_id), index_id, row_group_id, delta_store_hobt_id, state_desc, total_rows, trim_reason_desc, transition_to_compressed_state_desc
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('orders_filtered')



-- analytics query performance
set statistics time on
go

dbcc dropcleanbuffers

--run query to show the query plan
select max (PurchasePrice)
from orders_filtered

--run query to show the query plan
-- when the index was not filtered
select max (PurchasePrice)
from orders

-- a more complex query
select top 5 customername, sum (PurchasePrice), Avg (PurchasePrice)
from orders_filtered
where purchaseprice > 90.0 and OrderStatus = 5
group by customername



-- a more complex query without NCCI
 select top 5 customername, sum (PurchasePrice), Avg (PurchasePrice)
from orders_filtered
where purchaseprice > 100.0 and OrderStatus = 5
group by customername
option (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX)


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- CASE-3 - with no clustered index
-- Create Filtered NCCI
drop table if exists orders_filtered2
go

-- create the table
create table orders_filtered2 (
	accountkey			int not null,
	accountdescription	nvarchar (50),
	accounttype			nvarchar(50),
	unitsold		    int)


set nocount on
go

set statistics time off
go
set statistics IO Off
go

-- insert into the main table load 10000 rows
declare @outerloop int = 0
declare @i int = 0
while (@outerloop < 10000)
begin
	Select @i = 0

	begin tran
	while (@i < 2000)
	begin
			insert orders_filtered2 values (@i + @outerloop, 'test1', 'test2', @i)
			set @i += 1;
	end
	commit

	set @outerloop = @outerloop + 2000
	set @i = 0
end
go


--create NCCI
CREATE NONCLUSTERED COLUMNSTORE INDEX orders_filtered2_NCCI
ON orders_filtered2 (accountkey, accountdescription, unitsold)  where accountkey > 0

-- look at the row groups
select *
from sys.dm_db_column_store_row_group_physical_stats
where object_id = object_id('orders_filtered2')

select * from sys.index_columns  where object_id = object_id('orders_filtered2')

-- show that the 4th column is indeed included
-- this is an internally generated column to uniquely identify the row
sELECT segment_id, object_name(p.object_id), s.column_id,  s.segment_id, s.min_data_id, s.max_data_id, s.encoding_type
FROM sys.column_store_segments s, sys.partitions p
where object_id = object_id('orders_filtered2') and
p.hobt_id = s.hobt_id

-- show the query plan with filtered index
-- since there is no index to filter, it will do a table scan
select avg (convert (bigint, unitsold))
from orders_filtered2 with (index = orders_filtered2_ncci)
