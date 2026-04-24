-- Define an external data source
-- For accessing non-public external data sources, make sure to setup credentials
-- Read more here: https://azure.microsoft.com/en-us/documentation/articles/sql-data-warehouse-get-started-load-with-polybase/#step-2-create-an-external-table-for-the-sample-data
CREATE EXTERNAL DATA SOURCE NYTPublic
WITH
(
    TYPE = Hadoop
,   LOCATION = 'wasbs://2013@nytpublic.blob.core.windows.net/'
); 