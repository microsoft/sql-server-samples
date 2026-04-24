# SQL Server 2019 Feature Notebooks
In this folder, you will find various notebooks that you can use in [Azure Data Studio](https://docs.microsoft.com/sql/azure-data-studio/what-is) to guide you through the new features of SQL Server 2019.

The [What's New](https://docs.microsoft.com/sql/sql-server/what-s-new-in-sql-server-ver15) article covers all the *NEW* features in SQL Server 2019.

## Notebook List
### Notebooks
* **[SampleTSQLNotebook.ipynb](https://github.com/microsoft/azuredatastudio/blob/master/samples/notebookSamples/SampleTSQLNotebook.ipynb)** - This is a great place to start if you're curious about what notebooks are and how you can create your own notebooks in Azure Data Studio.

### Intelligent Query Processing
*  **[Scalar_UDF_Inlining.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/intelligent-query-processing/notebooks/Scalar_UDF_Inlining.ipynb)** - This notebook demonstrates the benefits of Scalar UDF Inlining along with how to find out which UDFs in your database can be inlined.
* **[Table_Variable_Deferred_Compilation.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/intelligent-query-processing/notebooks/Table_Variable_Deferred_Compilation.ipynb)** - In this notebook, you will learn about Table Variable Deferred Compilation which benefit the performance of queries that use table variables on SQL Server 2019.
* **[Batch_Mode_on_Rowstore.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/intelligent-query-processing/notebooks/Batch_Mode_on_Rowstore.ipynb)** - In this notebook, you will learn about how Batch Mode for Rowstore can help execute queries faster on SQL Server 2019.
* **[Memory_Grant_Feedback.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/intelligent-query-processing/notebooks/Memory_Grant_Feedback.ipynb)** - In this notebook, you will learn about how Memory Grant Feedback for Batch mode and Row mode can help execute queries faster on SQL Server 2019.
* **[Approximate_QP.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/intelligent-query-processing/notebooks/Approximate_QP.ipynb)** - In this notebook, you will learn about the new area of approximate query processing on SQL Server 2019.

### Security
* **[TDE_on_Standard.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/security/tde-sql2019-standard/TDE_on_Standard.ipynb)** - This notebook demonstrates the ability to enable TDE on SQL Server 2019 Standard Edition along with Encryption Scan SUSPEND and RESUME.
* **[TDE_on_Standard_EKM.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/security/tde-sql2019-standard/TDE_on_Standard_EKM.ipynb)** - This notebook demonstrates the ability to enable TDE on a SQL Server 2019 Standard Edition using EKM and Azure Key Vault.

### In-Memory Database
* **[MemoryOptimizedTempDBMetadata-TSQL.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/in-memory-database/memory-optimized-tempdb-metadata/MemoryOptimizedTempDBMetadata-TSQL.ipynb)** - This is a T-SQL notebook which shows the benefits of Memory Optimized Tempdb metadata.
* **[MemoryOptmizedTempDBMetadata-Python.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/in-memory-database/memory-optimized-tempdb-metadata/MemoryOptmizedTempDBMetadata-Python.ipynb)** - This is a Python notebook which shows the benefits of Memory Optimized Tempdb metadata.

### Availability
* **[Basic_ADR.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/accelerated-database-recovery/basic_adr.ipynb)** - In this notebook, you will see how fast long-running transaction rollback can now be with Accelerated Database Recovery. You will also see that a long active transaction does not affect the ability to truncate the transaction log.
* **[Recovery_ADR.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/accelerated-database-recovery/recovery_adr.ipynb)** - In this example, you will see how Accelerated Database Recovery will speed up recovery.

### Unicode Support (UTF-8 and UTF-16)
* **[DataType_WesternMyth.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/unicode/notebooks/DataType_WesternMyth.ipynb)**  - In this notebook, you will see evidence that the integer that defines the length of string types (CHAR/VARCHAR/NCHAR/NVARCHAR) does not mean "number of characters" but "number of bytes to encode", debunking a common misconception regarding string data types in SQL Server.
* **[Functional.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/unicode/notebooks/Functional.ipynb)** - In this notebook, you will see how to use UTF-8 in your database or columns.
* **[Storage.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/unicode/notebooks/Storage.ipynb)** - In this notebook, you will see how to the storage footprint differences are expressive between Unicode encoded in UTF-8 and UTF-16.
* **[Perf_Latin.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/unicode/notebooks/Perf_Latin.ipynb)** - In this notebook, you will see the performance differences of using string data encoded in UTF-8 and UTF-16 using Latin data.
* **[Perf_Non-Latin.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/unicode/notebooks/Perf_Non-Latin.ipynb)** - In this notebook, you will see the performance differences of using string data encoded in UTF-8 and UTF-16 using non-Latin data.
* **[CheckStorageReq_CurrDB.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/unicode/notebooks/CheckStorageReq_CurrDB.ipynb)** - In this notebook, you will be able to determine the UTF8 storage requirements for all tables and string columns in the database in scope.

### SQL Server 2019 Querying 1 TRILLION rows
* **[OneTrillionRowsWarm.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/sql2019notebooks/OneTrillionRowsWarm.ipynb)** - This notebook shows how SQL Server 2019 reads **9 BILLION rows/second** using a 1 trillion row table using a warm cache,
* **[OneTrillionRowsCold.ipynb](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/sql2019notebooks/OneTrillionRowsCold.ipynb)** - This notebook shows how SQL Server 2019 performs IO at **~24GB/s** using a 1 trillion row table with a cold cache.

### Big Data, Machine Learning & Data Virtualization
* **[SQL Server Big Data Clusters](https://github.com/microsoft/sqlworkshops/tree/master/sqlserver2019bigdataclusters/SQL2019BDC/notebooks)** - Part of our **[Ground to Cloud](https://aka.ms/sqlworkshops)** workshop. In this lab, you will use notebooks to experiment with SQL Server Big Data Clusters (BDC), and learn how you can use it to implement large-scale data processing and machine learning.
* **[Data Virtualization using PolyBase](https://github.com/microsoft/sqlworkshops/tree/master/sql2019workshop/sql2019wks/08_DataVirtualization/sqldatahub)** - The notebooks in this SQL Server 2019 workshop cover how to use SQL Server as a hub for data virtualization for sources like [Oracle](https://github.com/microsoft/sqlworkshops/tree/master/sql2019lab/04_DataVirtualization/sqldatahub/oracle), [SAP HANA](https://github.com/microsoft/sqlworkshops/tree/master/sql2019lab/04_DataVirtualization/sqldatahub/saphana), [Azure CosmosDB](https://github.com/microsoft/sqlworkshops/tree/master/sql2019lab/04_DataVirtualization/sqldatahub/cosmosdb), [SQL Server](https://github.com/microsoft/sqlworkshops/tree/master/sql2019lab/04_DataVirtualization/sqldatahub/sql2008r2) and [Azure SQL Database](https://github.com/microsoft/sqlworkshops/tree/master/sql2019lab/04_DataVirtualization/sqldatahub/azuredb).

* **[Spark with Big Data Clusters](https://github.com/microsoft/sql-server-samples/tree/master/samples/features/sql-big-data-cluster/spark)** - The notebooks in this folder cover the following scenarios:
  * Data Loading - Transforming CSV to Parquet
  * Data Transfer - Spark to SQL using Spark JDBC connector
  * Data Transfer - Spark to SQL using MSSQL Spark connector
  * Configure - Configure a spark session using a notebook
  * Install - Install 3rd party packages
  * Restful-Access - Access Spark in BDC via restful Livy APIs

* **Machine Learning**
  * **[Powerplant Output Prediction](https://github.com/microsoft/sql-server-samples/blob/master/samples/features/sql-big-data-cluster/machine-learning/spark/h2o/h2o-automl-powerplant.ipynb)** - This sample uses the automated machine learning capabilities of the third party H2O package running in Spark in a SQL Server 2019 Big Data Cluster to build a machine learning model that predicts powerplant output.
  * **[TensorFlow on GPUs in SQL Server 2019 big data cluster](https://github.com/microsoft/sql-server-samples/tree/master/samples/features/sql-big-data-cluster/machine-learning/spark/tensorflow)** - The notebooks in this directory illustrate fitting TensorFlow image classification models using GPU acceleration.

### SQL Server Troubleshooting Notebooks
* **[SQL Server Troubleshooting Notebooks](https://github.com/microsoft/tigertoolbox/tree/master/Troubleshooting-Notebooks)** - This repository of notebooks helps you troubleshooting common scenarios that you could encounter with SQL Server including Big Data Clusters.

### SQL Assessment API
* **[SQL Assessment API Quick Start and Tutorial Notebooks](https://github.com/microsoft/sql-server-samples/tree/master/samples/manage/sql-assessment-api/notebooks)** - SQL Assessment API provides a mechanism to evaluate the configuration of your SQL Server for best practices. In this repository, you will find two Azure Data Studio notebooks, one is for quick start in two steps and the other is a comprehensive tutorial that will step you through all the features of SQL Assessment API including customizing the existing rules and creating your own ones.

