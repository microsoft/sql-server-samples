PRINT 'Inserting Purchasing.SupplierCategories'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT Purchasing.SupplierCategories
  (SupplierCategoryID, SupplierCategoryName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'Other Wholesaler', 1, @CurrentDateTime, @EndOfTime)
, (2,'Novelty Goods Supplier', 1, @CurrentDateTime, @EndOfTime)
, (3,'Toy Supplier', 1, @CurrentDateTime, @EndOfTime)
, (4,'Clothing Supplier', 1, @CurrentDateTime, @EndOfTime)
, (5,'Packaging Supplier', 1, @CurrentDateTime, @EndOfTime)
, (6,'Courier', 1, @CurrentDateTime, @EndOfTime)
, (7,'Financial Services Supplier', 1, @CurrentDateTime, @EndOfTime)
, (8,'Marketing Services Supplier', 1, @CurrentDateTime, @EndOfTime)
, (9,'Insurance Services Supplier', 1, @CurrentDateTime, @EndOfTime)
GO
