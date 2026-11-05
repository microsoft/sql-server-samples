#requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
<#
  Unit tests for ShrinkDriver.
  Run:  Invoke-Pester -Path .\tests\ShrinkDriver.Unit.Tests.ps1
#>

BeforeAll {
    # Dot-source the file to expose functions for testing.
    . (Join-Path $PSScriptRoot '..\src\ShrinkDriver.ps1')
}

Describe 'Test-ShrinkParameterSet' {
    It 'rejects TruncateOnly + NoTruncate together' {
        $e = Test-ShrinkParameterSet @{ AuthType='EntraID'; Sessions=5; AbortAfterWait='SELF'; TruncateOnly=$true; NoTruncate=$true }
        $e | Should -Not -BeNullOrEmpty
        ($e -join ';') | Should -Match 'mutually exclusive'
    }
    It 'rejects TruncateOnly + FileTargetSizeGiB' {
        $e = Test-ShrinkParameterSet @{ AuthType='EntraID'; Sessions=5; AbortAfterWait='SELF'; TruncateOnly=$true; FileTargetSizeGiB=100 }
        ($e -join ';') | Should -Match 'FileTargetSizeGiB'
    }
    It 'requires a login for SQL auth (the password is prompted, not required)' {
        $e = Test-ShrinkParameterSet @{ AuthType='SQL'; Sessions=5; AbortAfterWait='SELF' }
        ($e -join ';') | Should -Match 'SqlLogin'
        ($e -join ';') | Should -Not -Match 'SqlPassword'
    }
    It 'rejects a plain-text SqlPassword for SQL auth' {
        $e = Test-ShrinkParameterSet @{ AuthType='SQL'; SqlLogin='u'; SqlPassword='p'; AbortAfterWait='SELF' }
        ($e -join ';') | Should -Match 'SecureString'
    }
    It 'accepts a SecureString SqlPassword for SQL auth' {
        $sec = ConvertTo-SecureString 'p' -AsPlainText -Force
        $e = Test-ShrinkParameterSet @{ AuthType='SQL'; SqlLogin='u'; SqlPassword=$sec; AbortAfterWait='SELF' }
        ($e -join ';') | Should -Not -Match 'SqlPassword'
    }
    It 'rejects an invalid AbortAfterWait' {
        $e = Test-ShrinkParameterSet @{ AuthType='EntraID'; Sessions=5; AbortAfterWait='NONE' }
        ($e -join ';') | Should -Match 'AbortAfterWait'
    }
    It 'accepts a valid EntraID parameter set' {
        $e = Test-ShrinkParameterSet @{ AuthType='EntraID'; Sessions=5; AbortAfterWait='SELF'; TruncateOnly=$false; NoTruncate=$false }
        $e | Should -BeNullOrEmpty
    }
}

Describe 'Resolve-ShrinkLogPath' {
    It 'returns the full path for a writable file in an existing directory' {
        $p = Join-Path $TestDrive 'shrink.log'
        Resolve-ShrinkLogPath -Path $p | Should -Be ([System.IO.Path]::GetFullPath($p))
    }
    It 'creates the file if it does not yet exist' {
        $p = Join-Path $TestDrive 'created.log'
        Resolve-ShrinkLogPath -Path $p | Out-Null
        Test-Path -LiteralPath $p | Should -BeTrue
    }
    It 'resolves a relative path against the current location' {
        Push-Location $TestDrive
        try {
            $expected = Join-Path (Get-Location).ProviderPath 'rel.log'
            Resolve-ShrinkLogPath -Path 'rel.log' | Should -Be $expected
        } finally { Pop-Location }
    }
    It 'throws when the directory does not exist' {
        $p = Join-Path $TestDrive 'missing-dir\deep\x.log'
        { Resolve-ShrinkLogPath -Path $p } | Should -Throw '*does not exist*'
    }
    It 'throws when the path is a directory' {
        { Resolve-ShrinkLogPath -Path $TestDrive } | Should -Throw '*is a directory*'
    }
}

Describe 'Numeric parameter validation' {
    It '<Param> declares ValidateRange <Min>..<Max>' -TestCases @(
        @{ Param = 'Sessions';              Min = 1; Max = [int]::MaxValue }
        @{ Param = 'RetryCount';            Min = 0; Max = 50 }
        @{ Param = 'FileTargetSizeGiB';     Min = 0; Max = [int]::MaxValue }
        @{ Param = 'MaxRuntimeMinutes';     Min = 1; Max = [int]::MaxValue }
        @{ Param = 'StepGiB';               Min = 1; Max = [int]::MaxValue }
        @{ Param = 'MinReclaimGiB';         Min = 0; Max = [int]::MaxValue }
        @{ Param = 'StatusIntervalSeconds'; Min = 1; Max = [int]::MaxValue }
        @{ Param = 'StuckWindowSeconds';    Min = 1; Max = [int]::MaxValue }
    ) {
        $range = (Get-Command Invoke-ShrinkDriver).Parameters[$Param].Attributes |
            Where-Object { $_ -is [ValidateRange] } | Select-Object -First 1
        $range | Should -Not -BeNullOrEmpty
        $range.MinRange | Should -Be $Min
        $range.MaxRange | Should -Be $Max
    }

    It 'rejects <Param>=<Value> as out of range' -TestCases @(
        @{ Param = 'Sessions';              Value = 0 }
        @{ Param = 'RetryCount';            Value = -1 }
        @{ Param = 'RetryCount';            Value = 51 }
        @{ Param = 'FileTargetSizeGiB';     Value = -1 }
        @{ Param = 'MaxRuntimeMinutes';     Value = 0 }
        @{ Param = 'StepGiB';               Value = 0 }
        @{ Param = 'MinReclaimGiB';         Value = -1 }
        @{ Param = 'StatusIntervalSeconds'; Value = 0 }
        @{ Param = 'StuckWindowSeconds';    Value = 0 }
    ) {
        $splat = @{ ServerName = 's'; DatabaseName = 'd'; $Param = $Value }
        { Invoke-ShrinkDriver @splat } |
            Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-ShrinkDriver'
    }
}

