PRINT 'Inserting Sales.BuyingGroups'
GO
DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT Sales.BuyingGroups
  (BuyingGroupID, BuyingGroupName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 1, 'Individual Buyers', 1, @CurrentDateTime, @EndOfTime)
, ( 2, 'Tailspin Toys', 1, @CurrentDateTime, @EndOfTime)
, ( 3, 'Wingtip Toys', 1, @CurrentDateTime, @EndOfTime)
, ( 4, 'Contoso Suites', 1, @CurrentDateTime, @EndOfTime)
, ( 5, 'Alpine Ski House', 1, @CurrentDateTime, @EndOfTime)
, ( 6, 'First Up Consultants', 1, @CurrentDateTime, @EndOfTime)
, ( 7, 'Fourth Coffee', 1, @CurrentDateTime, @EndOfTime)
, ( 8, 'Liberty''s Delightful Sinful Bakery & Cafe', 1, @CurrentDateTime, @EndOfTime)
, ( 9, 'Munson''s Pickles and Preserves Farm', 1, @CurrentDateTime, @EndOfTime)
, (10, 'Margie''s Travel', 1, @CurrentDateTime, @EndOfTime)
, (11, 'Northwind Traders', 1, @CurrentDateTime, @EndOfTime)
, (12, 'Southridge Video', 1, @CurrentDateTime, @EndOfTime)
, (13, 'VanArsdel, Ltd.', 1, @CurrentDateTime, @EndOfTime)
, (14, 'Relecloud', 1, @CurrentDateTime, @EndOfTime)
, (15, 'Blue Younder Airlines', 1, @CurrentDateTime, @EndOfTime)

GO

PRINT 'Inserting Sales.CustomerCategories'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT Sales.CustomerCategories
  (CustomerCategoryID, CustomerCategoryName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'Agent', 1, @CurrentDateTime, @EndOfTime)
, (2,'Wholesaler', 1, @CurrentDateTime, @EndOfTime)
, (3,'Novelty Shop', 1, @CurrentDateTime, @EndOfTime)
, (4,'Supermarket', 1, @CurrentDateTime, @EndOfTime)
, (5,'Computer Store', 1, @CurrentDateTime, @EndOfTime)
, (6,'Gift Store', 1, @CurrentDateTime, @EndOfTime)
, (7,'Corporate', 1, @CurrentDateTime, @EndOfTime)
GO
