CREATE PROCEDURE [WebApi].[UpdateSalesOrderFromJson](@SalesOrder NVARCHAR(MAX), @SalesOrderID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Sales.Orders SET
				SalespersonPersonID = ISNULL(json.SalespersonPersonID,Sales.Orders.SalespersonPersonID),
				PickedByPersonID = ISNULL(json.PickedByPersonID,Sales.Orders.PickedByPersonID),
				ContactPersonID = ISNULL(json.ContactPersonID,Sales.Orders.ContactPersonID),
				BackorderOrderID = ISNULL(json.BackorderOrderID,Sales.Orders.BackorderOrderID),
				OrderDate = ISNULL(json.OrderDate,Sales.Orders.OrderDate),
				ExpectedDeliveryDate = ISNULL(json.ExpectedDeliveryDate,Sales.Orders.ExpectedDeliveryDate),
				CustomerPurchaseOrderNumber = ISNULL(json.CustomerPurchaseOrderNumber,Sales.Orders.CustomerPurchaseOrderNumber),
				IsUndersupplyBackordered = ISNULL(json.IsUndersupplyBackordered,Sales.Orders.IsUndersupplyBackordered),
				PickingCompletedWhen = ISNULL(json.PickingCompletedWhen,Sales.Orders.PickingCompletedWhen),
				LastEditedBy = @UserID
			FROM OPENJSON(@SalesOrder)
				WITH (
					SalespersonPersonID int,
					PickedByPersonID int,
					ContactPersonID int,
					BackorderOrderID int,
					OrderDate date,
					ExpectedDeliveryDate date,
					CustomerPurchaseOrderNumber nvarchar(20),
					IsUndersupplyBackordered bit,
					PickingCompletedWhen date) as json
			WHERE
				Sales.Orders.OrderID = @SalesOrderID

END