Describe 'Mode parameter' {
    It 'allows only Report and Shrink' {
        $vs = (Get-Command Invoke-ShrinkDriver).Parameters['Mode'].Attributes |
            Where-Object { $_ -is [ValidateSet] } | Select-Object -First 1
        $vs.ValidValues | Should -Contain 'Report'
        $vs.ValidValues | Should -Contain 'Shrink'
        $vs.ValidValues.Count | Should -Be 2
    }
    It 'rejects an invalid mode' {
        { Invoke-ShrinkDriver -ServerName s -DatabaseName d -Mode Nope } |
            Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-ShrinkDriver'
    }
}

Describe 'Get-ShrinkBackoffSeconds' {
    It 'never exceeds min(cap, base*2^attempt) and is >= 0' {
        $rng = [System.Random]::new(42)
        foreach ($a in 0..10) {
            $cap = [Math]::Min(60, 5 * [Math]::Pow(2, $a))
            $v = Get-ShrinkBackoffSeconds -Attempt $a -BaseSec 5 -CapSec 60 -Random $rng
            $v | Should -BeGreaterOrEqual 0
            $v | Should -BeLessOrEqual $cap
        }
    }
    It 'is deterministic with a seeded RNG' {
        $a = Get-ShrinkBackoffSeconds -Attempt 3 -Random ([System.Random]::new(7))
        $b = Get-ShrinkBackoffSeconds -Attempt 3 -Random ([System.Random]::new(7))
        $a | Should -Be $b
    }
}

Describe 'Format-ShrinkKeyValueTable' {
    It 'pads labels to the widest key and keeps the colon aligned' {
        $lines = Format-ShrinkKeyValueTable -Rows ([ordered]@{ 'A' = 1; 'Longer' = 2 })
        $lines.Count | Should -Be 2
        $lines[1] | Should -Be '  Longer : 2'
        $lines[0] | Should -Match '^\s{2}A\s+: 1$'
        $lines[0].IndexOf(':') | Should -Be ($lines[1].IndexOf(':'))
    }
}

Describe 'Format-ShrinkTable' {
    It 'returns nothing for an empty set' {
        @(Format-ShrinkTable -Rows @()) | Should -BeNullOrEmpty
    }
    It 'renders a header, separator, and one line per row' {
        $rows = @(
            [ordered]@{ A = '1';  Name = 'x';  B = '10' }
            [ordered]@{ A = '22'; Name = 'yy'; B = '3' }
        )
        $lines = @(Format-ShrinkTable -Rows $rows -RightAlign @('A', 'B'))
        $lines.Count | Should -Be 4
        $lines[0] | Should -Match 'A\s+Name\s+B'
        $lines[1] | Should -Match '^-+\s+-+\s+-+$'
    }
    It 'right-aligns listed columns and left-aligns the rest' {
        $rows = @(
            [ordered]@{ Name = 'a';  Val = '1' }
            [ordered]@{ Name = 'bb'; Val = '100' }
        )
        $lines = @(Format-ShrinkTable -Rows $rows -RightAlign @('Val'))
        # Name left-aligned (short value flush left), Val right-aligned (short value padded left).
        $lines[2] | Should -Match '^a\s+\S*1$'
        $lines[3] | Should -Match '^bb\s+100$'
    }
}

Describe 'Test-ShrinkWorthwhile' {
    It 'is worthwhile when reclaimable meets the minimum' {
        Test-ShrinkWorthwhile -AllocatedMB 1000 -UsedMB 100 -MinReclaimMB 100 | Should -BeTrue
    }
    It 'is not worthwhile when reclaimable is below the minimum' {
        Test-ShrinkWorthwhile -AllocatedMB 1000 -UsedMB 950 -MinReclaimMB 100 | Should -BeFalse
    }
    It 'treats exactly the minimum as worthwhile' {
        Test-ShrinkWorthwhile -AllocatedMB 1000 -UsedMB 900 -MinReclaimMB 100 | Should -BeTrue
    }
    It 'uses the larger of used pages and the target floor' {
        Test-ShrinkWorthwhile -AllocatedMB 1000 -UsedMB 100 -FloorMB 950 -MinReclaimMB 100 | Should -BeFalse
    }
    It 'is not worthwhile for a zero-size file' {
        Test-ShrinkWorthwhile -AllocatedMB 0 -UsedMB 0 -MinReclaimMB 100 | Should -BeFalse
    }
    It 'ignores a tiny gain on a large file' {
        Test-ShrinkWorthwhile -AllocatedMB 100000 -UsedMB 99950 -MinReclaimMB 100 | Should -BeFalse
    }
}

Describe 'Get-ShrinkReclaimableMB' {
    It 'is allocated minus used with no floor' {
        Get-ShrinkReclaimableMB -AllocatedMB 1000 -UsedMB 200 | Should -Be 800
    }
    It 'uses the target floor when it is larger than used' {
        Get-ShrinkReclaimableMB -AllocatedMB 1000 -UsedMB 200 -FloorMB 600 | Should -Be 400
    }
    It 'ignores the target floor when used is larger' {
        Get-ShrinkReclaimableMB -AllocatedMB 1000 -UsedMB 700 -FloorMB 600 | Should -Be 300
    }
    It 'never returns a negative value' {
        Get-ShrinkReclaimableMB -AllocatedMB 100 -UsedMB 500 | Should -Be 0
    }
}

Describe 'Get-ShrinkSumMB' {
    It 'sums the property across items' {
        $items = @([pscustomobject]@{ V = 10 }, [pscustomobject]@{ V = 32 })
        Get-ShrinkSumMB -Items $items -Property V | Should -Be 42
    }
    It 'returns 0 for an empty set' {
        Get-ShrinkSumMB -Items @() -Property V | Should -Be 0
    }
}

