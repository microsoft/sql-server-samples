CREATE   VIEW [WebApi].[PurchaseOrders]
AS
SELECT	o.PurchaseOrderID, o.OrderDate, o.ExpectedDeliveryDate, o.SupplierReference, o.IsOrderFinalized,
		dm.DeliveryMethodName, o.DeliveryMethodID, o.SupplierID,
		ContactName = c.FullName, ContactPhone = c.PhoneNumber, ContactFax = c.FaxNumber, ContactEmail = c.EmailAddress
FROM	Purchasing.PurchaseOrders o
		INNER JOIN Application.People c
			ON o.ContactPersonID = c.PersonID
		INNER JOIN Application.DeliveryMethods dm
			ON o.DeliveryMethodID = dm.DeliveryMethodID
