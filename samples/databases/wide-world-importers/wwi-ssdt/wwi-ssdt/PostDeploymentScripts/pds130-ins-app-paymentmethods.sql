PRINT 'Inserting Application.PaymentMethods'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101';
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

INSERT [Application].PaymentMethods
  (PaymentMethodID, PaymentMethodName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'Cash', 1, @CurrentDateTime, @EndOfTime)
, (2,'Check', 1, @CurrentDateTime, @EndOfTime)
, (3,'Credit Card', 1, @CurrentDateTime, @EndOfTime)
, (4,'EFT', 1, @CurrentDateTime, @EndOfTime)
GO
