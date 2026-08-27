<#PSScriptInfo
.VERSION 1.1.0
.GUID 1b801c08-f374-45df-ba3e-34d9983e9133
.AUTHOR Microsoft
.COMPANYNAME Microsoft
.COPYRIGHT (c) Microsoft Corporation. Licensed under the MIT License.
.TAGS SQL SQLServer AzureSQL DBCC SHRINKFILE shrink maintenance
.LICENSEURI https://github.com/microsoft/sql-server-samples/blob/master/license.txt
.PROJECTURI https://github.com/microsoft/sql-server-samples
#>

<#
.SYNOPSIS
  Loads Invoke-ShrinkDriver, a command that reclaims allocated but unused space from
  a MSSQL database's data files by running DBCC SHRINKFILE commands in parallel on
  multiple sessions.

.DESCRIPTION
  Dot-source this file to define the command, then call it:

    . .\ShrinkDriver.ps1
    Invoke-ShrinkDriver -ServerName <server> -DatabaseName <database>

  Requires PowerShell 7 or later. Depends on the SqlServer module
  (Install-Module SqlServer -Scope CurrentUser). See the README for the full list.

  Run 'Get-Help Invoke-ShrinkDriver -Full' for the description, parameters, and examples.
#>

#Requires -Version 7.0

Set-StrictMode -Version Latest

