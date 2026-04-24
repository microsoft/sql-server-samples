# Building Web Apps using Dapper ORM and SQL/JSON functionalities

This project contains an example implementation of ASP.NET REST Service/App that enables you to get or modify list of products in catalog and show reports.

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
- **Key features:** JSON functions in SQL Server 2016/Azure SQL Database, Dapper ORM
- **Programming Language:** C#, Transact-SQL
- **Authors:** Jovan Popovic

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. Visual Studio 2015+ or Visual Studio Code Editor with the ASP.NET Core 1.0 (or higher)

**Azure prerequisites:**

1. Permission to create an Azure SQL Database

<a name=run-this-sample></a>

## Run this sample

1. Create a database on SQL Server 2016 or Azure SQL Database and set compatibility level to 130+.

2. From SQL Server Management Studio or Sql Server Data Tools connect to your SQL Server 2016 or Azure SQL database and execute [sql-scripts/setup.sql](sql-scripts/setup.sql) script that will create and populate Product table and create required stored procedures.

3. From Visual Studio 2015, open the **ProductCatalog.xproj** file from the root directory. Restore packages using right-click menu on the project in Visual Studio and by choosing Restore Packages item. As an alternative, you may run **dotnet restore** from the command line (from the root folder of application).

4. Add a connection string in appsettings.json or appsettings.development.json file. An example of the content of appsettings.development.json is shown in the following configuration:

```
{
  "ConnectionStrings": {
    "ProductCatalog": "Server=.;Database=ProductCatalog;Integrated Security=true"
  }
}
```

If database is hosted on Azure you can add something like:
```
{
  "ConnectionStrings": {
    "ProductCatalog": "Server=<<SERVER>>.database.windows.net;Database=ProductCatalog;User Id=<<USER>>;Password=<<PASSWORD>>"
  }
}
```

5. Build solution using Ctrl+Shift+B, right-click on project + Build, Build/Build Solution from menu, or **dotnet build** command from the command line (from the root folder of application).

6. Run the sample app using F5 or Ctrl+F5 in Visual Studio 2015, or using **dotnet run** executed in the command prompt of the project root folder.
  1. Open /api/Product Url to get all products from database,
  2. Open /api/Product/18 Url to get the product with id,
  3. Send POST Http request to /api/Product Url with JSON like {"Name":"Blade","Color":"Magenta","Price":18.0000,"Quantity":45} in the body of request to create new product,
  4. Send PUT Http request with JSON like {"Name":"Blade","Color":"Magenta","Price":18.0000,"Quantity":45} in the body of request to update the product with specified id,
  5. Send DELETE Http request /api/Product/18 Url to delete the product with specified id(18),
  6. Open index.html to see how JavaScript client-side app can use underlying REST API,
  7. Open report.html to see how you can create reports with pie/bar charts using D3 library and underlying REST API.

<a name=sample-details></a>

## Sample details

This sample application shows how to create REST API that returns list of products, single product, or update products in table.
Dapper ORM framework is used for data access. Dapper-Stream extension is used to integrate Dapper with SQL/JSON functionalities.
Server-side code is implemented using ASP.NET.
SQL Server JSON functions are used to format product data that will be sent to front-end page.
Client-side code is inplemented using various JavaScript components.

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended demonstrate some general guidance and architectural patterns for web development. It contains minimal code required to create REST API, and it does not use some patterns such as Repository. Sample uses built-in ASP.NET Core Dependency Injection mechanism; however, this is not prerequisite.
You can easily modify this code to fit the architecture of your application.

<a name=related-links></a>

## Related Links

The architecture is based on a samples presented in [Building REST API using SQL Server JSON functionalities](http://sqlblog.com/blogs/davide_mauri/archive/2017/04/30/pass-appdev-recording-building-rest-api-with-sql-server-using-json-functions.aspx) PASS AppDev webinar.
You can find more information about the components that are used in this sample on these locations:
- Server-side components
 - [ASP.NET](http://www.asp.net).
 - [JSON Support in Sql Server](https://msdn.microsoft.com/en-us/library/dn921897.aspx).
 - [Dapper](https://github.com/StackExchange/Dapper) framework is used for data access.
- Front-end components used in this sample are:
 - [JQuery library](https://jquery.com/) that is used to define UI logic in the front-end application.
 - [JQuery DataTable plugin](https://datatables.net/) that is used to display list of products in a table.
 - [JQuery View Engine](https://jocapc.github.io/jquery-view-engine/) that is used to populate HTML form using JSON model object.
 - [Twitter Bootstrap](http://getbootstrap.com/) that is used to style application.
 - [D3 library](https://d3js.org/) that is use to display pie/bar charts.

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.

## Questions
Email questions to: [sqlserversamples@microsoft.com](mailto: sqlserversamples@microsoft.com).