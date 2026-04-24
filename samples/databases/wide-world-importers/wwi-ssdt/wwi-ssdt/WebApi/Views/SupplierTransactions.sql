CREATE VIEW [WebApi].[SupplierTransactions]
AS
SELECT        st.SupplierTransactionID, st.TransactionDate, st.AmountExcludingTax, st.TaxAmount, st.TransactionAmount, st.OutstandingBalance, st.FinalizationDate, st.IsFinalized, s.SupplierName, tt.TransactionTypeName,
                         pm.PaymentMethodName, st.SupplierID, st.TransactionTypeID, st.PurchaseOrderID, st.PaymentMethodID, po.OrderDate, po.IsOrderFinalized, po.ExpectedDeliveryDate, po.SupplierReference
FROM            Purchasing.SupplierTransactions AS st LEFT OUTER JOIN
                         Purchasing.PurchaseOrders AS po ON st.PurchaseOrderID = po.PurchaseOrderID LEFT OUTER JOIN
                         Application.TransactionTypes AS tt ON st.TransactionTypeID = tt.TransactionTypeID LEFT OUTER JOIN
                         Purchasing.Suppliers AS s ON st.SupplierID = s.SupplierID LEFT OUTER JOIN
                         Application.PaymentMethods AS pm ON st.PaymentMethodID = pm.PaymentMethodID