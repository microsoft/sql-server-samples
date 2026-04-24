CREATE VIEW [WebApi].[Invoices]
AS
SELECT  inv.InvoiceID, inv.InvoiceDate, inv.CustomerPurchaseOrderNumber, inv.IsCreditNote, inv.TotalDryItems, inv.TotalChillerItems, inv.DeliveryRun, inv.RunPosition,
        ReturnedDeliveryData = JSON_QUERY(inv.ReturnedDeliveryData), inv.ConfirmedDeliveryTime,
        inv.ConfirmedReceivedBy, c.CustomerName, sp.FullName AS SalesPersonName, contact.FullName AS ContactName, contact.PhoneNumber AS ContactPhone, contact.EmailAddress AS ContactEmail,
        sp.EmailAddress AS SalesPersonEmail, dm.DeliveryMethodName, inv.CustomerID, inv.OrderID, inv.DeliveryMethodID, inv.ContactPersonID, inv.AccountsPersonID, inv.SalespersonPersonID, inv.PackedByPersonID
FROM    Sales.Invoices AS inv INNER JOIN
            Sales.Customers AS c ON inv.CustomerID = c.CustomerID INNER JOIN
            Application.DeliveryMethods AS dm ON inv.DeliveryMethodID = dm.DeliveryMethodID INNER JOIN
            Application.People AS contact ON inv.ContactPersonID = contact.PersonID INNER JOIN
            Application.People AS sp ON inv.SalespersonPersonID = sp.PersonID