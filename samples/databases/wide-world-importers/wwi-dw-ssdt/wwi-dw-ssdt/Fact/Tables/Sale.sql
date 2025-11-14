CREATE TABLE [Fact].[Sale] (
    [Sale Key]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [City Key]             INT             NOT NULL,
    [Customer Key]         INT             NOT NULL,
    [Bill To Customer Key] INT             NOT NULL,
    [Stock Item Key]       INT             NOT NULL,
    [Invoice Date Key]     DATE            NOT NULL,
    [Delivery Date Key]    DATE            NULL,
    [Salesperson Key]      INT             NOT NULL,
    [WWI Invoice ID]       INT             NOT NULL,
    [Description]          NVARCHAR (100)  NOT NULL,
    [Package]              NVARCHAR (50)   NOT NULL,
    [Quantity]             INT             NOT NULL,
    [Unit Price]           DECIMAL (18, 2) NOT NULL,
    [Tax Rate]             DECIMAL (18, 3) NOT NULL,
    [Total Excluding Tax]  DECIMAL (18, 2) NOT NULL,
    [Tax Amount]           DECIMAL (18, 2) NOT NULL,
    [Profit]               DECIMAL (18, 2) NOT NULL,
    [Total Including Tax]  DECIMAL (18, 2) NOT NULL,
    [Total Dry Items]      INT             NOT NULL,
    [Total Chiller Items]  INT             NOT NULL,
    [Lineage Key]          INT             NOT NULL,
    CONSTRAINT [PK_Fact_Sale] PRIMARY KEY NONCLUSTERED ([Sale Key] ASC, [Invoice Date Key] ASC) ON [PS_Date] ([Invoice Date Key]),
    CONSTRAINT [FK_Fact_Sale_Bill_To_Customer_Key_Dimension_Customer] FOREIGN KEY ([Bill To Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Sale_City_Key_Dimension_City] FOREIGN KEY ([City Key]) REFERENCES [Dimension].[City] ([City Key]),
    CONSTRAINT [FK_Fact_Sale_Customer_Key_Dimension_Customer] FOREIGN KEY ([Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Sale_Delivery_Date_Key_Dimension_Date] FOREIGN KEY ([Delivery Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Sale_Invoice_Date_Key_Dimension_Date] FOREIGN KEY ([Invoice Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Sale_Salesperson_Key_Dimension_Employee] FOREIGN KEY ([Salesperson Key]) REFERENCES [Dimension].[Employee] ([Employee Key]),
    CONSTRAINT [FK_Fact_Sale_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Bill_To_Customer_Key]
    ON [Fact].[Sale]([Bill To Customer Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_City_Key]
    ON [Fact].[Sale]([City Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Customer_Key]
    ON [Fact].[Sale]([Customer Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Delivery_Date_Key]
    ON [Fact].[Sale]([Delivery Date Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Invoice_Date_Key]
    ON [Fact].[Sale]([Invoice Date Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Salesperson_Key]
    ON [Fact].[Sale]([Salesperson Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Stock_Item_Key]
    ON [Fact].[Sale]([Stock Item Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);



GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Sale fact table (invoiced sales to customers)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Sale fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Sale Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'City for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'City Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bill To Customer for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Bill To Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Invoice date for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Invoice Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that these items were delivered', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Delivery Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Salesperson for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Salesperson Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'InvoiceID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'WWI Invoice ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the item supplied (Usually the stock item name but can be overridden)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of package supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit price charged', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Unit Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate applied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Tax Rate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount excluding tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Excluding Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount of tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Tax Amount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount of profit', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Profit';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount including tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Including Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total number of dry items', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Dry Items';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total number of chiller items', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Chiller Items';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Lineage Key';