Describe 'Get-ShrinkSizeUnit' {
    It 'picks <unit> for <mb> MiB' -TestCases @(
        @{ Mb = 0.5;      Unit = 'KiB' }
        @{ Mb = 500;      Unit = 'MiB' }
        @{ Mb = 2048;     Unit = 'GiB' }
        @{ Mb = 2097152;  Unit = 'TiB' }
    ) {
        (Get-ShrinkSizeUnit -MaxMegabytes $Mb).Name | Should -Be $Unit
    }
}

Describe 'Format-ShrinkFileReport' {
    It 'includes a header row' {
        $files = 1..3 | ForEach-Object { [pscustomobject]@{ FileId = $_; Name = "f$_"; UsedMB = 10; AllocatedMB = ($_ * 1000); ReclaimableMB = ($_ * 1000 - 10); IsEligible = $true } }
        (@(Format-ShrinkFileReport -Files $files) -join "`n") | Should -Match 'File\s+Name\s+Used \(\w+\)\s+Allocated \(\w+\)\s+Reclaimable \(\w+\)\s+Eligible'
    }
    It 'uses one unit for the whole table, noted in the header' {
        $files = @(
            [pscustomobject]@{ FileId = 1; Name = 'big';  UsedMB = 1; AllocatedMB = (50 * 1024); ReclaimableMB = (50 * 1024 - 1); IsEligible = $true }
            [pscustomobject]@{ FileId = 2; Name = 'tiny'; UsedMB = 1; AllocatedMB = 8;           ReclaimableMB = 7;             IsEligible = $false }
        )
        $lines = @(Format-ShrinkFileReport -Files $files)
        $lines[0] | Should -Match 'Used \(GiB\)'
        $lines[0] | Should -Match 'Allocated \(GiB\)'
        $lines[0] | Should -Match 'Reclaimable \(GiB\)'
        # The tiny file is shown in the table's GiB unit (rounds to 0.0), not its own MiB unit.
        $tinyRow = $lines | Where-Object { $_ -match '^\s*2\s+tiny\s' }
        $tinyRow | Should -Match '0\.0'
        ($lines | Where-Object { $_ -match 'MiB|KiB|TiB' }) | Should -BeNullOrEmpty
    }
    It 'lists the most reclaimable file first' {
        $files = 1..3 | ForEach-Object { [pscustomobject]@{ FileId = $_; Name = "f$_"; UsedMB = 10; AllocatedMB = ($_ * 1000); ReclaimableMB = ($_ * 1000 - 10); IsEligible = $true } }
        $lines = @(Format-ShrinkFileReport -Files $files)
        $lines[2] | Should -Match '^\s*3\s+f3'
    }
    It 'limits to TopN and notes the omitted files' {
        $many = 1..150 | ForEach-Object { [pscustomobject]@{ FileId = $_; Name = "f$_"; UsedMB = 1; AllocatedMB = ($_ * 10); ReclaimableMB = ($_ * 10 - 1); IsEligible = $true } }
        $lines = @(Format-ShrinkFileReport -Files $many -TopN 100)
        ($lines | Where-Object { $_ -match '50 other file\(s\) omitted' }) | Should -Not -BeNullOrEmpty
        $lines.Count | Should -Be 103
    }
    It 'renders the eligibility column as Yes or No' {
        $files = @(
            [pscustomobject]@{ FileId = 1; Name = 'a'; UsedMB = 10; AllocatedMB = 5000; ReclaimableMB = 4990; IsEligible = $true }
            [pscustomobject]@{ FileId = 2; Name = 'b'; UsedMB = 10; AllocatedMB = 20;   ReclaimableMB = 10;   IsEligible = $false }
        )
        $lines = @(Format-ShrinkFileReport -Files $files)
        ($lines | Where-Object { $_ -match '^\s*1\s+a\s' }) | Should -Match 'Yes'
        ($lines | Where-Object { $_ -match '^\s*2\s+b\s' }) | Should -Match 'No'
    }
    It 'handles an empty set' {
        @(Format-ShrinkFileReport -Files @()) | Should -Be '(no data files found)'
    }
}

Describe 'Get-ShrinkNextTargetMB' {
    It 'steps down by 20 GiB by default' {
        Get-ShrinkNextTargetMB -AllocatedMB 100000 | Should -Be (100000 - 20480)
    }
    It 'never goes below the floor' {
        Get-ShrinkNextTargetMB -AllocatedMB 12000 -FloorMB 10000 | Should -Be 10000
    }
    It 'clamps to the floor when a full step would overshoot it' {
        Get-ShrinkNextTargetMB -AllocatedMB 10500 -FloorMB 10000 | Should -Be 10000
    }
    It 'never returns 0, since DBCC reads target 0 as the file creation size' {
        Get-ShrinkNextTargetMB -AllocatedMB 10240 | Should -Be 1
    }
    It 'clamps an allocation within one step of 0 to 1 rather than 0' {
        Get-ShrinkNextTargetMB -AllocatedMB 3000 | Should -Be 1
    }
}

