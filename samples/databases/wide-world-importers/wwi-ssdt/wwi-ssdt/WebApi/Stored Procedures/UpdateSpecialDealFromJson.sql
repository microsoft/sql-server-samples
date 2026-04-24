CREATE PROCEDURE [WebApi].[UpdateSpecialDealFromJson](@SpecialDeal NVARCHAR(MAX), @SpecialDealID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Sales.SpecialDeals SET
				StockItemID = json.StockItemID,
				CustomerID = json.CustomerID,
				BuyingGroupID = json.BuyingGroupID,
				CustomerCategoryID = json.CustomerCategoryID,
				StockGroupID = json.StockGroupID,
				DealDescription = ISNULL(json.DealDescription,Sales.SpecialDeals.DealDescription),
				StartDate = ISNULL(json.StartDate,Sales.SpecialDeals.StartDate),
				EndDate = ISNULL(json.EndDate,Sales.SpecialDeals.EndDate),
				DiscountAmount = json.DiscountAmount,
				DiscountPercentage = json.DiscountPercentage,
				UnitPrice = json.UnitPrice,
				LastEditedBy = @UserID
			FROM OPENJSON(@SpecialDeal)
				WITH (
					StockItemID int,
					CustomerID int,
					BuyingGroupID int,
					CustomerCategoryID int,
					StockGroupID int,
					DealDescription nvarchar(30),
					StartDate date,
					EndDate date,
					DiscountAmount decimal(18,2),
					DiscountPercentage decimal(18,3),
					UnitPrice decimal(18,2)) as json
			WHERE
				Sales.SpecialDeals.SpecialDealID = @SpecialDealID

END