# SSMS Custom Reports

This sample provides custom reports for SQL Server R Services that can be viewed from SQL Server Management Studio. The reports can be used to view configuration information, resource usage, execution statistics, active sessions and other information about R Services.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

<!-- Delete the ones that don't apply -->
- **Applies to:** SQL Server 2016 (or higher)
- **Key features:**
- **Workload:** SQL Server R Services
- **Programming Language:** T-SQL, R
- **Authors:** Umachandar Jayachandran
- **Update history:** Custom reports for R Services to show configuration, resource usage & model management.

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

<!-- Examples -->
1. SQL Server 2016 (or higher) with R Services installed
2. SQL Server Management Studio

<a name=run-this-sample></a>

## Run this sample
Installation instructions for R Services can be found [here](https://msdn.microsoft.com/en-us/library/mt696069.aspx).

Steps:
- Download a zip file  containing the reports to a folder using one of the links below:
    - [DownGit Link](https://minhaskamal.github.io/DownGit/#/home?url=https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/r-services/SSMS-Custom-Reports) to get Zip file with contents
    - Use [GitZip](http://kinolien.github.io/gitzip/) & specify the [Url](https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/r-services/SSMS-Custom-Reports)
- Open the custom reports from SQL Server Management Studio using the instructions from "[Add a custom report to Management Studio](https://msdn.microsoft.com/en-us/library/bb153687.aspx)" topic in SQL Server Books Online

<a name=sample-details></a>

## Sample details

Custom reports for R Services allow you to perform the following tasks from Object Explorer in SQL Server Management Studio. Add the reports to the server name in Object Explorer.

1. Configuration of R Services feature after Installation
2. View list of R packages installed on the SQL Server instance
3. View resource usage of R scripts and resource governance settings
4. View list of extended events for R Services
5. View execution statistics for R scripts
6. View sessions that are currently executing R scripts

### R Services - Configuration.rdl

This report can be used to view the installation settings of R Services and properties of the R runtime. You can also use this report to configure R Services after installation.

### R Services - Packages.rdl

This report lists the R packages installed on the SQL Server instance and properties like version, name.

### R Services - Resource Usage.rdl

This report can be used to view the CPU, Memory, IO consumption of SQL Server & R scripts execution. You can also view the memory setting of external resource pools.

### R Services - Extended Events.rdl

This report can be used to view the extended events that are available to get more insights into R scripts execution.

### R Services - Execution Statistics.rdl

This report can be used to view the execution statistics of R services. For example, you can get the total number of R scripts executions, number of parallel executions and frequently used RevoScaleR functions.

<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For additional content, see these articles:

[SQL Server R Services - Upgrade and Installation FAQ](https://msdn.microsoft.com/en-us/library/mt653951.aspx)

[SQL Server R Services Tutorials](https://msdn.microsoft.com/en-us/library/mt591993.aspx)