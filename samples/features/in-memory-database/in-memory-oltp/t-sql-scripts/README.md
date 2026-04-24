# T-SQL scripts supporting SQL In-Memory Features

Utility scripts, as well as scripts supporting several samples.


### Contents

[About this sample](#about-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher), Azure SQL Database
- **Key features:** In-Memory OLTP and Columnstore
- **Workload:** OLTP and Analytics
- **Programming Language:** T-SQL
- **Authors:** Jos de Bruijn

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2016 (or higher) or an Azure SQL Database (Premium)
2. SQL Server Management Studio

## Sample details

**[enable-in-memory-oltp.sql](enable-in-memory-oltp.sql)**

Helper script that enables the SQL Server or Azure SQL database for using In-Memory OLTP and configures the recommended database options.

**[sql_in-memory_oltp_sample.sql](sql_in-memory_oltp_sample.sql)**

Script to add In-Memory OLTP to the AdventureWorksLT sample database in Azure SQL Database. For details on this sample, see [Install the In-Memory OLTP sample](https://azure.microsoft.com/documentation/articles/sql-database-in-memory/#a-install-the-in-memory-oltp-sample).

**[sql_in-memory_analytics_sample.sql](sql_in-memory_analytics_sample.sql)**

Script to add In-Memory Analytics (Columnstore) to the AdventureWorksLT sample database in Azure SQL Database. For details on this sample, see [Install the In-Memory Analytics sample](https://azure.microsoft.com/en-us/documentation/articles/sql-database-in-memory/#b-install-the-in-memory-analytics-sample).

**[clustered_columnstore_sample_queries.sql](clustered_columnstore_sample_queries.sql)**

T-SQL queries accompanying the In-Memory Analytics (Columnstore) sample in the AdventureWorksLT sample database for Azure SQL Database.

<a name=related-links></a>

## Related Links

For more information, see these articles:
- [In-Memory OLTP (In-Memory Optimization)] (https://msdn.microsoft.com/library/dn133186.aspx)
- [Quick Start 1: In-Memory OLTP Technologies for Faster Transact-SQL Performance] (https://msdn.microsoft.com/library/mt694156.aspx)
- [Get started with Columnstore for real time operational analytics] (https://msdn.microsoft.com/library/dn817827.aspx)
- [Columnstore Indexes Guide] (https://msdn.microsoft.com/library/gg492088.aspx)