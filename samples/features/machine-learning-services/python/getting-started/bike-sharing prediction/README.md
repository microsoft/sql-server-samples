# Build a predictive model with RevoScalePy using SQL Server 2017 Machine Learning Services

This sample shows how to create a predictive model using RevoScalePy in conjunction with python machine learning stack.

The dataset  used in this tutorial is based on Vélib which is a large scale public service of rent bike in Paris, the service offers today about around 14500 bicycles and 1230 stations http://en.velib.paris.fr/.

The dataset is a one month long  sampled on a 15 minutes frequency of the 8th district of Paris.


### Contents

[About this sample](#about-this-sample)

[Before you begin](#before-you-begin)

[Sample details](#sample-details)




## About this sample


This sample consist of a  binary classifier that predict whether a particular bike station is empty or not.




- **Applies to:** SQL Server 2017 CTP2.0 or higher
- **Key features:** SQL Server Machine Learning Services
- **Workload:** SQL Server Machine Learning Services
- **Programming Language:** Python, TSQL
- **Author:** Yassine Khelifi



## Before you begin

To run this sample, you need the following prerequisites:
1. [Download this DB backup file](https://sq14samples.blob.core.windows.net/data/velibDB.bak) and restore it using Setup.sql.

**Software prerequisites:**


1. [SQL Server 2017 CTP2.0](https://www.microsoft.com/en-us/sql-server/sql-server-2017) (or higher) with Machine Learning Services (Python) installed
2. [SQL Server Management Studio](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
3. [Python Tools for Visual Studio](https://www.visualstudio.com/vs/python/) or another Python IDE

## Run this sample
1. From SQL Server Management Studio, or SQL Server Data Tools, connect to your SQL Server 2017 database and execute setup.sql to restore the sample DB you have downloaded

2. From Python Tools for Visual Studio, open the python tools command under tools menu, add the Machine Learning Services Python environment to the corresponding paths https://docs.microsoft.com/en-us/visualstudio/python/python-environments

   *  "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\PYTHON_SERVICES" if you run in-db Python Server
   *  "C:\Program Files\Microsoft SQL Server\140\PYTHON_SERVER" if you have the standalone Machine Learning Server installed .

3. Create new Python project from existing code and point to the downloaded python source files, and the Machine Learning Services Python environment defined in step 2.






## Sample details

#### datasource.py
This Python script defines the class that pull data from Sql database and provides access to SQL Server Compute Context.

####  pipeline.py
This python file defines the machine learning pipeline that performs features engineering and the classifier that fits the RevoScalePy binary logistic regression.

####  runner.py
This python file defines the startup code and main method from which to excecute the solution.

####  setup.sql
Restores the sample DB (Make sure to update the path to the .bak file)





## Disclaimers
The dataset used in this sample is obtained from JCdecaux https://developer.jcdecaux.com/#/opendata/license




