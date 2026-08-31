<#
.SYNOPSIS
  Test fixtures for the ShrinkDriver integration tests: provision, populate, and tear down a small
  throwaway database with several data files and interspersed free space. Works against box SQL Server
  / LocalDB and Azure SQL Database (engine-aware provisioning).

  Not a Pester test file (no *.Tests.ps1 suffix), so Pester does not execute it as tests.

  Portability notes:
  - All data files live in PRIMARY (Azure SQL Database has no user filegroups).
  - Rows are generated with a portable TOP/ROW_NUMBER query over sys.all_objects.
  - Connections use Microsoft.Data.SqlClient with the same auth options as the driver itself
    (Windows / EntraID with Active Directory Default then Interactive fallback / SQL).
#>

# Ensure Microsoft.Data.SqlClient is loaded (the SqlServer module ships it). Needed at import time so
# Get-ShrinkTestServer works during Pester discovery, before the driver script is dot-sourced.
if (-not ('Microsoft.Data.SqlClient.SqlConnection' -as [type])) {
    Import-Module SqlServer -ErrorAction Stop
}

# ----- connection layer (Microsoft.Data.SqlClient; mirrors the driver's auth) -----

function New-ShrinkTestConnection {
    [CmdletBinding()][OutputType([Microsoft.Data.SqlClient.SqlConnection])]
    param(
        [Parameter(Mandatory)][string]$ServerInstance,
        [string]$Database = 'master',
        [ValidateSet('Windows', 'EntraID', 'SQL')][string]$Auth = 'Windows',
        [string]$SqlLogin,
        [securestring]$SqlPassword,
        [bool]$TrustServerCertificate = $false
    )
    $csb = [Microsoft.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $csb['Data Source'] = $ServerInstance
    $csb['Initial Catalog'] = $Database
    $csb['Encrypt'] = $true
    $csb['TrustServerCertificate'] = $TrustServerCertificate
    $csb['Connect Timeout'] = 60
    $csb['Pooling'] = $false
    $conn = [Microsoft.Data.SqlClient.SqlConnection]::new()
    switch ($Auth) {
        'Windows' {
            $csb['Integrated Security'] = $true
            $conn.ConnectionString = $csb.ConnectionString
            $conn.Open()
        }
        'SQL' {
            $conn.ConnectionString = $csb.ConnectionString
            # Resolve the SQL password securely: use the SecureString passed in, else one already
            # entered this session, else prompt for it. It is never stored or read as clear text.
            $pw = if ($SqlPassword) { $SqlPassword }
                  elseif ($global:ShrinkTestSqlPassword) { $global:ShrinkTestSqlPassword }
                  else { $global:ShrinkTestSqlPassword = Read-Host -AsSecureString "SQL password for login '$SqlLogin'"; $global:ShrinkTestSqlPassword }
            if (-not $pw.IsReadOnly()) { $pw.MakeReadOnly() }
            $conn.Credential = [Microsoft.Data.SqlClient.SqlCredential]::new($SqlLogin, $pw)
            $conn.Open()
        }
        'EntraID' {
            # Try the ambient credential first, then fall back to an interactive sign-in (browser),
            # exactly as the driver's New-ShrinkConnection does.
            foreach ($mode in @('Active Directory Default', 'Active Directory Interactive')) {
                $csb['Authentication'] = $mode
                $conn.ConnectionString = $csb.ConnectionString
                try { $conn.Open(); break }
                catch { if ($mode -eq 'Active Directory Interactive') { throw } }
            }
        }
    }
    $conn
}

function Invoke-ShrinkTestSql {
    <#
    .SYNOPSIS
      Run a T-SQL batch on a fresh connection and return any result-set rows as PSCustomObjects.
      Drains all result sets so every statement in a multi-statement batch executes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Context,   # ServerInstance / Auth / SqlLogin / SqlPassword
        [Parameter(Mandatory)][string]$Query,
        [string]$Database = 'master',
        [int]$CommandTimeout = 300
    )
    $conn = New-ShrinkTestConnection -ServerInstance $Context.ServerInstance -Database $Database `
        -Auth $Context.Auth -SqlLogin $Context.SqlLogin -SqlPassword $Context.SqlPassword `
        -TrustServerCertificate ([bool]$Context.TrustServerCertificate)
    try {
        $cmd = $conn.CreateCommand(); $cmd.CommandText = $Query; $cmd.CommandTimeout = $CommandTimeout
        $rd = $cmd.ExecuteReader()
        $rows = [System.Collections.Generic.List[object]]::new()
        try {
            do {
                while ($rd.Read()) {
                    $o = [ordered]@{}
                    for ($i = 0; $i -lt $rd.FieldCount; $i++) {
                        $name = $rd.GetName($i)
                        if ([string]::IsNullOrEmpty($name)) { $name = "Column$i" }
                        $o[$name] = if ($rd.IsDBNull($i)) { $null } else { $rd.GetValue($i) }
                    }
                    $rows.Add([pscustomobject]$o)
                }
            } while ($rd.NextResult())
        }
        finally { $rd.Dispose(); $cmd.Dispose() }
        # Emit rows so a pipeline (e.g. Measure-Object) enumerates them individually. Consumers that
        # index the first row with (...)[0] still work for single-row results.
        $rows.ToArray()
    }
    finally { $conn.Dispose() }
}