function Invoke-ShrinkDriver {
    <#
    .SYNOPSIS
      Reclaims unused space from a database's data files by running several
      DBCC SHRINKFILE operations in parallel, with progress monitoring and retries.
    .DESCRIPTION
      Connects to the target database, shrinks each eligible data file toward the
      requested size in steps using multiple concurrent sessions, and writes a status
      report to the console and a log file at a regular interval.

      Requires PowerShell 7 or later and membership in the db_owner database role
      or the sysadmin server role. Supported platforms: SQL Server 2022 or later,
      Azure SQL Managed Instance, and Azure SQL Database.

      Entra ID authentication first uses the ambient Azure credential (managed identity,
      Azure CLI, Azure PowerShell, or Visual Studio); if none is available it falls back
      to an interactive browser sign-in. To use a specific account, sign in first (for
      example, Connect-AzAccount or az login).

      Dependencies: the SqlServer module.
    .PARAMETER ServerName
      Target SQL Server / Azure SQL logical server name.
    .PARAMETER DatabaseName
      Target database name.
    .PARAMETER AuthType
      Authentication method: EntraID (default), Windows, or SQL.
    .PARAMETER SqlLogin
      Login name; required when AuthType is SQL.
    .PARAMETER SqlPassword
      Password as a SecureString, used when AuthType is SQL. Optional: if omitted, you are prompted for
      it securely at run time. If supplied it must be a SecureString, not plain text - for example:
      $pw = Read-Host -AsSecureString 'SQL password'. A plain string is rejected.
    .PARAMETER TrustServerCertificate
      Allow connecting when the server's TLS certificate cannot be validated - for example a local
      development SQL Server with a self-signed certificate (the connection is still encrypted). Off by
      default. It is a fallback only: the driver always tries a fully validated connection first, so a
      server with a trusted certificate (such as Azure SQL) is never connected to without validation.
    .PARAMETER Sessions
      The maximum number of files to shrink concurrently (default 5). Capped at the eligible file count.
    .PARAMETER TruncateOnly
      Release unused space at the end of each file only, without moving data.
    .PARAMETER NoTruncate
      Compact each file without releasing the unused space.
    .PARAMETER Mode
      Report (default) lists each data file's used, allocated, and potentially reclaimable space,
      plus a database-wide summary, without changing anything; Shrink performs the DBCC SHRINKFILE
      operations. Report respects -FileTargetSizeGiB (reclaimable is measured down to the target,
      otherwise down to the used space) and ignores the other shrink options. For databases with
      more than 100 data files, only the 100 most reclaimable files are listed, with a note of how
      many were omitted.
    .PARAMETER WaitAtLowPriority
      Run shrink at low lock priority to reduce blocking of other queries (default true).
    .PARAMETER AbortAfterWait
      On a low-priority wait timeout, abort file shrink (SELF, default) or kill the
      blocking sessions (BLOCKERS). BLOCKERS terminates other transactions, use with caution.
    .PARAMETER FileTargetSizeGiB
      Optional per-file floor in GiB; no file is shrunk below this size.
    .PARAMETER RetryCount
      Retry attempts per file for transient failures (default 5, range 0-50; 0 disables retries).
    .PARAMETER MaxRuntimeMinutes
      Optional overall time budget; the run stops when it is reached.
    .PARAMETER StepGiB
      Increment size used for gradual shrinking (default 20 GiB).
    .PARAMETER MinReclaimGiB
      Minimum unused space per file, in GiB, worth running a shrink pass to reclaim. A file whose unused space -
      or a file's remaining unused space after earlier passes - is below this is left as is (default 1 GiB).
    .PARAMETER StatusIntervalSeconds
      How often the status report is written, in seconds (default 180).
    .PARAMETER StuckWindowSeconds
      A shrink blocked with no progress for this long is cancelled and retried (default 300).
      Stuck detection runs only at each status report, so this is effectively rounded up to a
      multiple of StatusIntervalSeconds; a value below StatusIntervalSeconds is raised to it.
    .PARAMETER LogPath
      Log file path. Defaults to a timestamped file next to this script. The parent directory
      must already exist and be writable; otherwise the run stops before doing any work.
    .PARAMETER PassThru
      Emit a structured result object (mode, totals, per-file outcomes) to the pipeline for
      programmatic callers. By default the run reports only to the console and log and returns
      nothing, so interactive runs are not cluttered with a raw object dump.
    .EXAMPLE
      Invoke-ShrinkDriver -ServerName myserver.database.windows.net -DatabaseName MyDb -Sessions 5
    .EXAMPLE
      Invoke-ShrinkDriver -ServerName sql01 -DatabaseName MyDb -AuthType Windows -FileTargetSizeGiB 500 -Sessions 8
    .LINK
      https://learn.microsoft.com/azure/azure-sql/database/file-space-manage
    .LINK
      https://learn.microsoft.com/sql/t-sql/database-console-commands/dbcc-shrinkfile-transact-sql
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ServerName,
        [Parameter(Mandatory)][string]$DatabaseName,

        [ValidateSet('EntraID', 'Windows', 'SQL')][string]$AuthType = 'EntraID',
        [string]$SqlLogin,
        [object]$SqlPassword,
        [switch]$TrustServerCertificate,

        [ValidateRange(1, [int]::MaxValue)][int]$Sessions = 5,
        [ValidateSet('Report', 'Shrink')][string]$Mode = 'Report',
        [switch]$TruncateOnly,
        [switch]$NoTruncate,
        [bool]$WaitAtLowPriority = $true,
        [ValidateSet('SELF', 'BLOCKERS')][string]$AbortAfterWait = 'SELF',

        [ValidateRange(0, [int]::MaxValue)][Nullable[int]]$FileTargetSizeGiB = $null,
        [ValidateRange(0, 50)][int]$RetryCount = 5,
        [ValidateRange(1, [int]::MaxValue)][Nullable[int]]$MaxRuntimeMinutes = $null,

        [ValidateRange(1, [int]::MaxValue)][int]$StepGiB = 20,
        [ValidateRange(0, [int]::MaxValue)][int]$MinReclaimGiB = 1,
        [ValidateRange(1, [int]::MaxValue)][int]$StatusIntervalSeconds = 180,
        [ValidateRange(1, [int]::MaxValue)][int]$StuckWindowSeconds = 300,
        [string]$LogPath,
        [switch]$PassThru,

        # --- Test-only parameters (intentionally omitted from help; not for normal use) ---
        # Shorten retry backoff and allow sub-GiB sizes / a seconds-level time limit so integration
        # tests can drive the real paths quickly and deterministically.
        [int]$BackoffBaseSeconds = 5,
        [int]$BackoffCapSeconds = 60,
        [Nullable[long]]$StepMBOverride = $null,
        [Nullable[long]]$MinReclaimMBOverride = $null,
        [Nullable[long]]$FileTargetMBOverride = $null,
        [Nullable[int]]$MaxRuntimeSecondsOverride = $null
    )

    $ErrorActionPreference = 'Stop'
    $selfPath = $PSCommandPath
    $hasTarget = ($null -ne $FileTargetSizeGiB) -or ($null -ne $FileTargetMBOverride)

    # ----- validate parameters -----
    $paramSet = @{
        AuthType = $AuthType; SqlLogin = $SqlLogin; SqlPassword = $SqlPassword
        TruncateOnly = [bool]$TruncateOnly; NoTruncate = [bool]$NoTruncate
        WaitAtLowPriority = $WaitAtLowPriority; AbortAfterWait = $AbortAfterWait
        FileTargetSizeGiB = $(if ($hasTarget) { [int]$FileTargetSizeGiB } else { $null })
    }
    $validationErrors = Test-ShrinkParameterSet -Params $paramSet
    if ($validationErrors.Count -gt 0) {
        $validationErrors | ForEach-Object { Write-Error $_ }
        throw "Parameter validation failed with $($validationErrors.Count) error(s)."
    }
    # SQL auth: prompt for the password securely if it was not supplied, so it never has to be typed on
    # the command line (where it would be visible and saved in history). Validation already confirmed a
    # SecureString when one was passed, and that SqlLogin is present.
    if ($AuthType -eq 'SQL' -and -not $SqlPassword) {
        $SqlPassword = Read-Host -AsSecureString "SQL password for login '$SqlLogin'"
    }
    $stepMB = if ($null -ne $StepMBOverride) { [long]$StepMBOverride } else { [long]$StepGiB * 1024 }
    $floorMB = if ($null -ne $FileTargetMBOverride) { [long]$FileTargetMBOverride } elseif ($null -ne $FileTargetSizeGiB) { [long]$FileTargetSizeGiB * 1024 } else { $null }
    $minReclaimMB = if ($null -ne $MinReclaimMBOverride) { [long]$MinReclaimMBOverride } else { [long]$MinReclaimGiB * 1024 }

    # ----- logging (console + mirrored file) -----
    if (-not $LogPath) {
        $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
        $LogPath = Join-Path $PSScriptRoot ("shrink-{0}.log" -f $stamp)
    }
    # Validate up front so a bad path fails fast with a clear message instead of failing
    # part-way through the run; also normalizes to a full path for the logged 'LogFile' value.
    $LogPath = Resolve-ShrinkLogPath -Path $LogPath
    $logLock = [object]::new()
    # Console color is additive emphasis only (the level tag and text convey everything without it);
    # the log file always gets plain text. Honor the NO_COLOR convention to turn it off.
    $useColor = [string]::IsNullOrEmpty($env:NO_COLOR)
    function Write-ShrinkLog {
        param([string]$Message, [string]$Level = 'INFO')
        $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
        $line = '{0} [{1}] {2}' -f $stamp, $Level, $Message
        [System.Threading.Monitor]::Enter($logLock)
        try {
            Add-Content -LiteralPath $LogPath -Value $line -Encoding utf8
            if (-not $useColor) {
                Write-Host $line
            }
            else {
                $tagColor = switch ($Level) { 'ERROR' { 'Red' } 'WARN' { 'Yellow' } 'EVENT' { 'DarkCyan' } default { 'DarkGray' } }
                $msgColor = switch ($Level) {
                    'ERROR' { 'Red' }
                    'WARN' { 'Yellow' }
                    default {
                        if ($Message -match '^-{3,}') { 'Cyan' } # section dividers/headers
                        elseif ($Message -match '(Grew|Gave up|Partly shrunk)\s*:\s*[1-9]') { 'Yellow' } # non-zero problem outcomes
                        elseif ($Message -match '(Shrunk|Repacked)\s*:\s*[1-9]') { 'Green' } # non-zero successful outcomes
                        else { $null }
                    }
                }
                Write-Host $stamp -ForegroundColor DarkGray -NoNewline
                Write-Host (' [{0}] ' -f $Level) -ForegroundColor $tagColor -NoNewline
                if ($null -ne $msgColor) { Write-Host $Message -ForegroundColor $msgColor }
                else { Write-Host $Message }
            }
        }
        finally { [System.Threading.Monitor]::Exit($logLock) }
    }

    @(
        '-------------------- ShrinkDriver run --------------------'
        "Server           : $ServerName"
        "Database         : $DatabaseName"
        "Mode             : $Mode"
        "AuthType         : $AuthType" + $(if ($AuthType -eq 'SQL') { " (login $SqlLogin)" } else { '' })
        "TrustServerCert  : $([bool]$TrustServerCertificate)" + $(if ([bool]$TrustServerCertificate) { ' (used only as a fallback if certificate validation fails)' } else { '' })
        "Sessions         : $Sessions"
        "TruncateOnly     : $([bool]$TruncateOnly)"
        "NoTruncate       : $([bool]$NoTruncate)"
        "WaitAtLowPriority: $WaitAtLowPriority"
        "AbortAfterWait   : $AbortAfterWait"
        "FileTargetSizeGiB: $(if ($hasTarget) { [int]$FileTargetSizeGiB } else { '(min possible)' })"
        "StepGiB          : $StepGiB"
        "MinReclaimGiB    : $MinReclaimGiB"
        "RetryCount       : $RetryCount"
        "MaxRuntimeMinutes: $(if ($null -ne $MaxRuntimeMinutes) { [int]$MaxRuntimeMinutes } else { '(none)' })"
        "StatusInterval   : $StatusIntervalSeconds s"
        "LogFile          : $LogPath"
        '----------------------------------------------------------'
    ) | ForEach-Object { Write-ShrinkLog $_ }
    if ($WaitAtLowPriority -and $AbortAfterWait -eq 'BLOCKERS') {
        Write-ShrinkLog 'AbortAfterWait=BLOCKERS will roll back transactions that block shrink. Use with caution.' 'WARN'
    }
    # Stuck detection only runs at each status report, so a stuck window finer than the report
    # cadence cannot be honored. Raise it to the report interval and tell the user.
    if ($StuckWindowSeconds -lt $StatusIntervalSeconds) {
        Write-ShrinkLog ("StuckWindowSeconds ({0}s) is below StatusIntervalSeconds ({1}s); stuck detection only runs at each status report, so raising StuckWindowSeconds to {1}s." -f $StuckWindowSeconds, $StatusIntervalSeconds) 'WARN'
        $StuckWindowSeconds = $StatusIntervalSeconds
    }

    # Log any terminating error to the file before it propagates to the console.
    $control = $null
    $runResult = $null
    try {

    # ----- connection helpers -----
    # The Microsoft.Data.SqlClient types come from the SqlServer module. Import it on
    # demand; if it is not installed, stop with instructions to install it.
    if (-not ('Microsoft.Data.SqlClient.SqlConnection' -as [type])) {
        if (-not (Get-Module -ListAvailable -Name SqlServer)) {
            throw "The 'SqlServer' module is required but not installed. Install it with " +
                  "'Install-Module SqlServer -Scope CurrentUser' (needs PowerShell 7 or later), then retry."
        }
        Import-Module SqlServer -ErrorAction Stop
    }
    function New-ShrinkConnection {
        $csb = [Microsoft.Data.SqlClient.SqlConnectionStringBuilder]::new()
        $csb['Data Source'] = $ServerName; $csb['Initial Catalog'] = $DatabaseName
        $csb['Encrypt'] = $true; $csb['Connect Timeout'] = 30; $csb['Application Name'] = 'ShrinkDriver'
        # This tool holds a few long-lived connections, so pooling gives no benefit and would keep the
        # physical connection (and its server session) open after Dispose, to be handed back to a later
        # run. Turn pooling off so Close/Dispose actually closes the connection when we are done.
        $csb['Pooling'] = $false
        # A connection-level retry provider rides out transient open failures (for example an Azure
        # SQL restart or failover). It is a shallow inner retry; callers keep their own retry loop.
        $retry = New-ShrinkRetryProvider
        if ($AuthType -eq 'Windows') {
            $csb['Integrated Security'] = $true
            $conn = Open-ShrinkSqlConnection -Builder $csb -RetryProvider $retry -AllowTrustServerCertificate ([bool]$TrustServerCertificate)
            return [pscustomobject]@{ Connection = $conn; EntraMode = $null }
        }
        if ($AuthType -eq 'SQL') {
            $pw = $SqlPassword.Copy(); $pw.MakeReadOnly()
            $cred = [Microsoft.Data.SqlClient.SqlCredential]::new($SqlLogin, $pw)
            $conn = Open-ShrinkSqlConnection -Builder $csb -Credential $cred -RetryProvider $retry -AllowTrustServerCertificate ([bool]$TrustServerCertificate)
            return [pscustomobject]@{ Connection = $conn; EntraMode = $null }
        }
        # EntraID: try the ambient credential (managed identity, Azure CLI, Azure PowerShell,
        # Visual Studio) first; if it is unavailable, fall back to interactive sign-in. The mode
        # that succeeds is reused by the worker sessions. EntraID targets Azure SQL, whose certificate
        # is always valid, so certificate trust is never needed here.
        foreach ($mode in @('Active Directory Default', 'Active Directory Interactive')) {
            $csb['Authentication'] = $mode
            try {
                $conn = Open-ShrinkSqlConnection -Builder $csb -RetryProvider $retry -AllowTrustServerCertificate $false
                return [pscustomobject]@{ Connection = $conn; EntraMode = $mode }
            } catch {
                if ($mode -eq 'Active Directory Interactive') { throw }
                # The ambient credential is often unavailable on dev machines, and interactive
                # sign-in silently reuses a cached token (no browser prompt) when one exists, so
                # this fallback is not worth a warning on every run. Surface it only under -Verbose.
                Write-Verbose ("Ambient Azure sign-in unavailable ({0}); falling back to interactive sign-in." -f $_.Exception.Message.Split([Environment]::NewLine)[0])
            }
        }
    }
    function Get-ShrinkLiveControl {
        # Return a live control connection, reopening it if the server dropped it (e.g. a restart).
        param($Conn)
        if ($Conn -and $Conn.State -eq 'Open') { return $Conn }
        if ($Conn) { try { $Conn.Dispose() } catch {} }
        (New-ShrinkConnection).Connection
    }

    # ----- pre-flight -----
    $controlConn = New-ShrinkConnection
    $control = $controlConn.Connection
    $resolvedEntraMode = $controlConn.EntraMode
    Write-ShrinkLog "Connected to [$DatabaseName] on [$ServerName]."

    function Get-EligibleFiles {
        param([Microsoft.Data.SqlClient.SqlConnection]$Conn)
        $sql = @'
SELECT df.file_id, df.name,
       CAST(df.size / 128.0 AS bigint) AS alloc_mb,
       CAST(FILEPROPERTY(df.name, 'SpaceUsed') / 128.0 AS bigint) AS used_mb
FROM sys.database_files df
JOIN sys.filegroups fg ON df.data_space_id = fg.data_space_id
WHERE df.type_desc = 'ROWS' AND df.state_desc = 'ONLINE' AND fg.is_read_only = 0 AND df.is_read_only = 0;
'@
        $cmd = $Conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 120
        $rd = $cmd.ExecuteReader()
        $files = [System.Collections.Generic.List[object]]::new()
        try {
            while ($rd.Read()) {
                $files.Add([pscustomobject]@{
                        FileId = [int]$rd['file_id']; Name = [string]$rd['name']
                        AllocatedMB = [long]$rd['alloc_mb']; UsedMB = [long]$rd['used_mb']; FloorMB = $floorMB
                    })
            }
        } finally { $rd.Dispose(); $cmd.Dispose() }
        $files
    }

    function Get-ShrinkFileSizes {
        <# .SYNOPSIS Allocated and used size (MiB) for a set of data files, fetched in one query,
           returned as a hashtable keyed by file_id. Batching avoids one FILEPROPERTY round-trip per
           file: during heavy concurrent shrink, FILEPROPERTY('SpaceUsed') contends on the same file
           latches the shrink holds, so many separate calls routinely time out. #>
        param([Microsoft.Data.SqlClient.SqlConnection]$Conn, [int[]]$FileIds)
        $sizes = @{}
        if (-not $FileIds -or $FileIds.Count -eq 0) { return $sizes }
        $cmd = $Conn.CreateCommand()
        $cmd.CommandText = "SELECT file_id, size / 128.0 AS alloc_mb, ISNULL(FILEPROPERTY(name, 'SpaceUsed'), 0) / 128.0 AS used_mb FROM sys.database_files WHERE file_id IN ($($FileIds -join ','));"
        # A single batched query still calls FILEPROPERTY('SpaceUsed') on files being shrunk, so it can
        # latch-wait under heavy concurrency; give it a generous timeout (well under the status interval)
        # so a transient wait delays one report at most rather than dropping it.
        $cmd.CommandTimeout = 120
        $rd = $cmd.ExecuteReader()
        try {
            while ($rd.Read()) { $sizes[[int]$rd['file_id']] = @{ Alloc = [double]$rd['alloc_mb']; Used = [double]$rd['used_mb'] } }
        } finally { $rd.Dispose(); $cmd.Dispose() }
        $sizes
    }

    function Get-ShrinkDatabaseTotals {
        <# .SYNOPSIS Total allocated and used size (MiB) across the eligible (online, writable) ROWS files, in one query. #>
        param([Microsoft.Data.SqlClient.SqlConnection]$Conn)
        $sql = @'
SELECT ISNULL(SUM(CAST(df.size AS bigint)) / 128.0, 0) AS alloc_mb,
       ISNULL(SUM(CAST(ISNULL(FILEPROPERTY(df.name, 'SpaceUsed'), 0) AS bigint)) / 128.0, 0) AS used_mb
FROM sys.database_files df
JOIN sys.filegroups fg ON df.data_space_id = fg.data_space_id
WHERE df.type_desc = 'ROWS' AND df.state_desc = 'ONLINE' AND fg.is_read_only = 0 AND df.is_read_only = 0;
'@
        $cmd = $Conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 60
        $rd = $cmd.ExecuteReader()
        try {
            if ($rd.Read()) { @{ Alloc = [double]$rd['alloc_mb']; Used = [double]$rd['used_mb'] } } else { @{ Alloc = 0.0; Used = 0.0 } }
        } finally { $rd.Dispose(); $cmd.Dispose() }
    }

    # Report mode: read the file sizes, print the shrink-potential report, and exit without
    # shrinking. The shrink prerequisites below (SQL version, db_owner/sysadmin, AUTO_SHRINK) are
    # skipped because this mode does not shrink anything, and reading file space usage from
    # sys.database_files / FILEPROPERTY only needs the public role.
    if ($Mode -eq 'Report') {
        Write-ShrinkLog 'Report mode: analyzing reclaimable space; no files will be shrunk.'
        $report = @(Get-EligibleFiles -Conn $control | ForEach-Object {
                [pscustomobject]@{
                    FileId = $_.FileId; Name = $_.Name; UsedMB = $_.UsedMB; AllocatedMB = $_.AllocatedMB
                    ReclaimableMB = (Get-ShrinkReclaimableMB -AllocatedMB $_.AllocatedMB -UsedMB $_.UsedMB -FloorMB $floorMB)
                    IsEligible = (Test-ShrinkWorthwhile -AllocatedMB $_.AllocatedMB -UsedMB $_.UsedMB -FloorMB $floorMB -MinReclaimMB $minReclaimMB)
                }
            })
        Write-ShrinkLog '-------------------- shrink potential report --------------------'
        Format-ShrinkFileReport -Files $report -TopN 100 | ForEach-Object { Write-ShrinkLog $_ }
        $eligibleFiles = @($report | Where-Object { $_.IsEligible })
        $sumUsed = Get-ShrinkSumMB -Items $report -Property UsedMB
        $sumAlloc = Get-ShrinkSumMB -Items $report -Property AllocatedMB
        # Report only the space a shrink with these settings would actually reclaim (the eligible
        # files); files below the threshold are left as-is, so they don't count toward the total.
        $sumRecl = Get-ShrinkSumMB -Items $eligibleFiles -Property ReclaimableMB
        Write-ShrinkLog '-------------------- summary --------------------'
        Format-ShrinkKeyValueTable -Rows ([ordered]@{
                'Data files'             = $report.Count
                'Eligible to shrink'     = $eligibleFiles.Count
                'Used'                   = (Format-ShrinkSize $sumUsed)
                'Allocated'              = (Format-ShrinkSize $sumAlloc)
                'Reclaimable (eligible)' = (Format-ShrinkSize $sumRecl)
            }) | ForEach-Object { Write-ShrinkLog $_ }
        Write-ShrinkLog '-------------------------------------------------'
        Write-ShrinkLog 'To shrink these files, run again with -Mode Shrink.'
        $control.Close()
        $reportResult = [pscustomobject]@{
            Mode             = 'Report'
            DataFiles        = $report.Count
            Eligible         = $eligibleFiles.Count
            TotalUsedMB      = $sumUsed
            TotalAllocatedMB = $sumAlloc
            ReclaimableMB    = $sumRecl
            Files            = @($report | ForEach-Object { [pscustomobject]@{ FileId = $_.FileId; Name = $_.Name; UsedMB = $_.UsedMB; AllocatedMB = $_.AllocatedMB; ReclaimableMB = $_.ReclaimableMB; IsEligible = $_.IsEligible } })
        }
        if ($PassThru) { return $reportResult }
        return
    }

    # Supported platforms only: SQL Server 2022 or later, Azure SQL Database, and Azure SQL Managed
    # Instance. Read version, edition, permission, AUTO_SHRINK, and read-only checks in one round trip.
    $pfCmd = $control.CreateCommand(); $pfCmd.CommandTimeout = 30
    $pfCmd.CommandText = @'
SELECT CAST(SERVERPROPERTY('EngineEdition') AS int) AS engine_edition,
       CAST(SERVERPROPERTY('ProductMajorVersion') AS int) AS major_version,
       CASE WHEN IS_ROLEMEMBER('db_owner') = 1 OR IS_SRVROLEMEMBER('sysadmin') = 1 THEN 1 ELSE 0 END AS has_perm,
       CAST(DATABASEPROPERTYEX(DB_NAME(), 'IsAutoShrink') AS int) AS auto_shrink,
       CASE WHEN DATABASEPROPERTYEX(DB_NAME(), 'Updateability') = 'READ_ONLY' THEN 1 ELSE 0 END AS read_only;
'@
    $pfRd = $pfCmd.ExecuteReader()
    try {
        [void]$pfRd.Read()
        $engineEdition = [int]$pfRd['engine_edition']
        $majorVersion = [int]$pfRd['major_version']
        $hasPerm = [int]$pfRd['has_perm']
        $autoShrink = [int]$pfRd['auto_shrink']
        $dbReadOnly = [int]$pfRd['read_only']
    } finally { $pfRd.Dispose(); $pfCmd.Dispose() }
    if (-not ($engineEdition -in @(5, 8)) -and $majorVersion -lt 16) {
        throw "ShrinkDriver supports only SQL Server 2022 or later, Azure SQL Database, and Azure SQL Managed Instance. Detected major version $majorVersion (EngineEdition $engineEdition), which is not supported."
    }
    if ($hasPerm -ne 1) { throw "The login must be a member of db_owner on [$DatabaseName] or sysadmin." }
    if ($autoShrink -eq 1) {
        throw "AUTO_SHRINK is ON for [$DatabaseName]. Disable it (ALTER DATABASE ... SET AUTO_SHRINK OFF) before running ShrinkDriver."
    }
    if ($dbReadOnly -eq 1) {
        throw "Database [$DatabaseName] is read-only; its files cannot be shrunk."
    }
    if ($NoTruncate) {
        Write-ShrinkLog 'NoTruncate moves data pages toward the front of each file without releasing space; the allocated size will not change (each file is reported as Repacked).'
    }

    $allFiles = @(Get-EligibleFiles -Conn $control)
    $eligible = @($allFiles | Where-Object { Test-ShrinkWorthwhile -AllocatedMB $_.AllocatedMB -UsedMB $_.UsedMB -FloorMB $floorMB -MinReclaimMB $minReclaimMB })
    $allocSum = [long](($allFiles | Measure-Object AllocatedMB -Sum).Sum)
    $usedSum = [long](($allFiles | Measure-Object UsedMB -Sum).Sum)
    Write-ShrinkLog ("Eligible data files: {0} of {1} (with at least {2} to reclaim). Total allocated {3}, used {4}, reclaimable {5}." -f `
            $eligible.Count, $allFiles.Count, (Format-ShrinkSize $minReclaimMB),
        (Format-ShrinkSize $allocSum), (Format-ShrinkSize $usedSum), (Format-ShrinkSize ($allocSum - $usedSum)))
    if ($eligible.Count -eq 0) {
        Write-ShrinkLog ("No files have at least {0} of space to reclaim above the target. Nothing to do." -f (Format-ShrinkSize $minReclaimMB))
        $control.Close()
        return [pscustomobject]@{
            Mode          = 'Shrink'
            Elapsed       = '0s'
            StoppedBy     = $null
            DbUsedMB      = $usedSum
            DbAllocatedMB = $allocSum
            Counts        = (Get-ShrinkBucketCounts -Buckets @())
            EligibleRemaining = 0
            Files         = @()
        }
    }
    $effectiveSessions = [Math]::Min($Sessions, $eligible.Count)
    if ($effectiveSessions -lt $Sessions) {
        Write-ShrinkLog ("Capping concurrency to {0} (eligible file count) from requested {1}." -f $effectiveSessions, $Sessions) 'WARN'
    }

    # ----- shared state -----
    $shared = [hashtable]::Synchronized(@{})
    $shared.Files = [System.Collections.Generic.List[object]]::new(); $eligible | ForEach-Object { $shared.Files.Add($_) }
    # Completed: every file that reached a terminal state this run, keyed by file id. The
    # value records which bucket it landed in (Shrunk, PartlyShrunk, AlreadyMinimal,
    # AlreadyAtTarget, Grew, GaveUp, Interrupted, or NotProcessed) plus an optional reason.
    # Files listed here are never selected again.
    $shared.Owned = @{}; $shared.Completed = @{}
    # Sessions is read by the monitor thread and written by every worker (at startup and on each state
    # change), so it must be thread-safe. A plain hashtable corrupts under concurrent writes, which can
    # drop a worker's entry and make it throw (and die) before it ever starts a file. Owned/Completed
    # stay plain hashtables because every access to them is already serialized by $shared.Lock.
    $shared.Sessions = [System.Collections.Concurrent.ConcurrentDictionary[int, object]]::new()
    $shared.Events = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $shared.Stop = $false; $shared.StopReason = $null; $shared.Force = $false; $shared.Lock = [object]::new()

    $connParams = @{
        Server = $ServerName; Database = $DatabaseName; AuthType = $AuthType
        SqlLogin = $SqlLogin; SqlPassword = $SqlPassword; EntraMode = $resolvedEntraMode
        TrustAllowed = [bool]$TrustServerCertificate
        TruncateOnly = [bool]$TruncateOnly; NoTruncate = [bool]$NoTruncate
        Wlp = [bool]$WaitAtLowPriority; AbortAfterWait = $AbortAfterWait
        FloorMB = $floorMB; StepMB = $stepMB; RetryCount = $RetryCount
        MinReclaimMB = $minReclaimMB
        BackoffBaseSec = $BackoffBaseSeconds; BackoffCapSec = $BackoffCapSeconds
    }

    $workerScript = {
        param($workerId, $shared, $selfPath, $connParams)
        . $selfPath
        Set-StrictMode -Version Latest

        function New-WConn {
            $csb = [Microsoft.Data.SqlClient.SqlConnectionStringBuilder]::new()
            $csb['Data Source'] = $connParams.Server; $csb['Initial Catalog'] = $connParams.Database
            $csb['Encrypt'] = $true; $csb['Connect Timeout'] = 30; $csb['Application Name'] = "ShrinkDriver-w$workerId"
            $csb['Pooling'] = $false   # dedicated, long-lived connection; close it for real on Dispose
            $retry = New-ShrinkRetryProvider
            switch ($connParams.AuthType) {
                'Windows' {
                    $csb['Integrated Security'] = $true
                    Open-ShrinkSqlConnection -Builder $csb -RetryProvider $retry -AllowTrustServerCertificate $connParams.TrustAllowed
                }
                'SQL' {
                    $pw = $connParams.SqlPassword.Copy(); $pw.MakeReadOnly()
                    $cred = [Microsoft.Data.SqlClient.SqlCredential]::new($connParams.SqlLogin, $pw)
                    Open-ShrinkSqlConnection -Builder $csb -Credential $cred -RetryProvider $retry -AllowTrustServerCertificate $connParams.TrustAllowed
                }
                default {
                    $csb['Authentication'] = $connParams.EntraMode
                    Open-ShrinkSqlConnection -Builder $csb -RetryProvider $retry -AllowTrustServerCertificate $false
                }
            }
        }
        function Emit($msg) { $shared.Events.Enqueue(('worker {0}: {1}' -f $workerId, $msg)) }
        function Get-Size($conn, $fileId) {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "SELECT CAST(size/128.0 AS bigint) AS a, CAST(FILEPROPERTY(name,'SpaceUsed')/128.0 AS bigint) AS u FROM sys.database_files WHERE file_id = $fileId;"
            $rd = $cmd.ExecuteReader()
            try { if ($rd.Read()) { @{ Alloc = [long]$rd['a']; Used = [long]$rd['u'] } } else { $null } }
            finally { $rd.Dispose(); $cmd.Dispose() }
        }
        function Get-ShrinkOldestTran($conn) {
            # Oldest active transaction in this database; on Hyperscale it can hold the low watermark
            # that blocks shrink.
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = @'
SELECT TOP (1) s.session_id AS spid,
       DATEDIFF(SECOND, dt.database_transaction_begin_time, SYSDATETIME()) AS age_s,
       s.program_name AS prog,
       snap.is_snapshot
FROM sys.dm_tran_database_transactions AS dt
JOIN sys.dm_tran_session_transactions AS st ON st.transaction_id = dt.transaction_id
JOIN sys.dm_exec_sessions AS s ON s.session_id = st.session_id
LEFT JOIN sys.dm_tran_active_snapshot_database_transactions AS snap ON snap.transaction_id = dt.transaction_id
WHERE dt.database_id = DB_ID() AND dt.database_transaction_begin_time IS NOT NULL
ORDER BY dt.database_transaction_begin_time ASC;
'@
            try {
                $rd = $cmd.ExecuteReader()
                try {
                    if ($rd.Read()) {
                        $prog = if ($rd['prog'] -is [DBNull]) { '' } else { [string]$rd['prog'] }
                        $who = if ($prog) { "session $([int]$rd['spid']), $prog" } else { "session $([int]$rd['spid'])" }
                        $snapTag = ''
                        if (-not ($rd['is_snapshot'] -is [DBNull])) {
                            $snapTag = if ([int]$rd['is_snapshot'] -eq 1) { '; snapshot isolation transaction holding row versions' } else { '; transaction holding row versions' }
                        }
                        $age = Format-ShrinkDuration -TimeSpan ([TimeSpan]::FromSeconds([int]$rd['age_s']))
                        "oldest active transaction in the database is $age old ($who)$snapTag"
                    } else { $null }
                } finally { $rd.Dispose() }
            } catch { $null }
            finally { $cmd.Dispose() }
        }
        function Get-WConnResilient {
            # Re-establish the worker connection, tolerating a server that is briefly offline (for
            # example during an Azure SQL restart or failover). New-WConn's connection-level retry
            # provider handles transient errors; this loop is the outer backstop that keeps trying,
            # with backoff, for errors outside that list so a 1-2 minute outage does not kill the
            # worker. On success it also refreshes the session's SPID (a reconnect gets a new one) so
            # the status report keeps tracking the worker. Throws if it cannot reconnect in the bound.
            $maxTries = [Math]::Max(10, [int]$connParams.RetryCount)
            for ($try = 1; $try -le $maxTries; $try++) {
                if ($shared.Stop) { throw [System.OperationCanceledException]::new('stop requested during reconnect') }
                try {
                    $newConn = New-WConn
                    $spidCmd = $newConn.CreateCommand(); $spidCmd.CommandText = 'SELECT @@SPID'
                    $newSpid = [int]$spidCmd.ExecuteScalar(); $spidCmd.Dispose()
                    # Publish the new session id (a reconnect gets a fresh one) and mark the worker
                    # live again so the status report tracks the right session. Reset ConnectTime too,
                    # so the worker's Elapsed reflects its current connection; the run-wide elapsed is
                    # shown separately in the database-total section.
                    $shared.Sessions[$workerId].Spid = $newSpid
                    $shared.Sessions[$workerId].State = 'Shrinking'
                    $shared.Sessions[$workerId].ConnectTime = [System.Diagnostics.Stopwatch]::GetTimestamp()
                    Emit "reconnected on attempt $try (session ID $newSpid)"
                    return $newConn
                }
                catch {
                    if ($try -eq $maxTries) { throw }
                    $w = Get-ShrinkBackoffSeconds -Attempt $try -BaseSec $connParams.BackoffBaseSec -CapSec $connParams.BackoffCapSec
                    Emit "reconnect attempt $try/$maxTries failed ($($_.Exception.Message.Split([Environment]::NewLine)[0])); retrying in $([int]$w)s"
                    Start-Sleep -Seconds $w
                }
            }
        }

        $conn = New-WConn
        $spidCmd = $conn.CreateCommand(); $spidCmd.CommandText = 'SELECT @@SPID'
        $spid = [int]$spidCmd.ExecuteScalar(); $spidCmd.Dispose()
        $shared.Sessions[$workerId] = @{ Spid = $spid; Command = $null; FileId = $null; State = 'Idle'; ConnectTime = [System.Diagnostics.Stopwatch]::GetTimestamp(); RequestSeq = 0 }
        Emit "Connected (session ID $spid)"

        try {
            while (-not $shared.Stop) {
                $file = $null
                [System.Threading.Monitor]::Enter($shared.Lock)
                try {
                    $file = Select-ShrinkNextFile -Files $shared.Files.ToArray() `
                        -OwnedFileIds ([int[]]$shared.Owned.Keys) -ExcludedFileIds ([int[]]$shared.Completed.Keys)
                    if ($file) { $shared.Owned[$file.FileId] = $workerId }
                } finally { [System.Threading.Monitor]::Exit($shared.Lock) }
                if (-not $file) { break }

                $shared.Sessions[$workerId].FileId = $file.FileId
                $shared.Sessions[$workerId].State = 'Shrinking'
                Emit "Start file $($file.FileId) [$($file.Name)]"

                $attempt = 0
                $startAlloc = $null            # allocated size (MB) when this worker took the file
                $bucket = $null                # terminal outcome: Shrunk | PartlyShrunk | AlreadyMinimal | AlreadyAtTarget | Grew | GaveUp
                $bucketReason = $null          # detail text, recorded for the give-up outcomes
                $connLost = $false             # set if the connection dropped and could not be re-established
                while (-not $shared.Stop) {
                    $sz = $null
                    try { $sz = Get-Size $conn $file.FileId }
                    catch [Microsoft.Data.SqlClient.SqlException] {
                        if ($shared.Stop) { break }
                        # The server dropped the connection between shrink steps; reconnect and retry.
                        # Clear the (now dead) session id first so the status report does not match a
                        # recycled spid to an unrelated session while we reconnect.
                        Emit "File $($file.FileId) connection lost; reconnecting"
                        $shared.Sessions[$workerId].Spid = $null
                        $shared.Sessions[$workerId].State = 'Reconnecting'
                        try { $conn.Dispose() } catch {}
                        try { $conn = Get-WConnResilient }
                        catch {
                            # Could not reconnect within the bound. This is an external failure, not the
                            # shrink running out of options, and the file's final size was not reassessed,
                            # so classify it as Interrupted rather than GaveUp.
                            $bucket = 'Interrupted'
                            $bucketReason = "lost the connection to the server and could not reconnect: $($_.Exception.Message.Split([Environment]::NewLine)[0])"
                            $connLost = $true
                        }
                        if ($connLost) { break }
                        continue
                    }
                    if (-not $sz) { break }
                    if ($null -eq $startAlloc) { $startAlloc = $sz.Alloc }

                    if ($connParams.TruncateOnly) {
                        $sql = New-ShrinkCommandText -FileId $file.FileId -TruncateOnly `
                            -WaitAtLowPriority:$connParams.Wlp -AbortAfterWait $connParams.AbortAfterWait
                    } else {
                        # A shrink is long and expensive, so never launch one for a trivial gain: stop as
                        # soon as less than MinReclaimMB of space can still be reclaimed, whether that floor
                        # is the file's used pages or the requested target size.
                        if (-not (Test-ShrinkWorthwhile -AllocatedMB $sz.Alloc -UsedMB $sz.Used -FloorMB $connParams.FloorMB -MinReclaimMB $connParams.MinReclaimMB)) {
                            $atTarget = ($null -ne $connParams.FloorMB) -and ([long]$connParams.FloorMB -ge $sz.Used)
                            if ($sz.Alloc -lt $startAlloc) {
                                $bucket = 'Shrunk'
                                $where = if ($atTarget) { 'target size' } else { 'its minimum size' }
                                Emit "File $($file.FileId) shrunk to $where, now $(Format-ShrinkSize $sz.Alloc)"
                            } elseif ($atTarget) {
                                $bucket = 'AlreadyAtTarget'
                                Emit "File $($file.FileId) already at or below target size ($(Format-ShrinkSize $sz.Alloc)); nothing to do"
                            } else {
                                $bucket = 'AlreadyMinimal'
                                Emit "File $($file.FileId) already at its minimum size ($(Format-ShrinkSize $sz.Alloc)); nothing to reclaim"
                            }
                            break
                        }
                        $next = Get-ShrinkNextTargetMB -AllocatedMB $sz.Alloc -FloorMB $connParams.FloorMB -StepMB $connParams.StepMB
                        $sql = New-ShrinkCommandText -FileId $file.FileId -TargetMB $next `
                            -NoTruncate:$connParams.NoTruncate -WaitAtLowPriority:$connParams.Wlp -AbortAfterWait $connParams.AbortAfterWait
                    }

                    $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 0
                    # A new DBCC SHRINKFILE step is a new request, so its per-request cpu_time/reads/writes
                    # counters restart at zero. Bump the sequence the status report uses to key its deltas
                    # so it only differences counters within one request, never across a step boundary.
                    $shared.Sessions[$workerId].RequestSeq++
                    $shared.Sessions[$workerId].Command = $cmd
                    $before = $sz.Alloc
                    try {
                        # DBCC SHRINKFILE returns a one-row result set; read CurrentSize from it to learn
                        # the file's size after the attempt without a second round trip.
                        $result = $null
                        $rd = $cmd.ExecuteReader()
                        try {
                            if ($rd.Read()) {
                                $result = @{ CurrentMB = ([double][long]$rd['CurrentSize']) / 128.0 }
                            }
                        } finally { $rd.Dispose() }

                        if ($connParams.TruncateOnly) {
                            $after = if ($result) { [long]$result.CurrentMB } else { (Get-Size $conn $file.FileId).Alloc }
                            if ($after -lt $startAlloc) {
                                $bucket = 'Shrunk'
                                Emit "File $($file.FileId) truncated to $(Format-ShrinkSize $after)"
                            } else {
                                $bucket = 'AlreadyMinimal'
                                Emit "File $($file.FileId) had no unused space to truncate ($(Format-ShrinkSize $after))"
                            }
                            break
                        }

                        if ($connParams.NoTruncate) {
                            # NoTruncate moves allocated pages toward the front of the file but never
                            # releases space, so the allocated size is unchanged by design. Treat a
                            # completed pass as its own success (Repacked) rather than a give-up, and do
                            # not loop: a second pass would not reduce the size either.
                            $bucket = 'Repacked'
                            Emit "File $($file.FileId) repacked; NoTruncate leaves the allocated size unchanged ($(Format-ShrinkSize $before))"
                            break
                        }

                        $after = if ($result) { [long]$result.CurrentMB } else { (Get-Size $conn $file.FileId).Alloc }
                        if ($after -lt $before) {
                            # Made progress this pass; keep shrinking.
                            $attempt = 0
                        }
                        elseif ($after -gt $before) {
                            # The file grew during this pass (other workloads added data). Growth can be
                            # transient, so back off and retry up to the limit before giving up.
                            $attempt++
                            if ($attempt -gt $connParams.RetryCount) {
                                if ($after -gt $startAlloc) {
                                    $bucket = 'Grew'
                                    $bucketReason = "grew from $(Format-ShrinkSize $startAlloc) to $(Format-ShrinkSize $after) during the shrink (other workloads adding data); gave up after $($connParams.RetryCount) retries"
                                    Emit "File $($file.FileId) grew to $(Format-ShrinkSize $after) during the shrink (other workloads adding data); gave up"
                                } else {
                                    $bucket = 'PartlyShrunk'
                                    $bucketReason = "reduced from $(Format-ShrinkSize $startAlloc) to $(Format-ShrinkSize $after) but kept growing during the shrink; gave up after $($connParams.RetryCount) retries"
                                    Emit "File $($file.FileId) partly shrunk to $(Format-ShrinkSize $after), then gave up: the file kept growing during the shrink"
                                }
                                break
                            }
                            $wait = Get-ShrinkBackoffSeconds -Attempt $attempt -BaseSec $connParams.BackoffBaseSec -CapSec $connParams.BackoffCapSec
                            Emit "File $($file.FileId) grew during the shrink; retry $attempt in $([int]$wait)s"
                            Start-Sleep -Seconds $wait
                        }
                        else {
                            # No progress, yet the pre-check confirmed there was more than MinReclaimMB of
                            # unused space to reclaim. Retrying has no high confidence of helping.
                            # Stop and report a partial result.
                            if ($after -lt $startAlloc) {
                                $bucket = 'PartlyShrunk'
                                $bucketReason = "reduced from $(Format-ShrinkSize $startAlloc) to $(Format-ShrinkSize $after), but the remaining unused space could not be reclaimed"
                                Emit "File $($file.FileId) partly shrunk to $(Format-ShrinkSize $after); the remaining unused space could not be reclaimed"
                            } else {
                                $bucket = 'GaveUp'
                                $bucketReason = "the shrink could not reclaim any of the unused space"
                                Emit "Gave up on file $($file.FileId): $bucketReason"
                            }
                            break
                        }
                    } catch [Microsoft.Data.SqlClient.SqlException] {
                        if ($shared.Stop) { break }
                        $num = $_.Exception.Number
                        if ($num -eq 5201) {
                            if ($before -lt $startAlloc) {
                                $bucket = 'Shrunk'
                                Emit "File $($file.FileId) shrunk to $(Format-ShrinkSize $before) (MSSQL error 5201: no more reclaimable space)"
                            } else {
                                $bucket = 'AlreadyMinimal'
                                Emit "File $($file.FileId) cannot be shrunk (MSSQL error 5201: no reclaimable space)"
                            }
                            break
                        }
                        if ($num -eq 49537) {
                            # 49537: a page shrink must relocate is pinned by the database low watermark - a
                            # long-running transaction on the primary (possibly another concurrent shrink moving
                            # pages) or a lagging/long-queried secondary. The engine has already exhausted its
                            # own retries and the watermark rarely advances within a client retry, so stop and let
                            # a later run reclaim the space once the watermark moves.
                            $after = if ($conn.State -eq 'Open') { (Get-Size $conn $file.FileId).Alloc } else { $before }
                            $held = if ($conn.State -eq 'Open') { Get-ShrinkOldestTran $conn } else { $null }
                            $bucket = Get-ShrinkGaveUpBucket -StartAllocMB $startAlloc -FinalAllocMB $after
                            $bucketReason = 'blocked by the database low watermark (MSSQL error 49537): a page to be moved is pinned by a long-running transaction or a lagging secondary; run shrink again later'
                            if ($held) { $bucketReason += "; $held" }
                            Emit ("File $($file.FileId) blocked by the low watermark (MSSQL error 49537); run shrink again later" + $(if ($held) { " ($held)" } else { '' }))
                            break
                        }
                        if ($conn.State -ne 'Open') {
                            # The connection dropped (server restart, failover, or the client machine
                            # sleeping). Reconnecting is not a per-file failure, so it does not count
                            # against the retry budget; Get-WConnResilient has its own bound. Clear the
                            # dead session id first so the status report does not match a recycled spid.
                            Emit "File $($file.FileId) connection lost (MSSQL error $num); reconnecting"
                            $shared.Sessions[$workerId].Spid = $null
                            $shared.Sessions[$workerId].State = 'Reconnecting'
                            try { $conn.Dispose() } catch {}
                            try { $conn = Get-WConnResilient }
                            catch {
                                # External failure, not a shrink that ran out of options: the last DBCC step
                                # may have been mid-flight, so the final size is unknown. Classify as Interrupted.
                                $bucket = 'Interrupted'
                                $bucketReason = "lost the connection to the server and could not reconnect: $($_.Exception.Message.Split([Environment]::NewLine)[0])"
                                Emit "File $($file.FileId) interrupted: $bucketReason"
                                $connLost = $true; break
                            }
                        }
                        else {
                            # The connection is still up but the command failed transiently; retry the
                            # file up to the retry budget with backoff.
                            $attempt++
                            if ($attempt -gt $connParams.RetryCount) {
                                $bucket = Get-ShrinkGaveUpBucket -StartAllocMB $startAlloc -FinalAllocMB $before
                                $bucketReason = "MSSQL error $num after $($connParams.RetryCount) retries: $($_.Exception.Message.Split([Environment]::NewLine)[0])"
                                Emit "Gave up on file $($file.FileId): $bucketReason"; break
                            }
                            $wait = Get-ShrinkBackoffSeconds -Attempt $attempt -BaseSec $connParams.BackoffBaseSec -CapSec $connParams.BackoffCapSec
                            Emit "File $($file.FileId) MSSQL error $num (retry $attempt in $([int]$wait)s): $($_.Exception.Message.Split([Environment]::NewLine)[0])"
                            Start-Sleep -Seconds $wait
                        }
                    } finally {
                        $shared.Sessions[$workerId].Command = $null
                        try { $cmd.Dispose() } catch {}
                    }
                }

                # If the run was stopped while this file was still in progress, decide how to record it.
                # An early stop that is not a forced quit (the run time limit, or the first Ctrl+C) is an
                # orderly wind-down: reassess the file and report its real outcome - DBCC SHRINKFILE keeps
                # the space it reclaimed even when cancelled, so a fresh measurement is authoritative. A
                # forced quit (second Ctrl+C) or a lost connection leaves the file Interrupted instead.
                if (-not $bucket -and $shared.Stop) {
                    $cause = if ($shared.StopReason -eq 'Timeout') { 'Timeout' } else { 'Ctrl+C' }
                    # Re-measure the file's real size (unless force-quitting or the connection is gone).
                    # DBCC SHRINKFILE keeps the space it reclaimed even when cancelled, so a fresh read is
                    # authoritative. Track the command so a second Ctrl+C can cancel it if the server hangs.
                    $final = $null
                    if (-not $shared.Force -and $null -ne $startAlloc -and $conn.State -eq 'Open') {
                        try {
                            $mcmd = $conn.CreateCommand()
                            $mcmd.CommandText = "SELECT CAST(size/128.0 AS bigint) FROM sys.database_files WHERE file_id = $($file.FileId);"
                            $shared.Sessions[$workerId].Command = $mcmd
                            $final = [long]$mcmd.ExecuteScalar()
                            $shared.Sessions[$workerId].Command = $null; $mcmd.Dispose()
                        } catch { $shared.Sessions[$workerId].Command = $null; $final = $null }
                    }
                    $outcome = Get-ShrinkStopOutcome -StartAllocMB $startAlloc -FinalAllocMB $final -Cause $cause -Force:([bool]$shared.Force)
                    $bucket = $outcome.Bucket; $bucketReason = $outcome.Reason
                }

                [System.Threading.Monitor]::Enter($shared.Lock)
                try {
                    $shared.Owned.Remove($file.FileId)
                    if ($bucket) { $shared.Completed[$file.FileId] = @{ Bucket = $bucket; Reason = $bucketReason } }
                } finally { [System.Threading.Monitor]::Exit($shared.Lock) }
                $shared.Sessions[$workerId].FileId = $null; $shared.Sessions[$workerId].State = 'Idle'
                if ($connLost) { Emit 'connection lost and not recoverable; worker stopping'; break }
            }
        }
        catch {
            # Surface why a worker dies instead of failing silently - otherwise the error is only seen
            # at run end via EndInvoke. The worker then exits cleanly through the finally below.
            Emit "worker failed: $($_.Exception.Message.Split([Environment]::NewLine)[0])"
        }
        finally {
            # Release any file this worker still owns (e.g. if it died mid-file) so another can retry it.
            [System.Threading.Monitor]::Enter($shared.Lock)
            try { foreach ($fid in @($shared.Owned.Keys)) { if ($shared.Owned[$fid] -eq $workerId) { $shared.Owned.Remove($fid) } } }
            finally { [System.Threading.Monitor]::Exit($shared.Lock) }
            # Clear the session id: once this connection is disposed the server can recycle its
            # session_id for an unrelated (e.g. internal) task, and a lingering id would make the
            # status report match that stranger's request. Nulling it (as on reconnect) drops the
            # worker from the live-spid query and shows it as SPID '-', Stopped.
            $shared.Sessions[$workerId].Spid = $null; $shared.Sessions[$workerId].FileId = $null
            $shared.Sessions[$workerId].State = 'Stopped'
            try { $conn.Dispose() } catch {}
            Emit 'stopped'
        }
    }

    # ----- launch workers -----
    $iss = [initialsessionstate]::CreateDefault()
    $pool = [runspacefactory]::CreateRunspacePool(1, $effectiveSessions, $iss, $Host)
    $pool.Open()
    $workers = for ($workerId = 0; $workerId -lt $effectiveSessions; $workerId++) {
        $ps = [powershell]::Create(); $ps.RunspacePool = $pool
        [void]$ps.AddScript($workerScript).AddArgument($workerId).AddArgument($shared).AddArgument($selfPath).AddArgument($connParams)
        [pscustomobject]@{ WorkerId = $workerId; PS = $ps; Handle = $ps.BeginInvoke() }
    }
    Write-ShrinkLog "Launched $effectiveSessions worker session(s)."

    # Graceful Ctrl+C: do NOT use a Console.CancelKeyPress handler - PowerShell raises that event on
    # a background thread with no runspace, so a script handler throws and crashes the process. Make
    # Ctrl+C an ordinary key instead and poll for it on this (runspace) thread in the monitor loop.
    # Restored in the finally block. Only do this when we are attached to a console we can read keys from.
    $ctrlCAsInput = $false
    $prevTreatCtrlC = $false
    if (-not [Console]::IsInputRedirected) {
        try { $prevTreatCtrlC = [Console]::TreatControlCAsInput; [Console]::TreatControlCAsInput = $true; $ctrlCAsInput = $true } catch {}
    }

    # ----- monitor loop -----
    # Drive all run-time and interval math from a monotonic clock so a wall-clock change mid-run (a
    # DST transition or an NTP/manual adjustment) cannot make the run-time limit fire early or late,
    # or yield a negative elapsed.
    $runClock = [System.Diagnostics.Stopwatch]::StartNew()
    $limitSeconds = if ($null -ne $MaxRuntimeSecondsOverride) { [double]$MaxRuntimeSecondsOverride } elseif ($null -ne $MaxRuntimeMinutes) { [double]$MaxRuntimeMinutes * 60 } else { $null }
    $prev = @{}; $stuckState = @{}

    function Write-StatusReport {
        $evt = ''
        while ($shared.Events.TryDequeue([ref]$evt)) { Write-ShrinkLog $evt 'EVENT' }
        $spids = @($shared.Sessions.Values | Where-Object { $_.Spid } | ForEach-Object { [int]$_.Spid })
        $rows = [System.Collections.Generic.List[object]]::new()
        # Query only for workers that currently have a live session id. A worker mid-reconnect has
        # none (its spid was cleared), so it is shown from its shared state instead - this avoids
        # matching a stale, recycled spid to an unrelated system session.
        if ($spids.Count -gt 0) {
            $inList = ($spids -join ',')
            $sql = @"
SELECT r.session_id, r.status, r.command, ISNULL(r.wait_type,'') AS wait_type, r.wait_time,
       r.percent_complete, r.cpu_time, r.reads, r.writes, ISNULL(r.blocking_session_id,0) AS blocker,
       ISNULL((SELECT TOP 1 b.command FROM sys.dm_exec_requests b WHERE b.session_id = r.blocking_session_id),'') AS blocker_cmd
FROM sys.dm_exec_requests r WHERE r.session_id IN ($inList);
"@
            $cmd = $control.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 60
            $rd = $cmd.ExecuteReader()
            try { while ($rd.Read()) { $rows.Add([pscustomobject]@{
                            Spid = [int]$rd['session_id']; Status = [string]$rd['status']; Command = [string]$rd['command']
                            Wait = [string]$rd['wait_type']; WaitTime = [long]$rd['wait_time']; Pct = [double]$rd['percent_complete']
                            Cpu = [long]$rd['cpu_time']; Reads = [long]$rd['reads']; Writes = [long]$rd['writes']; Blocker = [int]$rd['blocker']; BlockerCmd = [string]$rd['blocker_cmd']
                        }) } } finally { $rd.Dispose(); $cmd.Dispose() }
        }

        Write-ShrinkLog '---- status ----'
        # Fetch every in-flight file's size in one query rather than one FILEPROPERTY round-trip per
        # worker: FILEPROPERTY('SpaceUsed') contends on the same file latches the shrink holds, so
        # under high concurrency the per-file calls time out and the whole report is dropped.
        $statusFileIds = @($shared.Sessions.Values | Where-Object { $_.FileId } | ForEach-Object { [int]$_.FileId } | Sort-Object -Unique)
        $sizeById = Get-ShrinkFileSizes -Conn $control -FileIds $statusFileIds
        $statusData = [System.Collections.Generic.List[object]]::new()
        foreach ($sess in $shared.Sessions.GetEnumerator() | Sort-Object { $_.Key }) {
            $workerId = $sess.Key; $s = $sess.Value
            $seq = [int]$s.RequestSeq
            # Elapsed is the worker's time on its current connection (it resets when the worker
            # reconnects). ConnectTime is a monotonic timestamp; the run-wide elapsed since script
            # start is in the database-total section.
            $sessElapsedS = if ($s.ConnectTime) { [int](([System.Diagnostics.Stopwatch]::GetTimestamp() - [long]$s.ConnectTime) / [System.Diagnostics.Stopwatch]::Frequency) } else { $null }
            $row = $rows | Where-Object Spid -eq $s.Spid | Select-Object -First 1
            if (-not $row) {
                $statusData.Add([pscustomobject]@{
                        Worker = $workerId; Spid = $s.Spid; FileId = $s.FileId; UsedMB = $null; AllocMB = $null
                        Cmd = ''; Status = $s.State; Pct = $null; ElapsedS = $sessElapsedS; Increment = $seq
                        Wait = ''; DCpu = '-'; DReads = '-'; DWrites = '-'; Blocker = ''
                    })
                continue
            }
            # cpu_time/reads/writes in dm_exec_requests are per-request and restart on each new shrink step,
            # so a delta is only meaningful when the increment is unchanged since the last report; otherwise
            # show '-'.
            $dCpu = '-'; $dReads = '-'; $dWrites = '-'
            if ($prev.ContainsKey($s.Spid) -and $prev[$s.Spid].Seq -eq $seq) {
                $c = Get-ShrinkDeltaWithReset -Previous $prev[$s.Spid].Cpu -Current $row.Cpu
                $rr = Get-ShrinkDeltaWithReset -Previous $prev[$s.Spid].Reads -Current $row.Reads
                $rw = Get-ShrinkDeltaWithReset -Previous $prev[$s.Spid].Writes -Current $row.Writes
                $dCpu = if ($c.IsReset) { '-' } else { '{0:N0}' -f $c.Delta }
                $dReads = if ($rr.IsReset) { '-' } else { '{0:N0}' -f $rr.Delta }
                $dWrites = if ($rw.IsReset) { '-' } else { '{0:N0}' -f $rw.Delta }
            }
            $prev[$s.Spid] = @{ Seq = $seq; Cpu = $row.Cpu; Reads = $row.Reads; Writes = $row.Writes }
            $z = if ($s.FileId -and $sizeById.ContainsKey([int]$s.FileId)) { $sizeById[[int]$s.FileId] } else { $null }
            $statusData.Add([pscustomobject]@{
                    Worker = $workerId; Spid = $s.Spid; FileId = $s.FileId
                    UsedMB = $(if ($z) { $z.Used } else { $null }); AllocMB = $(if ($z) { $z.Alloc } else { $null })
                    Cmd = $row.Command; Status = $row.Status; Pct = [math]::Round($row.Pct, 1); ElapsedS = $sessElapsedS; Increment = $seq
                    Wait = $(if ($row.Wait) { "$($row.Wait) $($row.WaitTime)ms" } else { '' })
                    DCpu = $dCpu; DReads = $dReads; DWrites = $dWrites
                    Blocker = $(if ($row.Blocker) { "$($row.Blocker) ($($row.BlockerCmd))" } else { '' })
                })

            if (-not $stuckState.ContainsKey($s.Spid)) { $stuckState[$s.Spid] = @{ Blocker = 0; Cpu = 0; Reads = 0; BlockerSince = $null; NoProgressSince = $null } }
            $st = Update-ShrinkStuckState -State $stuckState[$s.Spid] -Blocker $row.Blocker -Cpu $row.Cpu -Reads $row.Reads -NowSeconds $runClock.Elapsed.TotalSeconds -WindowSec $StuckWindowSeconds
            if ($st.IsStuck -and $s.Command) {
                $why = if ($st.BlockerStuck -and $row.Blocker) { "blocked by session $($row.Blocker)" } else { 'no CPU or read progress' }
                Write-ShrinkLog ("worker {0} session ID {1} stuck ({2}) for >= {3}s: cancelling command." -f $workerId, $s.Spid, $why, $StuckWindowSeconds) 'WARN'
                try { $s.Command.Cancel() } catch {}
                $stuckState[$s.Spid].BlockerSince = $null
                $stuckState[$s.Spid].NoProgressSince = $null
            }
        }
        # Render the collected worker rows as one aligned table, using a single size unit chosen from
        # the largest allocation so the used/allocated columns never mix units across workers.
        $maxMb = 0.0
        foreach ($d in $statusData) { if ($null -ne $d.AllocMB -and [double]$d.AllocMB -gt $maxMb) { $maxMb = [double]$d.AllocMB } }
        $unit = Get-ShrinkSizeUnit -MaxMegabytes $maxMb
        $numFmt = '{0:N' + $unit.Decimals + '}'
        $usedHdr = "Used ($($unit.Name))"; $allocHdr = "Alloc ($($unit.Name))"
        $statusTable = foreach ($d in $statusData) {
            [ordered]@{
                Worker    = [string]$d.Worker
                SPID      = $(if ($null -ne $d.Spid) { [string]$d.Spid } else { '-' })
                File      = $(if ($d.FileId) { [string]$d.FileId } else { '-' })
                $usedHdr  = $(if ($null -ne $d.UsedMB) { $numFmt -f ([double]$d.UsedMB / $unit.PerMB) } else { '' })
                $allocHdr = $(if ($null -ne $d.AllocMB) { $numFmt -f ([double]$d.AllocMB / $unit.PerMB) } else { '' })
                '%Done'   = $(if ($null -ne $d.Pct) { [string]$d.Pct } else { '' })
                Elapsed   = $(if ($null -ne $d.ElapsedS) { Format-ShrinkDuration -TimeSpan ([TimeSpan]::FromSeconds($d.ElapsedS)) } else { '' })
                Increment = [string]$d.Increment
                Cmd       = [string]$d.Cmd
                Status    = [string]$d.Status
                dCPU      = [string]$d.DCpu
                dReads    = [string]$d.DReads
                dWrites   = [string]$d.DWrites
                Blocker   = $(if ($d.Blocker) { [string]$d.Blocker } else { '-' })
                Wait      = [string]$d.Wait
            }
        }
        Format-ShrinkTable -Rows @($statusTable) -RightAlign @('Worker', 'SPID', 'File', $usedHdr, $allocHdr, '%Done', 'Elapsed', 'Increment', 'dCPU', 'dReads', 'dWrites') |
            ForEach-Object { Write-ShrinkLog $_ }
        $tot = Get-ShrinkDatabaseTotals -Conn $control
        $dbUsedMb = $tot.Used; $dbAllocMb = $tot.Alloc
        [System.Threading.Monitor]::Enter($shared.Lock)
        try { $buckets = @($shared.Completed.Values | ForEach-Object { $_.Bucket }) } finally { [System.Threading.Monitor]::Exit($shared.Lock) }
        $c = Get-ShrinkBucketCounts -Buckets $buckets
        Write-ShrinkLog '---- database total ----'
        Format-ShrinkKeyValueTable -Rows (Get-ShrinkTotalsRows `
                -RunTime (Format-ShrinkDuration -TimeSpan $runClock.Elapsed) `
                -Used (Format-ShrinkSize $dbUsedMb) -Allocated (Format-ShrinkSize $dbAllocMb) -Counts $c) |
            ForEach-Object { Write-ShrinkLog $_ }
    }

    # Poll frequently so worker events (connects, file starts, retries, give-ups) surface
    # promptly, but run the heavier per-file status report only every StatusIntervalSeconds
    # (with the first one shortly after startup so progress shows without a long initial wait).
    $pollSeconds = [Math]::Max(1, [Math]::Min(2, $StatusIntervalSeconds))
    $nextReportAtS = [double][Math]::Min(15, $StatusIntervalSeconds)
    try {
        while ($true) {
            $evt = ''
            while ($shared.Events.TryDequeue([ref]$evt)) { Write-ShrinkLog $evt 'EVENT' }
            if ($ctrlCAsInput -and [Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq [ConsoleKey]::C -and ($k.Modifiers -band [ConsoleModifiers]::Control)) {
                    if (-not $shared.Stop) {
                        # First Ctrl+C: stop early but still report what each in-flight file achieved, just
                        # like the run time limit. Keep listening so a second press can be caught.
                        Write-ShrinkLog 'Ctrl+C received: stopping early and recording each in-flight file''s current state. Press Ctrl+C again to stop immediately.' 'WARN'
                        $shared.StopReason = 'Ctrl+C'
                        $shared.Stop = $true
                        foreach ($sess in $shared.Sessions.Values) { if ($sess.Command) { try { $sess.Command.Cancel() } catch {} } }
                    } else {
                        # Second Ctrl+C: don't wait to reassess (the server may be unresponsive); report the
                        # in-flight files as Interrupted. Cancel any measurement in progress, then restore the
                        # default handler so a further press can force-quit a truly wedged process.
                        Write-ShrinkLog 'Ctrl+C received again: stopping immediately; in-flight files are reported as Interrupted.' 'WARN'
                        $shared.Force = $true
                        foreach ($sess in $shared.Sessions.Values) { if ($sess.Command) { try { $sess.Command.Cancel() } catch {} } }
                        try { [Console]::TreatControlCAsInput = $prevTreatCtrlC } catch {}
                        $ctrlCAsInput = $false
                    }
                }
            }
            if ($runClock.Elapsed.TotalSeconds -ge $nextReportAtS) {
                # The status report reads through the control connection; if the server dropped it
                # (e.g. a restart), reopen it and skip just this report rather than failing the run.
                try {
                    $control = Get-ShrinkLiveControl $control
                    Write-StatusReport
                }
                catch {
                    Write-ShrinkLog ("Status report skipped (control connection issue): {0}" -f $_.Exception.Message.Split([Environment]::NewLine)[0]) 'WARN'
                    try { $control = Get-ShrinkLiveControl $control } catch { Write-ShrinkLog ("Control reconnect failed; will retry at the next report: {0}" -f $_.Exception.Message.Split([Environment]::NewLine)[0]) 'WARN' }
                }
                $nextReportAtS = $runClock.Elapsed.TotalSeconds + $StatusIntervalSeconds
            }
            if (-not ($workers | Where-Object { -not $_.Handle.IsCompleted })) { Write-ShrinkLog 'All workers finished.'; break }
            if ($null -ne $limitSeconds -and $runClock.Elapsed.TotalSeconds -ge $limitSeconds -and -not $shared.Stop) {
                Write-ShrinkLog 'Run time limit reached: stopping and recording each in-flight file''s current state.' 'WARN'
                $shared.StopReason = 'Timeout'
                $shared.Stop = $true
                foreach ($sess in $shared.Sessions.Values) { if ($sess.Command) { try { $sess.Command.Cancel() } catch {} } }
            }
            Start-Sleep -Seconds $pollSeconds
        }
    } finally {
        if ($ctrlCAsInput) { try { [Console]::TreatControlCAsInput = $prevTreatCtrlC } catch {} }
        foreach ($w in $workers) {
            try { $w.PS.EndInvoke($w.Handle) | Out-Null } catch { Write-ShrinkLog "Worker $($w.WorkerId) error: $($_.Exception.Message)" 'WARN' }
            $w.PS.Dispose()
        }
        $pool.Close(); $pool.Dispose()
        # Flush any worker events that arrived after the last poll, then write a single final summary.
        $evt = ''
        while ($shared.Events.TryDequeue([ref]$evt)) { Write-ShrinkLog $evt 'EVENT' }
        $elapsed = Format-ShrinkDuration -TimeSpan $runClock.Elapsed
        # The final totals need a live control connection; if the server dropped it (e.g. a restart),
        # try once to reopen, but never let that stop us from writing the outcome summary.
        $dbUsedMb = $null; $dbAllocMb = $null
        # After shrinking, re-check which data files still have at least MinReclaimMB of reclaimable
        # space. A file may have been shrunk only partly or skipped for reasons that are often transient
        # (it grew while being shrunk, or was blocked), and files can also become eligible during a long
        # run; in either case a later run can frequently reclaim more. This is advisory only.
        $remainingEligible = @()
        try {
            $control = Get-ShrinkLiveControl $control
            $tot = Get-ShrinkDatabaseTotals -Conn $control
            $dbUsedMb = $tot.Used; $dbAllocMb = $tot.Alloc
            $remainingEligible = @(Get-EligibleFiles -Conn $control | Where-Object { Test-ShrinkWorthwhile -AllocatedMB $_.AllocatedMB -UsedMB $_.UsedMB -FloorMB $floorMB -MinReclaimMB $minReclaimMB })
        } catch { Write-ShrinkLog ("Could not read final database totals: {0}" -f $_.Exception.Message.Split([Environment]::NewLine)[0]) 'WARN' }
        # Reconcile: any eligible file that never reached a terminal state (e.g. left unprocessed after
        # an unrecoverable outage, or never started) is recorded as NotProcessed, so the summary reflects
        # every eligible file instead of silently implying the run finished them all.
        [System.Threading.Monitor]::Enter($shared.Lock)
        try {
            foreach ($f in $shared.Files) {
                if (-not $shared.Completed.ContainsKey($f.FileId)) {
                    $shared.Completed[$f.FileId] = @{ Bucket = 'NotProcessed'; Reason = 'eligible but not processed before the run ended' }
                }
            }
        } finally { [System.Threading.Monitor]::Exit($shared.Lock) }
        $c = Get-ShrinkBucketCounts -Buckets @($shared.Completed.Values | ForEach-Object { $_.Bucket })
        Write-ShrinkLog '-------------------- summary --------------------'
        Format-ShrinkKeyValueTable -Rows (Get-ShrinkTotalsRows -RunTime $elapsed `
                -Used $(if ($null -ne $dbUsedMb) { Format-ShrinkSize $dbUsedMb } else { '(unavailable)' }) `
                -Allocated $(if ($null -ne $dbAllocMb) { Format-ShrinkSize $dbAllocMb } else { '(unavailable)' }) -Counts $c) |
            ForEach-Object { Write-ShrinkLog $_ }
        foreach ($r in $shared.Completed.GetEnumerator() | Sort-Object { [int]$_.Key }) { if ($r.Value.Reason) { Write-ShrinkLog ("  file {0} [{1}]: {2}" -f $r.Key, $r.Value.Bucket, $r.Value.Reason) } }
        if ($remainingEligible.Count -gt 0) {
            $reclRemainMb = [long]0
            foreach ($f in $remainingEligible) { $reclRemainMb += (Get-ShrinkReclaimableMB -AllocatedMB $f.AllocatedMB -UsedMB $f.UsedMB -FloorMB $floorMB) }
            Write-ShrinkLog ("{0} data file(s) still have reclaimable space ({1} total). A partial or skipped shrink can be due to transient conditions (such as concurrent growth or blocking), so running shrink again might reclaim more." -f $remainingEligible.Count, (Format-ShrinkSize $reclRemainMb))
        }
        Write-ShrinkLog '-------------------------------------------------'
        # Structured result for programmatic callers / tests (the log/console is unchanged).
        $runResult = [pscustomobject]@{
            Mode          = 'Shrink'
            Elapsed       = $elapsed
            StoppedBy     = $shared.StopReason
            DbUsedMB      = $dbUsedMb
            DbAllocatedMB = $dbAllocMb
            Counts        = $c
            EligibleRemaining = $remainingEligible.Count
            Files         = @($shared.Completed.GetEnumerator() | Sort-Object { [int]$_.Key } | ForEach-Object { [pscustomobject]@{ FileId = [int]$_.Key; Bucket = $_.Value.Bucket; Reason = $_.Value.Reason } })
        }
        try { $control.Close() } catch {}
        try { $control.Dispose() } catch {}
    }
    }
    catch {
        Write-ShrinkLog "Fatal error [$($_.Exception.GetType().Name)]: $($_.Exception.Message)" 'ERROR'
        throw
    }
    finally {
        # Safety net: make sure the control connection is closed on every exit path (report/return, a
        # pre-flight failure, or a fatal error), not just the normal monitor-loop shutdown.
        if ($control) { try { $control.Dispose() } catch {} }
    }
    if ($PassThru) { $runResult }
}

