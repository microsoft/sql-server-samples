
CREATE PROCEDURE Sequences.ReseedAllSequences
AS BEGIN
    -- Ensures that the next sequence values are above the maximum value of the related table columns
    SET NOCOUNT ON;

    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'BuyingGroupID', @SchemaName = 'Sales', @TableName = 'BuyingGroups', @ColumnName = 'BuyingGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CityID', @SchemaName = 'Application', @TableName = 'Cities', @ColumnName = 'CityID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'ColorID', @SchemaName = 'Warehouse', @TableName = 'Colors', @ColumnName = 'ColorID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CountryID', @SchemaName = 'Application', @TableName = 'Countries', @ColumnName = 'CountryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CustomerCategoryID', @SchemaName = 'Sales', @TableName = 'CustomerCategories', @ColumnName = 'CustomerCategoryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CustomerID', @SchemaName = 'Sales', @TableName = 'Customers', @ColumnName = 'CustomerID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'DeliveryMethodID', @SchemaName = 'Application', @TableName = 'DeliveryMethods', @ColumnName = 'DeliveryMethodID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'InvoiceID', @SchemaName = 'Sales', @TableName = 'Invoices', @ColumnName = 'InvoiceID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'InvoiceLineID', @SchemaName = 'Sales', @TableName = 'InvoiceLines', @ColumnName = 'InvoiceLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'OrderID', @SchemaName = 'Sales', @TableName = 'Orders', @ColumnName = 'OrderID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'OrderLineID', @SchemaName = 'Sales', @TableName = 'OrderLines', @ColumnName = 'OrderLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PackageTypeID', @SchemaName = 'Warehouse', @TableName = 'PackageTypes', @ColumnName = 'PackageTypeID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PaymentMethodID', @SchemaName = 'Application', @TableName = 'PaymentMethods', @ColumnName = 'PaymentMethodID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PersonID', @SchemaName = 'Application', @TableName = 'People', @ColumnName = 'PersonID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PurchaseOrderID', @SchemaName = 'Purchasing', @TableName = 'PurchaseOrders', @ColumnName = 'PurchaseOrderID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PurchaseOrderLineID', @SchemaName = 'Purchasing', @TableName = 'PurchaseOrderLines', @ColumnName = 'PurchaseOrderLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SpecialDealID', @SchemaName = 'Sales', @TableName = 'SpecialDeals', @ColumnName = 'SpecialDealID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StateProvinceID', @SchemaName = 'Application', @TableName = 'StateProvinces', @ColumnName = 'StateProvinceID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockGroupID', @SchemaName = 'Warehouse', @TableName = 'StockGroups', @ColumnName = 'StockGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockItemID', @SchemaName = 'Warehouse', @TableName = 'StockItems', @ColumnName = 'StockItemID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockItemStockGroupID', @SchemaName = 'Warehouse', @TableName = 'StockItemStockGroups', @ColumnName = 'StockItemStockGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SupplierCategoryID', @SchemaName = 'Purchasing', @TableName = 'SupplierCategories', @ColumnName = 'SupplierCategoryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SupplierID', @SchemaName = 'Purchasing', @TableName = 'Suppliers', @ColumnName = 'SupplierID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SystemParameterID', @SchemaName = 'Application', @TableName = 'SystemParameters', @ColumnName = 'SystemParameterID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Purchasing', @TableName = 'SupplierTransactions', @ColumnName = 'SupplierTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Sales', @TableName = 'CustomerTransactions', @ColumnName = 'CustomerTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Warehouse', @TableName = 'StockItemTransactions', @ColumnName = 'StockItemTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionTypeID', @SchemaName = 'Application', @TableName = 'TransactionTypes', @ColumnName = 'TransactionTypeID';
END;