# ----- discovery -----

function Get-ShrinkTestServer {
    <#
    .SYNOPSIS
      Resolve a SQL target for integration tests as a context object
      { ServerInstance, Auth, SqlLogin, SqlPassword, TrustServerCertificate }, or $null if none is
      reachable. Honors $env:SHRINKDRIVER_TEST_SERVER (+ _AUTH / _LOGIN / _TRUSTCERT); for SQL auth the
      password is prompted for securely at connect time. Otherwise falls back to SQL Server LocalDB with
      Windows auth.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param()

    if ($env:SHRINKDRIVER_TEST_SERVER) {
        $auth = if ($env:SHRINKDRIVER_TEST_AUTH) { $env:SHRINKDRIVER_TEST_AUTH } else { 'EntraID' }
        return [pscustomobject]@{
            ServerInstance         = $env:SHRINKDRIVER_TEST_SERVER
            Auth                   = $auth
            SqlLogin               = $env:SHRINKDRIVER_TEST_LOGIN
            SqlPassword            = $null   # SQL-auth password is prompted for securely at connect time, never stored as clear text
            # Trust a self-signed certificate only when explicitly opted in, e.g. a local
            # dev build.
            TrustServerCertificate = [bool]($env:SHRINKDRIVER_TEST_TRUSTCERT -in @('1', 'true', 'yes'))
        }
    }

    $localDbExe = Get-Command sqllocaldb -ErrorAction SilentlyContinue
    if (-not $localDbExe) { return $null }
    try {
        & sqllocaldb start MSSQLLocalDB *> $null
        $ctx = [pscustomobject]@{ ServerInstance = '(localdb)\MSSQLLocalDB'; Auth = 'Windows'; SqlLogin = $null; SqlPassword = $null; TrustServerCertificate = [bool]($env:SHRINKDRIVER_TEST_TRUSTCERT -in @('1', 'true', 'yes')) }
        Invoke-ShrinkTestSql -Context $ctx -Query 'SELECT 1 AS ok;' -Database master | Out-Null
        return $ctx
    }
    catch { return $null }
}

function Get-ShrinkTestEngineEdition {
    [CmdletBinding()][OutputType([int])]
    param([Parameter(Mandatory)][pscustomobject]$Context, [string]$Database = 'master')
    [int](Invoke-ShrinkTestSql -Context $Context -Database $Database -Query "SELECT CAST(SERVERPROPERTY('EngineEdition') AS int) AS ee;")[0].ee
}

# ----- provisioning -----

