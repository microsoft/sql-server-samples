PRINT 'Inserting Application.TransactionTypes'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT [Application].TransactionTypes
  (TransactionTypeID, TransactionTypeName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'Customer Invoice', 1, @CurrentDateTime, @EndOfTime)
, (2,'Customer Credit Note', 1, @CurrentDateTime, @EndOfTime)
, (3,'Customer Payment Received', 1, @CurrentDateTime, @EndOfTime)
, (4,'Customer Refund', 1, @CurrentDateTime, @EndOfTime)
, (5,'Supplier Invoice', 1, @CurrentDateTime, @EndOfTime)
, (6,'Supplier Credit Note', 1, @CurrentDateTime, @EndOfTime)
, (7,'Supplier Payment Issued', 1, @CurrentDateTime, @EndOfTime)
, (8,'Supplier Refund', 1, @CurrentDateTime, @EndOfTime)
, (9,'Stock Transfer', 1, @CurrentDateTime, @EndOfTime)
, (10,'Stock Issue', 1, @CurrentDateTime, @EndOfTime)
, (11,'Stock Receipt', 1, @CurrentDateTime, @EndOfTime)
, (12,'Stock Adjustment at Stocktake', 1, @CurrentDateTime, @EndOfTime)
GO
