

# This script checks if SQL Server is installed on Windows

    [string] $SqlInstalled = ""
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'
    if (Test-Path $regPath) {
        $inst = (get-itemproperty $regPath).InstalledInstances
        #$SqlInstalled = ($inst.Count -gt 0)
        foreach ($i in $inst) {
            # Read registry data
            #
            $p = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$i
            $setupValues = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup")
            $edition = ($setupValues.Edition -split ' ')[0]
            $version = ($setupValues.Version)
            $SqlInstalled =  $version, $edition -join ':'
        }
    }
    Write-Output $SqlInstalled