function New-ShrinkTestDatabase {
    <#
    .SYNOPSIS
      Create a throwaway test database with several data files in PRIMARY, fill it with page-packed
      rows, then create interspersed free space by dropping every other table. Engine-aware:
      - box SQL Server / LocalDB: CREATE DATABASE with explicit multiple PRIMARY files.
      - Azure SQL Database (EngineEdition 5): CREATE DATABASE with a General Purpose service objective.
        An Azure SQL Database has a single data file at the outset. So on Azure
        the descriptor's FileCount is 1 and the multi-file / concurrency tests skip there.
      Returns a descriptor carrying the connection context plus { Database, DataDir, Engine, FileCount }.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][pscustomobject]$Context,
        [string]$Database = ('ShrinkTest_{0}' -f [guid]::NewGuid().ToString('N').Substring(0, 8)),
        [int]$FileCount = 4,
        [int]$Tables = 16,
        [int]$RowsPerTable = 2000,   # ~15.6 MB per table (char(8000) => 1 row/page)
        [string]$DataDir,
        [string]$AzureServiceObjective = 'GP_Gen5_2',
        [int]$AzureMaxSizeGB = 32   # GP reserves storage up to maxsize; file count is independent of it (verified), so keep it small
    )

    $engine = Get-ShrinkTestEngineEdition -Context $Context
    $isAzureDb = ($engine -eq 5)

    if ($isAzureDb) {
        # A General Purpose database always has a single ROWS data file at creation,
        # so FileCount is 1 here and the multi-file tests skip on this platform.
        Invoke-ShrinkTestSql -Context $Context -Database master -CommandTimeout 120 -Query @"
CREATE DATABASE [$Database] (EDITION = 'GeneralPurpose', SERVICE_OBJECTIVE = '$AzureServiceObjective', MAXSIZE = $AzureMaxSizeGB GB);
"@ | Out-Null
    }
    else {
        if (-not $DataDir) { $DataDir = Join-Path ([System.IO.Path]::GetTempPath()) ('shrinktest_' + $Database) }
        New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
        $addedFiles = (2..($FileCount + 1) | ForEach-Object { " (NAME='${Database}_$_', FILENAME='$DataDir\${Database}_$_.ndf', SIZE=8MB, FILEGROWTH=16MB)" }) -join ",`n"
        Invoke-ShrinkTestSql -Context $Context -Database master -CommandTimeout 120 -Query @"
IF DB_ID('$Database') IS NOT NULL BEGIN ALTER DATABASE [$Database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$Database]; END;
CREATE DATABASE [$Database] ON PRIMARY
 (NAME='${Database}_1', FILENAME='$DataDir\$Database.mdf', SIZE=16MB, FILEGROWTH=16MB),
$addedFiles
 LOG ON (NAME='${Database}_log', FILENAME='$DataDir\${Database}_log.ldf', SIZE=64MB, FILEGROWTH=64MB);
"@ | Out-Null
    }

    # Fill in one batch (portable row generator). Then drop every other table to leave interspersed
    # free space (forces the page-movement shrink path, not just a tail truncate).
    $fill = [System.Text.StringBuilder]::new()
    [void]$fill.AppendLine('SET NOCOUNT ON;')
    for ($t = 1; $t -le $Tables; $t++) {
        [void]$fill.AppendLine("CREATE TABLE dbo.t$t (id int NOT NULL, filler char(8000) NOT NULL) ON [PRIMARY];")
        [void]$fill.AppendLine("INSERT INTO dbo.t$t (id, filler) SELECT TOP ($RowsPerTable) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), REPLICATE('x', 8000) FROM sys.all_objects a CROSS JOIN sys.all_objects b;")
    }
    Invoke-ShrinkTestSql -Context $Context -Database $Database -Query $fill.ToString() -CommandTimeout 600 | Out-Null

    $drop = [System.Text.StringBuilder]::new()
    for ($t = 1; $t -le $Tables; $t += 2) { [void]$drop.AppendLine("DROP TABLE dbo.t$t;") }
    Invoke-ShrinkTestSql -Context $Context -Database $Database -Query $drop.ToString() | Out-Null

    # Actual number of data (ROWS) files (the platform decides this on Azure General Purpose).
    $dataFileCount = [int](Invoke-ShrinkTestSql -Context $Context -Database $Database -Query "SELECT COUNT(*) AS n FROM sys.database_files WHERE type_desc = 'ROWS';")[0].n

    [pscustomobject]@{
        ServerInstance = $Context.ServerInstance
        Auth           = $Context.Auth
        SqlLogin       = $Context.SqlLogin
        SqlPassword    = $Context.SqlPassword
        TrustServerCertificate = $Context.TrustServerCertificate
        Database       = $Database
        DataDir        = $DataDir
        Engine         = $engine
        FileCount      = $dataFileCount
    }
}

function Wait-ShrinkFreeSpaceSettled {
    <#
    .SYNOPSIS
      Wait until deferred deallocation is reflected in FILEPROPERTY 'SpaceUsed' (DROP TABLE space
      release lags, even on a box engine). Polls until the minimum free MB across the data files has
      reached $MinFreeMB and stopped growing (settled), or the timeout elapses. Returns the observed
      minimum free MB.
    #>
    [CmdletBinding()][OutputType([int])]
    param(
        [Parameter(Mandatory)][pscustomobject]$TestDb,
        [int]$MinFreeMB = 8,
        [int]$TimeoutSeconds = 120
    )
    $sql = "SELECT CAST(size/128.0 AS int) - CAST(FILEPROPERTY(name,'SpaceUsed')/128.0 AS int) AS free_mb FROM sys.database_files WHERE type_desc = 'ROWS';"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $minFree = 0; $prevMin = -1
    do {
        Invoke-ShrinkTestSql -Context $TestDb -Database $TestDb.Database -Query 'CHECKPOINT;' | Out-Null
        Start-Sleep -Milliseconds 800
        $rows = @(Invoke-ShrinkTestSql -Context $TestDb -Database $TestDb.Database -Query $sql)
        $minFree = [int]($rows | Measure-Object -Property free_mb -Minimum).Minimum
        # Settle once the reclaimable space has reached the floor and stopped growing between polls, so a
        # later shrink sees the real free space rather than a still-deallocating snapshot.
        $settled = ($minFree -ge $MinFreeMB) -and ($minFree -eq $prevMin)
        $prevMin = $minFree
    } until ($settled -or $sw.Elapsed.TotalSeconds -gt $TimeoutSeconds)
    $minFree
}

