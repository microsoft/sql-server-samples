# ShrinkDriver

Reclaim allocated but unused space from the data files of a MSSQL database
by running parallel `DBCC SHRINKFILE` operations, with progress monitoring,
incremental shrinking, and automatic retries.

## What it does

- Runs in two modes: `Report` (default) shows each file's used, allocated, and reclaimable space without changing anything; `Shrink` performs the shrink.
- Shrinks multiple data files at once (one session per file) to reduce total run time.
- Shrinks each file gradually in incremental steps toward an optional target size, instead of in one large operation.
- Retries transient failures with backoff, and moves on from files that cannot shrink further.
- Skips files with little unused space to reclaim.
- Optionally runs shrink at low lock priority to reduce blocking of other queries.
- Writes a status report to the console and a log file at a regular interval, and stops on Ctrl+C or an optional time limit.
- Supports Entra ID, Windows, and SQL authentication when connecting to the database.

## Requirements

- SQL Server 2022 or later, Azure SQL Managed Instance, or Azure SQL Database.
- To shrink (`-Mode Shrink`): membership in the `db_owner` database role, or the `sysadmin` server role.
- To report (`-Mode Report`, the default): connection to the database.
- PowerShell 7 or later.
- The `SqlServer` module:
  `Install-Module SqlServer -Scope CurrentUser`.

## Usage

Load the script, then call `Invoke-ShrinkDriver`:

```powershell
. .\src\ShrinkDriver.ps1

# Report (default): show each file's used, allocated, and reclaimable space, without changing anything
Invoke-ShrinkDriver -ServerName myserver.database.windows.net -DatabaseName MyDb

# Shrink with Entra ID auth (default) to the smallest possible size, working on up to 5 files concurrently
Invoke-ShrinkDriver -ServerName myserver.database.windows.net -DatabaseName MyDb -Mode Shrink -Sessions 5

# Shrink with Windows auth: don't shrink below 500 GiB, working on up to 8 files concurrently
Invoke-ShrinkDriver -ServerName sql01 -DatabaseName MyDb -Mode Shrink -AuthType Windows -FileTargetSizeGiB 500 -Sessions 8

# Shrink with SQL auth (prompts securely for the password when it is not supplied)
Invoke-ShrinkDriver -ServerName sql01 -DatabaseName MyDb -Mode Shrink -AuthType SQL -SqlLogin appuser

# Connect to an instance with a self-signed certificate
Invoke-ShrinkDriver -ServerName devsql01 -DatabaseName MyDb -Mode Shrink -AuthType Windows -TrustServerCertificate
```

For the full list of parameters and what they do:

```powershell
Get-Help Invoke-ShrinkDriver -Full
```

## Output

Progress is written to the console and mirrored to a log file — by default a
timestamped `shrink-<time>.log` next to the script, or the
path given with `-LogPath`. The log records specified parameter values and a 
periodic per-file status report plus notable events (retries and cancellations).

### Status report

Each periodic report has one row per worker session, with these columns:

- **Worker** — the worker number.
- **SPID** — its session ID on the server.
- **File** — the data file being shrunk.
- **Used**, **Alloc** — the file's used and allocated size.
- **%Done** — progress of the current `DBCC SHRINKFILE` increment as reported in `sys.dm_exec_requests`.
- **Elapsed** — time since the worker's session was established.
- **Increment** — the number of the current incremental shrink step.
- **Cmd** — the current shrink phase, as reported by `sys.dm_exec_requests`, such as `DbccSpaceReclaim` or `DbccFilesCompact`.
- **Status** — the request's execution status (running, suspended, and so on).
- **dCPU**, **dReads**, **dWrites** — CPU, reads, and writes since the previous report, within the same shrink increment.
- **Blocker** — the blocking session, if any.
- **Wait** — the current wait type, if any.

It closes with a database-wide total: overall run time, total used and allocated
space, and a running tally of file outcomes.

Here's an example of the status report:

```output
2026-07-13 11:30:04 [INFO] ---- status ----
2026-07-13 11:30:04 [INFO] Worker  SPID  File  Used (GiB)  Alloc (GiB)  %Done     Elapsed  Increment  Cmd               Status       dCPU  dReads  dWrites  Blocker                 Wait              
2026-07-13 11:30:04 [INFO] ------  ----  ----  ----------  -----------  -----  ----------  ---------  ----------------  ---------  ------  ------  -------  ----------------------  ------------------
2026-07-13 11:30:04 [INFO]      0   157    13        66.3         78.0   88.8  4h 37m 34s         12  DbccFilesCompact  suspended  37,507  68,713  143,163  -                       PAGEIOLATCH_EX 1ms
2026-07-13 11:30:04 [INFO]      1   160    11        66.2         78.0     89  4h 37m 34s         13  DbccFilesCompact  suspended  34,064  69,614  143,715  -                       PAGEIOLATCH_EX 1ms
2026-07-13 11:30:04 [INFO]      2   162    33        43.5         50.0   89.6  4h 37m 33s         17  DbccFilesCompact  runnable   45,499  67,346  141,368  -                                         
2026-07-13 11:30:04 [INFO]      3   143    12        65.7         68.0   97.2  4h 37m 34s         18  DbccFilesCompact  suspended       -       -        -  -                       PAGEIOLATCH_EX 0ms
2026-07-13 11:30:04 [INFO]      4   170    31        80.2         88.0   93.7  4h 37m 34s         11  DbccFilesCompact  running    45,815  66,481  154,862  -                                         
2026-07-13 11:30:04 [INFO]      5   179     6        70.3         78.4   92.5  4h 37m 33s         12  DbccFilesCompact  suspended  33,075  79,371  153,667  164 (DbccFilesCompact)  LCK_M_X 0ms       
2026-07-13 11:30:04 [INFO]      6   164     5        72.4         98.0   92.3  4h 37m 34s         15  DbccFilesCompact  running    45,118  79,988  175,718  -                                         
2026-07-13 11:30:04 [INFO]      7   172    29        80.5         98.0   94.6  4h 37m 33s         11  DbccFilesCompact  running    36,587  69,368  143,467  -                                         
2026-07-13 11:30:04 [INFO]      8   161    34        31.4         50.0   92.5  4h 37m 34s         14  DbccFilesCompact  suspended  39,537  55,254  150,108  179 (DbccFilesCompact)  LCK_M_X 5ms       
2026-07-13 11:30:04 [INFO]      9   141    30        80.4         88.0   92.6  4h 37m 34s         12  DbccFilesCompact  suspended  40,900  68,313  150,113  161 (DbccFilesCompact)  LCK_M_X 2ms       
2026-07-13 11:30:04 [INFO] ---- database total ----
2026-07-13 11:30:04 [INFO]   Run time           : 12h 10m 24s
2026-07-13 11:30:04 [INFO]   Used               : 2.3 TiB
2026-07-13 11:30:04 [INFO]   Allocated          : 2.5 TiB
2026-07-13 11:30:04 [INFO]   Shrunk             : 16
2026-07-13 11:30:04 [INFO]   Repacked           : 0
2026-07-13 11:30:04 [INFO]   Partly shrunk      : 1
2026-07-13 11:30:04 [INFO]   Already at minimum : 0
2026-07-13 11:30:04 [INFO]   Already at target  : 0
2026-07-13 11:30:04 [INFO]   Grew               : 0
2026-07-13 11:30:04 [INFO]   Gave up            : 0
```

### End summary

A summary at the end reports how each file ended up:

- **Shrunk** — the file was reduced in size, reaching the target or minimum size.
- **Repacked** — with `-NoTruncate`, data pages were moved toward the front of the file; the allocated size is unchanged by design (space is not released).
- **Partly shrunk** — reduced, but gave up before reaching the target or minimum size.
- **Already at minimum** — already at its smallest possible size; nothing to reclaim.
- **Already at target** — already at or below the requested target size.
- **Grew** — ended larger than it started because other sessions added data during the shrink.
- **Gave up** — abandoned after retries with no change in size.
- **Interrupted** — shrinking of this file was cut short before any measurable result.
- **Not processed** — eligible for shrinking, but the run ended before it was completed (for example, it never started, or the connection was lost and could not be recovered).

Here's an example of the end summary:

```output
2026-07-13 12:31:24 [INFO] -------------------- summary --------------------
2026-07-13 12:31:24 [INFO]   Run time           : 13h 11m 44s
2026-07-13 12:31:24 [INFO]   Used               : 2.3 TiB
2026-07-13 12:31:24 [INFO]   Allocated          : 2.3 TiB
2026-07-13 12:31:24 [INFO]   Shrunk             : 30
2026-07-13 12:31:24 [INFO]   Repacked           : 0
2026-07-13 12:31:24 [INFO]   Partly shrunk      : 1
2026-07-13 12:31:24 [INFO]   Already at minimum : 0
2026-07-13 12:31:24 [INFO]   Already at target  : 0
2026-07-13 12:31:24 [INFO]   Grew               : 0
2026-07-13 12:31:24 [INFO]   Gave up            : 0
2026-07-13 12:31:24 [INFO]   file 35 [PartlyShrunk]: reduced from 40.0 GiB to 10.0 GiB, but the remaining unused space could not be reclaimed
2026-07-13 12:31:24 [INFO] -------------------------------------------------
```

## Tests

The script ships with unit and integration tests. For more information, see [tests/README.md](tests/README.md).

## Shrink documentation

- [DBCC SHRINKFILE](https://learn.microsoft.com/sql/t-sql/database-console-commands/dbcc-shrinkfile-transact-sql).
- [Manage file space for databases in Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/file-space-manage).
