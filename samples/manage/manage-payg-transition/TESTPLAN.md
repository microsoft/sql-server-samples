# Test Plan — manage-payg-transition.ps1 and modify-azure-sql-license-type.ps1 fixes

This document records the tests performed to validate the changes on this branch,
against a live Azure environment (Microsoft tenant `72f988bf-86f1-41af-91ab-2d7cd011db47`).

## Changes under test

1. **`modify-azure-sql-license-type.ps1`**
   - `Connect-Azure` now reuses an existing valid Az PowerShell/CLI session for the
     target tenant instead of always forcing re-login.
   - Module presence check now verifies `Az.Accounts >= 4.2.0` directly instead of
     checking for the `Az` meta-package (which caused false negatives and unnecessary/
     conflicting `Install-Module -Name Az -Force` calls).

2. **`manage-payg-transition.ps1`**
   - Removed unused `Force_Start_On_Resources` parameter usage.
   - Fixed the Arc script download URL path
     (`azure-hybrid-benefit` → `azure-arc-enabled-sql-server`).
   - Reformatted wrapper argument line-continuation logic so backticks are placed
     correctly regardless of how many arguments are present.
   - Fixed `RunMode Single`: the Arc/Azure sub-scripts were referenced by the
     generated wrapper but never downloaded first, causing
     `term ... is not recognized` errors. Added the missing `Invoke-RestMethod`
     download calls (mirroring the existing `Invoke-RemoteScript` logic used for
     `RunMode Scheduled`).
   - Made the script fully **self-contained**: embedded the complete logic of
     `modify-azure-sql-license-type.ps1`, `modify-arc-sql-license-type.ps1`, and
     `set-azurerunbook.ps1` directly in `manage-payg-transition.ps1`. No external
     downloads from `raw.githubusercontent.com` occur anymore — the embedded
     content is materialized to local files at runtime (required for local
     script invocation and Azure Automation runbook import).
   - Added `-TargetLicenseType` parameter (`PAYG` default, or `AHUB`) to control
     which license model resources are transitioned to, translated internally to
     each embedded script's own vocabulary (`LicenseIncluded`/`BasePrice` for
     Azure SQL resources, `PAYG`/`LicenseOnly` for Arc SQL Server). Previously
     the Arc transition target was hardcoded to `PAYG` only.

## Test environment

- Tenant: Microsoft (`72f988bf-86f1-41af-91ab-2d7cd011db47`) only, per requirement.
- Primary test resource: SQL Server VM `rajpoTest`
  (`/subscriptions/6a37df99-a9de-48c4-91e5-7e6ab00b2362/resourceGroups/rajpobuddy/...`).
- Secondary test resource: SQL Managed Instance `abhisqlmi`
  (`/subscriptions/fa58cf66-caaf-4ba9-875d-f310d3694845/resourceGroups/dms-demos-49855/...`).

## Test cases and results

