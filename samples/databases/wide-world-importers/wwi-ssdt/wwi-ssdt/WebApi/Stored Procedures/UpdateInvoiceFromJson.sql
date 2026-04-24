CREATE PROCEDURE [WebApi].UpdateInvoiceFromJson(@Invoice NVARCHAR(MAX), @InvoiceID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Sales.Invoices SET
				CustomerID = ISNULL(json.CustomerID, Sales.Invoices.CustomerID),
				BillToCustomerID = ISNULL(json.BillToCustomerID, Sales.Invoices.BillToCustomerID),
				DeliveryMethodID = ISNULL(json.DeliveryMethodID, Sales.Invoices.DeliveryMethodID),
				ContactPersonID = ISNULL(json.ContactPersonID, Sales.Invoices.ContactPersonID),
				AccountsPersonID = ISNULL(json.AccountsPersonID, Sales.Invoices.AccountsPersonID),
				SalespersonPersonID = ISNULL(json.SalespersonPersonID, Sales.Invoices.SalespersonPersonID),
				PackedByPersonID = ISNULL(json.PackedByPersonID, Sales.Invoices.PackedByPersonID),
				InvoiceDate = ISNULL(json.InvoiceDate, Sales.Invoices.InvoiceDate),
				CustomerPurchaseOrderNumber = json.CustomerPurchaseOrderNumber,
				IsCreditNote = ISNULL(json.IsCreditNote, Sales.Invoices.IsCreditNote),
				TotalDryItems = ISNULL(json.TotalDryItems, Sales.Invoices.TotalDryItems),
				TotalChillerItems = ISNULL(json.TotalChillerItems, Sales.Invoices.TotalChillerItems),
				DeliveryRun = json.DeliveryRun,
				RunPosition = json.RunPosition,
				LastEditedBy = @UserID
			FROM OPENJSON(@Invoice)
				WITH (
					CustomerID int,
					BillToCustomerID int,
					OrderID int,
					DeliveryMethodID int,
					ContactPersonID int,
					AccountsPersonID int,
					SalespersonPersonID int,
					PackedByPersonID int,
					InvoiceDate date,
					CustomerPurchaseOrderNumber nvarchar(20),
					IsCreditNote bit,
					TotalDryItems int,
					TotalChillerItems int,
					DeliveryRun nvarchar(5),
					RunPosition nvarchar(5)) as json
			WHERE
				Sales.Invoices.InvoiceID = @InvoiceID

END