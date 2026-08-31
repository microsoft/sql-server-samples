# AdventureWorks Readme

The `AdventureWorks` databases are sample databases that were originally published by Microsoft to show how to design a SQL Server database using SQL Server 2008. `AdventureWorks` is the OLTP sample, and `AdventureWorksDW` is the data warehouse sample.

## Release history

Database design has progressed since `AdventureWorks` was first published. For a sample database leveraging more recent features of SQL Server, see [WideWorldImporters](../wide-world-importers/).

### Changes between SQL Server 2012 and SQL Server 2022

`AdventureWorks` has not seen any significant changes since the 2012 version. The only differences between the various versions of `AdventureWorks` are the name of the database and the database compatibility level. To install the `AdventureWorks` databases with the database compatibility level of your SQL Server instance, you can install from a version-specific backup file or from an install script.

### Changes in SQL Server 2025

To coincide with the release of SQL Server 2025, the `AdventureWorks` database has been modified to take advantage of recent Database Engine features:

- Query Store is enabled
- Accelerated database recovery (ADR) is enabled
- Optimized locking is enabled
- Dates have been adjusted

## Prerequisites

FILESTREAM must be installed in your SQL Server instance.

## Install from a script

The install scripts create the sample database to have the database compatibility of your current version of SQL Server. Each script generates the version-specific information based on your current instance of SQL Server. This means you can use either the `AdventureWorks` or `AdventureWorksDW` install script on any version of SQL Server including preview versions, service packs, cumulative updates, and interim releases.

### Install notes

When installing from a script, the default database name is `AdventureWorks` or `AdventureWorksDW`. If you want the version added to the name, edit the database name at the beginning of the script.

The OLTP script drops an existing `AdventureWorks` database, and the data warehouse script drops an existing `AdventureWorksDW`. If you don't want that to happen, you can update the `$(DatabaseName)` parameter in the script to a different name, for example `AdventureWorks-new`.

### Install AdventureWorks

1. Copy the GitHub data files and scripts for [AdventureWorks](https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/adventure-works/oltp-install-script) to the `C:\Samples\AdventureWorks` folder on your local client.

1. Or, [download AdventureWorks-oltp-install-script.zip](https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip) and extract the zip file to the `C:\Samples\AdventureWorks` folder.

1. Open `C:\Samples\AdventureWorks\instawdb.sql` in SQL Server Management Studio (SSMS) and follow the instructions at the top of the file.

### Install AdventureWorksDW

1. Copy the GitHub data files and scripts for [AdventureWorksDW](https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/adventure-works/data-warehouse-install-script) to the `C:\Samples\AdventureWorksDW` folder on your local client.

1. Or, [download AdventureWorksDW-data-warehouse-install-script.zip](https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksDW-data-warehouse-install-script.zip) and extract the zip file to the `C:\Samples\AdventureWorksDW` folder.

1. Open `C:\Samples\AdventureWorksDW\instawdbdw.sql` in SSMS and follow the instructions at the top of the file.

## Install from a backup

Download backup files from [AdventureWorks samples databases](https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks) on GitHub.

You can install `AdventureWorks` or `AdventureWorksDW` by restoring a backup file. The backup files are version-specific. You can restore each backup to its respective version of SQL Server, or a later version.

For example, you can restore `AdventureWorks2016` to SQL Server (starting with 2016). Regardless of whether `AdventureWorks2016` is restored to SQL Server 2016 or a later version, the restored database has the database compatibility level of SQL Server 2016 (130).

### To restore a database backup

1. Locate the Backup folder for your SQL Server instance. The default path for 64-bit SQL Server 2025 is `C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup`. You can replace `MSSQL17` with a different value depending on the SQL Server version installed.

   | SQL Server version | MSSQL value | Compatibility level |
   | --- | --- | --- |
   | SQL Server 2025 (17.x) | MSSQL17 | 170 |
   | SQL Server 2022 (16.x) | MSSQL16 | 160 |
   | SQL Server 2019 (15.x) | MSSQL15 | 150 |
   | SQL Server 2017 (14.x) | MSSQL14 | 140 |
   | SQL Server 2016 (13.x) | MSSQL13 | 130 |

1. Download the `.bak` file from [AdventureWorks release](https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks) and save it to the Backup folder for your SQL Server instance.

1. Open SQL Server Management Studio (SSMS) and connect to your SQL Server instance.

1. Restore the database using the SSMS user interface. For more information, see [Restore a database backup using SSMS](https://learn.microsoft.com/sql/relational-databases/backup-restore/restore-a-database-backup-using-ssms).

1. Or, run the `RESTORE DATABASE` command in a new query window. On the Standard toolbar, click the New Query button.

1. Execute the following code in the query window. The file paths in the scripts are the default paths. You may need to update the paths in the scripts to match your environment.

## Examples

### Restore AdventureWorks2025 database

This example restores `AdventureWorks2025` to SQL Server 2025. The file paths are the default paths. If you use this example, you might need to update the paths in the scripts to match your environment.

```sql
USE [master];
GO

RESTORE DATABASE AdventureWorks2025
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorks2025.bak'
WITH
    MOVE 'AdventureWorks2025_data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorks2025.mdf',
    MOVE 'AdventureWorks2025_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorks2025.ldf',
    REPLACE;
```

### Restore AdventureWorksDW2022 database

This example restores `AdventureWorksDW2022` to SQL Server 2022. The file paths are the default paths. If you use this example, you might need to update the paths in the scripts to match your environment.

```sql
USE [master];
GO

RESTORE DATABASE AdventureWorksDW2022
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW2022.bak'
WITH
    MOVE 'AdventureWorksDW2022_data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2022.mdf',
    MOVE 'AdventureWorksDW2022_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2022.ldf',
    REPLACE;
```
