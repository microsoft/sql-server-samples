#requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
<#
  Integration tests for ShrinkDriver. These run real DBCC SHRINKFILE operations against a live SQL
  instance. By default they use SQL Server LocalDB (Windows auth); set $env:SHRINKDRIVER_TEST_SERVER
  (+ optionally _AUTH = EntraID|Windows|SQL, _LOGIN, _PASSWORD, and _TRUSTCERT=1 for a self-signed dev
  instance) to target another instance, e.g. an Azure SQL Database logical server. They are skipped
  automatically when no instance is reachable, so they never break the unit test gate.

  Run:  Invoke-Pester -Path .\tests\ShrinkDriver.Integration.Tests.ps1 -Tag Integration

  Notes:
  - Small files are used so the suite runs quickly.
  - DROP-created free space appears only after deferred deallocation settles (handled
    by Wait-ShrinkFreeSpaceSettled).
  - Shrinks assert on the returned result object and use -BackoffBaseSeconds/-BackoffCapSeconds 0
    for instant retries. Most contexts pass -WaitAtLowPriority:$false so an (optionally blocked)
    shrink resolves immediately instead of waiting at low priority; WAIT_AT_LOW_PRIORITY itself is
    exercised by its own context.
#>

BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot 'fixtures\ShrinkTestDb.psm1') -Force
    $server = Get-ShrinkTestServer
    # Box SQL Server / LocalDB vs Azure SQL Database (EngineEdition 5, which provisions a single data
    # file). Some contexts apply only to the box engine and are skipped otherwise.
    $isBoxEngine = $false
    if ($server) {
        try { $isBoxEngine = (Get-ShrinkTestEngineEdition -Context $server) -ne 5 } catch { $isBoxEngine = $false }
    }
}

