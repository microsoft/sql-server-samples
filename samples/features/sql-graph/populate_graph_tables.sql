/* POPULATE NODE TABLES */

-- for performance purposes, disable default indexes on edge and node tables.
 ALTER INDEX ALL ON Graph.Customers disable;
 ALTER INDEX ALL ON Graph.Suppliers disable;
 ALTER INDEX ALL ON Graph.StockItems disable;

 ALTER INDEX ALL ON Graph.InvoiceLines_CustomersToStockItems disable;
 ALTER INDEX ALL ON Graph.InvoiceLines_StockItemsToCustomers disable;
 ALTER INDEX ALL ON Graph.OrderLines_CustomersToStockItems disable;
 ALTER INDEX ALL ON Graph.OrderLines_StockItemsToCustomers disable;
 ALTER INDEX ALL ON Graph.PurchaseOrderLines_StockItemsToSuppliers disable;
 ALTER INDEX ALL ON Graph.PurchaseOrderLines_SuppliersToStockItems disable;
 GO

-- populate node table Graph.Customers from Sales.Customers
INSERT INTO Graph.Customers (
	CustomerID,
	CustomerName,
	BillToCustomerID,
	CustomerCategoryID,
	BuyingGroupID,
	PrimaryContactPersonID,
	AlternateContactPersonID,
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	CreditLimit,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryAddressLine2,
	DeliveryPostalCode,
	DeliveryLocation,
	PostalAddressLine1,
	PostalAddressLine2,
	PostalPostalCode,
	LastEditedBy,
	ValidFrom,
	ValidTo
) SELECT
	CustomerID,
	CustomerName,
	BillToCustomerID,
	CustomerCategoryID,
	BuyingGroupID,
	PrimaryContactPersonID,
	AlternateContactPersonID,
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	CreditLimit,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryAddressLine2,
	DeliveryPostalCode,
	DeliveryLocation,
	PostalAddressLine1,
	PostalAddressLine2,
	PostalPostalCode,
	LastEditedBy,
	ValidFrom,
	ValidTo
FROM Sales.Customers;

-- populate node table Graph.StockItems from Warehouse.StockItems
INSERT INTO Graph.StockItems (
	StockItemID,
	StockItemName,
	SupplierID,
	ColorID,
	UnitPackageID,
	OuterPackageID,
	Size,
	LeadTimeDays,
	QuantityPerOuter,
	IsChillerStock,
	Barcode,
	TaxRate,
	UnitPrice,
	RecommendedRetailPrice,
	TypicalWeightPerUnit,
	MarketingComments,
	InternalComments,
	Photo,
	CustomFields,
	Tags,
	SearchDetails,
	LastEditedBy,
	ValidFrom,
	ValidTo
) SELECT
	StockItemID,
	StockItemName,
	SupplierID,
	ColorID,
	UnitPackageID,
	OuterPackageID,
	Size,
	LeadTimeDays,
	QuantityPerOuter,
	IsChillerStock,
	Barcode,
	TaxRate,
	UnitPrice,
	RecommendedRetailPrice,
	TypicalWeightPerUnit,
	MarketingComments,
	InternalComments,
	Photo,
	CustomFields,
	Tags,
	SearchDetails,
	LastEditedBy,
	ValidFrom,
	ValidTo
FROM Warehouse.StockItems;

-- populate node table Graph.Suppliers from Purchasing.Suppliers
INSERT INTO Graph.Suppliers (
	SupplierID,
	SupplierName,
	SupplierCategoryID,
	PrimaryContactPersonID,
	AlternateContactPersonID,
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	SupplierReference,
	BankAccountName,
	BankAccountBranch,
	BankAccountCode,
	BankAccountNumber,
	BankInternationalCode,
	PaymentDays,
	InternalComments,
	PhoneNumber,
	FaxNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryAddressLine2,
	DeliveryPostalCode,
	DeliveryLocation,
	PostalAddressLine1,
	PostalAddressLine2,
	PostalPostalCode,
	LastEditedBy,
	ValidFrom,
	ValidTo
) SELECT
	SupplierID,
	SupplierName,
	SupplierCategoryID,
	PrimaryContactPersonID,
	AlternateContactPersonID,
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	SupplierReference,
	BankAccountName,
	BankAccountBranch,
	BankAccountCode,
	BankAccountNumber,
	BankInternationalCode,
	PaymentDays,
	InternalComments,
	PhoneNumber,
	FaxNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryAddressLine2,
	DeliveryPostalCode,
	DeliveryLocation,
	PostalAddressLine1,
	PostalAddressLine2,
	PostalPostalCode,
	LastEditedBy,
	ValidFrom,
	ValidTo
