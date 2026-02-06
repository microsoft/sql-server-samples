<!-- Always leave the MS logo -->
![](https://github.com/microsoft/sql-server-samples/blob/master/media/solutions-microsoft-logo-small.png)

# Optimized Locking: Transaction ID (TID) locking internals

This sample describes how to read and interpret the Transaction ID (TID) stored in row data pages.

## Background

Optimized Locking is a database engine feature designed to reduce the memory used for lock management, decrease the phenomenon known as lock escalation, and increase workload concurrency.

Optimized Locking depends on two technologies that have long been part of the SQL Server engine:
- [Accelerated Database Recovery (ADR)](https://learn.microsoft.com/sql/relational-databases/accelerated-database-recovery-concepts) is a required prerequisite for enabling Optimized Locking 
- [Read Committed Snapshot Isolation (RCSI)](https://learn.microsoft.com/sql/t-sql/statements/set-transaction-isolation-level-transact-sql) is not a strict requirement, but allows full benefit from Optimized Locking

Optimized Locking is based on two key mechanisms:
- Transaction ID (TID) locking
- Lock After Qualification (LAQ)

### What is the Transaction ID (TID)?

The Transaction ID (TID) is a unique transaction identifier.

When a [row-versioning based isolation level](https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide#Row_versioning) is active, or when [Accelerated Database Recovery (ADR)](https://learn.microsoft.com/sql/relational-databases/accelerated-database-recovery-concepts) is enabled, every row in the database internally contains a transaction identifier.

The TID is stored on disk in the additional 14 bytes that are associated with each row when features such as RCSI or ADR are enabled.

Every transaction that modifies a row tags that row with its own TID, so each row in the database is labeled with the last TID that modified it.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample Details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>
## About this sample

- **Applies to:** SQL Server 2025 (or higher), Azure SQL Database
- **Key features:** Optimized Locking
- **Workload:** No workload related to this sample
- **Programming Language:** T-SQL
- **Authors:** [Sergio Govoni](https://www.linkedin.com/in/sgovoni/) | [Microsoft MVP Profile](https://mvp.microsoft.com/mvp/profile/c7b770c0-3c9a-e411-93f2-9cb65495d3c4) | [Blog](https://segovoni.medium.com/) | [GitHub](https://github.com/segovoni) | [X](https://twitter.com/segovoni)

<a name=before-you-begin></a>
## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server 2025 (or higher) or Azure SQL Database

<a name=run-this-sample></a>
## Run this sample

### Setup code

1. Download [create-configure-optimizedlocking-db.sql](sql-scripts/create-configure-optimizedlocking-db.sql) T-SQL script from sql-scripts folder
2. Verify that a database named OptimizedLocking does not already exist in your SQL Server instance
3. Execute create-configure-optimizedlocking-db.sql script on your SQL Server instance
4. Run the commands described in the sample details section

<a name=sample-details></a>
## Sample Details

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

Before committing the transaction, we query the [sys.dm_tran_locks](https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views/sys-dm-tran-locks-transact-sql) DMV, which exposes the TID locks as a new resource type = `XACT`.

```sql
BEGIN TRANSACTION;

INSERT INTO dbo.TelemetryPacket DEFAULT VALUES;
INSERT INTO dbo.TelemetryPacket DEFAULT VALUES;
INSERT INTO dbo.TelemetryPacket DEFAULT VALUES;

SELECT
  l.resource_description
  ,l.resource_associated_entity_id
  ,l.resource_lock_partition
  ,l.request_mode
  ,l.request_type
  ,l.request_status
  ,l.request_owner_type
FROM
  sys.dm_tran_locks AS l
WHERE
  (l.request_session_id = @@SPID)
  AND (l.resource_type = 'XACT');

COMMIT;
```

The resource_description column, in this example, reports the `XACT` value equal to `10:1147:0`.

TID `1147` represents the identifier of the transaction that inserted the rows and it will be stored in the row data page if the transaction is confirmed. Every subsequent change to the rows will update the TID.

Now let's make a change on the row identified by the PacketID value 2 and before confirming the transaction let's repeat again the query on the DMV.

```sql
BEGIN TRANSACTION;

UPDATE
  t
SET
  t.Device = 'Something updated'
FROM
  dbo.TelemetryPacket AS t
WHERE
  t.PacketID = 2;

SELECT
  l.resource_description
  ,l.resource_associated_entity_id
  ,l.resource_lock_partition
  ,l.request_mode
  ,l.request_type
  ,l.request_status
  ,l.request_owner_type
FROM
  sys.dm_tran_locks AS l
WHERE
  (l.request_session_id = @@SPID)
  AND (l.resource_type = 'XACT');

COMMIT;
```

Even for the `UPDATE` command, the resource_description column displays the TID of the transaction that is modifying the row. If the transaction is confirmed, the TID will be stored in the data page of the row itself.

<a name=disclaimers></a>
## Disclaimers

The code included in this sample is not intended to be a set of best practices on how to build scalable enterprise grade applications. This is beyond the scope of this sample.

<a name=related-links></a>
## Related Links

- [Optimized locking](https://learn.microsoft.com/sql/relational-databases/performance/optimized-locking)