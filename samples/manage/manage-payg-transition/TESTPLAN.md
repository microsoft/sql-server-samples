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
| 6 | `RunMode Single -Target Arc`, real transition | Ran end-to-end against Arc-enabled machines in subscription `fbaf508b-cb61-4383-9cda-a42bfa0c7bc9` (tenant `d1623670`, AdaptiveCloudLab) | ✅ Passed (originally blocked — see note below). 12 machines transitioned to `PAYG`, including `sqltvm`, `az-sqlnode1` and `sac-mabs` (the latter two were `Paid`, confirming `-Force` works). Verified independently via `Search-AzGraph` against `microsoft.hybridcompute/machines/extensions` and via the per-resource CSV report. |
| 7 | Wrapper line-continuation formatting (Scheduled mode) | Code review of the `for` loop building `$wrapper` lines for both Arc and Azure blocks | ✅ Confirmed a trailing backtick is appended to every line except the last, for any number of arguments |
| 8 | SQL Managed Instance transition (regression, prior fixes) | Ran against `abhisqlmi` (`BasePrice` → `LicenseIncluded`) | ✅ Passed; exactly 1 resource modified out of 247 unrelated SQL Servers in the subscription |
| 9 | Azure Policy-based compliance sample (PR #1490, IaaS SQL VM variant) | End-to-end: policy definition, assignment, compliance scan, remediation against `rajpoTest` | ✅ Passed (separate from this branch's fixes, but validated as an alternate transition method during the same testing session) |
| 10 | Self-contained script: no external downloads | Ran `manage-payg-transition.ps1 -Target Azure -RunMode Single` (default `-TargetLicenseType PAYG`) against `rajpoTest` (reset to `AHUB`) | ✅ Passed; log shows only "Writing embedded script ... to ..." (local file write), no `Invoke-RestMethod`/network download calls; `rajpoTest` transitioned `AHUB`→`PAYG`, CSV report generated with exactly 1 resource |
| 11 | `-TargetLicenseType AHUB` reverse transition | Ran the same command with `-TargetLicenseType AHUB` against `rajpoTest` (now `PAYG`) | ✅ Passed; internal query correctly used `BasePrice` filter (Azure SQL vocabulary); `rajpoTest` transitioned `PAYG`→`AHUB`, CSV report generated with exactly 1 resource |
| 12 | `-Force` emitted as a bare switch | Ran `-RunMode Single` with no `-targetSubscription` and inspected the generated `runnow.ps1` | ✅ Passed after fix. Previously the generator emitted `-Force 'True'`; since `-Force` is a `[switch]` it does not consume the following token, so the orphaned `'True'` bound to the first positional parameter (`$SubId`), producing *"Subscription True was not found in tenant"*. Now emitted as a bare `-Force`. |
| 13 | `-TenantId` / `-ReportOnly` pass-through | Ran `-Target Arc -TenantId d1623670-... -targetResourceGroup rajposqltvm -TargetLicenseType AHUB -ReportOnly` | ✅ Passed; log shows "Using provided TenantId: d1623670-...", `Found 1 resource(s) to update`, "ReportOnly mode enabled. Skipping modification for: sqltvm". No resource was modified; generated `runnow.ps1` contains a bare `-ReportOnly` switch. |
| 14 | Resource count reported correctly | Same dry run as #13, before and after the fix | ✅ Passed after fix. `Found N resource(s) to update` read `$resources.Count` *before* the paging loop populated `$resources`, so it always printed `0` even when resources were found and modified. Now reads `$allResults.Count` after the loop and correctly reports `Found 1 resource(s) to update`. |
| 15 | Self-containment in an isolated folder | Copied **only** `manage-payg-transition.ps1` into an empty temp directory and ran it there with `-ReportOnly` | ✅ Passed; with zero sibling files present the script materialized `manage-payg-transition\modify-arc-sql-license-type.ps1` (19,100 B) from its embedded here-string, generated `runnow.ps1`, and produced a valid CSV report. Confirms no dependency on co-located files. |
| 16 | Embedded vs standalone Arc script in sync | `Compare-Object` between the embedded `Arc` here-string block and the standalone `modify-arc-sql-license-type.ps1` | ✅ Passed; 1 difference, a trailing blank line only — functionally identical. |
| 17 | Arc update outcome reported truthfully | Code review + dry run producing the CSV report | ✅ Passed after fix. `Set-AzConnectedMachineExtension` runs with `-NoWait` and had no `-ErrorAction`, so service-side failures (e.g. *"An extension of type ... is still processing"*) were non-terminating: the `catch` never fired and the script printed `Updated --` for resources that had actually failed. Added `-ErrorAction Stop` plus `UpdateResult`/`UpdateError` CSV columns (`NotAttempted`/`RequestSubmitted`/`Failed`). |
| 18 | Idempotent re-run | Re-ran the default (`-TargetLicenseType PAYG`) against an already-converged scope | ✅ Passed; reported `Found 0 resource(s) to update`. Resources already at the target license type are excluded by the discovery query (`properties.settings.LicenseType != '<target>'`) by design, so repeat runs are safe. |
| 19 | README parameters match the script | Automated cross-check of every `-Param` used in a README example against the script's AST parameter block | ✅ Passed after fix. Previously 5 documented parameters did not exist (`-SubId`, `-ResourceGroup`, `-RunAt`, `-AutomationAccount`, `-ExclusionTag`), so every documented example would have failed. All 11 parameters now resolve. |

| 20 | `Stop-Transcript` no longer errors when transcription never started | Reproduced by pointing `Start-Transcript` at an unwritable path (`Z:\...`), then ran the script end-to-end | ✅ Passed after fix. Previously `Start-Transcript` could fail silently (unwritable log path, or a host that does not support transcription such as an Azure Automation runbook) and the unguarded `Stop-Transcript` at the end threw *"An error occurred stopping transcription: The host is not currently transcribing"* — surfacing a spurious failure after an otherwise successful run. Now emits `WARNING: Unable to start transcript logging: ... Continuing without a transcript.` and completes cleanly. Verified in all four copies (Arc/Azure × standalone/embedded). |

## Cleanup

- All temporary test artifacts (generated wrapper scripts, materialized sub-scripts,
  CSV reports, transcript logs, and isolated temp-folder copies of the orchestrator
  used for self-containment testing) were removed after each run.
- A `.gitignore` was added to the sample folder so these runtime artifacts
  (`manage-payg-transition/`, `runnow.ps1`, `ModifiedResources_*.csv`, `*.log`)
  cannot be committed by accident.
- `rajpoTest` was left in `AHUB` state and `abhisqlmi` in `LicenseIncluded` at the
  user's explicit request (for portal verification); they were deliberately **not** reverted.

## Known gaps / follow-ups

- `RunMode Scheduled` has **never been executed end-to-end**. The runbook import-path fix
  (the embedded `set-azurerunbook.ps1` hardcoded `./PayTransitionDownloads/` while the
  orchestrator materializes to `./manage-payg-transition/`) is validated by code review
  and parse checks only. Confirming it requires provisioning a real Azure Automation
  Account.
- 9 Arc machines in the test subscription could not be transitioned because their agents
  are `Disconnected` or `Expired` (`ASRTEST`, `ASTTest`, `kerimASRvm1`, `sql2022image-Rajpo`,
  `az-sqln01`, and four `Tag-TVM-sql2-*`). The extension setting can only be pushed to a
  reachable agent, so these need to be re-run once the machines reconnect. One
  (`Tag-TVM-sql2-fab2ee81`) also has `provisioningState = Failed` and is excluded by the
  discovery query regardless.
- `microsoft.azurearcdata/SqlServerInstances` resources with `hostType = "Azure Virtual Machine"`
  are read-only discovery mirrors; Azure rejects direct `licenseType` writes on them
  ("must be set to 'Undefined'"). The writable resource for VM-hosted SQL is
  `Microsoft.SqlVirtualMachine/SqlVirtualMachines/<name>`.
- There is no automated check that the three embedded here-string copies stay in sync with
  their standalone sources; test #16 was performed manually via `Compare-Object`.
- The generated wrapper interpolates values into single-quoted strings without escaping
  embedded `'` characters.

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
