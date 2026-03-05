![](../media/solutions-microsoft-logo-small.png)

# About
This source code is an example of buildling cloud-ready apps that are resilient to transient errors and failovers in the cloud. In particular, the example was made in C# with Azure SQL Managed Instance, but it can be applied to other SQL servers as well.

The accompanying article to this source code is the following: here: http://aka.ms/mifailover-techblog

# How to build

- Create Console app project in Visual Studio
- Copy-paste the program file
- Use App.config to enter your SQL MI connection details. In Visual Studio, you will also need to [add your config file](https://docs.microsoft.com/en-us/visualstudio/ide/how-to-add-app-config-file) to the project.

# Database side configuration

On SQL MI (e.g. using SSMS) you will need to create a failoverDB. Use the follwing t-sql script:

```t-sql
CREATE DATABASE failoverDB;
USE failoverDB;
CREATE TABLE timetable (datestamp datetime);
INSERT INTO timetable (datestamp) VALUES (CURRENT_TIMESTAMP);
SELECT * FROM timetable;
```

# Demo

- Use boolean variable "ResilientQuery" to set the app resiliency. False would run the app with no resiliency which will cause the app to be terminanted on SQL MI failover. True would run the resilient retry logic, the application will continue running after SQL MI failover.
- As the application is running, you can use the SELECT * FROM timetable; to see the queries being inserted into the table.
- Use instructions in this article http://aka.ms/mifailover-techblog to execute a PowerShell that will failover a Managed Instance.
- Watch the application resiliency (with ResilientQuery variable true and false) while initiating failover on SQL MI