FROM Purchasing.Suppliers;

go


/* POPULATE EDGE TABLES */
-- populate edge table Graph.OrderLines_CustomersToStockItems from Sales.Orders and Sales.Orders
INSERT INTO Graph.OrderLines_CustomersToStockItems (
	$from_id,
	$to_id,

	-- from Sales.Orders
	OrderID,
	CustomerID,
	SalespersonPersonID,
	PickedByPersonID,
	ContactPersonID,
	BackorderOrderID,
	OrderDate,
	ExpectedDeliveryDate,
	CustomerPurchaseOrderNumber,
	IsUndersupplyBackordered,
	Comments,
	DeliveryInstructions,
	InternalComments,

	-- from Sales.OrderLines
	StockItemID,
	Description,
	PackageTypeID,
	Quantity,
	UnitPrice,
	TaxRate,
	PickedQuantity,
	PickingCompletedWhen,
	LastEditedBy,
	LastEditedWhen
) SELECT
	a1.n1,
	a2.n2,

	-- from Sales.Orders
	Sales.Orders.OrderID,
	Sales.Orders.CustomerID,
	Sales.Orders.SalespersonPersonID,
	Sales.Orders.PickedByPersonID,
	Sales.Orders.ContactPersonID,
	Sales.Orders.BackorderOrderID,
	Sales.Orders.OrderDate,
	Sales.Orders.ExpectedDeliveryDate,
	Sales.Orders.CustomerPurchaseOrderNumber,
	Sales.Orders.IsUndersupplyBackordered,
	Sales.Orders.Comments,
	Sales.Orders.DeliveryInstructions,
	Sales.Orders.InternalComments,

	-- from Sales.OrderLines
	Sales.OrderLines.StockItemID,
	Sales.OrderLines.Description,
	Sales.OrderLines.PackageTypeID,
	Sales.OrderLines.Quantity,
	Sales.OrderLines.UnitPrice,
	Sales.OrderLines.TaxRate,
	Sales.OrderLines.PickedQuantity,
	Sales.OrderLines.PickingCompletedWhen,
	Sales.OrderLines.LastEditedBy,
	Sales.OrderLines.LastEditedWhen
FROM Sales.Orders join Sales.OrderLines ON Sales.Orders.OrderID = Sales.OrderLines.OrderID
	join (SELECT $node_id AS n1, CustomerID FROM Graph.Customers) AS a1 ON a1.CustomerID = Sales.Orders.CustomerID
	join (SELECT $node_id AS n2, StockItemID FROM Graph.StockItems) AS a2 ON a2.StockItemID = Sales.OrderLines.StockItemID;

