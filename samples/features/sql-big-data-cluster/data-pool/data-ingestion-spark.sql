USE sales
GO

-- Create external table in a data pool in SQL Server 2019 big data cluster.
-- The SqlDataPool data source is a special data source that is available in
-- any new database in SQL Master instance. This is used to reference the
-- data pool in a SQL Server 2019 big data cluster.
--
IF NOT EXISTS(SELECT * FROM sys.external_tables WHERE name = 'web_clickstreams_spark_results')
    CREATE EXTERNAL TABLE [web_clickstreams_spark_results]
    ("wcs_click_date_sk" BIGINT , "wcs_click_time_sk" BIGINT , "wcs_sales_sk" BIGINT , "wcs_item_sk" BIGINT , "wcs_web_page_sk" BIGINT , "wcs_user_sk" BIGINT)
    WITH
    (
        DATA_SOURCE = SqlDataPool,
        DISTRIBUTION = ROUND_ROBIN
    );

-- Data can be ingested into the external table from a spark job.
--
-- Submit spark job with below parameters. You can use the Spark submit experience from Azure Data Studio.
-- Right click on server name in a SQL Server big data cluster connection and click "Submit Spark Job".
--
-- Specify following values in the Job submission dialog box:
---- job name: <yourJobName>
---- switch from "Local" to "HDFS"
---- Main class: "FileStreaming"
---- Path to jar: /jar/mssql-spark-lib-assembly-1.0.jar
---- Arguments:
---- --server mssql-master-pool-0.service-master-pool --port 1433 --user sa --password !yourPassword! --database sales --table web_clickstreams_spark_results --source_dir hdfs:///clickstream_data --input_format csv --enable_checkpoint false --timeout 380000

-- The arguments to jar file are
-- 1: server name - sql server to connect to read the table schema
-- 2: port number
-- 3: username - sql server username for master instance
-- 4: password - sql server password for master instance
-- 5: database name
-- 6: external table name
-- 7: Source directory for streaming. This must be a full URI - such as "hdfs:///clickstream_data"
-- 8: Input format. This can be "csv", "parquet", "json".
-- 9: enable checkpoint: true or false
-- 10: timeout - in milliseconds - how long to run for before stopping
--

-- After the Spark streaming job has been sucessfully submitted, you can run below query to view the results.
--
-- Wait until some rows are available.
WHILE (1=1)
    IF EXISTS(SELECT * FROM [web_clickstreams_spark_results])
        BREAK;

SELECT count(*) FROM [web_clickstreams_spark_results];
SELECT TOP 10 * FROM [web_clickstreams_spark_results];
GO

DROP EXTERNAL TABLE [dbo].[web_clickstreams_spark_results];
GO
