USE sales
GO

-- Create external data source for Data Pool inside a SQL big data cluster
--
IF NOT EXISTS(SELECT * FROM sys.external_data_sources WHERE name = 'SqlDataPool')
    CREATE EXTERNAL DATA SOURCE SqlDataPool
    WITH (LOCATION = 'sqldatapool://controller-svc/default');

-- Create external table in a data pool in SQL Server 2019 big data cluster.
-- The SqlDataPool data source is a special data source that is available in
-- any new database in SQL Master instance. This is used to reference the
-- data pool in a SQL Server 2019 big data cluster.
--
IF NOT EXISTS(SELECT * FROM sys.external_tables WHERE name = 'web_clickstream_clicks_data_pool')
    CREATE EXTERNAL TABLE [web_clickstream_clicks_data_pool]
    ("wcs_user_sk" BIGINT , "i_category_id" BIGINT , "clicks" BIGINT)
    WITH
    (
        DATA_SOURCE = SqlDataPool,
        DISTRIBUTION = ROUND_ROBIN
    );
GO

-- Insert results of a SELECT statement into the external table created on the data pool.
-- Store summary results for quick access instead of going to the source tables always.
--
INSERT INTO web_clickstream_clicks_data_pool
SELECT wcs_user_sk, i_category_id, COUNT_BIG(*) as clicks
  FROM sales.dbo.web_clickstreams_hdfs_parquet
 INNER JOIN sales.dbo.item it ON (wcs_item_sk = i_item_sk
                        AND wcs_user_sk IS NOT NULL)
 GROUP BY wcs_user_sk, i_category_id
HAVING COUNT_BIG(*) > 100;
GO

-- Query data inserted into the data pool table
--
SELECT count(*) FROM [dbo].[web_clickstream_clicks_data_pool]
SELECT TOP 10 * FROM [dbo].[web_clickstream_clicks_data_pool]

-- Join external table with local tables
--
SELECT TOP (100)
    w.wcs_user_sk,
    SUM( CASE WHEN i.i_category = 'Books' THEN w.clicks ELSE 0 END) AS book_category_clicks,
    SUM( CASE WHEN w.i_category_id = 1 THEN w.clicks ELSE 0 END) AS [Home & Kitchen],
    SUM( CASE WHEN w.i_category_id = 2 THEN w.clicks ELSE 0 END) AS [Music],
    SUM( CASE WHEN w.i_category_id = 3 THEN w.clicks ELSE 0 END) AS [Books],
    SUM( CASE WHEN w.i_category_id = 4 THEN w.clicks ELSE 0 END) AS [Clothing & Accessories],
    SUM( CASE WHEN w.i_category_id = 5 THEN w.clicks ELSE 0 END) AS [Electronics],
    SUM( CASE WHEN w.i_category_id = 6 THEN w.clicks ELSE 0 END) AS [Tools & Home Improvement],
    SUM( CASE WHEN w.i_category_id = 7 THEN w.clicks ELSE 0 END) AS [Toys & Games],
    SUM( CASE WHEN w.i_category_id = 8 THEN w.clicks ELSE 0 END) AS [Movies & TV],
    SUM( CASE WHEN w.i_category_id = 9 THEN w.clicks ELSE 0 END) AS [Sports & Outdoors]
  FROM [dbo].[web_clickstream_clicks_data_pool] as w
  INNER JOIN (SELECT DISTINCT i_category_id, i_category FROM item) as i
    ON i.i_category_id = w.i_category_id
GROUP BY w.wcs_user_sk;
GO

-- Cleanup
/*
DROP EXTERNAL TABLE [dbo].[web_clickstream_clicks_data_pool];
DROP EXTERNAL DATA SOURCE SqlDataPool;
GO
*/