Describe 'Select-ShrinkNextFile' {
    BeforeAll {
        $script:files = @(
            [pscustomobject]@{ FileId=1; AllocatedMB=1000; UsedMB=900; FloorMB=$null }  # reclaim 100
            [pscustomobject]@{ FileId=2; AllocatedMB=1000; UsedMB=200; FloorMB=$null }  # reclaim 800
            [pscustomobject]@{ FileId=3; AllocatedMB=1000; UsedMB=1000; FloorMB=$null } # reclaim 0
        )
    }
    It 'picks the most reclaimable file' {
        (Select-ShrinkNextFile -Files $script:files).FileId | Should -Be 2
    }
    It 'skips owned and excluded files' {
        (Select-ShrinkNextFile -Files $script:files -OwnedFileIds @(2) -ExcludedFileIds @()).FileId | Should -Be 1
    }
    It 'skips files that already reached a terminal state' {
        (Select-ShrinkNextFile -Files $script:files -ExcludedFileIds @(2)).FileId | Should -Be 1
    }
    It 'returns null when nothing is reclaimable' {
        Select-ShrinkNextFile -Files @($script:files[2]) | Should -BeNullOrEmpty
    }
    It 'ranks by reclaimable space above the floor, not raw unused space' {
        # File 1 has more raw unused space (900) but a floor that leaves only 100 reclaimable; file 2
        # has less unused space (500) but no floor, so 500 is reclaimable and it should be picked first.
        $files = @(
            [pscustomobject]@{ FileId = 1; AllocatedMB = 1000; UsedMB = 100; FloorMB = 900 } # reclaim 100
            [pscustomobject]@{ FileId = 2; AllocatedMB = 1000; UsedMB = 500; FloorMB = $null } # reclaim 500
        )
        (Select-ShrinkNextFile -Files $files).FileId | Should -Be 2
    }
}

Describe 'Get-ShrinkBucketCounts' {
    It 'tallies each bucket' {
        $c = Get-ShrinkBucketCounts -Buckets @('Shrunk','Shrunk','AlreadyMinimal','AlreadyAtTarget','GaveUp','Shrunk','PartlyShrunk','Grew','Repacked','Repacked','Interrupted','NotProcessed','NotProcessed')
        $c.Shrunk | Should -Be 3
        $c.Repacked | Should -Be 2
        $c.PartlyShrunk | Should -Be 1
        $c.AlreadyMinimal | Should -Be 1
        $c.AlreadyAtTarget | Should -Be 1
        $c.Grew | Should -Be 1
        $c.GaveUp | Should -Be 1
        $c.Interrupted | Should -Be 1
        $c.NotProcessed | Should -Be 2
    }
    It 'returns zeros for an empty set' {
        $c = Get-ShrinkBucketCounts -Buckets @()
        $c.Shrunk | Should -Be 0
        $c.Repacked | Should -Be 0
        $c.PartlyShrunk | Should -Be 0
        $c.AlreadyMinimal | Should -Be 0
        $c.AlreadyAtTarget | Should -Be 0
        $c.Grew | Should -Be 0
        $c.GaveUp | Should -Be 0
        $c.Interrupted | Should -Be 0
        $c.NotProcessed | Should -Be 0
    }
}

Describe 'Get-ShrinkGaveUpBucket' {
    It 'classifies a net reduction as PartlyShrunk' {
        Get-ShrinkGaveUpBucket -StartAllocMB 1000 -FinalAllocMB 600 | Should -Be 'PartlyShrunk'
    }
    It 'classifies a net growth as Grew' {
        Get-ShrinkGaveUpBucket -StartAllocMB 1000 -FinalAllocMB 1200 | Should -Be 'Grew'
    }
    It 'classifies no change as GaveUp' {
        Get-ShrinkGaveUpBucket -StartAllocMB 1000 -FinalAllocMB 1000 | Should -Be 'GaveUp'
    }
}

Describe 'Get-ShrinkStopOutcome' {
    It 'reports Interrupted on a forced quit regardless of sizes' {
        $o = Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 600 -Cause 'Ctrl+C' -Force
        $o.Bucket | Should -Be 'Interrupted'
        $o.Reason | Should -Match 'twice'
    }
    It 'reports PartlyShrunk when the file ended smaller' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 600 -Cause 'Timeout').Bucket | Should -Be 'PartlyShrunk'
    }
    It 'reports Grew when the file ended larger' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 1200 -Cause 'Ctrl+C').Bucket | Should -Be 'Grew'
    }
    It 'reports Interrupted (no progress) when the size is unchanged' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 1000 -Cause 'Timeout').Bucket | Should -Be 'Interrupted'
    }
    It 'reports Interrupted when the file was never measured (null start)' {
        (Get-ShrinkStopOutcome -StartAllocMB $null -FinalAllocMB $null -Cause 'Ctrl+C').Bucket | Should -Be 'Interrupted'
    }
    It 'reports Interrupted when the final size could not be read (null final)' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB $null -Cause 'Timeout').Bucket | Should -Be 'Interrupted'
    }
    It 'uses a run-time-limit reason for the Timeout cause' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 600 -Cause 'Timeout').Reason | Should -Match 'run time limit'
    }
    It 'uses a Ctrl+C reason for the Ctrl+C cause' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 600 -Cause 'Ctrl+C').Reason | Should -Match 'Ctrl\+C'
    }
    It 'uses a transaction-log reason for the LogFull cause' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 600 -Cause 'LogFull').Reason | Should -Match 'transaction log safety limit'
    }
    It 'uses a version-store reason for the PvsGrowth cause' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 600 -Cause 'PvsGrowth').Reason | Should -Match 'version store'
    }
    It 'still classifies by size for a safety-valve cause' {
        (Get-ShrinkStopOutcome -StartAllocMB 1000 -FinalAllocMB 600 -Cause 'LogFull').Bucket | Should -Be 'PartlyShrunk'
    }
}