Describe 'ShrinkDriver integration' -Tag 'Integration' -Skip:(-not $server) {

    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot 'fixtures\ShrinkTestDb.psm1') -Force
        . (Join-Path $PSScriptRoot '..\src\ShrinkDriver.ps1')
        $server = Get-ShrinkTestServer
        $log = Join-Path ([System.IO.Path]::GetTempPath()) 'shrinkdriver-integration.log'
        # A dev SQL Server with a self-signed certificate needs its certificate trusted; opt in for such
        # a target via $env:SHRINKDRIVER_TEST_TRUSTCERT. Instances with a valid or client-trusted
        # certificate (Azure SQL, LocalDB) are validated normally, so nothing is forced for them.
        if ($server.TrustServerCertificate) {
            $PSDefaultParameterValues['Invoke-ShrinkDriver:TrustServerCertificate'] = $true
        }
    }

    Context 'Report mode' {
        BeforeAll { $db = New-ShrinkTestDatabase -Context $server }
        AfterAll { Remove-ShrinkTestDatabase -TestDb $db }

        It 'returns a Report result listing eligible files' {
            $r = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Report `
                -AuthType $server.Auth -MinReclaimMBOverride 1 -PassThru -LogPath $log 6>$null
            $r.Mode | Should -Be 'Report'
            $r.Files.Count | Should -BeGreaterThan 0
            $r.Eligible | Should -BeGreaterThan 0
            @($r.Files | Where-Object IsEligible).Count | Should -Be $r.Eligible
        }

        It 'reports zero eligible when the threshold is huge (no crash)' {
            $r = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Report `
                -AuthType $server.Auth -MinReclaimMBOverride 1000000000 -PassThru -LogPath $log 6>$null
            $r.Mode | Should -Be 'Report'
            $r.Eligible | Should -Be 0
        }
    }

    Context 'Shrink happy path' {
        BeforeAll {
            $db = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $db -MinFreeMB 8 | Out-Null
            $allocBefore = (Get-ShrinkTestFileSizes -TestDb $db | Measure-Object -Property alloc_mb -Sum).Sum
            $res = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Shrink `
                -AuthType $server.Auth -WaitAtLowPriority:$false -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                -MinReclaimMBOverride 1 -StepMBOverride 20 -Sessions 4 -StatusIntervalSeconds 5 -PassThru -LogPath $log 6>$null
        }
        AfterAll { Remove-ShrinkTestDatabase -TestDb $db }

        It 'returns a Shrink result object' {
            $res.Mode | Should -Be 'Shrink'
            $res.Files.Count | Should -BeGreaterThan 0
        }

        It 'classifies every file into a known bucket' {
            $known = @('Shrunk', 'PartlyShrunk', 'AlreadyMinimal', 'AlreadyAtTarget', 'Repacked', 'Grew', 'GaveUp', 'Interrupted', 'NotProcessed')
            foreach ($f in $res.Files) { $f.Bucket | Should -BeIn $known }
        }

        It 'reclaims space from at least one file' {
            ($res.Counts.Shrunk + $res.Counts.PartlyShrunk) | Should -BeGreaterThan 0
        }

        It 'reduces the total allocated size' {
            $allocAfter = (Get-ShrinkTestFileSizes -TestDb $db | Measure-Object -Property alloc_mb -Sum).Sum
            $allocAfter | Should -BeLessThan $allocBefore
        }
    }

    Context 'WAIT_AT_LOW_PRIORITY (low-priority lock)' {
        # These runs are uncontended, so the low-priority lock is granted at once and the driver's emitted
        # WAIT_AT_LOW_PRIORITY (ABORT_AFTER_WAIT = ...) clause is exercised end-to-end for both
        # abort choices.
        BeforeAll {
            $known = @('Shrunk', 'PartlyShrunk', 'AlreadyMinimal', 'AlreadyAtTarget', 'Repacked', 'Grew', 'GaveUp', 'Interrupted', 'NotProcessed')

            $dbSelf = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $dbSelf -MinFreeMB 8 | Out-Null
            $allocBeforeSelf = (Get-ShrinkTestFileSizes -TestDb $dbSelf | Measure-Object -Property alloc_mb -Sum).Sum
            $resSelf = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $dbSelf.Database -Mode Shrink `
                -AuthType $server.Auth -WaitAtLowPriority:$true -AbortAfterWait SELF -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                -MinReclaimMBOverride 1 -StepMBOverride 20 -Sessions 4 -StatusIntervalSeconds 5 -PassThru -LogPath $log 6>$null
            $allocAfterSelf = (Get-ShrinkTestFileSizes -TestDb $dbSelf | Measure-Object -Property alloc_mb -Sum).Sum

            $dbBlockers = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $dbBlockers -MinFreeMB 8 | Out-Null
            $allocBeforeBlockers = (Get-ShrinkTestFileSizes -TestDb $dbBlockers | Measure-Object -Property alloc_mb -Sum).Sum
            $resBlockers = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $dbBlockers.Database -Mode Shrink `
                -AuthType $server.Auth -WaitAtLowPriority:$true -AbortAfterWait BLOCKERS -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                -MinReclaimMBOverride 1 -StepMBOverride 20 -Sessions 4 -StatusIntervalSeconds 5 -PassThru -LogPath $log 6>$null
            $allocAfterBlockers = (Get-ShrinkTestFileSizes -TestDb $dbBlockers | Measure-Object -Property alloc_mb -Sum).Sum
        }
        AfterAll {
            Remove-ShrinkTestDatabase -TestDb $dbSelf
            Remove-ShrinkTestDatabase -TestDb $dbBlockers
        }

        It 'reclaims space with ABORT_AFTER_WAIT = SELF' {
            ($resSelf.Counts.Shrunk + $resSelf.Counts.PartlyShrunk) | Should -BeGreaterThan 0
            $allocAfterSelf | Should -BeLessThan $allocBeforeSelf
        }

        It 'reclaims space with ABORT_AFTER_WAIT = BLOCKERS' {
            ($resBlockers.Counts.Shrunk + $resBlockers.Counts.PartlyShrunk) | Should -BeGreaterThan 0
            $allocAfterBlockers | Should -BeLessThan $allocBeforeBlockers
        }

        It 'classifies every file into a known bucket under low-priority waits' {
            $resSelf.Files.Count | Should -BeGreaterThan 0
            $resBlockers.Files.Count | Should -BeGreaterThan 0
            foreach ($f in $resSelf.Files) { $f.Bucket | Should -BeIn $known }
            foreach ($f in $resBlockers.Files) { $f.Bucket | Should -BeIn $known }
        }
    }

    Context 'Per-file floor (FileTargetMBOverride)' {
        BeforeAll {
            $db = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $db -MinFreeMB 8 | Out-Null
            $before = Get-ShrinkTestFileSizes -TestDb $db
            $allocBefore = ($before | Measure-Object -Property alloc_mb -Sum).Sum
            $beforeAllocById = @{}
            $before | ForEach-Object { $beforeAllocById[[int]$_.file_id] = [int]$_.alloc_mb }
            $maxUsed = ($before | Measure-Object -Property used_mb -Maximum).Maximum
            $floor = [int]$maxUsed + 5   # above every file's used
            $res = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Shrink `
                -AuthType $server.Auth -WaitAtLowPriority:$false -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                -MinReclaimMBOverride 1 -FileTargetMBOverride $floor -StepMBOverride 10 -Sessions 4 `
                -StatusIntervalSeconds 5 -PassThru -LogPath $log 6>$null
        }
        AfterAll { Remove-ShrinkTestDatabase -TestDb $db }

        It 'never shrinks a file below the floor' {
            # A file that started above the floor must be held at or above it. Files already smaller than
            # the floor are left untouched (and may legitimately sit below it), so they are excluded.
            foreach ($f in (Get-ShrinkTestFileSizes -TestDb $db)) {
                if ($beforeAllocById[[int]$f.file_id] -gt $floor) { $f.alloc_mb | Should -BeGreaterOrEqual $floor }
            }
        }

        It 'reduces total allocated size toward the floor' {
            $allocAfter = (Get-ShrinkTestFileSizes -TestDb $db | Measure-Object -Property alloc_mb -Sum).Sum
            $allocAfter | Should -BeLessThan $allocBefore
        }
    }

    Context 'NoTruncate (repack only)' {
        BeforeAll {
            $db = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $db -MinFreeMB 8 | Out-Null
            $allocBefore = (Get-ShrinkTestFileSizes -TestDb $db | Measure-Object -Property alloc_mb -Sum).Sum
            $res = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Shrink `
                -AuthType $server.Auth -NoTruncate -WaitAtLowPriority:$false -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                -MinReclaimMBOverride 1 -Sessions 4 -StatusIntervalSeconds 5 -PassThru -LogPath $log 6>$null
        }
        AfterAll { Remove-ShrinkTestDatabase -TestDb $db }

        It 'reports every processed file as Repacked' {
            $res.Files.Count | Should -BeGreaterThan 0
            $res.Counts.Repacked | Should -Be $res.Files.Count
        }

        It 'never releases space (nothing shrunk)' {
            ($res.Counts.Shrunk + $res.Counts.PartlyShrunk) | Should -Be 0
        }

        It 'leaves the total allocated size unchanged' {
            $allocAfter = (Get-ShrinkTestFileSizes -TestDb $db | Measure-Object -Property alloc_mb -Sum).Sum
            $allocAfter | Should -Be $allocBefore
        }
    }

    Context 'TruncateOnly (release tail free space)' -Skip:(-not $isBoxEngine) {
        BeforeAll {
            $db = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $db -MinFreeMB 8 | Out-Null
            # Grow every data file so there is guaranteed unused space at the tail for TRUNCATEONLY to
            # reclaim (the drop-created free space is interspersed and may not sit at the file end).
            Add-ShrinkTestTailSpace -TestDb $db -AddMB 48
            $allocBefore = (Get-ShrinkTestFileSizes -TestDb $db | Measure-Object -Property alloc_mb -Sum).Sum
            $res = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Shrink `
                -AuthType $server.Auth -TruncateOnly -WaitAtLowPriority:$false -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                -MinReclaimMBOverride 1 -Sessions 4 -StatusIntervalSeconds 5 -PassThru -LogPath $log 6>$null
        }
        AfterAll { Remove-ShrinkTestDatabase -TestDb $db }

        It 'classifies every file into a known bucket' {
            $known = @('Shrunk', 'PartlyShrunk', 'AlreadyMinimal', 'AlreadyAtTarget', 'Repacked', 'Grew', 'GaveUp', 'Interrupted', 'NotProcessed')
            $res.Files.Count | Should -BeGreaterThan 0
            foreach ($f in $res.Files) { $f.Bucket | Should -BeIn $known }
        }

        It 'reclaims the trailing free space' {
            $res.Counts.Shrunk | Should -BeGreaterThan 0
            $allocAfter = (Get-ShrinkTestFileSizes -TestDb $db | Measure-Object -Property alloc_mb -Sum).Sum
            $allocAfter | Should -BeLessThan $allocBefore
        }
    }

    Context 'Graceful stop on the run-time limit' {
        BeforeAll {
            $db = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $db -MinFreeMB 8 | Out-Null
            # Hold an exclusive lock on a table the fixture keeps (it drops every other one) so the
            # shrink must move that table's pages and blocks; the run then cannot finish and must stop
            # when the short run-time limit fires.
            $blocker = Open-ShrinkTestBlocker -TestDb $db -TableName 'dbo.t2'
            try {
                $res = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Shrink `
                    -AuthType $server.Auth -WaitAtLowPriority:$false -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                    -MinReclaimMBOverride 1 -StepMBOverride 10 -Sessions 2 -StatusIntervalSeconds 2 `
                    -MaxRuntimeSecondsOverride 5 -PassThru -LogPath $log 6>$null
            }
            finally {
                Close-ShrinkTestBlocker -Connection $blocker
            }
        }
        AfterAll { Remove-ShrinkTestDatabase -TestDb $db }

        It 'stops because of the run-time limit' {
            $res.StoppedBy | Should -Be 'Timeout'
        }

        It 'records in-flight or unprocessed files instead of dropping them' {
            $res.Files.Count | Should -BeGreaterThan 0
            ($res.Counts.Interrupted + $res.Counts.PartlyShrunk + $res.Counts.NotProcessed) | Should -BeGreaterThan 0
        }

        It 'reports data files that still have reclaimable space to reclaim on a re-run' {
            # The blocked and unprocessed files were not fully shrunk, so an end-of-run re-check finds
            # space still reclaimable and reports it for a follow-up run.
            $res.EligibleRemaining | Should -BeGreaterThan 0
        }
    }

    Context 'Worker reconnect after a dropped connection' -Skip:(-not $isBoxEngine) {
        BeforeAll {
            $db = New-ShrinkTestDatabase -Context $server
            Wait-ShrinkFreeSpaceSettled -TestDb $db -MinFreeMB 8 | Out-Null
            $rlog = Join-Path ([System.IO.Path]::GetTempPath()) ("shrinkdriver-reconnect-{0}.log" -f [guid]::NewGuid().ToString('N'))
            # Block the shrink with an exclusive lock on a table the fixture keeps (it drops every other
            # one) so the worker sessions stay connected, then kill one from a background job to force
            # the driver's reconnect path. A short run-time limit ends the (blocked) run.
            $blocker = Open-ShrinkTestBlocker -TestDb $db -TableName 'dbo.t2'
            $killJob = Start-Job -ScriptBlock {
                param($serverInstance, $database)
                Import-Module SqlServer -ErrorAction Stop
                $kills = 0
                $deadline = (Get-Date).AddSeconds(30)
                while ((Get-Date) -lt $deadline -and $kills -lt 2) {
                    try {
                        $r = Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -TrustServerCertificate -ErrorAction Stop `
                            -Query "SELECT TOP (1) session_id AS spid FROM sys.dm_exec_sessions WHERE program_name LIKE 'ShrinkDriver-w%' AND database_id = DB_ID()"
                        if ($r -and $null -ne $r.spid) {
                            Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -TrustServerCertificate -ErrorAction Stop -Query "KILL $($r.spid)"
                            $kills++
                        }
                    }
                    catch { }
                    Start-Sleep -Milliseconds 400
                }
                $kills
            } -ArgumentList $server.ServerInstance, $db.Database
            try {
                $res = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Shrink `
                    -AuthType $server.Auth -WaitAtLowPriority:$false -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                    -MinReclaimMBOverride 1 -StepMBOverride 10 -Sessions 3 -StatusIntervalSeconds 2 `
                    -MaxRuntimeSecondsOverride 20 -PassThru -LogPath $rlog 6>$null
            }
            finally {
                Close-ShrinkTestBlocker -Connection $blocker
            }
            $killCount = @(Receive-Job $killJob -Wait -AutoRemoveJob)[-1]
            $rlogText = Get-Content -Raw -LiteralPath $rlog
        }
        AfterAll {
            Remove-ShrinkTestDatabase -TestDb $db
            if ($rlog -and (Test-Path $rlog)) { Remove-Item -LiteralPath $rlog -ErrorAction SilentlyContinue }
        }

        It 'reconnects a worker whose session was killed' {
            $killCount | Should -BeGreaterThan 0
            $rlogText | Should -Match 'reconnected on attempt'
        }

        It 'still accounts for every eligible file' {
            $sum = ($res.Counts.PSObject.Properties | Measure-Object -Property Value -Sum).Sum
            $sum | Should -Be $res.Files.Count
        }
    }

    Context 'Concurrency (files > sessions)' -Skip:(-not $isBoxEngine) {
        BeforeAll {
            $db = New-ShrinkTestDatabase -Context $server -FileCount 6
            Wait-ShrinkFreeSpaceSettled -TestDb $db -MinFreeMB 8 | Out-Null
            $res = Invoke-ShrinkDriver -ServerName $server.ServerInstance -DatabaseName $db.Database -Mode Shrink `
                -AuthType $server.Auth -WaitAtLowPriority:$false -BackoffBaseSeconds 0 -BackoffCapSeconds 0 `
                -MinReclaimMBOverride 1 -StepMBOverride 20 -Sessions 2 -StatusIntervalSeconds 5 -PassThru -LogPath $log 6>$null
        }
        AfterAll { Remove-ShrinkTestDatabase -TestDb $db }

        It 'exercises more files than sessions' {
            # Sessions was capped at 2 while more eligible files exist, so a freed worker must pick up the rest.
            $res.Files.Count | Should -BeGreaterThan 2
        }

        It 'accounts for every eligible file exactly once (counts tally to files; none dropped)' {
            $sum = ($res.Counts.PSObject.Properties | Measure-Object -Property Value -Sum).Sum
            $sum | Should -Be $res.Files.Count
        }

        It 'shrinks at least one file under limited concurrency' {
            ($res.Counts.Shrunk + $res.Counts.PartlyShrunk) | Should -BeGreaterThan 0
        }
    }
}
