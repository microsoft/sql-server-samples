CREATE PROCEDURE [WebApi].[UpdateCustomerCategoryFromJson](@CustomerCategory NVARCHAR(MAX), @CustomerCategoryID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Sales.CustomerCategories SET
		CustomerCategoryName = json.CustomerCategoryName,
		LastEditedBy = @UserID
	FROM OPENJSON (@CustomerCategory)
		WITH (CustomerCategoryName nvarchar(50)) as json
	WHERE
		Sales.CustomerCategories.CustomerCategoryID = @CustomerCategoryID
END