function Get-ShrinkTestFileSizes {
    <# .SYNOPSIS Return the data files' allocated and used sizes (MB). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][pscustomobject]$TestDb)
    Invoke-ShrinkTestSql -Context $TestDb -Database $TestDb.Database -Query @"
SELECT file_id, name,
       CAST(size/128.0 AS int) AS alloc_mb,
       CAST(FILEPROPERTY(name,'SpaceUsed')/128.0 AS int) AS used_mb
FROM sys.database_files WHERE type_desc = 'ROWS' ORDER BY file_id;
"@
}

function Add-ShrinkTestTailSpace {
    <# .SYNOPSIS Grow each ROWS data file by $AddMB so a TRUNCATEONLY shrink has guaranteed unused space
       at the tail to reclaim (the drop-created free space is interspersed and may not sit at the end). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][pscustomobject]$TestDb, [int]$AddMB = 48)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($f in (Get-ShrinkTestFileSizes -TestDb $TestDb)) {
        $newSize = [int]$f.alloc_mb + $AddMB
        [void]$sb.AppendLine("ALTER DATABASE [$($TestDb.Database)] MODIFY FILE (NAME = '$($f.name)', SIZE = ${newSize}MB);")
    }
    Invoke-ShrinkTestSql -Context $TestDb -Database $TestDb.Database -Query $sb.ToString() -CommandTimeout 120 | Out-Null
}

function Open-ShrinkTestBlocker {
    <# .SYNOPSIS Open a connection that holds an exclusive lock on $TableName inside an open transaction,
       so a concurrent shrink of that data blocks and cannot finish. Returns the live connection; pass it
       to Close-ShrinkTestBlocker to roll back and release. #>
    [CmdletBinding()][OutputType([Microsoft.Data.SqlClient.SqlConnection])]
    param([Parameter(Mandatory)][pscustomobject]$TestDb, [string]$TableName = 'dbo.t2')
    $conn = New-ShrinkTestConnection -ServerInstance $TestDb.ServerInstance -Database $TestDb.Database `
        -Auth $TestDb.Auth -SqlLogin $TestDb.SqlLogin -SqlPassword $TestDb.SqlPassword `
        -TrustServerCertificate ([bool]$TestDb.TrustServerCertificate)
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "BEGIN TRAN; SELECT TOP (1) 1 FROM $TableName WITH (TABLOCKX, HOLDLOCK);"
    $cmd.CommandTimeout = 30
    $cmd.ExecuteNonQuery() | Out-Null
    $cmd.Dispose()
    $conn
}

function Close-ShrinkTestBlocker {
    <# .SYNOPSIS Roll back the blocking transaction and dispose the connection from Open-ShrinkTestBlocker. #>
    [CmdletBinding()]
    param([Microsoft.Data.SqlClient.SqlConnection]$Connection)
    if (-not $Connection) { return }
    try { $c = $Connection.CreateCommand(); $c.CommandText = 'IF @@TRANCOUNT > 0 ROLLBACK;'; $c.ExecuteNonQuery() | Out-Null; $c.Dispose() } catch { }
    try { $Connection.Dispose() } catch { }
}

function Remove-ShrinkTestDatabase {
    <# .SYNOPSIS Drop the test database and delete its files (box). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][pscustomobject]$TestDb)
    try {
        if ($TestDb.Engine -eq 5) {
            Invoke-ShrinkTestSql -Context $TestDb -Database master -Query "DROP DATABASE IF EXISTS [$($TestDb.Database)];" -CommandTimeout 120 | Out-Null
        }
        else {
            Invoke-ShrinkTestSql -Context $TestDb -Database master -Query "IF DB_ID('$($TestDb.Database)') IS NOT NULL BEGIN ALTER DATABASE [$($TestDb.Database)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$($TestDb.Database)]; END;" | Out-Null
        }
    }
    catch { Write-Warning "Failed to drop [$($TestDb.Database)]: $($_.Exception.Message)" }
    if ($TestDb.DataDir -and (Test-Path $TestDb.DataDir)) { Remove-Item -Recurse -Force $TestDb.DataDir -ErrorAction SilentlyContinue }
}

Export-ModuleMember -Function Get-ShrinkTestServer, Get-ShrinkTestEngineEdition, New-ShrinkTestDatabase, Wait-ShrinkFreeSpaceSettled, Get-ShrinkTestFileSizes, Add-ShrinkTestTailSpace, Open-ShrinkTestBlocker, Close-ShrinkTestBlocker, Remove-ShrinkTestDatabase
