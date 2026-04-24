DROP VIEW IF EXISTS History.Product
GO
DROP SCHEMA IF EXISTS History
GO
CREATE SCHEMA History
GO

CREATE VIEW History.Product
AS SELECT * FROM ProductCatalog.History.Product
GO

drop function if exists dbo.diff_Product
go
create function dbo.diff_Product (@id int, @date datetime2(0))
returns table
as
return (
	select * from ProductCatalog.dbo.diff_Product (@id, @date)
)
GO


drop procedure if exists dbo.GetProducts
go
create procedure dbo.GetProducts as
begin
	begin tran
	EXEC ProductCatalog.dbo.GetProducts
	commit
end
GO

drop procedure if exists dbo.GetProductsAsOf
go
create procedure dbo.GetProductsAsOf (@date datetime2) as
begin
	begin tran
	EXEC ProductCatalog.dbo.GetProductsAsOf @date
	commit
end
GO

GO
drop procedure if exists dbo.RestoreProduct
GO
create procedure dbo.RestoreProduct (@productid int, @date datetime2) as
begin
	begin tran
	EXEC ProductCatalog.dbo.RestoreProduct @productid, @date
	commit
end
GO