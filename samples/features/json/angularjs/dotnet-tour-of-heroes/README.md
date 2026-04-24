# Angular Heroes ASP.NET Core REST Web App

This project contains an implementation of [AngularJS Heroes sample app](https://angular.io/docs/ts/latest/tutorial/) implemented using ASP.NET Core REST API backend that use SQL/JSON functionalities.
AngularJs code is modified version of johnpapa [Github sample project](https://github.com/johnpapa/angular2-tour-of-heroes).
In this example you will see how easily you can integrate Single-page apps implemented using Angular JS with SQL Server 2016 or Azure SQL Database using ASP.NET Core and JSON functions.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Get this sample](#get-this-sample)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database
- **Key features:** JSON functionalities in SQL Server 2016/Azure SQL Database.
- **Programming Language:** JavaScript/AngularJS, C#, Transact-SQL
- **Authors:** Jovan Popovic

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database
2. Visual Studio 2017 or Visual Studio Code Editor with the ASP.NET Core 1.0/.Net Framework 4.6
3. .NET Core SDK for [Windows](https://go.microsoft.com/fwlink/?LinkID=827524) or other [operating systems](https://www.microsoft.com/net/core)
4. Node.js installation [Node.js](https://nodejs.org/en/download/)

**Azure prerequisites:**

1. Permission to create an Azure SQL Database


<a name=get-this-sample></a>

## Get this sample

Sample project is placed on SQL Server GitHub repository. You can clone or download repository and locate code
in samples/features/json/angularjs/dotnet-tour-of-heroes folder.

If you want to clone only this sample (without other samples), run the following commands from Git Bash:

```
git clone -n https://github.com/Microsoft/sql-server-samples sql-server-samples
cd sql-server-samples
git config core.sparsecheckout true
echo "samples/features/json/angularjs/dotnet-tour-of-heroes/*" >> .git/info/sparse-checkout
git checkout
```

Or you can use the following PowerShell script:
```
git clone -n https://github.com/Microsoft/sql-server-samples .\sql-server-samples
cd sql-server-samples
git config core.sparsecheckout true
echo samples/features/json/angularjs/dotnet-tour-of-heroes/* | Out-File -append -encoding ascii .git/info/sparse-checkout
git checkout
```

<a name=run-this-sample></a>

## Run this sample

1. Create a database on SQL Server 2016 or Azure SQL Database.

2. From SQL Server Management Studio or Sql Server Data Tools connect to your SQL Server 2016 or Azure SQL database and execute [sql-scripts/setup.sql](sql-scripts/setup.sql) script that will create and populate **Hero** table.

3. Add a connection string in appsettings.json or appsettings.development.json file. An example of the content of appsettings.development.json is shown in the following configuration:

```
{
  "ConnectionStrings": {
    "HeroDb": "Server=.;Database=HeroDb;Integrated Security=true"
  }
}
```

If your database is hosted on Azure you can add something like:
```
{
  "ConnectionStrings": {
    "HeroDb": "Server=<<SERVER>>.database.windows.net;Database=HeroDb;User Id=<<USER>>;Password=<<PASSWORD>>"
  }
}
```

### Build and run sample

1. Restore NugetPackages using **dotnet restore** command.
2. Restore npm packages using **npm install** command lines. This command will download packages in **node_modules** folder.
3. Build project using **dotnet build** command executed from command line (from project root folder) or using Visual Studio 2017.
4. Run the sample app using **dotnet run** executed in the command prompt of the project root folder.

Sequence of commands is:
```
npm install
dotnet restore
dotnet build
dotnet run
```

### Run the app
. Open /index.html Url to see heroes from database.
See more details about functionalities in [AngularJS Heroes sample app](https://angular.io/docs/ts/latest/tutorial/)

<a name=sample-details></a>

## Sample details

This sample application shows how to create REST API service is used as beckend for AngularJS app.
Front-end code stored in wwwroot folder is modified johnpapa [Github sample project](https://github.com/johnpapa/angular2-tour-of-heroes).
ASP.NET Core Web API is used to implement REST Service called by Hero front-end app.
Service uses FOR JSON clause that is available in SQL Server 2016 and Azure SQL Database.

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended demonstrate some general guidance and architectural patterns for web development. It contains minimal code required to create REST API, and it does not use some patterns such as Repository. Sample uses built-in ASP.NET Core Dependency Injection mechanism; however, this is not prerequisite.
You can easily modify this code to fit the architecture of your application.

<a name=related-links></a>

## Related Links

You can find more information about the components that are used in this sample on these locations:
- [ASP.NET Core](http://www.asp.net/core).
- [JSON Support in Sql Server](https://msdn.microsoft.com/en-us/library/dn921897.aspx).
- [AngularJS Heroes sample app](https://angular.io/docs/ts/latest/tutorial/).
- [Github sample project](https://github.com/johnpapa/angular2-tour-of-heroes).

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.

## Questions
Email questions to: [sqlserversamples@microsoft.com](mailto: sqlserversamples@microsoft.com).
