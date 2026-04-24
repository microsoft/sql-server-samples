Data Driven Precision Marketing with SQL Server R Service

As a data professional, do you wonder how you can leverage data science for creating new value in your organization? In this sample, learn how you can leverage your familiar knowledge on working with databases, and learn how you can get started with doing data science with databases.

----------

**Example**

In retail, tons of data are generated every data, which imply rich information about the whole market.

To provide market intelligence, the CRM analysis is commonly used to understand customer segmentation, predict customer behavior and better target potential buyers via right recommendation. With growing size of data and higher request on timeliness, it becomes a bit more challenging to do precision marketing on big data in a much more time-efficient way.

In this demo, we address the issue with Microsoft R Server's parallel computing algorithms and build an end-to-end operationalized analytical system using SQL Server R and Power BI.

Using a concrete example of customer relationship management for retail, we’ll share how you can jumpstart by

- Running R scripts using SQL Server as the compute context
- Operationalize your R scripts using stored procedures.

The insights delivered by these models are visualized using a Power BI dashboard.

----------

**Pre-requirements**

You have to do the following set-up before playing with this demo.

- Install SQL Server 2016 or create a SQL Server 2016 Enterprise VM on Azure with Standalone R Server and R Services installed/configured.
- Install R IDE: R Tools for Visual Studio or R Studio.
- Install PowerBI Desktop.
- Validate the successful installation.

----------

**Files**

This sample consists of the following directory structure.

- **Data** - This folder contains the CD sales data CDNOW.
- **R** - This folder contains the R code that you can run in any R IDE.
- **SQL Server** - This folder contains the sql files that you can run to create T-SQL stored procedures (with R code embeded) and try out this precision marketing example.
- **PowerBI** - This folder contains a sample PowerBI report.

To jumpstart, run the T-SQL files (crm_demo.sql)

**Note**

This is a demo built on SQL 2016 RC1 in Dec 2015. To try out it, please modify it to fit the new version of SQL Server R Services.






