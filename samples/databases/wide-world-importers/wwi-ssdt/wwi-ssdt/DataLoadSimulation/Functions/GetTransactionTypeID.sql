CREATE FUNCTION [DataLoadSimulation].[GetTransactionTypeID]
( @TransactionTypeName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the transaction type id for the passed in name

Usage:
  DECLARE @myTransactionTypeId INT = [DataLoadSimulation].[GetTransactionTypeID] (N'Supplier Payment Issued')
  SELECT @myTransactionTypeId

*/
  DECLARE @TransTypeId INT
  SELECT TOP 1
         @TransTypeId = TransactionTypeID
   FROM [Application].TransactionTypes
  WHERE TransactionTypeName = @TransactionTypeName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @TransTypeId

END