Describe 'Test-ShrinkResourcePressure' {
    It 'breaches LogFull when log used reaches the threshold percentage of the ceiling' {
        $r = Test-ShrinkResourcePressure -LogUsedBytes 60 -LogCeilingBytes 100 -MaxLogUsedPercent 60 -PvsKb 0 -FreeForGrowthKb 100 -MaxPvsPercentOfFreeSpace 80
        $r.Breach | Should -Be 'LogFull'
        $r.LogPercent | Should -Be 60
    }
    It 'does not breach the log below the threshold' {
        (Test-ShrinkResourcePressure -LogUsedBytes 59 -LogCeilingBytes 100 -MaxLogUsedPercent 60 -PvsKb 0 -FreeForGrowthKb 100 -MaxPvsPercentOfFreeSpace 80).Breach | Should -Be ''
    }
    It 'treats a log threshold of 0 as disabled even at 100% used' {
        (Test-ShrinkResourcePressure -LogUsedBytes 100 -LogCeilingBytes 100 -MaxLogUsedPercent 0 -PvsKb 0 -FreeForGrowthKb 100 -MaxPvsPercentOfFreeSpace 0).Breach | Should -Be ''
    }
    It 'treats a zero log ceiling with used log as fully consumed' {
        (Test-ShrinkResourcePressure -LogUsedBytes 10 -LogCeilingBytes 0 -MaxLogUsedPercent 60 -PvsKb 0 -FreeForGrowthKb 100 -MaxPvsPercentOfFreeSpace 80).Breach | Should -Be 'LogFull'
    }
    It 'breaches PvsGrowth when PVS reaches the threshold percentage of the runway' {
        $r = Test-ShrinkResourcePressure -LogUsedBytes 0 -LogCeilingBytes 100 -MaxLogUsedPercent 60 -PvsKb 80 -FreeForGrowthKb 100 -MaxPvsPercentOfFreeSpace 80
        $r.Breach | Should -Be 'PvsGrowth'
        $r.PvsPercent | Should -Be 80
    }
    It 'treats zero runway with PVS present as a PVS breach' {
        (Test-ShrinkResourcePressure -LogUsedBytes 0 -LogCeilingBytes 100 -MaxLogUsedPercent 60 -PvsKb 1 -FreeForGrowthKb 0 -MaxPvsPercentOfFreeSpace 80).Breach | Should -Be 'PvsGrowth'
    }
    It 'does not breach PVS when runway is zero and there is no PVS' {
        (Test-ShrinkResourcePressure -LogUsedBytes 0 -LogCeilingBytes 100 -MaxLogUsedPercent 60 -PvsKb 0 -FreeForGrowthKb 0 -MaxPvsPercentOfFreeSpace 80).Breach | Should -Be ''
    }
    It 'checks the log before PVS when both would breach' {
        (Test-ShrinkResourcePressure -LogUsedBytes 100 -LogCeilingBytes 100 -MaxLogUsedPercent 60 -PvsKb 100 -FreeForGrowthKb 100 -MaxPvsPercentOfFreeSpace 80).Breach | Should -Be 'LogFull'
    }
}

Describe 'Format-ShrinkSafetyValveMessage' {
    It 'says the log frees after rollback when a shrink worker holds it' {
        $m = Format-ShrinkSafetyValveMessage -Breach 'LogFull' -LogPercent 61 -PvsPercent 0 -LogReuseWaitDesc 'ACTIVE_TRANSACTION' -HolderText 'session 71 (MoveBlobPage, worker 3)' -HolderSpid 71 -HolderIsWorker $true
        $m | Should -Match 'Log 61% of max'
        $m | Should -Match 'worker 3'
        $m | Should -Match "rollback completes"
    }
    It 'names the blocking session when a non-worker holds the log' {
        $m = Format-ShrinkSafetyValveMessage -Breach 'LogFull' -LogPercent 61 -PvsPercent 0 -LogReuseWaitDesc 'ACTIVE_TRANSACTION' -HolderText 'session 88 (usr_bulkload, not a shrink worker)' -HolderSpid 88 -HolderIsWorker $false
        $m | Should -Match 'not a shrink worker'
        $m | Should -Match 'transaction on session 88 completes'
    }
    It 'reports a non-transaction reuse wait for the log' {
        $m = Format-ShrinkSafetyValveMessage -Breach 'LogFull' -LogPercent 61 -PvsPercent 0 -LogReuseWaitDesc 'LOG_BACKUP'
        $m | Should -Match 'Reuse wait is LOG_BACKUP'
        $m | Should -Match "won't free the log"
    }
    It 'says PVS cleanup resumes after rollback when a shrink worker pins the watermark' {
        $m = Format-ShrinkSafetyValveMessage -Breach 'PvsGrowth' -LogPercent 0 -PvsPercent 82 -PvsKb (410*1048576) -FreeForGrowthKb (500*1048576) -HolderText 'session 71 (MoveBlobPage, worker 3)' -HolderSpid 71 -HolderIsWorker $true
        $m | Should -Match 'PVS 82% of growth runway \(410\.0 GiB / 500\.0 GiB\)'
        $m | Should -Match 'low watermark'
        $m | Should -Match 'PVS cleanup resumes'
    }
    It 'uses natural size units so a small PVS or log size is not rounded to 0' {
        $m = Format-ShrinkSafetyValveMessage -Breach 'PvsGrowth' -LogPercent 0 -PvsPercent 6 -PvsKb (132*1024) -FreeForGrowthKb (1884*1024)
        $m | Should -Match 'PVS 6% of growth runway \(132\.0 MiB / 1\.8 GiB\)'
    }
    It 'names the pinning session when a non-worker holds the watermark' {
        $m = Format-ShrinkSafetyValveMessage -Breach 'PvsGrowth' -LogPercent 0 -PvsPercent 82 -PvsKb (410*1048576) -FreeForGrowthKb (500*1048576) -HolderText 'session 88 (usr_bulkload, not a shrink worker)' -HolderSpid 88 -HolderIsWorker $false
        $m | Should -Match 'transaction on session 88 completes'
    }
    It 'appends the fallback caveat when a file ceiling is unknown' {
        $m = Format-ShrinkSafetyValveMessage -Breach 'PvsGrowth' -LogPercent 0 -PvsPercent 82 -PvsKb 1 -FreeForGrowthKb 1 -FallbackFiles '1,3'
        $m | Should -Match 'max size unset on file\(s\) 1,3'
        $m | Should -Match 'may be premature'
    }
}

