USE sales
GO

-- Create external data source for HDFS inside SQL big data cluster.
--
IF NOT EXISTS(SELECT * FROM sys.external_data_sources WHERE name = 'SqlStoragePool')
    CREATE EXTERNAL DATA SOURCE SqlStoragePool
    WITH (LOCATION = 'sqlhdfs://controller-svc/default');

-- Create file format for CSV separated file with appropriate properties.
--
IF NOT EXISTS(SELECT * FROM sys.external_file_formats WHERE name = 'csv_file')
    CREATE EXTERNAL FILE FORMAT csv_file
    WITH (
        FORMAT_TYPE = DELIMITEDTEXT,
        FORMAT_OPTIONS(
            FIELD_TERMINATOR = ',',
            STRING_DELIMITER = '"',
            USE_TYPE_DEFAULT = TRUE)
    );


-- Create external table over HDFS data source (SqlStoragePool) in
-- SQL Server 2019 big data cluster. The SqlStoragePool data source
-- is a special data source that is available in any new database in
-- SQL Master instance.
--
IF NOT EXISTS(SELECT * FROM sys.external_tables WHERE name = 'product_reviews_hdfs_csv')
    CREATE EXTERNAL TABLE [product_reviews_hdfs_csv]
    ("pr_review_sk" BIGINT , "pr_review_content" varchar(8000))
    WITH
    (
        DATA_SOURCE = SqlStoragePool,
        LOCATION = '/product_review_data',
        FILE_FORMAT = csv_file
    );
GO

-- Join external table with local tables
--
SELECT
    p.pr_review_sk, pc.pr_review_content
  FROM product_reviews as p
  JOIN (SELECT TOP(10) * FROM product_reviews_hdfs_csv) AS pc
    ON pc.pr_review_sk = p.pr_review_sk;
GO

-- Cleanup
/*
DROP EXTERNAL TABLE [dbo].[product_reviews_hdfs_csv];
GO
*/
