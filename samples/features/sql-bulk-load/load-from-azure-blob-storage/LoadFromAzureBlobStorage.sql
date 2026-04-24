
--/********************************************************************************
*	Note: You can export file and create format file using bcp out command:
*
*>bcp "SELECT Name, Color, Price, Size, Quantity, Data, Tags FROM Product" queryout product.dat -d ProductCatalog -T
*
********************************************************************************/

/********************************************************************************
*								1. SETUP											*
********************************************************************************/


/********************************************************************************
*				1.1. OPTIONAL CREDENTIAL SETUP									*
*				(if data source is not public)									*
********************************************************************************/
-- 1.1.1. (optional) Create master key that will encrypt credentials
--
-- Required only if you need to setup CREDENTIAL in 1.1.2.
-- CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'some strong password';

-- 1.1.2. (optional) Create credential with Azure Blob SAS
--
-- CREATE DATABASE SCOPED CREDENTIAL MyAzureBlobStorageCredential
-- WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
-- SECRET = 'sv=2015-12-11&ss=b&srt=sco&sp=rwac&se=2017-02-01T00:55:34Z&st=2016-12-29T16:55:34Z&spr=https&sig=copyFromAzurePortal';
-- NOTE: DO NOT PUT FIRST CHARACTER '?'' IN SECRET!!!



/********************************************************************************
*				1.2. REQUIRE DATA SOURCE SETUP									*
*				(optionally add credential)										*
********************************************************************************/

-- Create external data source with the URL of the Blob storage Account and associated credential (if it is not public).
CREATE EXTERNAL DATA SOURCE MyAzureBlobStorage
WITH (	TYPE = BLOB_STORAGE,
		LOCATION = 'https://sqlchoice.blob.core.windows.net/sqlchoice/samples/load-from-azure-blob-storage',
--		CREDENTIAL= MyAzureBlobStorageCredential	--> CREDENTIAL is not required if a blob storage is public!
);

/********************************************************************************
*				1.3. CREATE DESTINATION TABLE (if not exists)					*
*********************************************************************************/

DROP TABLE IF EXISTS Product;
GO
--Create a permanent table.  A temp table currently is not supported for BULK INSERT, although it will will work
--with OPENROWSET
CREATE TABLE dbo.Product(
	Name nvarchar(50) NOT NULL,
	Color nvarchar(15) NULL,
	Price money NOT NULL,
	Size nvarchar(5) NULL,
	Quantity int NULL,
	Data nvarchar(4000) NULL,
	Tags nvarchar(4000) NULL
	--,INDEX cci CLUSTERED COLUMNSTORE
)
GO

/********************************************************************************
*								2. LOAD											*
*********************************************************************************/

-- 2.1. INSERT CSV file into Product table
BULK INSERT Product
FROM 'product.csv'
WITH (	DATA_SOURCE = 'MyAzureBlobStorage',
		FORMAT='CSV', CODEPAGE = 65001, --UTF-8 encoding
		FIRSTROW=2,
                ROWTERMINATOR = '0x0a',
		TABLOCK);

-- 2.2. INSERT file exported using bcp.exe into Product table
BULK INSERT Product
FROM 'product.bcp'
WITH (	DATA_SOURCE = 'MyAzureBlobStorage',
		FORMATFILE='product.fmt',
		FORMATFILE_DATA_SOURCE = 'MyAzureBlobStorage',
		TABLOCK);

-- 2.3. Read rows from product.dat file using format file and insert it into Product table
INSERT INTO Product WITH (TABLOCK) (Name, Color, Price, Size, Quantity, Data, Tags)
SELECT Name, Color, Price, Size, Quantity, Data, Tags
FROM OPENROWSET(BULK 'product.bcp',
				DATA_SOURCE = 'MyAzureBlobStorage',
				FORMATFILE='product.fmt',
				FORMATFILE_DATA_SOURCE = 'MyAzureBlobStorage') as products;

-- 2.4. Query remote file
SELECT Color, count(*)
FROM OPENROWSET(BULK 'product.bcp',
				DATA_SOURCE = 'MyAzureBlobStorage',
				FORMATFILE='data/product.fmt',
				FORMATFILE_DATA_SOURCE = 'MyAzureBlobStorage') as data
GROUP BY Color;
