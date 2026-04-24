CREATE FUNCTION [DataLoadSimulation].[GetPaymentMethodID]
( @PaymentMethodName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the transaction type id for the passed in name

Usage:
  DECLARE @myTransactionTypeId INT = [DataLoadSimulation].[GetPaymentMethodID] (N'EFT')
  SELECT @myTransactionTypeId

*/
  DECLARE @PayMethodId INT
  SELECT TOP 1
         @PayMethodId = PaymentMethodID
    FROM [Application].PaymentMethods
   WHERE PaymentMethodName = @PaymentMethodName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @PayMethodId

END