Describe 'Get-ShrinkTotalsRows' {
    It 'builds the run-time, size, and bucket rows in order' {
        $counts = Get-ShrinkBucketCounts -Buckets @('Shrunk', 'Grew')
        $rows = Get-ShrinkTotalsRows -RunTime '1m 2s' -Used '10.0 GiB' -Allocated '20.0 GiB' -Counts $counts
        @($rows.Keys) | Should -Be @('Run time', 'Used', 'Allocated', 'Shrunk', 'Repacked', 'Partly shrunk', 'Already at minimum', 'Already at target', 'Grew', 'Gave up', 'Interrupted', 'Not processed')
        $rows['Run time']  | Should -Be '1m 2s'
        $rows['Used']      | Should -Be '10.0 GiB'
        $rows['Allocated'] | Should -Be '20.0 GiB'
        $rows['Shrunk']    | Should -Be 1
        $rows['Grew']      | Should -Be 1
        $rows['Gave up']   | Should -Be 0
    }
}

Describe 'Get-ShrinkDeltaWithReset' {
    It 'returns a positive delta when increasing' {
        $r = Get-ShrinkDeltaWithReset -Previous 100 -Current 150
        $r.IsReset | Should -BeFalse
        $r.Delta | Should -Be 50
    }
    It 'flags a reset when the counter decreases' {
        $r = Get-ShrinkDeltaWithReset -Previous 100 -Current 10
        $r.IsReset | Should -BeTrue
        $r.Delta | Should -BeNullOrEmpty
    }
}

Describe 'Update-ShrinkStuckState' {
    It 'fires when the same non-zero blocker persists for the window, even while CPU advances' {
        $state = @{ Blocker=$null; Cpu=0; Reads=0; BlockerSince=$null; NoProgressSince=$null }
        (Update-ShrinkStuckState -State $state -Blocker 55 -Cpu 10 -Reads 10 -NowSeconds 0 -WindowSec 300).IsStuck | Should -BeFalse
        (Update-ShrinkStuckState -State $state -Blocker 55 -Cpu 999 -Reads 999 -NowSeconds 310 -WindowSec 300).IsStuck | Should -BeTrue
    }
    It 'fires when neither CPU nor reads advance for the window, with no blocker' {
        $state = @{ Blocker=$null; Cpu=0; Reads=0; BlockerSince=$null; NoProgressSince=$null }
        (Update-ShrinkStuckState -State $state -Blocker 0 -Cpu 10 -Reads 10 -NowSeconds 0 -WindowSec 300).IsStuck | Should -BeFalse
        (Update-ShrinkStuckState -State $state -Blocker 0 -Cpu 10 -Reads 10 -NowSeconds 310 -WindowSec 300).IsStuck | Should -BeTrue
    }
    It 'does not fire while CPU or reads keep advancing and there is no blocker' {
        $state = @{ Blocker=$null; Cpu=0; Reads=0; BlockerSince=$null; NoProgressSince=$null }
        Update-ShrinkStuckState -State $state -Blocker 0 -Cpu 10 -Reads 10 -NowSeconds 0 -WindowSec 300 | Out-Null
        (Update-ShrinkStuckState -State $state -Blocker 0 -Cpu 20 -Reads 30 -NowSeconds 400 -WindowSec 300).IsStuck | Should -BeFalse
    }
    It 'treats a per-request counter reset as progress' {
        $state = @{ Blocker=$null; Cpu=0; Reads=0; BlockerSince=$null; NoProgressSince=$null }
        Update-ShrinkStuckState -State $state -Blocker 0 -Cpu 500 -Reads 500 -NowSeconds 0 -WindowSec 300 | Out-Null
        (Update-ShrinkStuckState -State $state -Blocker 0 -Cpu 5 -Reads 5 -NowSeconds 310 -WindowSec 300).IsStuck | Should -BeFalse
    }
    It 'restarts the blocker streak when the blocker changes' {
        $state = @{ Blocker=$null; Cpu=0; Reads=0; BlockerSince=$null; NoProgressSince=$null }
        Update-ShrinkStuckState -State $state -Blocker 55 -Cpu 10 -Reads 10 -NowSeconds 0 -WindowSec 300 | Out-Null
        (Update-ShrinkStuckState -State $state -Blocker 77 -Cpu 20 -Reads 20 -NowSeconds 400 -WindowSec 300).IsStuck | Should -BeFalse
    }
    It 'does not fire within the window' {
        $state = @{ Blocker=$null; Cpu=0; Reads=0; BlockerSince=$null; NoProgressSince=$null }
        Update-ShrinkStuckState -State $state -Blocker 55 -Cpu 10 -Reads 10 -NowSeconds 0 -WindowSec 300 | Out-Null
        (Update-ShrinkStuckState -State $state -Blocker 55 -Cpu 10 -Reads 10 -NowSeconds 120 -WindowSec 300).IsStuck | Should -BeFalse
    }
}

Describe 'New-ShrinkRetryProvider' {
    It 'returns a provider when configurable retry is available, otherwise null, without throwing' {
        $provider = New-ShrinkRetryProvider
        if ('Microsoft.Data.SqlClient.SqlConfigurableRetryFactory' -as [type]) {
            $provider | Should -Not -BeNullOrEmpty
        } else {
            $provider | Should -BeNullOrEmpty
        }
    }
}

