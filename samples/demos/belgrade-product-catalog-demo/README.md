# ASP.NET Core Product Catalog application that uses new SQL Server/Azure SQL Db functionalities

This project contains an example implementation of ASP.NET Core application that shows how to implement product catalog SQL Server/Azure SQL Db functionalities.
- JSON functionalities are used to implement Web API that provides data to client HTML application,
- Temporal tables are used to show changes in data, go back in time, restore previous versions of products,
- Data masking is used to hide email, phone, and postcode data,
- Row-level security is used to isolate product data.

## Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database
- **Key features:** JSON functions, temporal tables, data masking and row-level security in SQL Server 2016/Azure SQL Database
- **Programming Language:** C#, Html/JavaScript, Transact-SQL
- **Authors:** Jovan Popovic

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. [ASP.NET Core 1.0 SDK](https://www.microsoft.com/net/core#windows) (or higher). Optional: Visual Studio 2015 Update 3 (or higher) or Visual Studio Code Editor.

**Azure prerequisites:**

1. Permission to create an Azure SQL Database

<a name=run-this-sample></a>

## Run this sample

1. Create a database on SQL Server 2016 or Azure SQL Database and set compatibility level to 130.

2. From SQL Server Management Studio or Visual Studio/Sql Server Data Tools connect to your SQL Server 2016 or Azure SQL database and execute **setup.sql** script that will create and populate Product table and create required stored procedures. Execute **setup-temporal.sql**, **rls.sql**, and **data-masking.sql** to add required features.

3. Build the project - Open command prompt in project root folder (the folder that contains **project.json** file), and run following commands: **dotnet restore** to take all necessary NuGet packages, **dotnet build** to build the project. As an alternative, open the **ProductCatalog.xproj** file from the root directory using Visual Studio 2015 Update 3 (or higher). Restore packages using right-click menu on the project in Visual Studio and by choosing Restore Packages item.

4. Locate **appsettings.json** file in the project, change connection string to reference your database (default value ProductCatalog database on local instance with integrated security), and build solution using Ctrl+Shift+B, right-click on project + Build, Build/Build Solution from menu, or **dotnet build** command from the command line (from the root folder of application).

5. Run the sample app using F5 or Ctrl+F5 in Visual Studio 2015, or using **dotnet run** executed in the command prompt of the project root folder.

Open /index.html Url to get all products from database. Add edit and delete products in table. Use green (+) button to see all changes that are made in rows. Restore some of the previous version. Use slider to go back in time (to the left side). Restore some version from history. Edit any product and validate that company information are masked. Log-in as some of the companies and verify that only product for the current company are displayed.

<a name=sample-details></a>

## Sample details

Front-end code is implemented using JQuery/JQuery UI libraries, and JQuery DataTable component for displaying data.
Server-side code is implemented using ASP.NET Core Web API with JSON functionalities that format results from database and de-serialize JSON request from the client-side.
SQL Server Temporal feature is used to track history, sow snapshots of data in some point in time in the past, and to restore previous versions of product.
Data masking-feature is used to mask company information.
Row-level security is used to isolate company data.

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended demonstrate some general guidance and architectural patterns for web development. It contains minimal code required to create REST API, and it does not use some patterns such as Repository. Sample uses built-in ASP.NET Core Dependency Injection mechanism; however, this is not prerequisite.
You can easily modify this code to fit the architecture of your application.

<a name=related-links></a>

## Related Links

You can find more information about the components that are used in this sample on these locations:
[.Net Core download](https://www.microsoft.com/net/core#windows)
[JQuery DataTables with row expansion](https://datatables.net/examples/api/row_details.html).
[JQuery UI Slider](https://jqueryui.com/slider/)

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.

## Questions
Email questions to: [sqlserversamples@microsoft.com](mailto: sqlserversamples@microsoft.com).
