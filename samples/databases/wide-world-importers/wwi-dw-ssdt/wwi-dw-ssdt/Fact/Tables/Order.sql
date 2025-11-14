CREATE TABLE [Fact].[Order] (
    [Order Key]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [City Key]            INT             NOT NULL,
    [Customer Key]        INT             NOT NULL,
    [Stock Item Key]      INT             NOT NULL,
    [Order Date Key]      DATE            NOT NULL,
    [Picked Date Key]     DATE            NULL,
    [Salesperson Key]     INT             NOT NULL,
    [Picker Key]          INT             NULL,
    [WWI Order ID]        INT             NOT NULL,
    [WWI Backorder ID]    INT             NULL,
    [Description]         NVARCHAR (100)  NOT NULL,
    [Package]             NVARCHAR (50)   NOT NULL,
    [Quantity]            INT             NOT NULL,
    [Unit Price]          DECIMAL (18, 2) NOT NULL,
    [Tax Rate]            DECIMAL (18, 3) NOT NULL,
    [Total Excluding Tax] DECIMAL (18, 2) NOT NULL,
    [Tax Amount]          DECIMAL (18, 2) NOT NULL,
    [Total Including Tax] DECIMAL (18, 2) NOT NULL,
    [Lineage Key]         INT             NOT NULL,
    CONSTRAINT [PK_Fact_Order] PRIMARY KEY NONCLUSTERED ([Order Key] ASC, [Order Date Key] ASC) ON [PS_Date] ([Order Date Key]),
    CONSTRAINT [FK_Fact_Order_City_Key_Dimension_City] FOREIGN KEY ([City Key]) REFERENCES [Dimension].[City] ([City Key]),
    CONSTRAINT [FK_Fact_Order_Customer_Key_Dimension_Customer] FOREIGN KEY ([Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Order_Order_Date_Key_Dimension_Date] FOREIGN KEY ([Order Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Order_Picked_Date_Key_Dimension_Date] FOREIGN KEY ([Picked Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Order_Picker_Key_Dimension_Employee] FOREIGN KEY ([Picker Key]) REFERENCES [Dimension].[Employee] ([Employee Key]),
    CONSTRAINT [FK_Fact_Order_Salesperson_Key_Dimension_Employee] FOREIGN KEY ([Salesperson Key]) REFERENCES [Dimension].[Employee] ([Employee Key]),
    CONSTRAINT [FK_Fact_Order_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_City_Key]
    ON [Fact].[Order]([City Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Customer_Key]
    ON [Fact].[Order]([Customer Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Order_Date_Key]
    ON [Fact].[Order]([Order Date Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Picked_Date_Key]
    ON [Fact].[Order]([Picked Date Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Picker_Key]
    ON [Fact].[Order]([Picker Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Salesperson_Key]
    ON [Fact].[Order]([Salesperson Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Stock_Item_Key]
    ON [Fact].[Order]([Stock Item Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [IX_Integration_Order_WWI_Order_ID]
    ON [Fact].[Order]([WWI Order ID] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Order fact table (customer orders)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Order fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Order Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'City for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'City Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Order date for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Order Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Picked date for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Picked Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Salesperson for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Salesperson Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Picker for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Picker Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'OrderID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'WWI Order ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'BackorderID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'WWI Backorder ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the item supplied (Usually the stock item name but can be overridden)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of package to be supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity to be supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit price to be charged', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Unit Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate to be applied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Tax Rate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount excluding tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Total Excluding Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount of tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Tax Amount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount including tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Total Including Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Lineage Key';

