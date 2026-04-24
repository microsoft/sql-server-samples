USE sales
GO

-- Create external data source for HDFS inside SQL big data cluster.
--
IF NOT EXISTS(SELECT * FROM sys.external_data_sources WHERE name = 'SqlStoragePool')
    CREATE EXTERNAL DATA SOURCE SqlStoragePool
    WITH (LOCATION = 'sqlhdfs://controller-svc/default');

-- Create file format for parquet file with appropriate properties.
--
IF NOT EXISTS(SELECT * FROM sys.external_file_formats WHERE name = 'parquet_file')
    CREATE EXTERNAL FILE FORMAT parquet_file
    WITH (
        FORMAT_TYPE = PARQUET
    );

-- Create external table over HDFS data source (SqlStoragePool) in
-- SQL Server 2019 big data cluster. The SqlStoragePool data source
-- is a special data source that is available in any new database in
-- SQL Master instance.
--
IF NOT EXISTS(SELECT * FROM sys.external_tables WHERE name = 'web_clickstreams_hdfs_parquet')
    CREATE EXTERNAL TABLE [web_clickstreams_hdfs_parquet]
    ("wcs_click_date_sk" BIGINT , "wcs_click_time_sk" BIGINT , "wcs_sales_sk" BIGINT , "wcs_item_sk" BIGINT , "wcs_web_page_sk" BIGINT , "wcs_user_sk" BIGINT)
    WITH
    (
        DATA_SOURCE = SqlStoragePool,
        LOCATION = '/user/hive/warehouse/web_clickstreams',
        FILE_FORMAT = parquet_file
    );
GO

-- Join external table with local tables
--
SELECT
    wcs_user_sk,
    SUM( CASE WHEN i_category = 'Books' THEN 1 ELSE 0 END) AS book_category_clicks,
    SUM( CASE WHEN i_category_id = 1 THEN 1 ELSE 0 END) AS [Home & Kitchen],
    SUM( CASE WHEN i_category_id = 2 THEN 1 ELSE 0 END) AS [Music],
    SUM( CASE WHEN i_category_id = 3 THEN 1 ELSE 0 END) AS [Books],
    SUM( CASE WHEN i_category_id = 4 THEN 1 ELSE 0 END) AS [Clothing & Accessories],
    SUM( CASE WHEN i_category_id = 5 THEN 1 ELSE 0 END) AS [Electronics],
    SUM( CASE WHEN i_category_id = 6 THEN 1 ELSE 0 END) AS [Tools & Home Improvement],
    SUM( CASE WHEN i_category_id = 7 THEN 1 ELSE 0 END) AS [Toys & Games],
    SUM( CASE WHEN i_category_id = 8 THEN 1 ELSE 0 END) AS [Movies & TV],
    SUM( CASE WHEN i_category_id = 9 THEN 1 ELSE 0 END) AS [Sports & Outdoors]
  FROM [dbo].[web_clickstreams_hdfs_parquet]
  INNER JOIN item it ON (wcs_item_sk = i_item_sk
                        AND wcs_user_sk IS NOT NULL)
GROUP BY  wcs_user_sk;
GO

-- Create view used for ML services training stored procedure
CREATE OR ALTER VIEW [dbo].[web_clickstreams_hdfs_book_clicks]
AS
	SELECT
        /* There is bug in TPCx-BB data generator which results in data where all users have purchased books.
        This will not work for the ML training purposes. So we will treat users with 1-5 clicks in the book category as
        not interested in books. */
	  CASE WHEN q.clicks_in_category < 6 THEN 0 ELSE q.clicks_in_category END AS clicks_in_category,
	  CASE WHEN cd.cd_education_status IN ('Advanced Degree', 'College', '4 yr Degree', '2 yr Degree') THEN 1 ELSE 0 END AS college_education,
	  CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END AS male,
	  COALESCE(cd.cd_credit_rating, 'Unknown') as cd_credit_rating,
	  q.clicks_in_1,
	  q.clicks_in_2,
	  q.clicks_in_3,
	  q.clicks_in_4,
	  q.clicks_in_5,
	  q.clicks_in_6,
	  q.clicks_in_7,
	  q.clicks_in_8,
	  q.clicks_in_9,
	  q.wcs_user_sk
	FROM(
	  SELECT
		w.wcs_user_sk,
		SUM( CASE WHEN i.i_category = 'Books' THEN 1 ELSE 0 END) AS clicks_in_category,
		SUM( CASE WHEN i.i_category_id = 1 THEN 1 ELSE 0 END) AS clicks_in_1,
		SUM( CASE WHEN i.i_category_id = 2 THEN 1 ELSE 0 END) AS clicks_in_2,
		SUM( CASE WHEN i.i_category_id = 3 THEN 1 ELSE 0 END) AS clicks_in_3,
		SUM( CASE WHEN i.i_category_id = 4 THEN 1 ELSE 0 END) AS clicks_in_4,
		SUM( CASE WHEN i.i_category_id = 5 THEN 1 ELSE 0 END) AS clicks_in_5,
		SUM( CASE WHEN i.i_category_id = 6 THEN 1 ELSE 0 END) AS clicks_in_6,
		SUM( CASE WHEN i.i_category_id = 7 THEN 1 ELSE 0 END) AS clicks_in_7,
		SUM( CASE WHEN i.i_category_id = 8 THEN 1 ELSE 0 END) AS clicks_in_8,
		SUM( CASE WHEN i.i_category_id = 9 THEN 1 ELSE 0 END) AS clicks_in_9
	  FROM web_clickstreams_hdfs_parquet as w
	  INNER JOIN item as i ON (w.wcs_item_sk = i_item_sk
						 AND w.wcs_user_sk IS NOT NULL)
	  GROUP BY w.wcs_user_sk
	) AS q
	INNER JOIN customer_ora as c ON q.wcs_user_sk = c.C_CUSTOMER_SK
	INNER JOIN customer_demographics as cd ON c.C_CURRENT_CDEMO_SK = cd.cd_demo_sk;
GO


-- Inspect top 100 rows
SELECT TOP(100) * FROM web_clickstreams_hdfs_book_clicks;
GO

-- Cleanup
/*
DROP EXTERNAL TABLE [dbo].[web_clickstreams_hdfs_parquet];
GO
*/