# ----- internal helper functions (used by Invoke-ShrinkDriver and the worker runspaces) -----

function New-ShrinkRetryProvider {
    <# .SYNOPSIS
      Build a Microsoft.Data.SqlClient connection-retry provider (exponential backoff with jitter)
      for transient connection-open failures, such as an Azure SQL restart or failover. This is a
      short, shallow inner retry that only smooths reopening; the caller's own retry loop remains
      the outer backstop for errors this provider's transient list does not cover. Returns $null
      when the driver predates configurable retry (Microsoft.Data.SqlClient earlier than 3.0). #>
    [CmdletBinding()]
    param(
        [int]$NumberOfTries = 5,
        [int]$DeltaSeconds = 4,
        [int]$MaxIntervalSeconds = 30
    )
    if (-not ('Microsoft.Data.SqlClient.SqlConfigurableRetryFactory' -as [type])) { return $null }
    $opt = [Microsoft.Data.SqlClient.SqlRetryLogicOption]::new()
    $opt.NumberOfTries = $NumberOfTries
    $opt.DeltaTime = [TimeSpan]::FromSeconds($DeltaSeconds)
    $opt.MaxTimeInterval = [TimeSpan]::FromSeconds($MaxIntervalSeconds)
    # Leave TransientErrors unset so the provider uses the driver's own maintained default list of
    # transient error numbers (Azure SQL restart/failover/throttling and transport drops). Our own
    # retry loop is a broad catch-all backstop for anything the default list happens to omit.
    [Microsoft.Data.SqlClient.SqlConfigurableRetryFactory]::CreateExponentialRetryProvider($opt)
}

