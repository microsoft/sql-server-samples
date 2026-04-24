# Get started with SQL Server and Java on Windows

Get started quickly with developing applications in Java on Windows with SQL Server


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
    - CRUD with Java
    - CRUD with Hibernate ORM
    - Performance improvements with Columnstore
- **Programming Language:** Java
- **Authors:** ajlam

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher)
2. Java
3. Apache Maven
4. A text editor

## Run this sample

1. Select the specific tutorial you want to run through.

2. From your favorite text editor, open the App.java file and update the connection string username and password with your own.

3. From your terminal, change directories to the tutorial folder (ex. SqlServerSample) you're running through. Build the project and jar by performing the following command:

    ```
    mvn package
    ```

4. Run the program by performing the following command:

    ```
    mvn -q exec:java -Dexec.mainClass=com.sqlsamples.App.java
    ```

5. Repeat the above steps for any of the other tutorials provided.

<a name=sample-details></a>

## Sample details

Please visit the [Java on Windows tutorial](https://www.microsoft.com/en-us/sql-server/developer-get-started/java-windows) to run through the sample in full with more detail.

<a name=disclaimers></a>

## Disclaimers
The scripts and this guide are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.

<a name=related-links></a>

## Related Links

For more information, see these articles:
* To see more getting started tutorials, visit our [tutorials page](https://www.microsoft.com/en-us/sql-server/developer-get-started/)