-- populate edge table Graph.OrderLines_StockItemsToCustomers from Sales.Orders and Sales.Orders
INSERT INTO Graph.OrderLines_StockItemsToCustomers (
	$from_id,
	$to_id,

	-- from Sales.Orders
	OrderID,
	CustomerID,
	SalespersonPersonID,
	PickedByPersonID,
	ContactPersonID,
	BackorderOrderID,
	OrderDate,
	ExpectedDeliveryDate,
	CustomerPurchaseOrderNumber,
	IsUndersupplyBackordered,
	Comments,
	DeliveryInstructions,
	InternalComments,

	-- from Sales.OrderLines
	StockItemID,
	Description,
	PackageTypeID,
	Quantity,
	UnitPrice,
	TaxRate,
	PickedQuantity,
	PickingCompletedWhen,
	LastEditedBy,
	LastEditedWhen
) SELECT
	a1.n1,
	a2.n2,

	-- from Sales.Orders
	Sales.Orders.OrderID,
	Sales.Orders.CustomerID,
	Sales.Orders.SalespersonPersonID,
	Sales.Orders.PickedByPersonID,
	Sales.Orders.ContactPersonID,
	Sales.Orders.BackorderOrderID,
	Sales.Orders.OrderDate,
	Sales.Orders.ExpectedDeliveryDate,
	Sales.Orders.CustomerPurchaseOrderNumber,
	Sales.Orders.IsUndersupplyBackordered,
	Sales.Orders.Comments,
	Sales.Orders.DeliveryInstructions,
	Sales.Orders.InternalComments,

	-- from Sales.OrderLines
	Sales.OrderLines.StockItemID,
	Sales.OrderLines.Description,
	Sales.OrderLines.PackageTypeID,
	Sales.OrderLines.Quantity,
	Sales.OrderLines.UnitPrice,
	Sales.OrderLines.TaxRate,
	Sales.OrderLines.PickedQuantity,
	Sales.OrderLines.PickingCompletedWhen,
	Sales.OrderLines.LastEditedBy,
	Sales.OrderLines.LastEditedWhen
FROM Sales.Orders join Sales.OrderLines ON Sales.Orders.OrderID = Sales.OrderLines.OrderID
	join (SELECT $node_id AS n1, StockItemID FROM Graph.StockItems) AS a1 ON a1.StockItemID = Sales.OrderLines.StockItemID
	join (SELECT $node_id AS n2, CustomerID FROM Graph.Customers) AS a2 ON a2.CustomerID = Sales.Orders.CustomerID;

-- populate edge table Graph.InvoiceLines_CustomersToStockItems from Sales.InvoiceLines and Sales.InvoiceLines
INSERT INTO Graph.InvoiceLines_CustomersToStockItems (
	$from_id,
	$to_id,

	-- from Sales.Invoices
	InvoiceID,
	CustomerID,
	BillToCustomerID,
	OrderID,
	DeliveryMethodID,
	ContactPersonID,
	AccountsPersonID,
	SalespersonPersonID,
	PackedByPersonID,
	InvoiceDate,
	CustomerPurchaseOrderNumber,
	IsCreditNote,
	CreditNoteReason,
	Comments,
	DeliveryInstructions,
	InternalComments,
	TotalDryItems,
	TotalChillerItems,
	DeliveryRun,
	RunPosition,
	ReturnedDeliveryData,
	ConfirmedDeliveryTime,
	ConfirmedReceivedBy,

	-- from Sales.InvoiceLines
	InvoiceLineID,
	StockItemID,
	Description,
	PackageTypeID,
	Quantity,
	UnitPrice,
	TaxRate,
	TaxAmount,
	LineProfit,
	ExtendedPrice,
	LastEditedBy,
	LastEditedWhen
) SELECT
	a1.n1,
	a2.n2,

	-- from Sales.Invoices
	Sales.Invoices.InvoiceID,
	Sales.Invoices.CustomerID,
	Sales.Invoices.BillToCustomerID,
	Sales.Invoices.OrderID,
	Sales.Invoices.DeliveryMethodID,
	Sales.Invoices.ContactPersonID,
	Sales.Invoices.AccountsPersonID,
	Sales.Invoices.SalespersonPersonID,
	Sales.Invoices.PackedByPersonID,
	Sales.Invoices.InvoiceDate,
	Sales.Invoices.CustomerPurchaseOrderNumber,
	Sales.Invoices.IsCreditNote,
	Sales.Invoices.CreditNoteReason,
	Sales.Invoices.Comments,
	Sales.Invoices.DeliveryInstructions,
	Sales.Invoices.InternalComments,
	Sales.Invoices.TotalDryItems,
	Sales.Invoices.TotalChillerItems,
	Sales.Invoices.DeliveryRun,
	Sales.Invoices.RunPosition,
	Sales.Invoices.ReturnedDeliveryData,
	Sales.Invoices.ConfirmedDeliveryTime,
	Sales.Invoices.ConfirmedReceivedBy,

	-- from Sales.InvoiceLines
	Sales.InvoiceLines.InvoiceLineID,
	Sales.InvoiceLines.StockItemID,
	Sales.InvoiceLines.Description,
	Sales.InvoiceLines.PackageTypeID,
	Sales.InvoiceLines.Quantity,
	Sales.InvoiceLines.UnitPrice,
	Sales.InvoiceLines.TaxRate,
	Sales.InvoiceLines.TaxAmount,
	Sales.InvoiceLines.LineProfit,
	Sales.InvoiceLines.ExtendedPrice,
	Sales.InvoiceLines.LastEditedBy,
	Sales.InvoiceLines.LastEditedWhen
