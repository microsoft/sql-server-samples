-- 1. INSERT CSV file into Product table
BULK INSERT Product
FROM 'product.csv'
WITH (	DATA_SOURCE = 'MyAzureBlobStorage',
		FORMAT='CSV', CODEPAGE = 65001, --UTF-8 encoding
		FIRSTROW=2,
		TABLOCK);

-- 2. INSERT file exported using bcp.exe into Product table
BULK INSERT Product
FROM 'product.dat'
WITH (	DATA_SOURCE = 'MyAzureBlobStorage',
		FORMATFILE='product.fmt',
		FORMATFILE_DATA_SOURCE = 'MyAzureBlobStorage',
		TABLOCK);

-- 3. Read rows from product.dat file using format file and insert it into Product table
INSERT INTO Product WITH (TABLOCK) (Name, Color, Price, Size, Quantity, Data, Tags)
SELECT Name, Color, Price, Size, Quantity, Data, Tags
FROM OPENROWSET(BULK 'product.dat',
				DATA_SOURCE = 'MyAzureBlobStorage',
				FORMATFILE='product.fmt',
				FORMATFILE_DATA_SOURCE = 'MyAzureBlobStorage') as products; 