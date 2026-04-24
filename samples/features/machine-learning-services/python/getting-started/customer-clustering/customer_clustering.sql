USE [tpcxbb_1gb]
GO

-- Stored procedure that performs customer clustering using Python and SQL Server ML Services
CREATE OR ALTER PROCEDURE [dbo].[py_generate_customer_return_clusters]
AS

BEGIN
	DECLARE

-- Input query to generate the purchase history & return metrics
	 @input_query NVARCHAR(MAX) = N'
SELECT
  ss_customer_sk AS customer,
  CAST( (ROUND(COALESCE(returns_count / NULLIF(1.0*orders_count, 0), 0), 7) ) AS FLOAT) AS orderRatio,
  CAST( (ROUND(COALESCE(returns_items / NULLIF(1.0*orders_items, 0), 0), 7) ) AS FLOAT) AS itemsRatio,
  CAST( (ROUND(COALESCE(returns_money / NULLIF(1.0*orders_money, 0), 0), 7) ) AS FLOAT) AS monetaryRatio,
  CAST( (COALESCE(returns_count, 0)) AS FLOAT) AS frequency
FROM
  (
    SELECT
      ss_customer_sk,
      -- return order ratio
      COUNT(distinct(ss_ticket_number)) AS orders_count,
      -- return ss_item_sk ratio
      COUNT(ss_item_sk) AS orders_items,
      -- return monetary amount ratio
      SUM( ss_net_paid ) AS orders_money
    FROM store_sales s
    GROUP BY ss_customer_sk
  ) orders
  LEFT OUTER JOIN
  (
    SELECT
      sr_customer_sk,
      -- return order ratio
      count(distinct(sr_ticket_number)) as returns_count,
      -- return ss_item_sk ratio
      COUNT(sr_item_sk) as returns_items,
      -- return monetary amount ratio
      SUM( sr_return_amt ) AS returns_money
    FROM store_returns
    GROUP BY sr_customer_sk
  ) returned ON ss_customer_sk=sr_customer_sk
 '

EXEC sp_execute_external_script
	  @language = N'Python'
	, @script = N'

import pandas as pd
from sklearn.cluster import KMeans

#We concluded in step2 in the tutorial that 4 would be a good number of clusters
n_clusters = 4

#Perform clustering
est = KMeans(n_clusters=n_clusters, random_state=111).fit(customer_data[["orderRatio","itemsRatio","monetaryRatio","frequency"]])
clusters = est.labels_
customer_data["cluster"] = clusters

#OutputDataSet = customer_data
'
	, @input_data_1 = @input_query
	, @input_data_1_name = N'customer_data'
	,@output_data_1_name = N'customer_data'
			 with result sets (("Customer" int, "orderRatio" float,"itemsRatio" float,"monetaryRatio" float,"frequency" float,"cluster" float));
END;
GO


--Creating a table for storing the clustering data
DROP TABLE IF EXISTS [dbo].[py_customer_clusters];
GO
--Create a table to store the predictions in
CREATE TABLE [dbo].[py_customer_clusters](
 [Customer] [bigint] NULL,
 [OrderRatio] [float] NULL,
 [itemsRatio] [float] NULL,
 [monetaryRatio] [float] NULL,
 [frequency] [float] NULL,
 [cluster] [int] NULL,
 ) ON [PRIMARY]
GO

--Execute the clustering and insert results into table
INSERT INTO py_customer_clusters
EXEC [dbo].[py_generate_customer_return_clusters];

-- Select contents of the table
SELECT * FROM py_customer_clusters;

--Get email addresses of customers in cluster 0
SELECT customer.[c_email_address], customer.c_customer_sk
  FROM dbo.customer
  JOIN
  [dbo].[py_customer_clusters] as c
  ON c.Customer = customer.c_customer_sk
  WHERE c.cluster = 0;

