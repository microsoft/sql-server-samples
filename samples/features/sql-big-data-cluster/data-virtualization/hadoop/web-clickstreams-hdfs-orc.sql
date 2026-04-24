USE sales
GO

-- Create data source for HDFS inside SQL big data cluster using the HADOOP type.
-- The HADOOP data source type was introduced in SQL Server 2016 to query data in
-- Hadoop clusters and relies on Java Hadoop client libraries and Map/Reduce for query
-- execution.
--
IF NOT EXISTS(SELECT * FROM sys.external_data_sources WHERE name = 'HadoopData')
    CREATE EXTERNAL DATA SOURCE HadoopData
    WITH(
            TYPE=HADOOP,
            LOCATION='hdfs://nmnode-0-svc:9000/',
            RESOURCE_MANAGER_LOCATION='sparkhead-svc:8032'
    );


-- Create file format for orc file with appropriate properties.
--
IF NOT EXISTS(SELECT * FROM sys.external_file_formats WHERE name = 'orc_file')
    CREATE EXTERNAL FILE FORMAT orc_file
    WITH (
        FORMAT_TYPE = ORC,
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
    );


-- Create external table over HDFS data source using HADOOP type in
-- SQL Server 2019 big data cluster. The HADOOP data source is existing
-- PolyBase v1 syntax available by specifying location to HDFS namenode in
-- SQL Server big data cluster.
--
IF NOT EXISTS(SELECT * FROM sys.external_tables WHERE name = 'web_clickstreams_hdfs_orc')
    CREATE EXTERNAL TABLE [web_clickstreams_hdfs_orc]
    ("wcs_click_date_sk" BIGINT , "wcs_click_time_sk" BIGINT , "wcs_sales_sk" BIGINT , "wcs_item_sk" BIGINT , "wcs_web_page_sk" BIGINT , "wcs_user_sk" BIGINT)
    WITH
    (
        DATA_SOURCE = HadoopData,
        LOCATION = '/user/hive/warehouse/web_clickstreams_orc',
        FILE_FORMAT = orc_file
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
  FROM [dbo].[web_clickstreams_hdfs_orc]
  INNER JOIN item it ON (wcs_item_sk = i_item_sk
                        AND wcs_user_sk IS NOT NULL)
GROUP BY  wcs_user_sk;
GO

-- Cleanup
/*
DROP EXTERNAL TABLE [dbo].[web_clickstreams_hdfs_orc];
GO
*/
