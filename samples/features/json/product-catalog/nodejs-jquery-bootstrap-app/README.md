# Node.js Product Catalog application that uses SQL/JSON functionalities

This project contains an example implementation of Node.js application that shows how to display list of products, add, edit, or delete products in the list.

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
- **Programming Language:** Html/JavaScript/Node.js, Transact-SQL
- **Authors:** Jovan Popovic

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. Node.js installation

**Azure prerequisites:**

1. Permission to create an Azure SQL Database

<a name=run-this-sample></a>

## Run this sample

1. Create a database on SQL Server 2016 or Azure SQL Database and set compatibility level to 130.

2. From SQL Server Management Studio or Sql Server Data Tools connect to your SQL Server 2016 or Azure SQL database and execute [sql-scripts/setup.sql](sql-scripts/setup.sql) script that will create and populate Product table and create required stored procedures.

3. From command line run **npm update** to update node.js packages.

4. Setup connection information db.js

5. Build and run sample using **npm build** and **npm run**.

6. Run the sample app using F5 or Ctrl+F5 in Visual Studio 2015, or using **dotnet run** executed in the command prompt of the project root folder.
  1. Open http://localhost:3000/index.html to get all products from database,
  2. Use **Add** button to add a new product,
  3. Edit a product using **Edit** button in table,
  4. Delete a product using **Delete** button in table,

<a name=sample-details></a>

## Sample details

This sample application shows how to display list of products, add, edit or delete some product.
Front-end code is implemented using JQuery/Bootstrap libraries, and JQuery DataTable component for displaying data in table.
Server-side code is implemented using Node.js Express4 REST API.
SQL Server JSON functions are used to format product data that will be sent to front-end page.

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended demonstrate some general guidance and architectural patterns for web development. It contains minimal code required to create REST API.
You can easily modify this code to fit the architecture of your application.

<a name=related-links></a>

## Related Links

You can find more information about the components that are used in this sample on these locations:
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