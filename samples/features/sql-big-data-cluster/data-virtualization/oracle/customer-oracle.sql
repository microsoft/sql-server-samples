USE sales
GO

-- Create database scoped credential to connect to Oracle server
-- Provide appropriate credentials to Oracle server in below statement.
-- If you are using SQL Server Management Studio then you can replace the parameters using
-- the Query menu, and "Specify Values for Template Parameters" option.
IF NOT EXISTS(SELECT * FROM sys.database_scoped_credentials WHERE name = 'OracleCredential')
  CREATE DATABASE SCOPED CREDENTIAL [OracleCredential]
  WITH IDENTITY = '<oracle_user,nvarchar(100),sales>', SECRET = '<oracle_user_password,nvarchar(100),sql19tw0oracle>';

-- Create external data source that points to Oracle server
--
IF NOT EXISTS(SELECT * FROM sys.external_data_sources WHERE name = 'OracleSalesSrvr')
  CREATE EXTERNAL DATA SOURCE [OracleSalesSrvr]
  WITH (LOCATION = 'oracle://<oracle_server,nvarchar(100),oracle-server-name>',CREDENTIAL = [OracleCredential]);

-- Create external table over inventory table on Oracle server
-- NOTE: Table names and column names will use ANSI SQL quoted identifier while querying against Oracle.
--       As a result, the names are case-sensitive so specify the name in the external table definition
--       that matches the exact case of the table and column names in the Oracle metadata.
CREATE EXTERNAL TABLE [dbo].[customer_ora]
(
    [C_CUSTOMER_SK] DECIMAL(10,0),
    [C_CUSTOMER_ID] NVARCHAR(16) COLLATE Latin1_General_100_BIN2_UTF8,
    [C_CURRENT_CDEMO_SK] DECIMAL(10,0),
    [C_CURRENT_HDEMO_SK] DECIMAL(10,0),
    [C_CURRENT_ADDR_SK] DECIMAL(10,0),
    [C_FIRST_SHIPTO_DATE_SK] DECIMAL(10,0),
    [C_FIRST_SALES_DATE_SK] DECIMAL(8,0),
    [C_SALUTATION] NVARCHAR(10) COLLATE Latin1_General_100_BIN2_UTF8,
    [C_FIRST_NAME] NVARCHAR(20) COLLATE Latin1_General_100_BIN2_UTF8,
    [C_LAST_NAME] NVARCHAR(30) COLLATE Latin1_General_100_BIN2_UTF8,
    [C_PREFERRED_CUST_FLAG] NVARCHAR COLLATE Latin1_General_100_BIN2_UTF8,
    [C_BIRTH_DAY] DECIMAL(8,0),
    [C_BIRTH_MONTH] DECIMAL(8,0),
    [C_BIRTH_YEAR] DECIMAL(8,0),
    [C_BIRTH_COUNTRY] NVARCHAR(20) COLLATE Latin1_General_100_BIN2_UTF8,
    [C_LOGIN] NVARCHAR(13) COLLATE Latin1_General_100_BIN2_UTF8,
    [C_EMAIL_ADDRESS] NVARCHAR(50) COLLATE Latin1_General_100_BIN2_UTF8,
    [C_LAST_REVIEW_DATE] NVARCHAR(20) COLLATE Latin1_General_100_BIN2_UTF8
)
WITH (DATA_SOURCE=[OracleSalesSrvr],
      LOCATION='<oracle_service_name,nvarchar(30),xe>.SALES.CUSTOMER');
GO

-- Find product reviews of customers who made purchases of items in a specific time window:
--
SELECT pr.pr_item_sk, pc.pr_review_content, pr.pr_user_sk AS customerid
FROM dbo.product_reviews as pr
JOIN (SELECT TOP(100) * FROM dbo.product_reviews_hdfs_csv) AS pc ON pc.pr_review_sk = pr.pr_review_sk
JOIN dbo.customer_ora AS c ON c.C_CUSTOMER_SK = pr.pr_user_sk
JOIN dbo.item AS i ON i.i_item_sk = pr.pr_item_sk
INNER JOIN (
    SELECT
      ws_item_sk
    FROM web_sales ws
    WHERE
        ws.ws_item_sk IS NOT null
        AND ws_sold_date_sk IN
            (
                SELECT d_date_sk
                FROM date_dim d
                WHERE d.d_date >= '2003-01-02'
                AND   d.d_date <= '2004-01-02'
            )
    GROUP BY ws_item_sk ) s
  ON pr.pr_item_sk = s.ws_item_sk;

-- Cleanup
--
/*
DROP EXTERNAL TABLE [customer_ora];
DROP EXTERNAL DATA SOURCE [OracleSalesSrvr] ;
DROP DATABASE SCOPED CREDENTIAL [OracleCredential];
*/