function Open-ShrinkSqlConnection {
    <# .SYNOPSIS
      Open a SqlConnection from a connection-string builder, validating the server's certificate. The
      first attempt always validates the certificate; only if it fails and $AllowTrustServerCertificate
      is set does it retry once trusting the certificate. #>
    [CmdletBinding()][OutputType([Microsoft.Data.SqlClient.SqlConnection])]
    param(
        [Parameter(Mandatory)][Microsoft.Data.SqlClient.SqlConnectionStringBuilder]$Builder,
        [Microsoft.Data.SqlClient.SqlCredential]$Credential,
        [object]$RetryProvider,
        [bool]$AllowTrustServerCertificate
    )
    foreach ($trust in @($false, $true)) {
        if ($trust) { $Builder['TrustServerCertificate'] = $true } else { [void]$Builder.Remove('TrustServerCertificate') }
        $conn = [Microsoft.Data.SqlClient.SqlConnection]::new()
        $conn.ConnectionString = $Builder.ConnectionString
        if ($Credential) { $conn.Credential = $Credential }
        if ($RetryProvider) { $conn.RetryLogicProvider = $RetryProvider }
        try { $conn.Open(); return $conn }
        catch {
            try { $conn.Dispose() } catch {}
            # Surface the error unless a trusting retry is still allowed and untried.
            if ($trust -or -not $AllowTrustServerCertificate) { throw }
        }
    }
}

