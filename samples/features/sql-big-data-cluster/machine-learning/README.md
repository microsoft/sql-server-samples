# Machine Learning in SQL Server 2019 big data cluster

## SQL Server Machine Learning Services

SQL Server 2016 added capability to run R script from T-SQL. SQL Server 2017 added support for running Python scripts from T-SQL. SQL Server 2019 adds support for running Java code from T-SQL. You can now run R, Python or Java code from T-SQL in SQL Server 2019 on Windows or Linux or SQL Server 2019 big data cluster.

[sql](sql)

SQL Server machine learning services samples showing R, Python & Java support.

## Machine learning using Spark

The new built-in notebooks in Azure Data Studio enables data scientists and data engineers to run Python, R, or Scala code against the cluster. This is a great way to explore the data and build machine learning models. Notebooks facilitate collaboration between teammates working on a shared data set.

This sample builds a machine learning model using AdultCensusIncome.csv available [here](https://amldockerdatasets.azureedge.net/AdultCensusIncome.csv).

[spark](spark)

### Instructions

In this example, you are going to run sample notebooks that build a machine learning model over a public data set.

Follow the steps below to get up and running with the sample.

#### Upload the data for analysis

1. From Azure Data Studio, connect to the SQL Server big data cluster endpoint. Information about how you connect from Azure Data Studio can be found [here](https://docs.microsoft.com/en-us/sql/azure-data-studio/sql-server-2019-extension?view=sql-server-ver15).

2. Download the data from https://amldockerdatasets.azureedge.net/AdultCensusIncome.csv and save AdultCensusIncome.csv in a folder called spark_ml in HDFS.

#### Run notebook for data preparation
As a first step we'll load the data, do some basic cleanup on that data, choose the features that we want to build the machine learning model with. Finally we'll split the data set as training and test sets.

1. Download and save the notebook file [spark/1-data-prep.ipynb](spark/1-data-prep.ipynb/) locally.

1. Open the notebook file in Azure Data Studio (right click on the SQL Server big data cluster  server name-> **Manage**-> Open Notebook.

1. Wait for the “Kernel” and the target context (“Attach to”) to be populated. Set the “Kernel” to **PySpark3** and “Attach to” needs to be the IP address of your big data cluster endpoint.

1. Run each cell in the Notebook sequentially using Azure Data Studio. Expect the first cell to take 20 sec to finish.

1. The training and test sets created would be stored as /spark_ml/AdultCensusIncomeTrain and /spark_ml/AdultCensusIncomeTest

#### Run notebook to create a machine learning model and use it to predict
We'll now create the machine learning model, use the model to predict results on the test set and then save the created model to a file.

1. Download and save the notebook (ipynb) file [spark\2-build-ml-model.ipynb](spark/2-build-ml-model.ipynb/)

1. Open the notebook file in Azure Data Studio (right click on the SQL Server big data cluster  server name-> **Manage**-> Open Notebook.

1. Wait for the “Kernel” and the target context (“Attach to”) to be populated. Set the “Kernel” to **PySpark3** and “Attach to” needs to be the IP address of your big data cluster endpoint.

1. Run each cell in the Notebook sequentially using Azure Data Studio.

1. The machine learning model would be persisted as /spark_ml/AdultCensus.mml.