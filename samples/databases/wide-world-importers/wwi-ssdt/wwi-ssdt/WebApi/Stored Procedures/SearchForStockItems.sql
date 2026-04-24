CREATE PROCEDURE [WebApi].[SearchForStockItems]
@Name nvarchar(100),
@Tag nvarchar(100),
@MinPrice decimal(18,2),
@MaxPrice decimal(18,2),
@StockGroupID int,
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    WITH value AS
	(SELECT
           si.StockItemID,
           si.StockItemName,
		   si.Brand,
		   si.ColorName,
		   si.UnitPrice,
		   si.TaxRate,
		   si.Size,
		   si.MarketingComments,
		   si.CustomFields
    FROM WebApi.StockItems AS si
    WHERE (@Name IS NULL OR si.StockItemName LIKE ('%' + @Name + '%'))
	AND (@MinPrice IS NULL OR si.UnitPrice > @MinPrice)
	AND (@MaxPrice IS NULL OR si.UnitPrice < @MaxPrice)
	)
	SELECT
		value = (SELECT TOP(@MaximumRowsToReturn) v.StockItemID,v.StockItemName,v.Brand,v.ColorName,v.UnitPrice,v.TaxRate,v.Size,v.MarketingComments
					FROM value v
					WHERE (@Tag IS NULL OR EXISTS (SELECT * FROM OPENJSON (CustomFields, '$.Tags') WITH (Tag nvarchar(20) '$') WHERE Tag = @Tag) )
					AND (@StockGroupID IS NULL OR EXISTS (SELECT * FROM Warehouse.StockItemStockGroups sisg WHERE sisg.StockItemID = StockItemID AND sisg.StockGroupID = @StockGroupID) )
				FOR JSON PATH),
		tags = (SELECT Tag, Items = COUNT(*)
					FROM value
						CROSS APPLY OPENJSON (CustomFields, '$.Tags')
									 WITH (Tag NVARCHAR(20) '$')
				GROUP BY Tag
				FOR JSON PATH)
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
END;
GO


