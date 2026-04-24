CREATE PROCEDURE [WebApi].[UpdateCustomerTransactionFromJson](@CustomerTransaction NVARCHAR(MAX), @CustomerTransactionID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Sales.CustomerTransactions SET
			TransactionTypeID = ISNULL(json.TransactionTypeID, Sales.CustomerTransactions.TransactionTypeID),
			PaymentMethodID = json.PaymentMethodID,
			TransactionDate = ISNULL(json.TransactionDate, Sales.CustomerTransactions.TransactionDate),
			AmountExcludingTax = ISNULL(json.AmountExcludingTax, Sales.CustomerTransactions.AmountExcludingTax),
			TaxAmount = ISNULL(json.TaxAmount, Sales.CustomerTransactions.TaxAmount),
			TransactionAmount = ISNULL(json.TransactionAmount, Sales.CustomerTransactions.TransactionAmount),
			OutstandingBalance = ISNULL(json.OutstandingBalance, Sales.CustomerTransactions.OutstandingBalance),
			FinalizationDate = json.FinalizationDate,
			LastEditedBy = @UserID
		FROM OPENJSON(@CustomerTransaction)
			WITH (
				TransactionTypeID int,
				PaymentMethodID int,
				TransactionDate date,
				FinalizationDate date,
				AmountExcludingTax decimal(18,2),
				TaxAmount decimal(18,2),
				TransactionAmount decimal(18,2),
				OutstandingBalance decimal(18,2)
				) as json
		WHERE
			Sales.CustomerTransactions.CustomerTransactionID = @CustomerTransactionID

END