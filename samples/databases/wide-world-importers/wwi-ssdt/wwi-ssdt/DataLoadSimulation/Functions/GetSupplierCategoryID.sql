CREATE FUNCTION [DataLoadSimulation].[GetSupplierCategoryID]
( @SupplierCategoryName NVARCHAR(50) )
RETURNS INT
AS
BEGIN

/*
Notes:
  Returns the SupplierCategoryID for the passed in Supplier Category Name

Usage:
  DECLARE @SupplierCatID INT
  SET @SupplierCatID = [DataLoadSimulation].[GetSupplierCategoryID] ('Toy Supplier')
  SELECT @SupplierCatID

*/

  DECLARE @SupCatID INT

  SELECT TOP 1 @SupCatID = SupplierCategoryID
    FROM Purchasing.SupplierCategories
   WHERE SupplierCategoryName = @SupplierCategoryName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @SupCatID

END
