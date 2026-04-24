<!-- Always leave the MS logo -->
![](https://github.com/microsoft/sql-server-samples/blob/master/media/solutions-microsoft-logo-small.png)

# Handling UPDATE STATISTICS on SQL Server PolyBase external tables

This sample describes an option to update statistics on SQL Server PolyBase external tables.

## Background

In the process of configuring a maintenance plan for a SQL Server database with external tables and external data sources for PolyBase queries, an error occurred during the update statistics task.

## Problem encountered

While attempting to update statistics on an external table, the following error message was encountered:

```sql
UPDATE STATISTICS [dbo].[ExternalTableName] WITH FULLSCAN, COLUMNS

Message 46519, level 16, state 22

The object Update Statistics isn't supported on External Table
```

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Case history](#case-history)<br/>
[Resolution steps](#resolution-steps)<br/>
[Further considerations](#further-considerations)<br/>
[Outcome](#outcome)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2017 (or higher)
- **Key features:** UPDATE STATISTICS
- **Workload:** No workload related to this sample
- **Programming Language:** T-SQL
- **Authors:** [Sergio Govoni](https://www.linkedin.com/in/sgovoni/) | [Microsoft MVP Profile](https://mvp.microsoft.com/mvp/profile/c7b770c0-3c9a-e411-93f2-9cb65495d3c4) | [Blog](https://segovoni.medium.com/) | [GitHub](https://github.com/segovoni) | [Twitter](https://twitter.com/segovoni)

<a name=before-you-begin></a>

## Before you begin

To run this example, the following basic concepts are required.

[SQL Server PolyBase](https://learn.microsoft.com/sql/relational-databases/polybase/polybase-guide?WT.mc_id=DP-MVP-4029181) enables your SQL Server instance to query data with T-SQL directly from SQL Server, Oracle, Teradata, MongoDB, Hadoop clusters, Cosmos DB, and S3-compatible object storage without separately installing client connection software. If you are new to PolyBase, you can find initial information in this article: [Polybase for beginners](https://techcommunity.microsoft.com/t5/sql-server-support-blog/polybase-for-beginners/ba-p/1075336).

<a name=case-history></a>

## Case history

Upon investigation, it became apparent that SQL Server does not support the direct updating of statistics on external tables, as documented in the [CREATE STATISTICS documentation page](https://learn.microsoft.com/sql/t-sql/statements/create-statistics-transact-sql?WT.mc_id=DP-MVP-4029181#limitations-and-restrictions).

<a name=resolution-steps></a>

## Resolution steps

### Understanding the limitation

Referring to the documentation page, it explicitly states, "Updating statistics is not supported on external tables. To update statistics on an external table, drop and re-create the statistics."

### Available solutions

* Option 1: Ignore External Tables:
  * This option is not feasible for maintenance plans managed by SQL Server Management Studio, necessitating third-party solutions.

* Option 2: Drop and Recreate Statistics:
  * Employ a stored procedure, [sp_drop_create_stats_external_table](https://github.com/microsoft/sql-server-samples/tree/master/samples/manage/polybase/external-table/source/sp-drop-create-stats-external-table.sql), to generate T-SQL statements for dropping and creating statistics on external tables. This procedure supports statistics on multiple columns.

### Implementation guide

- Execute `sp_drop_create_stats_external_table` to generate T-SQL statements
- Execute DROP STATISTICS statements before the maintenance statistics task
- Execute CREATE STATISTICS statements after the maintenance statistics task
- Implement robust error handling during the maintenance plan execution
- Validate the presence of statistics on the external table upon completion

<a name=further-considerations></a>

## Further considerations

- When dealing with large external tables, consider the performance implications of using default sampling versus full scan options
- Note that external tables utilizing DELIMITEDTEXT, CSV, PARQUET, or DELTA as data types only support statistics for one column per CREATE STATISTICS command

<a name=outcome></a>

## Outcome

By integrating the `sp_drop_create_stats_external_table` stored procedure into the maintenance plan, developers can effectively manage statistics on external tables within SQL Server databases, ensuring optimal performance and reliability.

From the maintenance plan prospective, CREATE and DROP STATISTICS statements can be stored on a temporary table or working table and executed separately. DROP STATISTICS statements can be executed before the maintenance statistics task and afterward the CREATE STATISTICS statements. Pay attention to the error handling during the maintenance plan because, at the end of the maintenance, statistics have to be in place on the external table. The output of the stored procedure cannot be missed.

<a name=disclaimers></a>

## Disclaimers

This code sample is provided for demonstration and educational purposes only. It is recommended to use it with caution and fully understand its implications before applying it in a production environment. The provided code may not fully reflect the best development or security practices and may require adjustments to meet specific project requirements. The author disclaims any liability for any damages resulting from the use or interpretation of this material.

<a name=related-links></a>

## Related links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For more information, see these articles:

- [Data virtualization with PolyBase in SQL Server](https://learn.microsoft.com/sql/relational-databases/polybase/polybase-guide?WT.mc_id=DP-MVP-4029181)
- [UPDATE STATISTICS (Transact-SQL)](https://learn.microsoft.com/sql/t-sql/statements/update-statistics-transact-sql?WT.mc_id=DP-MVP-4029181)
- [External tables: Why create statistics?](https://learn.microsoft.com/answers/questions/978155/external-tables-why-create-statistics?WT.mc_id=DP-MVP-4029181)
