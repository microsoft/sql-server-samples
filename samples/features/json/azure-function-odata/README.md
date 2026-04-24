# Rest API with Azure Functions and Azure SQL Database

This sample shows how to create REST API using Azure Function that read data from Azure SQL Database using FOR JSON clause.

## Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** Azure SQL Database, SQL Server 2016 (or higher)
- **Key features:** FOR JSON clause in SQL Server 2016/Azure SQL Database
- **Programming Language:** C#
- **Authors:** Jovan Popovic

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the be able to create Azure SQL Database and Azure Function.

<a name=run-this-sample></a>

## Run this sample

To run this sample, you need to download source code from SQL Server GitHub account, or copy the content of files directly from GitHub using browser.

### Setup Azure SQL Database

1. Create Azure SQL Database using Azure Portal, SQL Server Management Studio, or other tools.

### Setup Azure Function

1. Create Azure Function using Azure Portal. In the list of templates choose C#/Http Webhook as a type.

2. Add data-access NuGet package. Click on the **Files** link on the righ-hand side, and upload [project.json[(azure-function/project.json) file into your Azure Function. This file contains a reference to the Data Access library that will be used to get the data from Azure SQL Database.

3. Setup connection to your database. Click on manage link in Azure Function, and open settings of your Azure Function application. Scroll down to the connection string section, add a key **azure-db-connection** and put the connection string to your dataase as a value.

4. Modify C# code in your Azure Function (Run.csx file). Put the code in the [run.csx](azure-function/run.csx) file in your Azure Function.
   - Modify query in the code to create different REST API.

<a name=sample-details></a>

## Sample

In this sample is created one Azure Function that is called via URL, calls Azure SQL Database, and returns query result formatted as JSON. This is can be used to implement of REST API using Azure Function on Azure SQL Database.
Azure Function returns response to the caller using HttpResponseMessage class.

```
var httpStatus = HttpStatusCode.OK;
string body =
        await (new QueryMapper(ConnectionString)
                   .OnError(ex => { httpStatus = HttpStatusCode.InternalServerError; }))
          .GetStringAsync("select * from sys.objects for json path");

return new HttpResponseMessage() { Content = new StringContent(body), StatusCode = httpStatus };
```

**QueryMapper** is a class that maps results of SQL Query to some result. In this example, **QueryMapper** uses **GetStringAsync** method to asynchrously execute SQL query and map results to string that will be returned as a result of REST API call. On the **QueryMapper** object is added **OnError** handler that will set *Internal Server Error* code in the response if some error happens during the query execution (this is optional setting).


<a name=related-links></a>

## Related Links

You can find more information about the technologies that are used in this sample on these locations:
- [JSON support in Azure SQL Database](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-json-features).
- [Webhooks in Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-a-web-hook-or-api-function).

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.

## Questions
Email questions to: [sqlserversamples@microsoft.com](mailto: sqlserversamples@microsoft.com).
