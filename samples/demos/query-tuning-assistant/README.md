This is a repro package to demonstrate how to upgrade a database compatibility level using Query Tuning Assistant.
This feature is using telemetry from the Query Store feature we launched with Azure SQL Database and SQL Server 2016 to detect upgrade-related regressions.

This repro assumes the following:

- SQL Server 2016+ installed (pick at minimum Database Engine) on Windows.
- You have installed SQL Server Management Studio v18
- You have downloaded the RML Utilities from https://www.microsoft.com/en-us/download/details.aspx?id=4511.
- These demos use a named instance called SQL2017. You will need to edit the .cmd scripts which connect to SQL Server to change to a default instance or whatever named instance you have installed.

0. Install ostress from the package RML_Setup_AMD64.msi. Add C:\Program Files\Microsoft Corporation\RMLUtils to your path.

1. Attach the AdventureWorksDW2012 database to your SQL Server 2016+ instance. The adventure-works-2012-dw-data-file.mdf is provided in https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks2012

3. Start QTA following instructions in https://docs.microsoft.com/en-us/sql/relational-databases/performance/upgrade-dbcompat-using-qta.

4. When requested to run a baseline collection, run PreUpgrade.cmd to customize the AdventureWorksDW2012 database and start the demo. Run it to completion...

5. After its completed, continue QTA workflow.

6. When requested to re-run the same workload, run PostUpgrade.cmd. Run it to completion...

7. After its completed, continue QTA workflow.