| # | Test | Method | Result |
|---|------|--------|--------|
| 1 | Corrected Arc script URL resolves | `HEAD` request to the raw GitHub URL on `master` | ✅ 200 OK (old `azure-hybrid-benefit` path is missing/404s) |
| 2 | `Connect-Azure` reuses existing session | Ran script with an already-authenticated Az/CLI session | ✅ No re-login prompt, no hang; log shows "Reusing existing context/session" |
| 3 | `Az.Accounts` version check | Ran on a machine with `Az.Accounts 5.5.2` (not the `Az` meta-package) installed | ✅ Correctly detected as satisfying `>= 4.2.0`; no reinstall attempted |
| 4 | `RunMode Single -Target Azure`, SQL VM (AHUB→PAYG) | Reset `rajpoTest` to `AHUB`, ran `manage-payg-transition.ps1 -Target Azure -RunMode Single` end-to-end | ✅ Passed after fixing the missing-download bug; CSV report generated with exactly 1 resource (`rajpoTest`, `AHUB`→`PAYG`); final state confirmed via `az resource show` |
| 5 | `RunMode Single -Target Both` | Ran with `-Target Both` against `rajpoTest` (already PAYG) | ✅ No hangs; both Arc and Azure branches executed; correctly reported "no resources require update" (no false modification) |
| 6 | `RunMode Single -Target Arc`, real transition | Attempted against `rajpobuddy` RG Arc resources | ⚠️ Blocked — no Arc-extension-based resource (`Microsoft.AzureData` extension with `LicenseType != PAYG`) currently exists in the RG to exercise a real flip. The KQL query executed without error and returned 0 matches, confirming no regression in query logic, but an actual AHUB→PAYG transition was not exercised for Arc. |
| 7 | Wrapper line-continuation formatting (Scheduled mode) | Code review of the `for` loop building `$wrapper` lines for both Arc and Azure blocks | ✅ Confirmed a trailing backtick is appended to every line except the last, for any number of arguments |
| 8 | SQL Managed Instance transition (regression, prior fixes) | Ran against `abhisqlmi` (`BasePrice` → `LicenseIncluded`) | ✅ Passed; exactly 1 resource modified out of 247 unrelated SQL Servers in the subscription |
| 9 | Azure Policy-based compliance sample (PR #1490, IaaS SQL VM variant) | End-to-end: policy definition, assignment, compliance scan, remediation against `rajpoTest` | ✅ Passed (separate from this branch's fixes, but validated as an alternate transition method during the same testing session) |
| 10 | Self-contained script: no external downloads | Ran `manage-payg-transition.ps1 -Target Azure -RunMode Single` (default `-TargetLicenseType PAYG`) against `rajpoTest` (reset to `AHUB`) | ✅ Passed; log shows only "Writing embedded script ... to ..." (local file write), no `Invoke-RestMethod`/network download calls; `rajpoTest` transitioned `AHUB`→`PAYG`, CSV report generated with exactly 1 resource |
| 11 | `-TargetLicenseType AHUB` reverse transition | Ran the same command with `-TargetLicenseType AHUB` against `rajpoTest` (now `PAYG`) | ✅ Passed; internal query correctly used `BasePrice` filter (Azure SQL vocabulary); `rajpoTest` transitioned `PAYG`→`AHUB`, CSV report generated with exactly 1 resource |

## Cleanup

- All temporary test artifacts (generated wrapper scripts, downloaded sub-scripts,
  CSV reports, a local test harness copy of the orchestrator script used to bypass
  `raw.githubusercontent.com` during local-only testing) were removed after each run.
- `rajpoTest` was left in `PAYG` state at the end of testing.

## Known gaps / follow-ups

- Live Arc-target transition (test #6) should be re-validated once a suitable
  Arc SQL Server resource with a non-PAYG `Microsoft.AzureData` extension is available.
- `RunMode Scheduled` was validated via code review and log output only, not via an
  actual Windows Scheduled Task registration/execution.

## Required permissions

Derived from every Azure CLI/PowerShell call made by the two scripts:

| Script | Operations performed | Minimum built-in role(s) |
|---|---|---|
| `modify-azure-sql-license-type.ps1` | `az sql vm/mi/db/elastic-pool/instance-pool list` and `update`; `Get-AzDataFactoryV2(IntegrationRuntime)` / `Set-AzDataFactoryV2IntegrationRuntime`; `Get-AzSubscription`; `Set-AzContext` | **SQL DB Contributor** (covers `Microsoft.SqlVirtualMachine/*`, `Microsoft.Sql/managedInstances/*`, `Microsoft.Sql/servers/databases/*`, `Microsoft.Sql/servers/elasticPools/*`, `Microsoft.Sql/instancePools/*`) **+** write access to `Microsoft.DataFactory/factories/integrationRuntimes/*` (e.g. **Data Factory Contributor**) |
| `modify-arc-sql-license-type.ps1` | `Search-AzGraph` (Azure Resource Graph query over `microsoft.hybridcompute/machines` and `.../extensions`); `Get-AzConnectedMachine`; `Get/Set-AzConnectedMachineExtension` | **Azure Connected Machine Resource Administrator** (covers `Microsoft.HybridCompute/machines/extensions/*` write) — Resource Graph read is included in any role with `Microsoft.Resources/subscriptions/resourceGroups/resources/read` (e.g. **Reader**) |
| Both | `Get-AzSubscription`, `az account show` / `az account set` | **Reader** at minimum on every subscription scanned |

**Practical recommendation:** assign **Contributor** at the target subscription or
resource-group scope — it is a superset of all the writes above (SQL VM/MI/DB/elastic
pool/instance pool, Arc machine extensions, Data Factory integration runtimes) and
includes all required reads. For least-privilege, combine **SQL DB Contributor** +
**Azure Connected Machine Resource Administrator** (+ **Data Factory Contributor** if
SSIS Integration Runtime license updates are needed).

**Authentication prerequisite (not an RBAC role):** the executing identity must be able
to complete `Connect-AzAccount` / `az login` for the target tenant (or use an already
authenticated session / service principal) — required by the `Connect-Azure` function
in both scripts.
