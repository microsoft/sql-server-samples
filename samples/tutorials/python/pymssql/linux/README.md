# Connect to SQL using Python on Ubuntu Linux

Python sample code that runs on an Ubuntu Linux client computer to connect to an Azure SQL Database using the **pymssql** connector.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database, Azure SQL Data Warehouse, Parallel Data Warehouse
- **Workload:** CRUD
- **Programming Language:** Python
- **Authors:** Meet Bhagdev [meet-bhagdev]

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. Python

	```
	sudo apt-get --assume-yes update
	sudo apt-get --assume-yes install python-dev python-pip
	```
3. FreeTDS

	```
	sudo apt-get --assume-yes install freetds-dev freetds-bin
	```

4. pymssql

	```
	sudo pip install pymssql
	```

**Azure prerequisites:**

1. An AdventureWorks sample database:

	- The Python sample relies on the AdventureWorks sample database. If you do not already have AdventureWorks, you can see how to create it at the following topic: [Create your first Azure SQL Database](http://azure.microsoft.com/documentation/articles/sql-database-get-started/)
	
## Run this sample

1. From your terminal, update the connection string details in the Python file with your own username, password, and hostname.

2. Run the code sample by running the below in your terminal:

	```
	python sample_python_linux.py
	```

<a name=sample-details></a>

## Sample details

The above sample code just connected to your AdventureWorks database and performed a SELECT statement and an INSERT statement.

## Disclaimers
The scripts and this guide are copyright Microsoft Corporations and are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.