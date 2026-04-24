# Auto Tuning Performance Improvement Sample

This Windows Forms sample application built on .NET Framework 4.6 demonstrates the benefits of using SQL Server Automatic Tuning. You can compare the performance difference between enabling Automatic Tuning or leaveing it disabled, while running a workload that introduces a parameter sniffing regression.

<a name=about-this-sample></a>

## About this sample

<!-- Delete the ones that don't apply -->
* **Latest release:** [in-memory-oltp-perf-demo-v1.0](https://github.com/Microsoft/sql-server-samples/releases/tag/in-memory-oltp-demo-v1.0)
* **Applies to:** SQL Server 2017 (or higher), Azure SQL Database
* **Key features:** Automatic Tuning
* **Workload:** Reporting
* **Programming Language:** T-SQL, C#
* **Authors:** Pedro Lopes

![Alt text](/media/auto-tuning.png "WideWorldImporters Report")

## Running this sample
1. Before you can run this sample, you must have the following perquisites:
	- SQL Server 2017 (or higher)
	- Visual Studio 2015 (or higher) with the latest SSDT installed.

2. Clone this repository using Git for Windows (http://www.git-scm.com/), or download the zip file.

3. From Visual Studio, open the **AutoTuningDemo.sln** file from the root directory.

4. In Visual Studio Build menu, select **Build Solution** (or Press F6).

5. In the **App.config** file, located in the project root, find the **WideWorldImporters** app setting and edit the connectionString if needed. Currently it is configured to connect to the local default SQL Server Instance using Integrated Security.

6. Publish the WideWorldImporters Database
  - Right click on the WideWorldImporters SQL Server Database Project and Select **Publish**
  - Click Edit... to choose your connection string
  - Click Publish
  - Note: For publishing to Azure SQL you need to change the DB project target platform to **Microsoft Azure SQL Database V12**

7. Build the app for release and run it. Do not use the debugger, as that will slow down the app.

8. Start the workload with the **Start** button, and run for a while to show perf profile. Then press the **Regress** button to introduce the problem and observe the throughput going down.

9. Run for a while to show perf profile of regressed workload, and then press the **Auto Tuning** button and observe the system going back to a previously good plan captured by Query Store, and throughput is restored to initial Baseline status. You can tweak aspects of the workload (e.g., number of threads) through the configuration form accessed using the "Options" menu. No need to recompile or restart the application.

10. Publish the database project to the same database – the tool will take care of making the necessary changes.

When deploying to Azure SQL Database, make sure to run the app in an Azure VM in the same region as the database.

For any feedback on the sample, contact: sqlserversamples@microsoft.com

## About the code
The code included in this sample is not intended to be a set of best practices on how to build scalable enterprise grade applications. This is beyond the scope of this quick start sample.

## More information
- [Automatic tuning] (https://docs.microsoft.com/en-us/sql/relational-databases/automatic-tuning/automatic-tuning)
