# Connect to SQL using Ruby on Windows

Ruby sample code that runs on a Windows computer to connect to an Azure SQL Database.

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

1. Ruby
	- [Go the Ruby download page](http://rubyinstaller.org/downloads/) and download the appropriate 2.1.x installer. For example if you are on a 64 bit machine, download the **Ruby 2.1.6 (x64)** installer.
	- Once the installer is downloaded, do the following:

		- Double-click the file to start the installer.

		- Select your language, and agree to the terms.

		- On the install settings screen, select the check boxes next to both *Add Ruby executables to your PATH* and *Associate .rb and .rbw files with this Ruby installation*.


2. DevKit
	- Download DevKit from the [RubyInstaller page](http://rubyinstaller.org/downloads/)
	- After the download is finished, do the following:

		- Double-click the file. You will be asked where to extract the files.

		- Click the "..." button, and select "C:\DevKit". You will probably need to create this folder first by clicking "Make New Folder".

		- Click "OK", and then "Extract", to extract the files.

		- Now open the Command Prompt and enter the following commands:

			```
			chdir C:\DevKit
			ruby dk.rb init
			ruby dk.rb install
			```

3. tiny_tds
	- Navigate to C:\DevKit and run the following command from your terminal. This will install TinyTDS on your machine.

	```
	gem inst tiny_tds --pre
	```

**Azure prerequisites:**

1. An AdventureWorks sample database:

	- The Ruby sample relies on the AdventureWorks sample database. If you do not already have AdventureWorks, you can see how to create it at the following topic: [Create your first Azure SQL Database](http://azure.microsoft.com/documentation/articles/sql-database-get-started/)
	
## Run this sample

1. From your command prompt, update the connection string details in the Ruby file with your own username, password, and hostname.

2. Run the code sample by running the below in your terminal:

	```
	ruby sample_ruby_win.rb
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
	result = client.execute("SET QUOTED_IDENTIFIER ON"")
	result = client.execute("SET ANSI_WARNINGS ON")
	result = client.execute("SET CONCAT_NULL_YIELDS_NULL ON")
	
## Disclaimers
The scripts and this guide are copyright Microsoft Corporations and are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.