FROM Sales.Invoices join Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID
	join (SELECT $node_id AS n1, CustomerID FROM Graph.Customers) AS a1 ON a1.CustomerID = Sales.Invoices.CustomerID
	join (SELECT $node_id AS n2, StockItemID FROM Graph.StockItems) AS a2 ON a2.StockItemID = Sales.InvoiceLines.StockItemID;

-- populate edge table Graph.InvoiceLines_StockItemsToCustomers from Sales.InvoiceLines and Sales.InvoiceLines
INSERT INTO Graph.InvoiceLines_StockItemsToCustomers (
	$from_id,
	$to_id,

	-- from Sales.Invoices
	InvoiceID,
	CustomerID,
	BillToCustomerID,
	OrderID,
	DeliveryMethodID,
	ContactPersonID,
	AccountsPersonID,
	SalespersonPersonID,
	PackedByPersonID,
	InvoiceDate,
	CustomerPurchaseOrderNumber,
	IsCreditNote,
	CreditNoteReason,
	Comments,
	DeliveryInstructions,
	InternalComments,
	TotalDryItems,
	TotalChillerItems,
	DeliveryRun,
	RunPosition,
	ReturnedDeliveryData,
	ConfirmedDeliveryTime,
	ConfirmedReceivedBy,

	-- from Sales.InvoiceLines
	InvoiceLineID,
	StockItemID,
	Description,
	PackageTypeID,
	Quantity,
	UnitPrice,
	TaxRate,
	TaxAmount,
	LineProfit,
	ExtendedPrice,
	LastEditedBy,
	LastEditedWhen
) SELECT
	a1.n1,
	a2.n2,

	-- from Sales.Invoices
	Sales.Invoices.InvoiceID,
	Sales.Invoices.CustomerID,
	Sales.Invoices.BillToCustomerID,
	Sales.Invoices.OrderID,
	Sales.Invoices.DeliveryMethodID,
	Sales.Invoices.ContactPersonID,
	Sales.Invoices.AccountsPersonID,
	Sales.Invoices.SalespersonPersonID,
	Sales.Invoices.PackedByPersonID,
	Sales.Invoices.InvoiceDate,
	Sales.Invoices.CustomerPurchaseOrderNumber,
	Sales.Invoices.IsCreditNote,
	Sales.Invoices.CreditNoteReason,
	Sales.Invoices.Comments,
	Sales.Invoices.DeliveryInstructions,
	Sales.Invoices.InternalComments,
	Sales.Invoices.TotalDryItems,
	Sales.Invoices.TotalChillerItems,
	Sales.Invoices.DeliveryRun,
	Sales.Invoices.RunPosition,
	Sales.Invoices.ReturnedDeliveryData,
	Sales.Invoices.ConfirmedDeliveryTime,
	Sales.Invoices.ConfirmedReceivedBy,

	-- from Sales.InvoiceLines
	Sales.InvoiceLines.InvoiceLineID,
	Sales.InvoiceLines.StockItemID,
	Sales.InvoiceLines.Description,
	Sales.InvoiceLines.PackageTypeID,
	Sales.InvoiceLines.Quantity,
	Sales.InvoiceLines.UnitPrice,
	Sales.InvoiceLines.TaxRate,
	Sales.InvoiceLines.TaxAmount,
	Sales.InvoiceLines.LineProfit,
	Sales.InvoiceLines.ExtendedPrice,
	Sales.InvoiceLines.LastEditedBy,
	Sales.InvoiceLines.LastEditedWhen
