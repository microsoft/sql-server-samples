<!-- Always leave the MS logo -->
![](https://github.com/microsoft/sql-server-samples/blob/master/media/solutions-microsoft-logo-small.png)

# Regenerate IDENTITY columns in SQL Server and Azure SQL using sp_identity_rebirth

This sample describes an option to regenerate IDENTITY column values in SQL Server and Azure SQL tables, ensuring referential integrity and preserving related objects like constraints, indexes, and triggers. This process prevents data overflow errors and maintains data consistency without renaming or losing linked objects.

## Background

An INSERT command failed due to the error number 8115:

```sql
Arithmetic overflow error converting IDENTITY to data type int.
```

## Problem encountered

This error happens when the value in the IDENTITY column goes over the limit for its data type, in this case, an integer column with a maximum of 2,147,483,647. This problem often occurs in tables with frequent insert and delete operations. To keep referential integrity and avoid data loss, this sample describes a solution to regenerate IDENTITY column values without renaming tables or losing linked objects like constraints, indexes, statistics, and triggers.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Case history](#case-history)<br/>
[Resolution steps](#resolution-steps)<br/>
[Benefits](#benefits)<br/>
[Outcome](#outcome)<br/>
[Disclaimers](#disclaimers)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher)
- **Key features:** IDENTITY column
- **Workload:** No workload related to this sample
- **Programming Language:** T-SQL
- **Authors:** [Sergio Govoni](https://www.linkedin.com/in/sgovoni/) | [Microsoft MVP Profile](https://mvp.microsoft.com/mvp/profile/c7b770c0-3c9a-e411-93f2-9cb65495d3c4) | [Blog](https://segovoni.medium.com/) | [GitHub](https://github.com/segovoni) | [Twitter](https://twitter.com/segovoni)

<a name=before-you-begin></a>

## Before you begin

To run this example, the following basic concepts are required.

Identity columns can be used for generating key values. The identity property on a column guarantees that each new value is generated based on the current seed and increment, and that each new value for a particular transaction is different from other concurrent transactions on the table. All details about the IDENTITY property are available [here](https://learn.microsoft.com/sql/t-sql/statements/create-table-transact-sql-identity-property).

<a name=case-history></a>

## Case history

An overflow error occurs whenever we try to insert a value into a column that exceeds the data type's limit. In the case I followed, it was an integer column with the IDENTITY(1, 1) property, automatically incremented by SQL Server or Azure SQL with each data insertion. Overflow can occur on integer columns (as in this case) but also on tinyint, smallint, and bigint columns. The table in question contained about 600,000 records, but the current value of the IDENTITY column had exceeded the integer data type limit of 2,147,483,647. The data type limits are documented here: [Transact-SQL int, bigint, smallint, and tinyint](https://learn.microsoft.com/sql/t-sql/data-types/int-bigint-smallint-and-tinyint-transact-sql). The data type limit was reached due to multiple inserts and deletions in the problematic table. In the reported case, the IDENTITY column was also the primary key, referenced by a foreign key defined on a detail table.

<a name=resolution-steps></a>

## Resolution steps

### Available solutions

#### Option 1

One possible solution is to change the data type of the IDENTITY column. For example, if it is smallint, change it to integer, or if it is already integer, as in this case, change it to bigint. However, changing the data type of an IDENTITY column involves several potential issues and considerations that must be carefully evaluated. If the IDENTITY column is referenced by foreign keys in other tables, as in this case, you will also need to update the data type of those columns to ensure compatibility. You will need to update application code, queries, stored procedures, and reports that expect the IDENTITY column to be of a certain data type. Any integration with external systems that uses the IDENTITY column will need to be updated to reflect the new data type, which could involve significant changes in the integrated systems. Additionally, changing the data type from integer to bigint increases the amount of storage space required for each value. This can affect performance, especially in very large tables. If these issues are significant, an alternative solution is needed.

#### Option 2

An alternative solution is to compact, when possible, the values of the IDENTITY column without renaming the table and without losing connected objects such as constraints, indexes, statistics, triggers, etc., whose management would significantly complicate the solution.

Given that the table in question contained about 600,000 records, I chose to explore the solution that involves compacting the values. I adopted an approach that uses a temporary column to store the current values in the IDENTITY column, regenerate new values, and update the linked tables. It is important to note that you cannot directly update an IDENTITY column, even with IDENTITY_INSERT set to ON. From this study, the stored procedure [sp_identity_rebirth](https://github.com/microsoft/sql-server-samples/tree/master/samples/manage/stored-procedure/identity-management/source/sp-identity-rebirth.sql) was created, which uses a multi-phase strategy to regenerate the values of an IDENTITY column, maintaining referential integrity and minimizing the risks of data loss.

##### Resolution steps for option 2

1. **Input parameter validation**
   - Check that the schema name, table name, and IDENTITY column name are not empty
   - Verify that the IDENTITY column exists in the specified table

2. **Primary Key verification**
   - Determine if the IDENTITY column is the primary key of the table
   - If it is not the primary key, the procedure terminates (in its first version)

3. **Preparation for IDENTITY value regeneration**
   - Collect the necessary SQL commands into a temporary table (`@SQLCmd2IdentityRebirth`) to execute the operations sequentially

4. **Foreign Key management**
   - Identify and remove foreign keys that reference the IDENTITY column, primary key to avoid conflicts during regeneration

5. **Table backup and manipulation**
   - Add a temporary column to store the current IDENTITY values
   - Create a backup copy of the original table
   - Execute `TRUNCATE` on the original table to reset the IDENTITY column values

6. **Data reinsertion**
   - INSERT the data from the backup table into the original table, excluding the IDENTITY column (which will be regenerated automatically)
   - Update foreign key references to reflect the new IDENTITY column values

7. **Remove temporary column and restore foreign keys**
   - Remove the temporary column
   - Recreate the previously removed foreign keys

8. **Transaction and Error Handling**
   - Begin an explicit transaction if none exists
   - On error, rollback the transaction and raise an error
   - If all commands are executed successfully, commit the transaction

#### Implementation guide

- Execute `sp_identity_rebirth` and enjoy the result

<a name=benefits></a>

## Benefits of using the sp_identity_rebirth stored procedure

- **Foreign Key Management**: The procedure handles foreign keys, ensuring that references remain valid after regenerating the IDENTITY column values
- **Backup Creation**: Creating a backup copy of the original table provides a layer of security against data loss
- **Temporary Table for SQL Commands**: Using a temporary table to store SQL commands ensures that operations are executed in the correct sequence
- **Transactional Integrity**: The transaction ensures that all operations are atomic, reducing the risk of inconsistencies

<a name=outcome></a>

## Outcome

<a name=outcome></a>

By utilizing the [sp_identity_rebirth](https://github.com/microsoft/sql-server-samples/tree/master/samples/manage/stored-procedure/identity-management/source/sp-identity-rebirth.sql) stored procedure, you can successfully manage and regenerate IDENTITY column values in SQL Server and Azure SQL tables while maintaining referential integrity and preserving related objects such as constraints, indexes, and triggers. This approach effectively prevents data overflow errors and ensures data consistency without the need to rename tables or lose linked objects. Overall, integrating `sp_identity_rebirth` into your database maintenance strategy will help address issues related to IDENTITY column overflows and maintain the integrity of your database schema and relationships.

<a name=disclaimers></a>

## Disclaimers

This code sample is provided for demonstration and educational purposes only. It is recommended to use it with caution and fully understand its implications before applying it in a production environment. The provided code may not fully reflect the best development or security practices and may require adjustments to meet specific project requirements. The author disclaims any liability for any damages resulting from the use or interpretation of this material.
