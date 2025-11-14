CREATE TABLE [Fact].[Purchase] (
    [Purchase Key]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [Date Key]              DATE          NOT NULL,
    [Supplier Key]          INT           NOT NULL,
    [Stock Item Key]        INT           NOT NULL,
    [WWI Purchase Order ID] INT           NULL,
    [Ordered Outers]        INT           NOT NULL,
    [Ordered Quantity]      INT           NOT NULL,
    [Received Outers]       INT           NOT NULL,
    [Package]               NVARCHAR (50) NOT NULL,
    [Is Order Finalized]    BIT           NOT NULL,
    [Lineage Key]           INT           NOT NULL,
    CONSTRAINT [PK_Fact_Purchase] PRIMARY KEY NONCLUSTERED ([Purchase Key] ASC, [Date Key] ASC) ON [PS_Date] ([Date Key]),
    CONSTRAINT [FK_Fact_Purchase_Date_Key_Dimension_Date] FOREIGN KEY ([Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Purchase_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key]),
    CONSTRAINT [FK_Fact_Purchase_Supplier_Key_Dimension_Supplier] FOREIGN KEY ([Supplier Key]) REFERENCES [Dimension].[Supplier] ([Supplier Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Purchase_Date_Key]
    ON [Fact].[Purchase]([Date Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Purchase_Stock_Item_Key]
    ON [Fact].[Purchase]([Stock Item Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Purchase_Supplier_Key]
    ON [Fact].[Purchase]([Supplier Key] ASC)
    ON [PS_Date] ([Date Key]);



GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Purchase fact table (stock purchases from suppliers)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Purchase fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Purchase Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order date', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier for this purchase order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Supplier Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this purchase order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order ID in source system ', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'WWI Purchase Order ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of outers (ordering packages)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Ordered Outers';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of inners (selling packages)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Ordered Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Received outers (so far)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Received Outers';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Package ordered', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this purchase order now finalized?', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Is Order Finalized';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Lineage Key';