FROM Sales.Invoices join Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID
	join (SELECT $node_id AS n1, StockItemID FROM Graph.StockItems) AS a1 ON a1.StockItemID = Sales.InvoiceLines.StockItemID
	join (SELECT $node_id AS n2, CustomerID FROM Graph.Customers) AS a2 ON a2.CustomerID = Sales.Invoices.CustomerID;


-- populate edge table Graph.PurchaseOrderLines_StockItemsToSuppliers from Purchasing.PurchaseOrders and Purchasing.PurchaseOrderLines
INSERT INTO Graph.PurchaseOrderLines_StockItemsToSuppliers (
	$from_id,
	$to_id,

	-- from Purchasing.PurchaseOrders
	PurchaseOrderID,
	SupplierID,
	OrderDate,
	DeliveryMethodID,
	ContactPersonID,
	ExpectedDeliveryDate,
	SupplierReference,
	IsOrderFinalized,
	Comments,
	InternalComments,

	-- from Purchasing.PurchaseOrderLines
	PurchaseOrderLineID,
	StockItemID,
	OrderedOuters,
	Description,
	ReceivedOuters,
	PackageTypeID,
	ExpectedUnitPricePerOuter,
	LastReceiptDate,
	IsOrderLineFinalized,
	LastEditedBy,
	LastEditedWhen
) SELECT
	a1.n1,
	a2.n2,

	-- from Purchasing.PurchaseOrders.
	Purchasing.PurchaseOrders.PurchaseOrderID,
	Purchasing.PurchaseOrders.SupplierID,
	Purchasing.PurchaseOrders.OrderDate,
	Purchasing.PurchaseOrders.DeliveryMethodID,
	Purchasing.PurchaseOrders.ContactPersonID,
	Purchasing.PurchaseOrders.ExpectedDeliveryDate,
	Purchasing.PurchaseOrders.SupplierReference,
	Purchasing.PurchaseOrders.IsOrderFinalized,
	Purchasing.PurchaseOrders.Comments,
	Purchasing.PurchaseOrders.InternalComments,

	-- from Purchasing.PurchaseOrderLines
	Purchasing.PurchaseOrderLines.PurchaseOrderLineID,
	Purchasing.PurchaseOrderLines.StockItemID,
	Purchasing.PurchaseOrderLines.OrderedOuters,
	Purchasing.PurchaseOrderLines.Description,
	Purchasing.PurchaseOrderLines.ReceivedOuters,
	Purchasing.PurchaseOrderLines.PackageTypeID,
	Purchasing.PurchaseOrderLines.ExpectedUnitPricePerOuter,
	Purchasing.PurchaseOrderLines.LastReceiptDate,
	Purchasing.PurchaseOrderLines.IsOrderLineFinalized,
	Purchasing.PurchaseOrderLines.LastEditedBy,
	Purchasing.PurchaseOrderLines.LastEditedWhen
FROM Purchasing.PurchaseOrders join Purchasing.PurchaseOrderLines ON Purchasing.PurchaseOrders.PurchaseOrderID = Purchasing.PurchaseOrderLines.PurchaseOrderID
	join (SELECT $node_id AS n1, StockItemID FROM Graph.StockItems) AS a1 ON a1.StockItemID = Purchasing.PurchaseOrderLines.StockItemID
	join (SELECT $node_id AS n2, SupplierID FROM Graph.Suppliers) AS a2 ON a2.SupplierID = Purchasing.PurchaseOrders.SupplierID;

