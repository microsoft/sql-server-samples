# NodeJS Express4 REST API that uses SQL/JSON functionalities

This project contains an example implementation of NodeJS REST API with CRUD operations on a simple Todo table. You can learn how to build REST API on the existing database schema using NodeJS, Express4, and new JSON functionalities that are available in SQL Server 2016 (or higher) and Azure SQL Database.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database
- **Key features:** JSON Functions in SQL Server 2016/Azure SQL Database - FOR JSON and OPENJSON
- **Programming Language:** JavaScript (NodeJS), T-SQL
- **Authors:** Jovan Popovic

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. Node.js runtime.

**Azure prerequisites:**

1. Permission to create an Azure SQL Database

<a name=run-this-sample></a>

## Run this sample

1. Navigate to the folder where you have downloaded sample and run **npm update** in the command window.

2. From SQL Server Management Studio or SQL Server Data Tools connect to your SQL Server 2016 or Azure SQL database and
execute setup.sql script that will create and populate Todo table in the database and create necessary stored procedures.

3. Locate config folder in the project and setup connection info in default.json file. The content of the file should look like:
```
{
    "connection":{
        "server"  : "<<server name or ip>>",
        "userName": "<<user name>>",
        "password": "<<password>>",
        "options": { "encrypt": true, "database": "<<database name>>" }
    }
}
```
Content under connection key will be passed to Tedious package, which is used to
interact with SQL Database. You can find more information
about the properties in this object on [Tedious site](http://tediousjs.github.io/tedious/getting-started.html).

As an alternative, you can put connection info into Development.json or
Production.json file. This sample uses [config](https://www.npmjs.com/package/config)
npm module to read configurations from a file, so you can find more information about
the configuration there.

4. Run sample app from the command line using **node app.js**
 1. Open http://localhost:3000/todo Url to get list of all Todo items from a table,
 2. Open http://localhost:3000/todo/1 Url to get details about a single Todo item with id 1,
 2. Send POST, PUT, or DELETE Http requests to update content of Todo table.

<a name=sample-details></a>

## Sample details

This sample application shows how to create simple REST API service that performs CRUD operations on a simple Todo table.
NodeJS REST API is used to implement REST Service in the example.
1. app.js file that contains startup code.
3. routes/todo.js file that contains action that will be called on GET, POST, PUT, and DELETE Http requests.

Service uses Tedious library for data access and built-in JSON functionalities that are available in SQL Server 2016 and Azure SQL Database.

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended demonstrate some general guidance and architectural patterns for web development.
It contains minimal code required to create REST API.
You can easily modify this code to fit the architecture of your application.

<a name=related-links></a>

## Related Links

For more information, see this [MSDN documentation](https://msdn.microsoft.com/en-us/library/dn921897.aspx).

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.

## Questions
Email questions to: [sqlserversamples@microsoft.com](mailto: sqlserversamples@microsoft.com).