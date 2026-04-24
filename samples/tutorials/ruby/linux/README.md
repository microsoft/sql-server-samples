# Connect to SQL using Ruby on Ubuntu Linux

Ruby sample code that runs on an Ubuntu Linux client computer to connect to an Azure SQL Database.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>

<a name=about-this-sample></a>

## About this sample
- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database, Azure SQL Data Warehouse
- **Workload:** CRUD
- **Programming Language:** Ruby
- **Authors:** Andrea Lam [ajlam]

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. Ruby Version Manager

	```
	sudo apt-get --assume-yes update
	command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
	curl -L https://get.rvm.io | bash -s stable
	source ~/.rvm/scripts/rvm
	```
3. Ruby

	```
	rvm install 2.3.1
	rvm use 2.3.1 --default
	```

4. FreeTDS

	```
	sudo apt-get --assume-yes install freetds-dev freetds-bin
	```

5. tiny_tds

	```
	gem install tiny_tds
	```

**Azure prerequisites:**

1. An AdventureWorks sample database:

	- The Ruby sample relies on the AdventureWorks sample database. If you do not already have AdventureWorks, you can see how to create it at the following topic: [Create your first Azure SQL Database](http://azure.microsoft.com/documentation/articles/sql-database-get-started/)
	
## Run this sample

1. From your terminal, update the connection string details in the Ruby file with your own username, password, and hostname.

2. Run the code sample by running the below in your terminal:

	```
	ruby sample_ruby_linux.rb
	```

<a name=sample-details></a>

## Sample details

The above sample code just connected to your AdventureWorks database and performed a SELECT statement and an INSERT statement.

### Additional notes for using TinyTDS with Azure

It is recommend the following settings when using TinyTDS with Azure.

   ```
	SET ANSI_NULLS ON
	SET CURSOR_CLOSE_ON_COMMIT OFF
	SET ANSI_NULL_DFLT_ON ON
	SET IMPLICIT_TRANSACTIONS OFF
	SET ANSI_PADDING ON
	SET QUOTED_IDENTIFIER ON
	SET ANSI_WARNINGS ON
	SET CONCAT_NULL_YIELDS_NULL ON
   ```

This can be done by running the following code prior to executing queries:

	result = client.execute("SET ANSI_NULLS ON")
	result = client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF")
	result = client.execute("SET ANSI_NULL_DFLT_ON ON")
	result = client.execute("SET IMPLICIT_TRANSACTIONS OFF")
	result = client.execute("SET ANSI_PADDING ON")
	result = client.execute("SET QUOTED_IDENTIFIER ON")
	result = client.execute("SET ANSI_WARNINGS ON")
	result = client.execute("SET CONCAT_NULL_YIELDS_NULL ON")
	
## Disclaimers
The scripts and this guide are copyright Microsoft Corporations and are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.

