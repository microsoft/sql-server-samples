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
- **Workload:** SQL Server R Services, SQL Server Machine Learning Services
- **Programming Language:** T-SQL, R, Python
- **Authors:** Umachandar Jayachandran
- **Update history:** Custom reports for SQL Server Machine Learning Services to show configuration, resource usage & statistics.

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

<!-- Examples -->
1. SQL Server 2016 with R Services installed
1. SQL Server 2017 or higher with Machine Learning Services installed
2. SQL Server Management Studio

<a name=run-this-sample></a>

## Run this sample
Installation instructions for Machine Learning Services can be found [here](https://msdn.microsoft.com/en-us/library/mt696069.aspx).

To use custom reports from SQL Server Management Studio, follow the instructions from "[Add a custom report to Management Studio](https://msdn.microsoft.com/en-us/library/bb153687.aspx)" topic in SQL Server Books Online.

<a name=sample-details></a>

## Sample details

Custom reports for Machine Learning Services allow you to perform the following tasks from Object Explorer in SQL Server Management Studio. Add the reports to the server name in Object Explorer.

1. Configuration of Machine Learning Services feature after Installation
2. View list of R or Python packages installed on the SQL Server instance
3. View resource usage of external scripts and resource governance settings
4. View list of extended events for Machine Learning Services
5. View execution statistics for external scripts
6. View sessions that are currently executing external scripts

### R Services - Configuration.rdl

This report can be used to view the installation settings of Machine Learning Services and properties of the R or Python runtime. You can also use this report to configure Machine Learning Services after installation.

### R Services - Packages.rdl

This report lists the R or Python packages installed on the SQL Server instance and properties like version, name.

### R Services - Resource Usage.rdl

This report can be used to view the CPU, Memory, IO consumption of SQL Server & external scripts execution. You can also view the memory setting of external resource pools.

### R Services - Extended Events.rdl

This report can be used to view the extended events that are available to get more insights into external scripts execution.

### R Services - Execution Statistics.rdl

This report can be used to view the execution statistics of Machine Learning services. For example, you can get the total number of external scripts executions, number of parallel executions and frequently used RevoScaleR functions.

<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For additional content, see these articles:

[SQL Server Machine Learning Services - Upgrade and Installation FAQ](https://msdn.microsoft.com/en-us/library/mt653951.aspx)

[SQL Server Machine Learning Services Tutorials](https://msdn.microsoft.com/en-us/library/mt591993.aspx)
