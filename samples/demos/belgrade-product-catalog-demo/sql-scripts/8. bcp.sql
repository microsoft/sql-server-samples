CREATE TABLE Orders (
	OrderID int,
	OrderDate date,
	Status varchar(16),
	DeliveryDate date,
	Data nvarchar(4000)
)

CREATE TABLE OrderLines (
	OrderLineID int,
	OrderID int,
	ProductID int,
	Quantity int,
	UnitPrice decimal,
	TaxRate decimal
)

CREATE EXTERNAL DATA SOURCE MyAzureBlobStorage
WITH (	TYPE = BLOB_STORAGE, LOCATION = 'https://myazureblobstorage.blob.core.windows.net/data');


BULK INSERT Orders
FROM 'orders.bcp'
WITH (	DATA_SOURCE = 'MyAzureBlobStorage',
		FORMATFILE = 'orders.fmt',
		FORMATFILE_DATA_SOURCE = 'MyAzureBlobStorage',
		TABLOCK);


BULK INSERT OrderLines
FROM 'orderlines.bcp'
WITH (	DATA_SOURCE = 'MyAzureBlobStorage',
		FORMATFILE = 'orderlines.fmt',
		FORMATFILE_DATA_SOURCE = 'MyAzureBlobStorage',
		TABLOCK);

