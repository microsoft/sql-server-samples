
CREATE PROCEDURE DataLoadSimulation.InvoicePickedOrders
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Invoicing picked orders for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @OrderID int;
    DECLARE @InvoiceID int;
    DECLARE @PickingCompletedWhen datetime;
    DECLARE @BackorderOrderID int;
    DECLARE @BillToCustomerID int;
    DECLARE @InvoicingPersonID int --= (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @InvoicingPersonID OUTPUT

    DECLARE @PackedByPersonID int --= (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @PackedByPersonID OUTPUT

    DECLARE @TotalDryItems int;
    DECLARE @TotalChillerItems int;
    DECLARE @TransactionAmount decimal(18,2);
    DECLARE @TaxAmount decimal(18,2);
    DECLARE @ReturnedDeliveryData nvarchar(max);
    DECLARE @DeliveryEvent nvarchar(max);

    DECLARE OrderList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT o.OrderID, o.PickingCompletedWhen, c.BillToCustomerID
      FROM Sales.Orders AS o
     INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
     WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i WHERE i.OrderID = o.OrderID)     -- not already invoiced
       AND c.IsOnCreditHold = 0                                                           -- and customer not on credit hold
       AND ((o.PickingCompletedWhen IS NOT NULL)                                          -- order completely picked
            OR (o.PickingCompletedWhen IS NULL                                            -- order not picked but customer happy
                AND o.IsUndersupplyBackordered <> 0                                       -- for part shipments and at least one
                AND EXISTS (SELECT 1 FROM Sales.OrderLines AS ol                          -- order line has been picked
                                    WHERE ol.OrderID = o.OrderID
                                      AND ol.PickingCompletedWhen IS NOT NULL
                           )
               )
           );

    OPEN OrderList;
    FETCH NEXT FROM OrderList INTO @OrderID, @PickingCompletedWhen, @BillToCustomerID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @PickingCompletedWhen IS NULL
        BEGIN -- need to reorder undersupplied items

            BEGIN TRAN;

            SET @BackorderOrderID = NEXT VALUE FOR Sequences.OrderID;
            SET @PickingCompletedWhen = @StartingWhen;

            -- create the backorder order
            INSERT Sales.Orders
                (OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID,
                 OrderDate, ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered,
                 Comments, DeliveryInstructions, InternalComments, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
            SELECT @BackorderOrderID, o.CustomerID, o.SalespersonPersonID, NULL, o.ContactPersonID, NULL,
                   o.OrderDate, o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, 1,
                   o.Comments, o.DeliveryInstructions, o.InternalComments, NULL, @InvoicingPersonID, @StartingWhen
            FROM Sales.Orders AS o
            WHERE o.OrderID = @OrderID;

            -- move the items that haven't been supplied to the new order
            UPDATE Sales.OrderLines
            SET OrderID = @BackorderOrderID,
                LastEditedBy = @InvoicingPersonID,
                LastEditedWhen = @StartingWhen
            WHERE OrderID = @OrderID
            AND PickingCompletedWhen IS NULL;

            -- flag the original order as backordered and picking completed
            UPDATE Sales.Orders
            SET BackorderOrderID = @BackorderOrderID,
                PickingCompletedWhen = @PickingCompletedWhen,
                LastEditedBy = @InvoicingPersonID,
                LastEditedWhen = @StartingWhen
            WHERE OrderID = @OrderID;

            COMMIT;
        END;

        SELECT @TotalDryItems = SUM(CASE WHEN si.IsChillerStock <> 0 THEN 0 ELSE 1 END),
               @TotalChillerItems = SUM(CASE WHEN si.IsChillerStock <> 0 THEN 1 ELSE 0 END)
        FROM Sales.OrderLines AS ol
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID
        WHERE ol.OrderID = @OrderID;

        -- now invoice whatever is left on the order
        BEGIN TRAN;

        SET @InvoiceID = NEXT VALUE FOR Sequences.InvoiceID;

        SET @ReturnedDeliveryData = N'{"Events": []}';
        SET @DeliveryEvent = N'{ }';

        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.Event', N'Ready for collection');
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.EventTime', CONVERT(nvarchar(20), @StartingWhen, 126));
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.ConNote', N'EAN-125-' + CAST(@InvoiceID + 1050 AS nvarchar(20)));

        SET @ReturnedDeliveryData = JSON_MODIFY(@ReturnedDeliveryData, N'append $.Events', JSON_QUERY(@DeliveryEvent));

        INSERT Sales.Invoices
            (InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID,
             SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber,
             IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
             TotalDryItems, TotalChillerItems,
             DeliveryRun, RunPosition, ReturnedDeliveryData, LastEditedBy, LastEditedWhen)
        SELECT @InvoiceID, c.CustomerID, @BillToCustomerID, @OrderID, c.DeliveryMethodID, o.ContactPersonID, btc.PrimaryContactPersonID,
               o.SalespersonPersonID, @PackedByPersonID, @StartingWhen, o.CustomerPurchaseOrderNumber,
               0, NULL, NULL, c.DeliveryAddressLine1 + N', ' + c.DeliveryAddressLine2, NULL,
               @TotalDryItems, @TotalChillerItems,
               c.DeliveryRun, c.RunPosition, @ReturnedDeliveryData, @InvoicingPersonID, @StartingWhen
        FROM Sales.Orders AS o
        INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
        INNER JOIN Sales.Customers AS btc
        ON btc.CustomerID = c.BillToCustomerID
        WHERE o.OrderID = @OrderID;

        INSERT Sales.InvoiceLines
            (InvoiceID, StockItemID, [Description], PackageTypeID,
             Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
             LastEditedBy, LastEditedWhen)
        SELECT @InvoiceID, ol.StockItemID, ol.[Description], ol.PackageTypeID,
               ol.PickedQuantity, ol.UnitPrice, ol.TaxRate,
               ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               ROUND(ol.PickedQuantity * (ol.UnitPrice - sih.LastCostPrice), 2),
               ROUND(ol.PickedQuantity * ol.UnitPrice, 2)
                 + ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               @InvoicingPersonID, @StartingWhen
          FROM Sales.OrderLines AS ol
         INNER JOIN Warehouse.StockItems AS si
            ON ol.StockItemID = si.StockItemID
         INNER JOIN Warehouse.StockItemHoldings AS sih
            ON si.StockItemID = sih.StockItemID
         WHERE ol.OrderID = @OrderID
         ORDER BY ol.OrderLineID;

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT il.StockItemID, [DataLoadSimulation].[GetTransactionTypeID] (N'Stock Issue'),
               i.CustomerID, i.InvoiceID, NULL, NULL,
               @StartingWhen, 0 - il.Quantity, @InvoicingPersonID, @StartingWhen
          FROM Sales.InvoiceLines AS il
          INNER JOIN Sales.Invoices AS i
             ON il.InvoiceID = i.InvoiceID
          WHERE i.InvoiceID = @InvoiceID
          ORDER BY il.InvoiceLineID;

        WITH StockItemTotals
        AS
        (
            SELECT il.StockItemID, SUM(il.Quantity) AS TotalQuantity
              FROM Sales.InvoiceLines aS il
             WHERE il.InvoiceID = @InvoiceID
             GROUP BY il.StockItemID
        )
        UPDATE sih
        SET sih.QuantityOnHand -= sit.TotalQuantity,
            sih.LastEditedBy = @InvoicingPersonID,
            sih.LastEditedWhen = @StartingWhen
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN StockItemTotals AS sit
        ON sih.StockItemID = sit.StockItemID;

        SELECT @TransactionAmount = SUM(il.ExtendedPrice),
               @TaxAmount = SUM(il.TaxAmount)
        FROM Sales.InvoiceLines AS il
        WHERE il.InvoiceID = @InvoiceID;

        INSERT Sales.CustomerTransactions
            (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID,
             TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
             OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
        VALUES
            (@BillToCustomerID, [DataLoadSimulation].[GetTransactionTypeID] (N'Customer Invoice'),
             @InvoiceID, NULL,
             @StartingWhen, @TransactionAmount - @TaxAmount, @TaxAmount, @TransactionAmount,
             @TransactionAmount, NULL, @InvoicingPersonID, @StartingWhen);

        COMMIT;
        FETCH NEXT FROM OrderList INTO @OrderID, @PickingCompletedWhen, @BillToCustomerID;
    END;

    CLOSE OrderList;
    DEALLOCATE OrderList;

END;