# ASP.NET Core Product Catalog application that uses SQL/JSON functionalities

This project contains an example implementation of ASP.NET Core application that shows how to display list of products, add, edit, or delete products in the list.

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
- **Key features:** JSON functions in SQL Server 2016/Azure SQL Database
- **Programming Language:** C#, Html/JavaScript, Transact-SQL
- **Authors:** Jovan Popovic

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. Visual Studio 2015 Update 3 (or higher) or Visual Studio Code Editor with the ASP.NET Core 1.0 (or higher)

**Azure prerequisites:**

1. Permission to create an Azure SQL Database

<a name=run-this-sample></a>

## Run this sample

### Setup

1. Create a database on SQL Server 2016 or Azure SQL Database and set compatibility level to 130.

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

If your database is hosted on Azure you can add something like:
```
{
  "ConnectionStrings": {
    "ProductCatalog": "Server=<<SERVER>>.database.windows.net;Database=ProductCatalog;User Id=<<USER>>;Password=<<PASSWORD>>"
  }
}
```

### Build and run sample

1. Build solution using Ctrl+Shift+B, right-click on project + Build, Build/Build Solution from menu, or **dotnet build** command from the command line (from the root folder of application).

2. Run the sample app using F5 or Ctrl+F5 in Visual Studio 2015, or using **dotnet run** executed in the command prompt of the project root folder.
  1. Open /index.html Url to get all products from database,
  2. Use **Add** button to add a new product,
  3. Edit a product using **Edit** button in table,
  4. Delete a product using **Delete** button in table,

<a name=sample-details></a>

## Sample details

This sample application shows how to display list of products, add, edit or delete some product.
Front-end code is implemented using JQuery/Bootstrap libraries, and JQuery DataTable component for displaying data in table.
Server-side code is implemented using ASP.NET Core Web API.
SQL Server JSON functions are used to format product data that will be sent to front-end page.

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended demonstrate some general guidance and architectural patterns for web development. It contains minimal code required to create REST API, and it does not use some patterns such as Repository. Sample uses built-in ASP.NET Core Dependency Injection mechanism; however, this is not prerequisite.
You can easily modify this code to fit the architecture of your application.

<a name=related-links></a>

## Related Links

You can find more information about the components that are used in this sample on these locations:
- [ASP.NET Core](http://www.asp.net/core).
- [JSON Support in Sql Server](https://msdn.microsoft.com/en-us/library/dn921897.aspx).
- [JQuery](https://jquery.com/).
- [Bootstrap](http://getbootstrap.com/).
- [JQuery DataTables](https://datatables.net/).
- [JQuery SerializeJson](https://github.com/marioizquierdo/jquery.serializeJSON/).
- [Toastr](http://codeseven.github.io/toastr/).

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.

## Questions
Email questions to: [sqlserversamples@microsoft.com](mailto: sqlserversamples@microsoft.com).