Describe 'New-ShrinkCommandText' {
    It 'builds a plain target shrink with NO_INFOMSGS' {
        $c = New-ShrinkCommandText -FileId 3 -TargetMB 52000
        $c | Should -Be 'DBCC SHRINKFILE (3, 52000) WITH NO_INFOMSGS'
    }
    It 'builds TRUNCATEONLY without a target' {
        New-ShrinkCommandText -FileId 1 -TruncateOnly | Should -Be 'DBCC SHRINKFILE (1, TRUNCATEONLY) WITH NO_INFOMSGS'
    }
    It 'appends NOTRUNCATE to a target shrink' {
        New-ShrinkCommandText -FileId 2 -TargetMB 1000 -NoTruncate |
            Should -Be 'DBCC SHRINKFILE (2, 1000, NOTRUNCATE) WITH NO_INFOMSGS'
    }
    It 'adds WLP with SELF' {
        $c = New-ShrinkCommandText -FileId 5 -TargetMB 1 -WaitAtLowPriority -AbortAfterWait SELF
        $c | Should -Match 'WAIT_AT_LOW_PRIORITY \(ABORT_AFTER_WAIT = SELF\)'
    }
    It 'adds WLP with BLOCKERS' {
        New-ShrinkCommandText -FileId 5 -TargetMB 1 -WaitAtLowPriority -AbortAfterWait BLOCKERS |
            Should -Match 'ABORT_AFTER_WAIT = BLOCKERS'
    }
    It 'throws on TruncateOnly + NoTruncate' {
        { New-ShrinkCommandText -FileId 1 -TruncateOnly -NoTruncate } | Should -Throw
    }
}

Describe 'Format-ShrinkSize' {
    It 'formats <Mb> MiB as <Text>' -TestCases @(
        @{ Mb = 0;       Text = '0 KiB' }
        @{ Mb = 0.5;     Text = '512 KiB' }
        @{ Mb = 1;       Text = '1.0 MiB' }
        @{ Mb = 8;       Text = '8.0 MiB' }
        @{ Mb = 1024;    Text = '1.0 GiB' }
        @{ Mb = 1536;    Text = '1.5 GiB' }
        @{ Mb = 1048576; Text = '1.0 TiB' }
        @{ Mb = 1572864; Text = '1.5 TiB' }
    ) {
        Format-ShrinkSize -Megabytes $Mb | Should -Be $Text
    }
}

Describe 'Measure-ShrinkFileSpace' {
    It 'sums allocated, used, free, and growth headroom across files' {
        $rows = @(
            [pscustomobject]@{ FileId = 1; SizePages = 1280; UsedPages = 640; MaxSizePages = 2560 }
            [pscustomobject]@{ FileId = 3; SizePages = 256; UsedPages = 128; MaxSizePages = 256 }
        )
        $s = Measure-ShrinkFileSpace -Rows $rows
        $s.AllocMB | Should -Be 12
        $s.UsedMB | Should -Be 6
        $s.FreeKb | Should -Be ((640 + 128) * 8)
        $s.HeadroomKb | Should -Be (1280 * 8)
        $s.FallbackFiles | Should -Be ''
    }
    It 'returns per-file allocated and used MiB keyed by file id' {
        $s = Measure-ShrinkFileSpace -Rows @([pscustomobject]@{ FileId = 7; SizePages = 1280; UsedPages = 384; MaxSizePages = -1 })
        $s.Files[7].Alloc | Should -Be 10
        $s.Files[7].Used | Should -Be 3
    }
    It 'uses the current size as the ceiling for a file with no maximum size and lists it' {
        $rows = @(
            [pscustomobject]@{ FileId = 1; SizePages = 1000; UsedPages = 900; MaxSizePages = -1 }
            [pscustomobject]@{ FileId = 4; SizePages = 1000; UsedPages = 1000; MaxSizePages = -1 }
        )
        $s = Measure-ShrinkFileSpace -Rows $rows
        $s.HeadroomKb | Should -Be 0
        $s.FreeKb | Should -Be (100 * 8)
        $s.FallbackFiles | Should -Be '1,4'
    }
    It 'never counts negative free space or headroom' {
        # FILEPROPERTY can briefly report more used pages than the size during a shrink, and max_size can be
        # below size after a MODIFY FILE; neither should reduce the runway below zero.
        $s = Measure-ShrinkFileSpace -Rows @([pscustomobject]@{ FileId = 1; SizePages = 100; UsedPages = 120; MaxSizePages = 80 })
        $s.FreeKb | Should -Be 0
        $s.HeadroomKb | Should -Be 0
    }
    It 'returns zero totals for no files' {
        $s = Measure-ShrinkFileSpace -Rows @()
        $s.AllocMB | Should -Be 0
        $s.FreeKb | Should -Be 0
        $s.Files.Count | Should -Be 0
    }
}

Describe 'Format-ShrinkSafetySkipMessage' {
    It 'states the check and the reason' {
        $m = Format-ShrinkSafetySkipMessage -Check Log -Reason 'Execution Timeout Expired.' -ConsecutiveSkips 1 -IntervalSeconds 300
        $m | Should -Be 'Log safety check skipped: Execution Timeout Expired.'
    }
    It 'does not escalate below the threshold' {
        Format-ShrinkSafetySkipMessage -Check PVS -Reason 'x' -ConsecutiveSkips 2 -IntervalSeconds 300 | Should -Not -Match 'not protected'
    }
    It 'escalates at the threshold with the count and approximate span' {
        $m = Format-ShrinkSafetySkipMessage -Check PVS -Reason 'x' -ConsecutiveSkips 3 -IntervalSeconds 300
        $m | Should -Match 'Skipped 3 times in a row \(about 15m 0s\)'
        $m | Should -Match 'not protected against version store \(PVS\) growth'
    }
    It 'names log growth for the log check' {
        Format-ShrinkSafetySkipMessage -Check Log -Reason 'x' -ConsecutiveSkips 5 -IntervalSeconds 60 |
            Should -Match 'not protected against transaction log growth'
    }
    It 'honors a custom escalation threshold' {
        Format-ShrinkSafetySkipMessage -Check Log -Reason 'x' -ConsecutiveSkips 1 -IntervalSeconds 60 -EscalateAfter 1 |
            Should -Match 'Skipped 1 times in a row'
    }
}

