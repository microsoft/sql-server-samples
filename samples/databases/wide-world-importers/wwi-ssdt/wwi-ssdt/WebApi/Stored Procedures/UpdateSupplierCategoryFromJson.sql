CREATE PROCEDURE [WebApi].[UpdateSupplierCategoryFromJson](@SupplierCategory NVARCHAR(MAX), @SupplierCategoryID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Purchasing.SupplierCategories SET
		SupplierCategoryName = json.SupplierCategoryName,
		LastEditedBy = @UserID
	FROM OPENJSON (@SupplierCategory)
		WITH (SupplierCategoryName nvarchar(50)) as json
	WHERE
		Purchasing.SupplierCategories.SupplierCategoryID = @SupplierCategoryID

END