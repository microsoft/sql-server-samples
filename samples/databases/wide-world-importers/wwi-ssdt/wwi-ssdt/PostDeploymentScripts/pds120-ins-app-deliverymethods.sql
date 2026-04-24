PRINT 'Inserting Application.DeliveryMethods'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT [Application].DeliveryMethods
  (DeliveryMethodID, DeliveryMethodName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'Post', 1, @CurrentDateTime, @EndOfTime)
, (2,'Courier', 1, @CurrentDateTime, @EndOfTime)
, (3,'Delivery Van', 1, @CurrentDateTime, @EndOfTime)
, (4,'Customer Collect', 1, @CurrentDateTime, @EndOfTime)
, (5,'Van with Chiller', 1, @CurrentDateTime, @EndOfTime)
, (6,'Customer Courier to Collect', 1, @CurrentDateTime, @EndOfTime)
, (7,'Road Freight', 1, @CurrentDateTime, @EndOfTime)
, (8,'Air Freight', 1, @CurrentDateTime, @EndOfTime)
, (9,'Refrigerated Road Freight', 1, @CurrentDateTime, @EndOfTime)
, (10,'Refrigerated Air Freight', 1, @CurrentDateTime, @EndOfTime)
GO