function Format-ShrinkSize {
    <# .SYNOPSIS Format a size given in MiB using an auto-selected binary unit (KiB, MiB, GiB, or TiB). #>
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory)][double]$Megabytes)
    if ($Megabytes -ge 1048576) { '{0:N1} TiB' -f ($Megabytes / 1048576) }
    elseif ($Megabytes -ge 1024) { '{0:N1} GiB' -f ($Megabytes / 1024) }
    elseif ($Megabytes -ge 1) { '{0:N1} MiB' -f $Megabytes }
    else { '{0:N0} KiB' -f ($Megabytes * 1024) }
}

function Get-ShrinkSizeUnit {
    <# .SYNOPSIS
      Choose a single binary unit (KiB, MiB, GiB, or TiB) appropriate for the largest size in a
      set, so a table can render every value in one consistent unit. Returns the unit name, the
      number of MiB per unit, and the decimal places to use. #>
    [CmdletBinding()][OutputType([hashtable])]
    param([Parameter(Mandatory)][double]$MaxMegabytes)
    if ($MaxMegabytes -ge 1048576) { @{ Name = 'TiB'; PerMB = 1048576.0; Decimals = 1 } }
    elseif ($MaxMegabytes -ge 1024) { @{ Name = 'GiB'; PerMB = 1024.0; Decimals = 1 } }
    elseif ($MaxMegabytes -ge 1) { @{ Name = 'MiB'; PerMB = 1.0; Decimals = 1 } }
    else { @{ Name = 'KiB'; PerMB = (1.0 / 1024.0); Decimals = 0 } }
}