Describe 'Get-ShrinkLateFailureHint' {
    It 'returns nothing for a command shorter than the threshold' {
        Get-ShrinkLateFailureHint -ErrorNumber 1222 -CommandSeconds 1799 -ThresholdSeconds 1800 | Should -BeNullOrEmpty
    }
    It 'says the retry repeats the command, with its duration and error' {
        $h = Get-ShrinkLateFailureHint -ErrorNumber 1205 -CommandSeconds 7200 -ThresholdSeconds 1800
        $h | Should -Match 'ran for 2h 0m 0s and then ended with MSSQL error 1205; a retry runs the whole command again\.'
        $h | Should -Not -Match 'lock'
    }
    It 'says BLOCKERS avoids 49516 at low priority with SELF' {
        $h = Get-ShrinkLateFailureHint -ErrorNumber 49516 -CommandSeconds 40000 -ThresholdSeconds 1800 -WaitAtLowPriority $true -AbortAfterWait SELF
        $h | Should -Match 'low-priority lock wait timed out'
        $h | Should -Match '-AbortAfterWait BLOCKERS avoids this'
    }
    It 'says BLOCKERS often but not always avoids 1222 at low priority with SELF' {
        $h = Get-ShrinkLateFailureHint -ErrorNumber 1222 -CommandSeconds 40000 -ThresholdSeconds 1800 -WaitAtLowPriority $true -AbortAfterWait SELF
        $h | Should -Match 'MSSQL error 1222 is a lock timeout'
        $h | Should -Match '-AbortAfterWait BLOCKERS often avoids it'
        $h | Should -Match 'can still time out'
    }
    It 'does not suggest BLOCKERS when it is already used or low priority is off' -TestCases @(
        @{ Err = 1222; Wlp = $true; Aaw = 'BLOCKERS' }
        @{ Err = 1222; Wlp = $false; Aaw = 'SELF' }
        @{ Err = 49516; Wlp = $true; Aaw = 'BLOCKERS' }
    ) {
        $h = Get-ShrinkLateFailureHint -ErrorNumber $Err -CommandSeconds 40000 -ThresholdSeconds 1800 -WaitAtLowPriority $Wlp -AbortAfterWait $Aaw
        $h | Should -Match 'less write activity'
        $h | Should -Not -Match 'BLOCKERS'
    }
    It 'suggests a larger step when more than one step remains' {
        $h = Get-ShrinkLateFailureHint -ErrorNumber 1222 -CommandSeconds 40000 -ThresholdSeconds 1800 -StepMB 20480 -RemainingMB 100000
        $h | Should -Match 'larger -StepGiB'
    }
    It 'does not suggest a larger step for the last step or for TruncateOnly' -TestCases @(
        @{ Remaining = 20480; Trunc = $false }
        @{ Remaining = 100000; Trunc = $true }
    ) {
        $h = Get-ShrinkLateFailureHint -ErrorNumber 1222 -CommandSeconds 40000 -ThresholdSeconds 1800 -StepMB 20480 -RemainingMB $Remaining -TruncateOnly $Trunc
        $h | Should -Not -Match 'StepGiB'
    }
}

Describe 'Format-ShrinkDatabaseIdentity' {
    It 'describes a SQL Server instance with its edition and update level' {
        $id = @{ server_name = 'SQL01'; database_name = 'MyDb'; product_version = '16.0.4135.4'; product_update_level = 'CU15'
            engine_edition = 3; server_edition = 'Enterprise Edition (64-bit)'; database_edition = $null; service_objective = $null }
        Format-ShrinkDatabaseIdentity -Identity $id |
            Should -Be 'Server reports: server [SQL01], database [MyDb], version 16.0.4135.4 CU15, Enterprise Edition (64-bit).'
    }
    It 'describes Azure SQL Database with its edition and service objective' {
        $id = @{ server_name = 'myserver'; database_name = 'MyDb'; product_version = '12.0.2000.8'; product_update_level = $null
            engine_edition = 5; server_edition = 'SQL Azure'; database_edition = 'Hyperscale'; service_objective = 'HS_PRMS_8' }
        Format-ShrinkDatabaseIdentity -Identity $id |
            Should -Be 'Server reports: server [myserver], database [MyDb], version 12.0.2000.8, Azure SQL Database (Hyperscale, HS_PRMS_8).'
    }
    It 'describes Azure SQL Managed Instance' {
        $id = @{ server_name = 'mi1'; database_name = 'MyDb'; product_version = '12.0.2000.8'; engine_edition = 8; server_edition = 'SQL Azure' }
        Format-ShrinkDatabaseIdentity -Identity $id | Should -Match 'Azure SQL Managed Instance\.$'
    }
    It 'omits values the server did not return' {
        $id = @{ server_name = 'SQL01'; database_name = 'MyDb'; product_version = $null; engine_edition = $null; server_edition = $null }
        Format-ShrinkDatabaseIdentity -Identity $id | Should -Be 'Server reports: server [SQL01], database [MyDb].'
    }
}

Describe 'Get-ShrinkMissingFileNames' {
    It 'returns nothing when every requested name was found' {
        @(Get-ShrinkMissingFileNames -Requested @('data_1', 'data_2') -Found @('data_1', 'data_2', 'data_3')).Count | Should -Be 0
    }
    It 'returns the names that were not found' {
        Get-ShrinkMissingFileNames -Requested @('data_1', 'nope', 'log') -Found @('data_1') | Should -Be @('nope', 'log')
    }
    It 'matches names case-insensitively' {
        @(Get-ShrinkMissingFileNames -Requested @('DATA_1') -Found @('data_1')).Count | Should -Be 0
    }
    It 'reports a duplicated missing name once' {
        @(Get-ShrinkMissingFileNames -Requested @('x', 'x') -Found @()).Count | Should -Be 1
    }
}