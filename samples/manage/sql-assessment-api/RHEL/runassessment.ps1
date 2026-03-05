[CmdletBinding()] param ()

$Error.Clear()

# Create output directory if not exists

$outDir = '/var/opt/mssql/log/assessments'
if (-not ( Test-Path $outDir )) { mkdir $outDir }
$outPath = Join-Path $outDir 'assessment-latest'

$errorPath = Join-Path $outDir 'assessment-latest-errors'
if( Test-Path $errorPath ) { remove-item $errorPath }

function ConvertTo-LogOutput {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $input
    )
    process {
        switch($input){
            { $_ -is [System.Management.Automation.WarningRecord] }{
                $result = @{
                    'TimeStamp' = $(Get-Date).ToString("O");
                    'Warning'   = $_.Message
                }
            }
            default {
                $result = @{
                    'TimeStamp'      = $input.TimeStamp;
                    'Severity'       = $input.Severity;
                    'TargetType'     = $input.TargetType;
                    'ServerName'     = $serverName;
                    'HostName'       = $hostName;
                    'TargetName'     = $input.TargetObject.Name;
                    'TargetPath'     = $input.TargetPath;
                    'CheckId'        = $input.Check.Id;
                    'CheckName'      = $input.Check.DisplayName;
                    'Message'        = $input.Message;
                    'RulesetName'    = $input.Check.OriginName;
                    'RulesetVersion' = $input.Check.OriginVersion.ToString();
                    'HelpLink'       = $input.HelpLink
                }

                if ( $input.TargetType -eq 'Database') {
                    $result['AvailabilityGroup'] = $input.TargetObject.AvailabilityGroupName
                }
            }
        }

        $result
    }
}

function Get-TargetsRecursive {

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true)]
        [Microsoft.SqlServer.Management.Smo.Server] $server
    )

    $server
    $server.Databases
}

function Get-ConfSetting{
    [CmdletBinding()]
    param (
        $confFile,
        $section,
        $name,
        $defaultValue=$null
    )

    $inSection = $false

    switch -regex -file $confFile{
        "^\s*\[\s*(.+?)\s*\]"{
            $inSection = $matches[1] -eq $section
        }
        "^\s*$($name)\s*=\s*(.+?)\s*$"{
            if($inSection){
                return $matches[1]
            }
        }
    }

    return $defaultValue
}

try {

    Write-Verbose "Acquiring credentials"

    $login, $pwd    = Get-Content '/var/opt/mssql/secrets/assessment' -Encoding UTF8NoBOM -TotalCount 2
    $securePassword = ConvertTo-SecureString $pwd -AsPlainText -Force
    $credential     = New-Object System.Management.Automation.PSCredential ($login, $securePassword)

    Write-Verbose "Acquired credentials"

    $serverInstance = '.'

    if(Test-Path /var/opt/mssql/mssql.conf) {
        $port = Get-ConfSetting /var/opt/mssql/mssql.conf network tcpport


        if(-not [string]::IsNullOrWhiteSpace($port)) {
            Write-Verbose "Using port $($port)"
            $serverInstance = "$($serverInstance),$($port)"
        }
    }

    $serverName = (Invoke-SqlCmd -ServerInstance $serverInstance -Credential $credential -Query "SELECT @@SERVERNAME")[0]
    $hostName   = (Invoke-SqlCmd -ServerInstance $serverInstance -Credential $credential -Query "SELECT HOST_NAME()")[0]

    # Invoke assessment and store results.
    # Replace 'ConvertTo-Json' with 'ConvertTo-Csv' to change output format.
    # Available output formats: JSON, CSV, XML.
    # Encoding parameter is optional.

    Get-SqlInstance -ServerInstance $serverInstance -Credential $credential -ErrorAction Stop
    | Get-TargetsRecursive
    | %{ Write-Verbose "Invoke assessment on $($_.Urn)"; $_ }
    | Invoke-SqlAssessment 3>&1
    | ConvertTo-LogOutput
    | ConvertTo-Json -AsArray
    | Set-Content $outPath -Encoding UTF8NoBOM
}
finally {

    Write-Verbose "Error count: $($Error.Count)"

    if ($Error) {
        $Error
        | ForEach-Object { @{ 'TimeStamp' = $(Get-Date).ToString("O"); 'Message' = $_.ToString() } }
        | ConvertTo-Json -AsArray
        | Set-Content $errorPath -Encoding UTF8NoBOM
    }
}