function Format-ShrinkDuration {
    <# .SYNOPSIS Format a TimeSpan as a compact "Dd Hh Mm Ss" duration, omitting leading zero units. #>
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory)][TimeSpan]$TimeSpan)
    $parts = @()
    if ($TimeSpan.Days -gt 0) { $parts += '{0}d' -f $TimeSpan.Days }
    if ($parts.Count -gt 0 -or $TimeSpan.Hours -gt 0) { $parts += '{0}h' -f $TimeSpan.Hours }
    if ($parts.Count -gt 0 -or $TimeSpan.Minutes -gt 0) { $parts += '{0}m' -f $TimeSpan.Minutes }
    $parts += '{0}s' -f $TimeSpan.Seconds
    $parts -join ' '
}

function Format-ShrinkKeyValueTable {
    <# .SYNOPSIS Render ordered label/value pairs as aligned two-column rows (one string per row). #>
    [CmdletBinding()][OutputType([string[]])]
    param(
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Rows,
        [string]$Indent = '  '
    )
    $width = ($Rows.Keys | Measure-Object -Property Length -Maximum).Maximum
    foreach ($k in $Rows.Keys) { '{0}{1} : {2}' -f $Indent, ([string]$k).PadRight($width), $Rows[$k] }
}

function Format-ShrinkTable {
    <# .SYNOPSIS
      Render rows (each an [ordered] dictionary of column -> value) as an aligned fixed-width table
      with a header and separator. Columns whose names are listed in -RightAlign are right-justified;
      all others are left-justified. Returns one string per line (empty when there are no rows). #>
    [CmdletBinding()][OutputType([string[]])]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Rows,
        [string[]]$RightAlign = @()
    )
    if ($Rows.Count -eq 0) { return @() }
    $cols = @($Rows[0].Keys)
    $width = @{}
    foreach ($c in $cols) {
        $m = ([string]$c).Length
        foreach ($r in $Rows) { $len = ([string]$r[$c]).Length; if ($len -gt $m) { $m = $len } }
        $width[$c] = $m
    }
    $slots = for ($i = 0; $i -lt $cols.Count; $i++) {
        if ($cols[$i] -in $RightAlign) { "{$i,$($width[$cols[$i]])}" } else { "{$i,-$($width[$cols[$i]])}" }
    }
    $fmt = $slots -join '  '
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add(($fmt -f $cols))
    $lines.Add(($fmt -f @($cols | ForEach-Object { '-' * $width[$_] })))
    foreach ($r in $Rows) { $lines.Add(($fmt -f @($cols | ForEach-Object { [string]$r[$_] }))) }
    $lines.ToArray()
}

