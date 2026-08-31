# ShrinkDriver tests

The script is covered by two kinds of tests, both written with
[Pester](https://pester.dev) (the standard PowerShell test framework), version 5 or later:

- **Unit tests** — exercise the pure helper functions in isolation. Fast, and need **no database**.
- **Integration tests** — run real `DBCC SHRINKFILE` operations against a **live SQL instance**, so
  they validate the script's actual behavior end to end.

## Test files

| File | What it is |
| --- | --- |
| `ShrinkDriver.Unit.Tests.ps1` | Unit tests for the helper functions. |
| `ShrinkDriver.Integration.Tests.ps1` | Integration tests that create a small throwaway database, run real shrinks, and drop it. |
| `fixtures/ShrinkTestDb.psm1` | Helpers used by the integration tests to build and tear down the test database. Not a test file itself. |

## Prerequisites

- **PowerShell 7 or later.**
- **Pester 5 or later.** Install it once (per user):

  ```powershell
  Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser
  ```

- **For the integration tests only:** the `SqlServer` module and a reachable SQL instance.

  ```powershell
  Install-Module SqlServer -Scope CurrentUser
  ```

  By default the integration tests use **SQL Server LocalDB** (installed with most SQL Server tooling),
  so no extra setup is needed to run them locally.

> Run all the commands below from the **sample root** — the folder that contains the `src` and `tests`
> directories.

## Run the unit tests (fast, no database)

```powershell
Invoke-Pester -Path .\tests\ShrinkDriver.Unit.Tests.ps1
```

Pester prints one line per test (`[+]` passed, `[-]` failed) and a summary such as
`Tests Passed: 106, Failed: 0`. **Every change to `src\ShrinkDriver.ps1` should keep these green.**

## Run the integration tests

Against the default local instance (SQL Server LocalDB, Windows auth):

```powershell
Invoke-Pester -Path .\tests\ShrinkDriver.Integration.Tests.ps1 -Tag Integration
```

These create small throwaway databases, run real shrinks, and drop them afterward. They are **skipped
automatically when no SQL instance is reachable**, and individual tests that don't apply to the target
instance are skipped as well — so a run may report some `Skipped` tests, which is expected.

To target a different instance (for example, a database on an Azure SQL Database logical server), set these
environment variables before running, then clear them afterward:

```powershell
$env:SHRINKDRIVER_TEST_SERVER = 'myserver.database.windows.net'
$env:SHRINKDRIVER_TEST_AUTH   = 'EntraID'      # EntraID | Windows | SQL
# For SQL authentication, also set the login; the password is requested securely when the tests run:
# $env:SHRINKDRIVER_TEST_LOGIN = 'appuser'
# Only for an instance with a self-signed certificate if you trust the connection:
# $env:SHRINKDRIVER_TEST_TRUSTCERT = '1'

Invoke-Pester -Path .\tests\ShrinkDriver.Integration.Tests.ps1 -Tag Integration

Remove-Item Env:\SHRINKDRIVER_TEST_SERVER, Env:\SHRINKDRIVER_TEST_AUTH -ErrorAction SilentlyContinue
```

## Run everything, or just the fast gate

Run every test in the folder:

```powershell
Invoke-Pester -Path .\tests
```

Run only the fast unit gate (skip the integration tests):

```powershell
Invoke-Pester -Path .\tests -ExcludeTag Integration
```

## Validating a change to the script

After editing `src\ShrinkDriver.ps1`:

1. **Run the unit tests** and confirm they all pass — this catches most regressions quickly.
2. **Run the integration tests** (against LocalDB, or another instance via the variables above) to
   confirm the real shrink behavior still works.
3. If something fails, re-run with `-Output Detailed` to see each test and the failing assertion:

   ```powershell
   Invoke-Pester -Path .\tests\ShrinkDriver.Unit.Tests.ps1 -Output Detailed
   ```
