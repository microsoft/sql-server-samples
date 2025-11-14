CREATE TABLE [Fact].[Movement] (
    [Movement Key]                  BIGINT IDENTITY (1, 1) NOT NULL,
    [Date Key]                      DATE   NOT NULL,
    [Stock Item Key]                INT    NOT NULL,
    [Customer Key]                  INT    NULL,
    [Supplier Key]                  INT    NULL,
    [Transaction Type Key]          INT    NOT NULL,
    [WWI Stock Item Transaction ID] INT    NOT NULL,
    [WWI Invoice ID]                INT    NULL,
    [WWI Purchase Order ID]         INT    NULL,
    [Quantity]                      INT    NOT NULL,
    [Lineage Key]                   INT    NOT NULL,
    CONSTRAINT [PK_Fact_Movement] PRIMARY KEY NONCLUSTERED ([Movement Key] ASC, [Date Key] ASC) ON [PS_Date] ([Date Key]),
    CONSTRAINT [FK_Fact_Movement_Customer_Key_Dimension_Customer] FOREIGN KEY ([Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Movement_Date_Key_Dimension_Date] FOREIGN KEY ([Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Movement_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key]),
    CONSTRAINT [FK_Fact_Movement_Supplier_Key_Dimension_Supplier] FOREIGN KEY ([Supplier Key]) REFERENCES [Dimension].[Supplier] ([Supplier Key]),
    CONSTRAINT [FK_Fact_Movement_Transaction_Type_Key_Dimension_Transaction Type] FOREIGN KEY ([Transaction Type Key]) REFERENCES [Dimension].[Transaction Type] ([Transaction Type Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Customer_Key]
    ON [Fact].[Movement]([Customer Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Date_Key]
    ON [Fact].[Movement]([Date Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Stock_Item_Key]
    ON [Fact].[Movement]([Stock Item Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Supplier_Key]
    ON [Fact].[Movement]([Supplier Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Transaction_Type_Key]
    ON [Fact].[Movement]([Transaction Type Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [IX_Integration_Movement_WWI_Stock_Item_Transaction_ID]
    ON [Fact].[Movement]([WWI Stock Item Transaction ID] ASC)
    ON [PS_Date] ([Date Key]);



GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Movement fact table (movements of stock items)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Movement fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Movement Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Transaction date', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this purchase order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Supplier Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of transaction', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Transaction Type Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item transaction ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'WWI Stock Item Transaction ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Invoice ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'WWI Invoice ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'WWI Purchase Order ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of stock movement (positive is incoming stock, negative is outgoing)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Lineage Key';

