# Changelog

All notable changes to the ShrinkDriver sample are documented in this file.

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
