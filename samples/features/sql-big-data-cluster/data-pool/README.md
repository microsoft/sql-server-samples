# Data pools in SQL Server 2019 big data cluster

SQL Server Big Data clusters provide scale-out compute and storage to improve the performance of analyzing any data. Data from a variety of sources can be ingested and distributed across data pool instances for analysis. In this example, we will insert data from a SQL query into an external table stored in a data pool and query it.

## Data ingestion using SQL stored procedure

SQL Server Big Data clusters provide scale-out compute and storage to improve the performance of analyzing any data. Data from a variety of sources can be ingested and distributed across data pool instances for analysis. In this example, we will insert data from a SQL query into an external table stored in a data pool and query it.

### Instructions

1. Connect to SQL Server Master instance.

1. Execute the .sql script [data-ingestion-sql.sql](data-ingestion-sql.sql).

## Data ingestion using Spark streaming

In this example, you are going to use Spark to read and transform data from HDFS and cache it in a data pool. Querying the external table created over this aggregated data stored in data pools will be much more efficient than going to the raw data always.

### Instructions

1. Using Azure Data Studio, connect to the HDFS/Spark gateway (SQL Server big data cluster connection type).

1. Connect to SQL Server Master instance using Azure Data Studio.

1. Execute the SQL script [data-ingestion-spark.sql](data-ingestion-spark.sql).

1. Create and submit a Spark job that ingests data from HDFS into the external table.

Submitting a Spark job will start a Spark streaming session using spark-submit.

    The arguments to the jar file are:

    1. server name - sql server to connect to read the table schema
    2. port number
    3. username - sql server username for master instance
    4. password - sql server password for master instance
    5. database name
    6. external table name
    7. Source directory for streaming. This must be a full URI - such as "hdfs:///clickstream_data"
    8. Input format. This can be "csv", "parquet", "json".
    9. enable checkpoint: true or false

  Submit a Spark job with the below parameters. You can use the Spark submit experience from Azure Data Studio (right click on big data cluster endpoint -> Submit Spark Job):

    ARGUMENTS:

    **job name:** yourJobName

    **switch** from "Local" to "HDFS"

    **Path to jar** (copy/paste this):

    /jar/mssql-spark-lib-assembly-1.0.jar

    **Main class:**
    FileStreaming

    **Parameters (copy/paste this; make sure you replace the password!):**

    mssql-master-pool-0.service-master-pool 1433 sa passwordHere sales web_clickstreams_spark_results hdfs:///clickstream_data csv false

6. Query the external table we created earlier using the SELECT queries in the script to see data coming from the streaming job and landing in the table.