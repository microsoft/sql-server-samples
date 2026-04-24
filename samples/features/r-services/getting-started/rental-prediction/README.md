# Build a predictive model with SQL Server R Services

This sample shows how to create a predictive model in R and operationalize it with SQL Server 2016 or vNext.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

Predictive modeling is a powerful way to add intelligence to your application. It enables applications to predict outcomes against new data.
The act of incorporating predictive analytics into your applications involves two major phases:
model training and model operationalization.

In this sample, you will learn how to create a predictive model in R and operationalize it with SQL Server 2016.

Follow the step by step tutorial [here](http://aka.ms/sqldev/R) to walk through this sample.

<!-- Delete the ones that don't apply -->
- **Applies to:** SQL Server 2016 (or higher)
- **Key features:** SQL Server R Services
- **Workload:** SQL Server R Services
- **Programming Language:** T-SQL, R, JavaScript (NodeJS)
- **Authors:** Nellie Gustafsson
- **Update history:** Getting started tutorial for R Services

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.
Section 1 in the [tutorial](http://aka.ms/sqldev/R) covers the prerequisites.
After that, you can download a DB backup file and restore it using Setup.sql. [Download DB](https://sqlchoice.blob.core.windows.net/sqlchoice/TutorialDB.bak)

**Software prerequisites:**

<!-- Examples -->
1. SQL Server 2016 (or higher) with R Services installed
2. SQL Server Management Studio
3. R IDE Tool like Visual Studio RTVS

## Run this sample app
1. From SQL Server Management Studio or SQL Server Data Tools connect to your SQL Server 2016 or vNext SQL database and execute setup.sql to restore the sample DB
2. From SQL Server Management Studio or SQL Server Data Tools, execute Predictive Model.sql script to set up tables, train model, predict using that model etc.
This is all covered step by step in the [tutorial](http://aka.ms/sqldev/R)

3. Navigate to the folder where you have downloaded sample and run **npm install** in command window, or run setup.bat if you are on Windows operating system. This command will install necessary npm packages defined in project.json.

4. Locate db.js file in the project, change database connection info in createConnection() method to reference your database. the following tokens should be replaced:
 1. SERVERNAME - name of the database server.
 2. DATABASE - Name of database where Todo table is stored.
 3. USERNAME - SQL Server login that can access table data and execute stored procedures.
 4. PASSWORD - Password associated to SQL Server login.

```
    var config = {
        server  : "SERVER.database.windows.net",
        userName: "USER",
        password: "PASSWORD",
        // If you have a named instance, you can put the instance name here:
        options: { encrypt: true, database: 'DATABASE' }
    };
```

5. Run sample app by opening a command window, navigate to the location where here you have downloaded sample and run **node bin\www**
6. Go to a browser and navigate to the following [link] (http://localhost:3000/client.html). You should now see an HTML table containing the predictions generated using R in SQL Server.

<a name=sample-details></a>

## Sample details

This sample application shows how to create a predictive model and generate predictions using the model. It also shows how to build a simple REST API service tthat gets data from the DB.
NodeJS REST API is used to implement REST Service in the example.

### Predictive Model.R
The R script that generates a predictive model and uses it to predict rental counts

### Predictive Model.SQL
Takes the R code in PredictiveModel.R and deploys it inside SQL Server. Creating stored procedures and tables for training, storing models and creating stored procedures for prediction.

### app.js
File that contains startup code.
### db.js
File that contains functions that wrap Tedious library
### predictions.js
File that contains action that will be called to get the predictions

Service uses Tedious library for data access and built-in JSON functionalities that are available in SQL Server 2016 and Azure SQL Database.

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended demonstrate some general guidance and architectural patterns for web development.
It contains minimal code required to create a REST API.
You can easily modify this code to fit the architecture of your application.


<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For additional content, see these articles:

[SQL Server R Services - Upgrade and Installation FAQ](https://msdn.microsoft.com/en-us/library/mt653951.aspx) <br/>
[Other SQL Server R Services Tutorials](https://msdn.microsoft.com/en-us/library/mt591993.aspx) <br/>
[Watch a presentation about predictive modeling in SQL Server, that also goes through this sample](https://www.youtube.com/watch?v=YCyj9cdi4Nk&feature=youtu.be) <br/>