-- populate edge table Graph.PurchaseOrderLines_SuppliersToStockItems from Purchasing.PurchaseOrders and Purchasing.PurchaseOrderLines
INSERT INTO Graph.PurchaseOrderLines_SuppliersToStockItems (
	$from_id,
	$to_id,

	-- from Purchasing.PurchaseOrders
	PurchaseOrderID,
	SupplierID,
	OrderDate,
	DeliveryMethodID,
	ContactPersonID,
	ExpectedDeliveryDate,
	SupplierReference,
	IsOrderFinalized,
	Comments,
	InternalComments,

	-- from Purchasing.PurchaseOrderLines
	PurchaseOrderLineID,
	StockItemID,
	OrderedOuters,
	Description,
	ReceivedOuters,
	PackageTypeID,
	ExpectedUnitPricePerOuter,
	LastReceiptDate,
	IsOrderLineFinalized,
	LastEditedBy,
	LastEditedWhen
) SELECT
	a1.n1,
	a2.n2,

	-- from Purchasing.PurchaseOrders.
	Purchasing.PurchaseOrders.PurchaseOrderID,
	Purchasing.PurchaseOrders.SupplierID,
	Purchasing.PurchaseOrders.OrderDate,
	Purchasing.PurchaseOrders.DeliveryMethodID,
	Purchasing.PurchaseOrders.ContactPersonID,
	Purchasing.PurchaseOrders.ExpectedDeliveryDate,
	Purchasing.PurchaseOrders.SupplierReference,
	Purchasing.PurchaseOrders.IsOrderFinalized,
	Purchasing.PurchaseOrders.Comments,
	Purchasing.PurchaseOrders.InternalComments,

	-- from Purchasing.PurchaseOrderLines
	Purchasing.PurchaseOrderLines.PurchaseOrderLineID,
	Purchasing.PurchaseOrderLines.StockItemID,
	Purchasing.PurchaseOrderLines.OrderedOuters,
	Purchasing.PurchaseOrderLines.Description,
	Purchasing.PurchaseOrderLines.ReceivedOuters,
	Purchasing.PurchaseOrderLines.PackageTypeID,
	Purchasing.PurchaseOrderLines.ExpectedUnitPricePerOuter,
	Purchasing.PurchaseOrderLines.LastReceiptDate,
	Purchasing.PurchaseOrderLines.IsOrderLineFinalized,
	Purchasing.PurchaseOrderLines.LastEditedBy,
	Purchasing.PurchaseOrderLines.LastEditedWhen
FROM Purchasing.PurchaseOrders join Purchasing.PurchaseOrderLines ON Purchasing.PurchaseOrders.PurchaseOrderID = Purchasing.PurchaseOrderLines.PurchaseOrderID
	join (SELECT $node_id AS n1, SupplierID FROM Graph.Suppliers) AS a1 ON a1.SupplierID = Purchasing.PurchaseOrders.SupplierID
	join (SELECT $node_id AS n2, StockItemID FROM Graph.StockItems) AS a2 ON a2.StockItemID = Purchasing.PurchaseOrderLines.StockItemID;

GO

/*
Rebuild default indexes on node table. We advise against rebuilding default indexes on edge tables unless you eant to create a global view of all edge tables.
Add nonclustered indexes
*/
ALTER INDEX ALL ON Graph.Customers rebuild;
ALTER INDEX ALL ON Graph.Suppliers rebuild;
ALTER INDEX ALL ON Graph.StockItems rebuild;
GO

CREATE INDEX IX_InvoiceLines_CustomersToStockItems ON Graph.InvoiceLines_CustomersToStockItems ($from_id, $to_id);
CREATE INDEX IX_InvoiceLines_StockItemsToCustomers ON Graph.InvoiceLines_StockItemsToCustomers ($from_id, $to_id);
CREATE INDEX IX_OrderLines_CustomersToStockItems ON Graph.OrderLines_CustomersToStockItems ($from_id, $to_id);
CREATE INDEX IX_OrderLines_StockItemsToCustomers ON Graph.OrderLines_StockItemsToCustomers ($from_id, $to_id);
CREATE INDEX IX_PurchaseOrderLines_StockItemsToSuppliers ON Graph.PurchaseOrderLines_StockItemsToSuppliers ($from_id, $to_id);
CREATE INDEX IX_PurchaseOrderLines_SuppliersToStockItems ON Graph.PurchaseOrderLines_SuppliersToStockItems ($from_id, $to_id);
GO
