# Get started with SQL Server and Node.js on Ubuntu

Get started quickly with developing applications in Node.js on Ubuntu with SQL Server


### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher)
- **Workload:**
    - CRUD with Node.js
    - CRUD with Sequelize ORM
    - Performance improvements with Columnstore
- **Programming Language:** JavaScript

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher)
2. Node.js
3. Sequelize ORM
4. A text editor
5. sql-cli

## Run this sample

1. Create the database to be used for the rest of the samples. From your command prompt, run the following. Update the username and password with your own.

    ```
    mssql -s localhost -u sa -p your_password -q "CREATE DATABASE SampleDB;"
    ```

### CRUD via Node.js *(SqlServerSample)*
1. In your favorite text editor, open the **connect.js** file in the *SqlServerSample* folder and update the connection string username and password with your own.

2. From your terminal, run the project by performing the following command:

    ```
    node connect.js
    ```

3. From sql-cli, create the sample data to be used in the CRUD sample. Update the username and password with your own.

    ```
    mssql -s localhost -u sa -p your_password -d SampleDB -T 60000
    .run ./CreateTestData.sql
    ```

4. From your terminal, run the CRUD sample by performing the following command:

    ```
    node crud.js
    ```

### CRUD via Sequelize *(SqlServerSequelizeSample)*
1. In your favorite text editor, open the **orm.js** file in the *SqlServerSequelizeSample* folder and update the connection string username and password with your own.

2. From your command prompt, connect to your database and then create the sample data to be used in the columnstore sample. Update the username and password with your own.

    ```
    node orm.js
    ```

### Performance improvements with Columnstore *(SqlServerColumnstoreSample)*
1. In your favorite text editor, open the **columnstore.js** file in the *SqlServerColumnstoreSample* folder and update the connection string username and password with your own.

2. From your command prompt, connect to your database and then create the sample data to be used in the columnstore sample. Update the username and password with your own.

    ```
    mssql -s localhost -u sa -p your_password -d SampleDB -T 60000
    .run ./CreateSampleTable.sql
    ```

4. From your terminal, run the CRUD sample by performing the following command:

    ```
    node columnstore.js
    ```

<a name=sample-details></a>

## Sample details

Please visit the [Node.js on Ubuntu tutorial](https://www.microsoft.com/en-us/sql-server/developer-get-started/node-ubuntu) to run through the sample in full with more detail.

<a name=disclaimers></a>

## Disclaimers
The scripts and this guide are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.

<a name=related-links></a>

## Related Links

For more information, see these articles:
* To see more getting started tutorials, visit our [tutorials page](https://www.microsoft.com/en-us/sql-server/developer-get-started/)