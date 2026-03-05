# SQL Server big data clusters

SQL Server Big Data cluster bundles Spark and HDFS together with SQL server. Azure Data Studio IDE provides built in notebooks that enables data scientists and data engineers to run Spark notebooks and job in Python, R, or Scala code against the Big Data Cluster. This folder contains spark sample notebook on using Spark in SQL server Big data cluster

## Contents

[PySpark Hello World](data-loading/hello_PySpark.ipynb)

[Scala Hello World ](data-loading/hello_Scala.ipynb)

[SparkR Hello World ](data-loading/hello_sparkR.ipynb)

[Data Loading   - Transforming CSV to Parquet](data-loading/transform-csv-files.ipynb/)

[Data Virtualization - Spark to SQL using MSSQL Spark connector](data-virtualization/mssql_spark_connector_non_ad_pyspark.ipynb/)

[Data Virtualization - Spark to SQL using Spark JDBC connector](data-virtualization/spark_to_sql_jdbc.ipynb/)

[Data Virtualization - Spark with external Object Stores](data-virtualization/spark_external_object_store.ipynb/)

[Configure  - Configure a spark session using a notebook](config-install/configure_spark_session.ipynb/)

[Install - Install 3rd party packages](config-install/installpackage_Spark.ipynb/)

[Restful-Access - Access Spark in BDC via restful Livy APIs](restful-api-access/accessing_spark_via_livy.ipynb/)

## Instructions on how to run in Azure Data Studio

1. From Azure Data Studio Connect to the SQL Server Master instance in a big data cluster. 

2. Right-click on the server name, select **Manage**, switch to **SQL Server Big Data Cluster** tab, and open the notebook in Azure Data Studio.  Wait for the “Kernel” and the target context (“Attach to”) to be populated. If required set the relevant “Kernel” ( e.g **PySpark3** )  and **Attach to** needs to be the IP address of your big data cluster endpoint.

3. Run each cell in the Notebook sequentially.