function Format-ShrinkFileReport {
    <# .SYNOPSIS
      Render a per-file shrink-potential table (File, Name, Used, Allocated, Reclaimable),
      sorted by reclaimable space descending and limited to the top N files. Returns one string
      per line, with a trailing note when files are omitted. #>
    [CmdletBinding()][OutputType([string[]])]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Files,
        [int]$TopN = 100
    )
    $sorted = @($Files | Sort-Object `
            @{ Expression = { [long]$_.ReclaimableMB }; Descending = $true }, `
            @{ Expression = { [int]$_.FileId }; Descending = $false })
    $shown = @($sorted | Select-Object -First $TopN)
    if ($shown.Count -eq 0) { return '(no data files found)' }

    # Pick one unit for the whole table (from the largest value) so sizes are comparable and never
    # mixed across rows; the chosen unit is shown in the column headers instead of on each cell.
    $maxMb = 0.0
    foreach ($f in $shown) {
        foreach ($v in @([double]$f.AllocatedMB, [double]$f.UsedMB, [double]$f.ReclaimableMB)) {
            if ($v -gt $maxMb) { $maxMb = $v }
        }
    }
    $unit = Get-ShrinkSizeUnit -MaxMegabytes $maxMb
    $numFmt = '{0:N' + $unit.Decimals + '}'
    $usedHdr = "Used ($($unit.Name))"
    $allocHdr = "Allocated ($($unit.Name))"
    $reclHdr = "Reclaimable ($($unit.Name))"

    $rows = foreach ($f in $shown) {
        [ordered]@{
            File      = [string]$f.FileId
            Name      = [string]$f.Name
            $usedHdr  = ($numFmt -f ([double]$f.UsedMB / $unit.PerMB))
            $allocHdr = ($numFmt -f ([double]$f.AllocatedMB / $unit.PerMB))
            $reclHdr  = ($numFmt -f ([double]$f.ReclaimableMB / $unit.PerMB))
            Eligible  = if ($f.IsEligible) { 'Yes' } else { 'No' }
        }
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    Format-ShrinkTable -Rows @($rows) -RightAlign @('File', $usedHdr, $allocHdr, $reclHdr) |
        ForEach-Object { $lines.Add($_) }
    $omitted = $sorted.Count - $shown.Count
    if ($omitted -gt 0) {
        $lines.Add(("... {0} other file(s) omitted; showing the top {1} by reclaimable space." -f $omitted, $TopN))
    }
    $lines.ToArray()
}

function Get-ShrinkSumMB {
    <# .SYNOPSIS Sum a numeric property over a (possibly empty) set of items, returning 0 when empty. #>
    [CmdletBinding()][OutputType([long])]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Items,
        [Parameter(Mandatory)][string]$Property
    )
    $m = $Items | Measure-Object -Property $Property -Sum
    [long]$(if ($m) { $m.Sum } else { 0 })
}

function Get-ShrinkEffectiveFloorMB {
    <# .SYNOPSIS The size (MiB) a file will not shrink below: the larger of its used pages and any target floor. #>
    [CmdletBinding()][OutputType([long])]
    param(
        [Parameter(Mandatory)][long]$UsedMB,
        [Nullable[long]]$FloorMB = $null
    )
    [Math]::Max($UsedMB, $(if ($null -ne $FloorMB) { [long]$FloorMB } else { [long]0 }))
}

function Test-ShrinkWorthwhile {
    <# .SYNOPSIS
      True if at least MinReclaimMB of space can be reclaimed from the file - that is, the unused space
      above its effective floor (the larger of its used pages and any target floor). #>
    [CmdletBinding()][OutputType([bool])]
    param(
        [Parameter(Mandatory)][long]$AllocatedMB,
        [Parameter(Mandatory)][long]$UsedMB,
        [Nullable[long]]$FloorMB = $null,
        [long]$MinReclaimMB = 100
    )
    if ($AllocatedMB -le 0) { return $false }
    ($AllocatedMB - (Get-ShrinkEffectiveFloorMB -UsedMB $UsedMB -FloorMB $FloorMB)) -ge $MinReclaimMB
}

function Get-ShrinkReclaimableMB {
    <# .SYNOPSIS
      Space (MiB) that could be reclaimed from a file: allocated minus its effective floor
      (the larger of its used pages and any target floor), never negative. #>
    [CmdletBinding()][OutputType([long])]
    param(
        [Parameter(Mandatory)][long]$AllocatedMB,
        [Parameter(Mandatory)][long]$UsedMB,
        [Nullable[long]]$FloorMB = $null
    )
    [long][Math]::Max(0, $AllocatedMB - (Get-ShrinkEffectiveFloorMB -UsedMB $UsedMB -FloorMB $FloorMB))
}

function Get-ShrinkBucketCounts {
    <# .SYNOPSIS Tally completed-file outcomes (bucket names) into the reporting counts. #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Buckets)
    [pscustomobject]@{
        Shrunk          = @($Buckets | Where-Object { $_ -eq 'Shrunk' }).Count
        Repacked        = @($Buckets | Where-Object { $_ -eq 'Repacked' }).Count
        PartlyShrunk    = @($Buckets | Where-Object { $_ -eq 'PartlyShrunk' }).Count
        AlreadyMinimal  = @($Buckets | Where-Object { $_ -eq 'AlreadyMinimal' }).Count
        AlreadyAtTarget = @($Buckets | Where-Object { $_ -eq 'AlreadyAtTarget' }).Count
        Grew            = @($Buckets | Where-Object { $_ -eq 'Grew' }).Count
        GaveUp          = @($Buckets | Where-Object { $_ -eq 'GaveUp' }).Count
        Interrupted     = @($Buckets | Where-Object { $_ -eq 'Interrupted' }).Count
        NotProcessed    = @($Buckets | Where-Object { $_ -eq 'NotProcessed' }).Count
    }
}

function Get-ShrinkTotalsRows {
    <# .SYNOPSIS Build the ordered label/value rows shared by the database-total and final-summary tables. #>
    [CmdletBinding()][OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][string]$RunTime,
        [Parameter(Mandatory)][string]$Used,
        [Parameter(Mandatory)][string]$Allocated,
        [Parameter(Mandatory)][pscustomobject]$Counts
    )
    [ordered]@{
        'Run time'           = $RunTime
        'Used'               = $Used
        'Allocated'          = $Allocated
        'Shrunk'             = $Counts.Shrunk
        'Repacked'           = $Counts.Repacked
        'Partly shrunk'      = $Counts.PartlyShrunk
        'Already at minimum' = $Counts.AlreadyMinimal
        'Already at target'  = $Counts.AlreadyAtTarget
        'Grew'               = $Counts.Grew
        'Gave up'            = $Counts.GaveUp
        'Interrupted'        = $Counts.Interrupted
        'Not processed'      = $Counts.NotProcessed
    }
}

