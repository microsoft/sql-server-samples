# Changelog

All notable changes to the ShrinkDriver sample are documented in this file.

## [1.3.0] - 2026-11-04

### Added

- `-FileName`: limit a run to the named data files.
- The log records what the server reports about the connection: server and database name,
  product version and update level, and the edition or service objective.
- A **Retry** column in the status report shows the attempt count for the current increment
  (for example `2/5`).
- When a shrink command ends with an error (for example, a lock timeout) after running for a
  long time, the log notes that the retry repeats the whole command, with advice for lock
  timeouts and for the step size.

### Changed

- **Increment** in the status report now counts the shrink steps for the current file; a retry
  no longer increases it.
- The log and PVS safety checks run independently, so a failed read of one no longer disables
  the other. The PVS check reuses the file sizes read for the status report instead of running a
  separate, more expensive query. A check that is skipped several times in a row is reported as
  leaving the run unprotected.

### Fixed

- A blocked file-size read (for example, while files are being shrunk) no
  longer drops the whole status report or skips stuck detection; the sizes are shown as
  unavailable for that report.
- A worker no longer treats a timed-out file-size read as a lost connection and reconnects;
  it retries the read within the file's retry budget.
- If reading a file's size fails right after MSSQL error 49537 (shrink blocked by the low
  watermark; run shrink again later), the worker now records the file's outcome and
  continues, instead of stopping and leaving unstarted files unprocessed.

## [1.2.0] - 2026-09-11

### Added

- Safety valve (on by default): the run stops if the size of active transaction log or 
  the size of the persistent version store (PVS) nears a level where the shrink itself
  could cause an out-of-log condition or grow the database.

## [1.1.0] - 2026-08-27

### Changed

- A shrink blocked by the database low watermark not advancing because of an open
  transaction or other reasons (error 49537) now ends shrink for that file with a distinct
  "run shrink again later" outcome, instead of retrying it as a generic transient error.
  The shrink of other files in the same run continues.

## [1.0.0] - 2026-07-16

### Added

- `Invoke-ShrinkDriver`: reclaims allocated but unused space from a database's `ROWS`
  data files by running `DBCC SHRINKFILE` on multiple sessions in parallel.
- `Report` mode (default) and `Shrink` mode. `Report` needs only a connection; `Shrink`
  needs `db_owner` or `sysadmin`.
- Incremental, step-based shrinking toward an optional per-file target size
  (`-FileTargetSizeGiB`, `-StepGiB`), skipping files with less than `-MinReclaimGiB` of
  reclaimable space.
- `-TruncateOnly` (release tail free space only) and `-NoTruncate` (repack only) modes.
- `WAIT_AT_LOW_PRIORITY` support (`-WaitAtLowPriority`, `-AbortAfterWait`).
- Transient-failure retries with exponential backoff and full jitter, plus a
  connection-level retry provider and an outer reconnect loop that rides out an Azure SQL
  restart or failover.
- Stuck detection: a shrink blocked or making no progress for `-StuckWindowSeconds` is
  cancelled and retried.
- Graceful shutdown: two-stage Ctrl+C and an optional `-MaxRuntimeMinutes`, both of which
  reassess in-flight files to real outcomes.
- Per-file outcome buckets and an end-of-run advisory listing files that still have
  reclaimable space, so a follow-up run can recover more.
- A periodic status report written to the console and a log file, with a structured
  result object available via `-PassThru`.
- Entra ID, Windows, and SQL authentication; validate-first connections with an opt-in
  `-TrustServerCertificate` fallback; a secure `SecureString` password prompt.
- Support for SQL Server 2022 or later, Azure SQL Managed Instance, and Azure SQL Database.
