<!-- Always leave the MS logo -->
![](https://github.com/microsoft/sql-server-samples/blob/master/media/solutions-microsoft-logo-small.png)

# SQL Server 2025 Optimized Locking: Transaction ID (TID) Locking internals

This sample describes how to read and interpret the Transaction ID stored in row data pages.

## Background

Optimized Locking is a SQL Server 2025 database engine feature designed to reduce the memory used for lock management, decrease the phenomenon known as lock escalation, and increase workload concurrency.

Optimized Locking depends on two technologies that have long been part of the SQL Server engine:
- [Accelerated Database Recovery (ADR)](https://learn.microsoft.com/sql/relational-databases/accelerated-database-recovery-concepts) is a required prerequisite for enabling Optimized Locking 
- [Read Committed Snapshot Isolation (RCSI)](https://learn.microsoft.com/sql/t-sql/statements/set-transaction-isolation-level-transact-sql) is not a strict requirement, but allows full benefit from Optimized Locking

Optimized Locking is based on two key mechanisms:
- Transaction ID (TID) locking
- Lock After Qualification (LAQ)

### What is the Transaction ID?

The Transaction ID (TID) is a unique transaction identifier.

When a [row-versioning based isolation level](https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide#Row_versioning) is active, or when [Accelerated Database Recovery (ADR)](https://learn.microsoft.com/sql/relational-databases/accelerated-database-recovery-concepts) is enabled, every row in the database internally contains a transaction identifier.

The TID is stored on disk in the additional 14 bytes that are associated with each row when features such as RCSI or ADR are enabled.

Every transaction that modifies a row, it tags that row with its own TID, so each row in the database is labeled with the last TID that modified it.


### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample Details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>
## About this sample

- **Applies to:** SQL Server 2025 (or higher)
- **Key features:** SQL Server 2025 Optimized Locking
- **Workload:** No workload related to this sample
- **Programming Language:** T-SQL
- **Authors:** [Sergio Govoni](https://www.linkedin.com/in/sgovoni/) | [Microsoft MVP Profile](https://mvp.microsoft.com/mvp/profile/c7b770c0-3c9a-e411-93f2-9cb65495d3c4) | [Blog](https://segovoni.medium.com/) | [GitHub](https://github.com/segovoni) | [Twitter](https://twitter.com/segovoni)

<a name=before-you-begin></a>
## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2025 (or higher)

<a name=run-this-sample></a>
## Run this sample

### Setup code

1. Download [create-configure-optimizedlocking-db.sql T-SQL script](sql-scripts) from sql-scripts folder
2. Check if a database called OptimizedLocking does not exist in your SQL Server 2025 instance
3. Execute create-configure-optimizedlocking-db.sql script on your SQL Server 2025 instance
4. Run the commands described in the sample details section

<a name=sample-details></a>
## Sample Details

Currently, the only way to read the Transaction ID of a row is by using the `DBCC PAGE` command.

Let's consider the table dbo.TelemetryPacket, with the schema defined in the following T-SQL code snippet.

```sql
USE [OptimizedLocking]
GO

CREATE TABLE dbo.TelemetryPacket
(
  PacketID INT IDENTITY(1, 1)
  ,Device CHAR(8000) DEFAULT ('Something')
);
GO
```

The table schema is designed so that each row occupies exactly one data page.

Insert three rows with default values into the dbo.TelemetryPacket table. Note that this is done in a single transaction.

```sql
BEGIN TRANSACTION
INSERT INTO dbo.TelemetryPacket DEFAULT VALUES;
INSERT INTO dbo.TelemetryPacket DEFAULT VALUES;
INSERT INTO dbo.TelemetryPacket DEFAULT VALUES;
COMMIT
```

Let's explore the content of the dbo.TelemetryPacket table, enriched with the PageId column, which shows the result of the undocumented function sys.fn_PhysLocFormatter. Use this function to correlate the rows returned by the `SELECT` with their physical location on disk.

```sql
USE [OptimizedLocking]
GO

SELECT
  *
  ,PageId = sys.fn_PhysLocFormatter(%%physloc%%)
FROM
  dbo.TelemetryPacket;
```

The values shown in the PageId column represent the physical location of the data.

Let's look at the row where PacketID equals 1.

The value (1:XXXX:0) in the PageId column is composed of three parts separated by ":". Here is what each part represents:
- 1 is the numeric identifier of the database file (file number) where the page is located
- XXXX is the page number inside file 1 of the database
- 0 is the slot number

Use the `DBCC PAGE` command to inspect the TID of page XXXX.

```sql
DBCC PAGE ('OptimizedLocking', 1, XXXX, 3);
```

The value of the unique transaction identifier (TID) that modified the row with PacketID equal to 1 is in the Version Information section, under the Transaction Timestamp attribute.

<a name=disclaimers></a>
## Disclaimers

The code included in this sample is not intended to be a set of best practices on how to build scalable enterprise grade applications. This is beyond the scope of this sample.

<a name=related-links></a>
## Related Links

- [Optimized locking](https://learn.microsoft.com/sql/relational-databases/performance/optimized-locking)