function Get-ShrinkGaveUpBucket {
    <# .SYNOPSIS
      Classify a give-up outcome by the net change in allocated size since the worker took
      the file: PartlyShrunk (ended smaller), Grew (ended larger, e.g. other sessions added
      data faster than shrink could reclaim), or GaveUp (allocated size unchanged). #>
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory)][long]$StartAllocMB,
        [Parameter(Mandatory)][long]$FinalAllocMB
    )
    if ($FinalAllocMB -lt $StartAllocMB) { 'PartlyShrunk' }
    elseif ($FinalAllocMB -gt $StartAllocMB) { 'Grew' }
    else { 'GaveUp' }
}

function Get-ShrinkStopOutcome {
    <# .SYNOPSIS
      Classify a file's outcome when the run is stopped before the file finished. A forced quit
      (second Ctrl+C) is always Interrupted; otherwise the file is judged by its re-measured size:
      smaller than it started -> PartlyShrunk, larger -> Grew, unchanged -> Interrupted (no progress).
      StartAllocMB null (never measured) or FinalAllocMB null (could not re-measure) -> Interrupted.
      Pure/side-effect-free so the two-stage Ctrl+C and run-time-limit classification is unit-testable. #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Nullable[long]]$StartAllocMB,
        [Nullable[long]]$FinalAllocMB,
        [ValidateSet('Timeout', 'Ctrl+C')][string]$Cause = 'Ctrl+C',
        [switch]$Force
    )
    $causeText = if ($Cause -eq 'Timeout') { 'run time limit reached' } else { 'stopped early (Ctrl+C)' }
    if ($Force) {
        return [pscustomobject]@{ Bucket = 'Interrupted'; Reason = 'stopped immediately (Ctrl+C pressed twice); the final size was not measured' }
    }
    if ($null -eq $StartAllocMB) {
        return [pscustomobject]@{ Bucket = 'Interrupted'; Reason = "$causeText while this file was being shrunk" }
    }
    if ($null -eq $FinalAllocMB) {
        return [pscustomobject]@{ Bucket = 'Interrupted'; Reason = "$causeText; the final size could not be measured" }
    }
    if ([long]$FinalAllocMB -lt [long]$StartAllocMB) {
        return [pscustomobject]@{ Bucket = 'PartlyShrunk'; Reason = "$causeText; reduced from $(Format-ShrinkSize $StartAllocMB) to $(Format-ShrinkSize $FinalAllocMB)" }
    }
    if ([long]$FinalAllocMB -gt [long]$StartAllocMB) {
        return [pscustomobject]@{ Bucket = 'Grew'; Reason = "$causeText; grew from $(Format-ShrinkSize $StartAllocMB) to $(Format-ShrinkSize $FinalAllocMB) (other workloads adding data)" }
    }
    return [pscustomobject]@{ Bucket = 'Interrupted'; Reason = "$causeText before this file made measurable progress" }
}

function Test-ShrinkParameterSet {
    <# .SYNOPSIS Validate a parameter set; returns an array of error strings (empty = valid). #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param([Parameter(Mandatory)][hashtable]$Params)

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($Params['TruncateOnly'] -and $Params['NoTruncate']) {
        $errors.Add('TruncateOnly and NoTruncate cannot both be set (mutually exclusive).')
    }
    if ($Params['TruncateOnly'] -and $null -ne $Params['FileTargetSizeGiB']) {
        $errors.Add('FileTargetSizeGiB is not compatible with TruncateOnly (truncate-only does no data movement).')
    }
    if ($Params['AuthType'] -eq 'SQL') {
        if ([string]::IsNullOrWhiteSpace([string]$Params['SqlLogin'])) {
            $errors.Add('SqlLogin is required for SQL authentication.')
        }
        $pw = $Params['SqlPassword']
        if ($pw -and $pw -isnot [securestring]) {
            $errors.Add("SqlPassword must be a SecureString, not plain text. Create one with: `$pw = Read-Host -AsSecureString 'SQL password'; then pass -SqlPassword `$pw.")
        }
    }
    if ($Params['AuthType'] -notin @('EntraID', 'Windows', 'SQL')) {
        $errors.Add("Invalid AuthType '$($Params['AuthType'])' (expected EntraID, Windows, or SQL).")
    }
    if ($Params['AbortAfterWait'] -notin @('SELF', 'BLOCKERS')) {
        $errors.Add("Invalid AbortAfterWait '$($Params['AbortAfterWait'])' (expected SELF or BLOCKERS).")
    }
    , $errors.ToArray()
}

function Resolve-ShrinkLogPath {
    <# .SYNOPSIS
      Resolve a log file path to a full path and confirm its directory exists and the file is
      writable, creating the (empty) file if needed. Throws a clear error if the path is invalid,
      its directory is missing, the path is a directory, or it cannot be written. #>
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory)][string]$Path)

    # Resolve relative paths against the caller's PowerShell location ($PWD).
    try { $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path) }
    catch { throw "LogPath '$Path' is not a valid path: $($_.Exception.Message)" }

    $dir = [System.IO.Path]::GetDirectoryName($full)
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        throw "LogPath directory '$dir' does not exist. Create it or choose a different -LogPath."
    }
    if (Test-Path -LiteralPath $full -PathType Container) {
        throw "LogPath '$full' is a directory. Specify a file path for -LogPath."
    }
    try {
        $fs = [System.IO.File]::Open($full, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
        $fs.Dispose()
    } catch {
        throw "LogPath '$full' is not writable: $($_.Exception.Message)"
    }
    $full
}

function Get-ShrinkBackoffSeconds {
    <# .SYNOPSIS Exponential backoff with full jitter: uniform(0 .. min(Cap, Base*2^Attempt)). #>
    [CmdletBinding()][OutputType([double])]
    param(
        [Parameter(Mandatory)][int]$Attempt,
        [int]$BaseSec = 5,
        [int]$CapSec = 60,
        [System.Random]$Random
    )
    if (-not $Random) { $Random = [System.Random]::new() }
    $exp = [double]$BaseSec * [Math]::Pow(2, [Math]::Max(0, $Attempt))
    $cap = [Math]::Min([double]$CapSec, $exp)
    [Math]::Round($Random.NextDouble() * $cap, 2)
}

function Get-ShrinkNextTargetMB {
    <# .SYNOPSIS Next SHRINKFILE target (MB): one step below the current size, clamped to the floor and
       to a minimum of 1 (DBCC reads a target of 0 as "shrink to the file's creation size"). #>
    [CmdletBinding()][OutputType([long])]
    param(
        [Parameter(Mandatory)][long]$AllocatedMB,
        [Nullable[long]]$FloorMB = $null,
        [long]$StepMB = 20480
    )
    $floor = if ($null -ne $FloorMB) { [long]$FloorMB } else { [long]0 }
    $next = $AllocatedMB - $StepMB
    if ($next -lt $floor) { $next = $floor }
    # DBCC SHRINKFILE treats a target_size of 0 as "shrink to the file's creation size", which leaves
    # unused space unreclaimed (a file created at, say, 10 GiB never shrinks below 10 GiB). Never target
    # 0: 1 MB shrinks to the actual used-data size (SQL will not shrink a file past its used pages).
    if ($next -lt 1) { $next = 1 }
    [long]$next
}

function Select-ShrinkNextFile {
    <#
    .SYNOPSIS
      Pick the next file to shrink: the one with the most reclaimable space above its
      floor, skipping files already being shrunk by another session and files that have
      already reached a terminal state this run.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Files,
        [int[]]$OwnedFileIds = @(),
        [int[]]$ExcludedFileIds = @()
    )
    $cand = foreach ($f in $Files) {
        if ($f.FileId -in $OwnedFileIds) { continue }
        if ($f.FileId -in $ExcludedFileIds) { continue }
        if (([long]$f.AllocatedMB - [long]$f.UsedMB) -le 0) { continue }
        $floor = if ($null -ne $f.FloorMB) { [long]$f.FloorMB } else { [long]0 }
        if ([long]$f.AllocatedMB -le $floor) { continue }
        $f
    }
    if (-not $cand) { return $null }
    $cand |
        Sort-Object `
            @{ Expression = { Get-ShrinkReclaimableMB -AllocatedMB ([long]$_.AllocatedMB) -UsedMB ([long]$_.UsedMB) -FloorMB $_.FloorMB }; Descending = $true }, `
            @{ Expression = { [int]$_.FileId }; Descending = $false } |
        Select-Object -First 1
}

function Get-ShrinkDeltaWithReset {
    <# .SYNOPSIS Non-negative delta, detecting a counter reset (Current < Previous => skip). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][long]$Previous, [Parameter(Mandatory)][long]$Current)
    if ($Current -lt $Previous) {
        [pscustomobject]@{ IsReset = $true; Delta = $null }
    } else {
        [pscustomobject]@{ IsReset = $false; Delta = [long]($Current - $Previous) }
    }
}

function Update-ShrinkStuckState {
    <# .SYNOPSIS Update per-session stuck state. A worker is stuck when, for at least WindowSec, EITHER
       the same non-zero blocking session has persisted, OR neither CPU nor reads have advanced. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$State,
        [int]$Blocker = 0,
        [long]$Cpu = 0,
        [long]$Reads = 0,
        [double]$NowSeconds = ([System.Diagnostics.Stopwatch]::GetTimestamp() / [double][System.Diagnostics.Stopwatch]::Frequency),
        [int]$WindowSec = 300
    )
    # $NowSeconds is a monotonic seconds value (e.g. the run stopwatch's elapsed seconds), not wall
    # clock, so the elapsed-time comparisons below are immune to a clock change mid-run.
    # Blocker streak: how long the same non-zero blocking session has persisted. Cleared when there is
    # no blocker; restarted when the blocking session changes.
    if (-not $Blocker) {
        $State.BlockerSince = $null
    }
    elseif ($State.Blocker -ne $Blocker -or $null -eq $State.BlockerSince) {
        $State.BlockerSince = $NowSeconds
    }
    # No-progress streak: how long neither CPU nor reads have changed. Any change - including a
    # per-request counter reset, which signals a new step - counts as progress and restarts the streak.
    if ($State.Cpu -ne $Cpu -or $State.Reads -ne $Reads -or $null -eq $State.NoProgressSince) {
        $State.NoProgressSince = $NowSeconds
    }

    $blockerStuck = ($null -ne $State.BlockerSince) -and (($NowSeconds - [double]$State.BlockerSince) -ge $WindowSec)
    $noProgressStuck = ($null -ne $State.NoProgressSince) -and (($NowSeconds - [double]$State.NoProgressSince) -ge $WindowSec)
    $isStuck = [bool]($blockerStuck -or $noProgressStuck)

    $State.Blocker = $Blocker
    $State.Cpu = $Cpu
    $State.Reads = $Reads
    [pscustomobject]@{ IsStuck = $isStuck; BlockerStuck = [bool]$blockerStuck; NoProgressStuck = [bool]$noProgressStuck }
}

function New-ShrinkCommandText {
    <# .SYNOPSIS Build the DBCC SHRINKFILE T-SQL for one file. #>
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory)][int]$FileId,
        [Nullable[long]]$TargetMB = $null,
        [switch]$TruncateOnly,
        [switch]$NoTruncate,
        [switch]$WaitAtLowPriority,
        [ValidateSet('SELF', 'BLOCKERS')][string]$AbortAfterWait = 'SELF'
    )
    if ($TruncateOnly -and $NoTruncate) { throw 'TruncateOnly and NoTruncate are mutually exclusive.' }
    $inner =
        if ($TruncateOnly) { "$FileId, TRUNCATEONLY" }
        elseif ($null -ne $TargetMB) {
            if ($NoTruncate) { "$FileId, $TargetMB, NOTRUNCATE" } else { "$FileId, $TargetMB" }
        }
        else { "$FileId" }
    $withParts = [System.Collections.Generic.List[string]]::new()
    if ($WaitAtLowPriority) { $withParts.Add("WAIT_AT_LOW_PRIORITY (ABORT_AFTER_WAIT = $AbortAfterWait)") }
    $withParts.Add('NO_INFOMSGS')
    "DBCC SHRINKFILE ($inner) WITH $($withParts -join ', ')"
}
