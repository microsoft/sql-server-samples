CREATE TABLE [Fact].[Stock Holding] (
    [Stock Holding Key]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [Stock Item Key]          INT             NOT NULL,
    [Quantity On Hand]        INT             NOT NULL,
    [Bin Location]            NVARCHAR (20)   NOT NULL,
    [Last Stocktake Quantity] INT             NOT NULL,
    [Last Cost Price]         DECIMAL (18, 2) NOT NULL,
    [Reorder Level]           INT             NOT NULL,
    [Target Stock Level]      INT             NOT NULL,
    [Lineage Key]             INT             NOT NULL,
    CONSTRAINT [PK_Fact_Stock_Holding] PRIMARY KEY NONCLUSTERED ([Stock Holding Key] ASC),
    CONSTRAINT [FK_Fact_Stock_Holding_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Stock_Holding_Stock_Item_Key]
    ON [Fact].[Stock Holding]([Stock Item Key] ASC);



GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'INDEX', @level2name = N'FK_Fact_Stock_Holding_Stock_Item_Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Holdings of stock items', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Stock Holding fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Stock Holding Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item being held', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity on hand', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Quantity On Hand';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bin location (where is this stock in the warehouse)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Bin Location';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity present at last stocktake', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Last Stocktake Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit cost when the stock item was last purchased', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Last Cost Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity below which reordering should take place', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Reorder Level';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Typical stock level held', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Target Stock Level';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Lineage Key';

