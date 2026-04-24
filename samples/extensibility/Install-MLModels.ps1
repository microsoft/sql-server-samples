#
# Install-MLModels.ps1
# Copyright (C) Microsoft.  All rights reserved.
#

# See: https://learn.microsoft.com/sql/machine-learning/install/sql-pretrained-models-install

# Verify script is being run with elevated privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "This script must be run as Administrator"
    Exit 1
}

class SqlInstance
{
    static $Languages = @{`
        'R' = @{`
            'ModelsPath' = 'library\MicrosoftML\mxLibs\x64';`
            'SharedKey' = 'sql_shared_mr';`
            'DllName' = 'MR';`
            'ConfigNode' = 'mrs' };`
        'Python' = @{`
            'ModelsPath' = 'Lib\site-packages\microsoftml\mxLibs';`
            'SharedKey' = 'sql_shared_mpy';`
            'DllName' = 'MPY';`
            'ConfigNode' = 'mpy' }}

    [bool]$IsShared
    [Version]$MlmVersion
    [Version]$MlsVersion
    [string]$Name
    [string]$RootPath
    [string]$RSetupPath
    [string]$SqlVersion

    #
    # Returns SqlInstance or $null if an error occurred
    #
    [SqlInstance] static Create($isShared, $instanceName, $sqlVersion)
    {
        $sqlInstance = [SqlInstance]::new()

        $sqlInstance.IsShared = $isShared
        $sqlInstance.Name = $instanceName
        $sqlInstance.SqlVersion = $sqlVersion
        $sqlVersionName = ConvertSqlVersionToName( $sqlVersion )

        if( [string]::IsNullOrEmpty($sqlVersionName) ){
            Write-Warning "Sql name not found: instance name= $($instanceName), sql version=$($sqlVersion)"
            return $null
        }
        
        if ($sqlInstance.IsShared)
        {
            $found = $false   
            foreach ($language in [SqlInstance]::Languages.Values)
            {
                $sharedRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlVersion\$($language.SharedKey)"
                $sharedKey = Get-ItemProperty -Path $sharedRegPath -ErrorAction "Ignore"

                if ($sharedKey -ne $null)
                {
                    $sqlInstance.RootPath = (Get-Item($sharedKey.Path)).Parent.FullName
                    $sqlInstance.RSetupPath = "$($sqlInstance.RootPath)\Setup Bootstrap\{0}\x64\RSetup.exe" -f $sqlVersionName
                    $found = $true
                    break
                }
            }
            if(!$found)
            {
                return $null
            }
        }
        else
        {
            $setupRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceName\Setup"
            $sqlInstance.RootPath = (Get-Item (Get-ItemProperty -Path $setupRegPath -ErrorAction "Ignore").SQLPath).Parent.FullName
            $sqlInstance.RSetupPath = "{0}{1}\x64\RSetup.exe" -f`
                (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlVersion\Bootstrap" -ErrorAction "Ignore").BootstrapDir,`
                $sqlVersionName
        }

        # Set MLS version
        try
        {
            $bindingPath = Join-Path $sqlInstance.GetLanguageFolder("R") ".sqlbindr.ini"

            if ((Test-Path $bindingPath) -and ((Get-Item -Force $bindingPath).Length -gt 0))
            {
                $sqlInstance.MlsVersion = Get-Content $bindingPath
                $sqlInstance.RSetupPath = Join-Path (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\R Server').Path "Setup\rsetup.exe"
            }
            else
            {
                # Get MLS version from XML resource
                foreach ($language in [SqlInstance]::Languages.Values)
                {
                    $dllName = if ($sqlInstance.IsShared) {"S$($language.DllName)Dll"} else {"I$($language.DllName)Dll"}
                    $dllPath = if ($sqlInstance.IsShared) {"Shared\$dllName.dll"} else {"MSSQL\Binn\$dllName.dll"}
                    $dllPath = Join-Path $sqlInstance.RootPath $dllPath

                    if (Test-Path $dllPath)
                    {
                        $assembly = [System.Reflection.Assembly]::LoadFrom($dllPath)
                        $doc = New-Object System.Xml.XmlDocument
                        $doc.Load($assembly.GetManifestResourceStream("$dllName.$dllName.xml"))
                        $sqlInstance.MlsVersion = $doc.SelectSingleNode("/ConfigurationData/$($language.ConfigNode)").InnerText
                        break
                    }
                }
            }
        }
        catch
        {
            # Ignore exceptions
        }

        # check RSetup.exe exists
        if (($sqlInstance.RSetupPath -eq $null) -or !(Test-Path -Path $sqlInstance.RSetupPath -PathType Leaf))
        {
            Write-Warning "RSetup.exe not found for instance name= $($instanceName), sql version=$($sqlVersion)"
            return $null
        }

        # Map MLS version to MLM version
        if ($sqlInstance.MlsVersion.ToString(3) -eq "9.2.0")
        {
            $sqlInstance.MlmVersion = "9.2.0.24"
        }
        elseif ($sqlInstance.MlsVersion.ToString(3) -eq "9.2.1"`
            -or $sqlInstance.MlsVersion.ToString(3) -eq "9.3.0"`
            -or $sqlInstance.MlsVersion.ToString(3) -eq "9.4.1"`
            -or $sqlInstance.MlsVersion.ToString(3) -eq "9.4.7")
        {
            $sqlInstance.MlmVersion = $sqlInstance.MlsVersion.ToString(3)
        }
        else
        {
            $sqlInstance.MlmVersion = $sqlInstance.MlsVersion
        }

        return $sqlInstance
    }


    [string] GetLanguageFolder($language)
    {
        $languageFolder = $null

        if ([SqlInstance]::Languages.ContainsKey($language))
        {
            if ($this.IsShared)
            {
                $languageFolder = Join-Path $this.RootPath "$($language)_SERVER".ToUpper()
            }
            else
            {
                $languageFolder = Join-Path $this.RootPath "$($language)_SERVICES".ToUpper()
            }
        }

        return $languageFolder
    }
}

#
# Retursn sql version name or $null if name was not found
#
function ConvertSqlVersionToName($sqlVersion)
{
    $sqlVersionName = $null

    foreach ($sqlKey in (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlVersion" -ErrorAction "Ignore").PSChildName)
    {
        try
        {
            if ($sqlKey -imatch "^SQL(Server)?\d+$")
            {
                $sqlVersionName = $sqlKey
                break
            }
            #example: SQL2019CTP3.0
            if ($sqlKey -imatch "^SQL?\d{4}CTP\d+.\d+$")
            {
                $sqlVersionName = $sqlKey
                break
            }
        }
        catch
        {
            # Ignore exceptions
        }
    }

    return $sqlVersionName
}

#
# Returns number of instances found and hash table with successfully parsed instances
#
function GetSqlInstances()
{
    $sqlInstances = @{}
    
    # Handle shared installs
    foreach ($sqlVersion in (Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' -ErrorAction "Ignore").PSChildName)
    {
        try
        {
            $name = ConvertSqlVersionToName($sqlVersion)
            if( ![string]::IsNullOrEmpty($name))
            {
                $sqlInstance = [SqlInstance]::Create($true, "SHARED_{0}" -f $name.ToUpper(), $sqlVersion)
                
                if ( ($sqlInstance -ne $null) -and ($sqlInstance.MlmVersion -ne $null))
                {
                    $sqlInstances[$sqlInstance.Name] = $sqlInstance
                }
            }
        }
        catch
        {
            # Ignore exceptions
        }
    }

    # Handle per-instance installs
    foreach ($sqlKey in (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -ErrorAction "Ignore").PSObject.Properties)
    {
        try
        {
            $versionRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($sqlKey.Value)\MSSQLServer\CurrentVersion"
            $sqlVersion = (Get-ItemProperty -Path $versionRegPath -ErrorAction "Ignore").CurrentVersion -replace '^(\d+)\.(\d).*', '${1}0'

            if( ![string]::IsNullOrEmpty($sqlVersion) )
            {
                $sqlInstance = [SqlInstance]::Create($false, $sqlKey.Value, $sqlVersion)

                if (($sqlInstance -ne $null) -and ($sqlInstance.MlmVersion -ne $null))
                {
                    $sqlInstances[$sqlKey.Name] = $sqlInstance
                }
            }
        }
        catch
        {
            # Ignore exceptions
        }
    }

    return $sqlInstances
}

# Handle command-line arguments
if ($Args -ne $null -and $Args.Length -gt 0)
{
    $sqlInstances = GetSqlInstances

    if( $sqlInstances.Count -eq 0){
        Write-Host "INFO: no SQL Server instances identified for model installation"
        Exit 1
    }

    # Handle all instances
    foreach ($arg in $Args)
    {
        if ($sqlInstances.ContainsKey($arg))
        {
            $sqlInstance = $sqlInstances[$arg]

            Write-Host "INFO: processing instance $($sqlInstance.Name)"

            foreach ($language in [SqlInstance]::Languages.Keys)
            {
                $languageFolder = $sqlInstance.GetLanguageFolder($language)
                if (Test-Path $languageFolder)
                {
                    $modelsPath = [SqlInstance]::Languages[$language].ModelsPath
                    $installDir = Join-Path $languageFolder $modelsPath
                    $rsetupArgs = "/component MLM /version $($sqlInstance.MlmVersion) /language 1033 /destdir `"$installDir`""

                    # Verify models version
                    Write-Host "`tVerifying $language models [$($sqlInstance.MlmVersion)]"
                    &$sqlInstance.RSetupPath "/checkurl $rsetupArgs" 2>&1 > $null
                    if ($lastexitcode -eq -1 -or $lastexitcode -eq 2)
                    {
                        Write-Warning "MLS version $($sqlInstance.MlmVersion) not supported"
                        break
                    }
                    elseif ($lastexitcode -gt 10000)
                    {
                        Write-Warning "Error downloading models [https://go.microsoft.com/fwlink/?LinkId=$lastexitcode&clcid=1033]"
                        break
                    }
                    elseif ($lastexitcode -ne 0)
                    {
                        Write-Warning "rsetup.exe exited with $lastexitcode"
                        break
                    }

                    # Download models, if not already cached
                    &$sqlInstance.RSetupPath "/checkcache $rsetupArgs" 2>&1 > $null
                    if ($lastexitcode -ne 0)
                    {
                        Write-Host "`tDownloading $language models [$Env:TEMP]"
                        &$sqlInstance.RSetupPath "/download $rsetupArgs" 2>&1 > $null

                        if ($lastexitcode -gt 10000)
                        {
                            Write-Warning "Error downloading models [https://go.microsoft.com/fwlink/?LinkId=$lastexitcode&clcid=1033]"
                            break
                        }
                        if ($lastexitcode -ne 0)
                        {
                            Write-Warning "rsetup.exe exited with $lastexitcode"
                            break
                        }
                    }

                    # Install models
                    Write-Host "`tInstalling $language models [$installDir]"
                    &$sqlInstance.RSetupPath "/install $rsetupArgs" 2>&1 > $null
                    if ($lastexitcode -eq 0)
                    {
                        Write-Host "SUCCESS installed $language for $($sqlInstance.Name)"
                    }
                    else
                    {
                        Write-Warning "rsetup.exe failed and exited with $lastexitcode for $language and $($sqlInstance.Name)"
                        break
                    }
                }
            }
        }
        else
        {
            Write-Warning "$($arg): invalid instance"
        }
    }
}
else
{
    Write-Host
    Write-Host "USAGE: Install-MLModels.ps1 <INSTANCE> [<INSTANCE> ...]"
 
    $sqlInstances = GetSqlInstances

    if( $sqlInstances.Count -eq 0)
    {
        Write-Host "NOTE: no SQL Server instances identified for model installation"
        Exit 1
    }

    Write-Host
    Write-Host "Available instances:"

    # Display available instances
    foreach ($instanceName in $sqlInstances.Keys | Sort-Object)
    {
        $sqlInstance = $sqlInstances[$instanceName]
        Write-Host
        Write-Host "`tInstance=$($instanceName)"
        Write-Host "`tIsShared=$($sqlInstance.IsShared)"
        Write-Host "`tMlmVersion=$($sqlInstance.MlmVersion)"
        Write-Host "`tMlsVersion=$($sqlInstance.MlsVersion)"
        Write-Host "`tRootPath=$($sqlInstance.RootPath)"
        Write-Host "`tRSetupPath=$($sqlInstance.RSetupPath)"
        Write-Host "`tSqlVersion=$($sqlInstance.SqlVersion)"
        Write-Host "`tSqlVersionName=$(ConvertSqlVersionToName($sqlInstance.SqlVersion))"
    }
}

# SIG # Begin signature block
# MIIjigYJKoZIhvcNAQcCoIIjezCCI3cCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCOTihGgHRUMJIw
# J5dFR3HXpebAuyRhtn6jmFBEPnttOKCCDYUwggYDMIID66ADAgECAhMzAAABUptA
# n1BWmXWIAAAAAAFSMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTkwNTAyMjEzNzQ2WhcNMjAwNTAyMjEzNzQ2WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCxp4nT9qfu9O10iJyewYXHlN+WEh79Noor9nhM6enUNbCbhX9vS+8c/3eIVazS
# YnVBTqLzW7xWN1bCcItDbsEzKEE2BswSun7J9xCaLwcGHKFr+qWUlz7hh9RcmjYS
# kOGNybOfrgj3sm0DStoK8ljwEyUVeRfMHx9E/7Ca/OEq2cXBT3L0fVnlEkfal310
# EFCLDo2BrE35NGRjG+/nnZiqKqEh5lWNk33JV8/I0fIcUKrLEmUGrv0CgC7w2cjm
# bBhBIJ+0KzSnSWingXol/3iUdBBy4QQNH767kYGunJeY08RjHMIgjJCdAoEM+2mX
# v1phaV7j+M3dNzZ/cdsz3oDfAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU3f8Aw1sW72WcJ2bo/QSYGzVrRYcw
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzQ1NDEzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AJTwROaHvogXgixWjyjvLfiRgqI2QK8GoG23eqAgNjX7V/WdUWBbs0aIC3k49cd0
# zdq+JJImixcX6UOTpz2LZPFSh23l0/Mo35wG7JXUxgO0U+5drbQht5xoMl1n7/TQ
# 4iKcmAYSAPxTq5lFnoV2+fAeljVA7O43szjs7LR09D0wFHwzZco/iE8Hlakl23ZT
# 7FnB5AfU2hwfv87y3q3a5qFiugSykILpK0/vqnlEVB0KAdQVzYULQ/U4eFEjnis3
# Js9UrAvtIhIs26445Rj3UP6U4GgOjgQonlRA+mDlsh78wFSGbASIvK+fkONUhvj8
# B8ZHNn4TFfnct+a0ZueY4f6aRPxr8beNSUKn7QW/FQmn422bE7KfnqWncsH7vbNh
# G929prVHPsaa7J22i9wyHj7m0oATXJ+YjfyoEAtd5/NyIYaE4Uu0j1EhuYUo5VaJ
# JnMaTER0qX8+/YZRWrFN/heps41XNVjiAawpbAa0fUa3R9RNBjPiBnM0gvNPorM4
# dsV2VJ8GluIQOrJlOvuCrOYDGirGnadOmQ21wPBoGFCWpK56PxzliKsy5NNmAXcE
# x7Qb9vUjY1WlYtrdwOXTpxN4slzIht69BaZlLIjLVWwqIfuNrhHKNDM9K+v7vgrI
# bf7l5/665g0gjQCDCN6Q5sxuttTAEKtJeS/pkpI+DbZ/MIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCFVswghVXAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAFSm0CfUFaZdYgAAAAA
# AVIwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG3G
# 7RvsqFwz7WY6U4HOPqdKK3BPgFwYBSdAqzbXoj3uMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAGyMo1lNn2g9GCbLVrzD8KtHpnboaxDtKsqdu
# gIV6UjEl376n/D7+8zivlU+eSb1/H5hrorYzss2c0DJaZQG3wVjHzBuB/gmQHTig
# RYTLqb9fYqmzIaPt0hPFyRDSRU0vbicr8b8bmIC2BSPZdkwAWWvXfgTtsoa+ay8N
# G4DqDUJsGOkVLpPHQe0ixaH58OGRdFeQVN7XCDI5N+nM1V9LdxEy9HjCwNn8UBcE
# NjDz9R+nUCqIfdwdcAiEuChu2iCIljSGI2WC9cnsE/fJSit2s7blZ9+tMwR9A9Ds
# KsjD358pOzVBUQxFb9T+oaSBHxOeK7wdIK9LimSHzr75zkbxGKGCEuUwghLhBgor
# BgEEAYI3AwMBMYIS0TCCEs0GCSqGSIb3DQEHAqCCEr4wghK6AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFRBgsqhkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCDVLWm2KCM2EapNQd+shZsDvjT3+xGk9ZHM
# X7U16MZmPwIGXPEIIccdGBMyMDE5MDcxNjIzNTEwNy40MTFaMASAAgH0oIHQpIHN
# MIHKMQswCQYDVQQGEwJVUzELMAkGA1UECBMCV0ExEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9z
# b2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjpFMDQxLTRCRUUtRkE3RTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgc2VydmljZaCCDjwwggTxMIID2aADAgECAhMzAAAA1p5lgY4NGKM7AAAA
# AADWMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTE4MDgyMzIwMjY0OVoXDTE5MTEyMzIwMjY0OVowgcoxCzAJBgNVBAYTAlVT
# MQswCQYDVQQIEwJXQTEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVy
# YXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkUwNDEtNEJF
# RS1GQTdFMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBzZXJ2aWNlMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1c/AXoWbAgfvaGmvL/sJ4BCI
# UKntNpiAOe5phUnhNPuCPMQDYTo+DAc1fctJaTqds4EBHniBT95Rm6fa1ejs3AsP
# k7xUbBkjxmC1PAM7g3UEaPLDW8CZfmvx8A0UvkOUBuWkqvqjFrVawUX/hGbmJSC2
# ljjsprizJmgSfjWnTHkdAj+yhiVeYcAehNOMsp1R6ctphRDwE+Kfj9sAarA3jxHV
# OjG7WxQvIBXDgYSezQUEtX80U/HnMTLi+tD3W0CAvfX72jOfpQp9fUg8Jh8WiGzl
# l02sNhicmM3gV4K4kPCaTNVjZyh8kcyi765Ofd3IJJUg3NDxoPIGADjWOjTbiQID
# AQABo4IBGzCCARcwHQYDVR0OBBYEFGdUMJPgSTEafvZOFxynETg3j4j4MB8GA1Ud
# IwQYMBaAFNVjOlyKMZDzQ3t8RhvFM2hahW1VMFYGA1UdHwRPME0wS6BJoEeGRWh0
# dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1RpbVN0
# YVBDQV8yMDEwLTA3LTAxLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKG
# Pmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljVGltU3RhUENB
# XzIwMTAtMDctMDEuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUH
# AwgwDQYJKoZIhvcNAQELBQADggEBAE/ShYCJm+Wlw+CRtcUt/ma3+rn0rliEPXG2
# cBw3faMZjaJTfs3S9WPw8jVsYggVBu9exGJigWimWxY/9DR+p21tB+XwG8iTQfiw
# ACWKiLGjDu4DfwhX54v/yCAVTsAi+bxFolbivR067fz0NHwuZAubqdt4a3K2+Ahn
# 8csAJmFzkF+c8tLTgKFuit0zpnBIIZc591NOoK6vYSn+Be0rtgJhjeFeiZB2hpHo
# CvDt62eyXLJs6JIleKNXEcGhNjpMlT6bG5+r2VXvx0EscTTaAVYwoE6L83VAgNAa
# Eh/k+1zum8IbVNyes5I3/t4WPUWFx8R6Mjfi+2uWKdCGQI+8Jr8wggZxMIIEWaAD
# AgECAgphCYEqAAAAAAACMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBD
# ZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3MDEyMTM2NTVaFw0yNTA3
# MDEyMTQ2NTVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcRijog7PwTl/X6f2mUa3RUENWl
# CgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AVUycEMR9BGxqVHc4JE458YTBZsTBED/Fg
# iIRUQwzXTbg4CLNC3ZOs1nMwVyaCo0UN0Or1R4HNvyRgMlhgRvJYR4YyhB50YWeR
# X4FUsc+TTJLBxKZd0WETbijGGvmGgLvfYfxGwScdJGcSchohiq9LZIlQYrFd/Xcf
# PfBXday9ikJNQFHRD5wGPmd/9WbAA5ZEfu/QS/1u5ZrKsajyeioKMfDaTgaRtogI
# Neh4HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJRF1eFpwBBU8iTQIDAQABo4IB
# 5jCCAeIwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNVjOlyKMZDzQ3t8RhvF
# M2hahW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAP
# BgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjE
# MFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kv
# Y3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEF
# BQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGgBgNVHSABAf8E
# gZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggrBgEFBQcC
# AjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBtAGUA
# bgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aIUQ3ixuCYP4FxAz2do6Ehb7Pr
# psz1Mb7PBeKp/vpXbRkws8LFZslq3/Xn8Hi9x6ieJeP5vO1rVFcIK1GCRBL7uVOM
# zPRgEop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMivv3/Gf/I3fVo/HPKZeUqRUgCv
# OA8X9S95gWXZqbVr5MfO9sp6AG9LMEQkIjzP7QOllo9ZKby2/QThcJ8ySif9Va8v
# /rbljjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbiOewZSnFjnXshbcOco6I8+n99
# lmqQeKZt0uGc+R38ONiU9MalCpaGpL2eGq4EQoO4tYCbIjggtSXlZOz39L9+Y1kl
# D3ouOVd2onGqBooPiRa6YacRy5rYDkeagMXQzafQ732D8OE7cQnfXXSYIghh2rBQ
# Hm+98eEA3+cxB6STOvdlR3jo+KhIq/fecn5ha293qYHLpwmsObvsxsvYgrRyzR30
# uIUBHoD7G4kqVDmyW9rIDVWZeodzOwjmmC3qjeAzLhIp9cAvVCch98isTtoouLGp
# 25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99je/WZii8bxyGvWbWu3EQ8l1Bx16HS
# xVXjad5XwdHeMMD9zOZN+w2/XU/pnR4ZOC+8z1gFLu8NoFA12u8JJxzVs341Hgi6
# 2jbb01+P3nSISRKhggLOMIICNwIBATCB+KGB0KSBzTCByjELMAkGA1UEBhMCVVMx
# CzAJBgNVBAgTAldBMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTA0MS00QkVF
# LUZBN0UxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2WiIwoB
# ATAHBgUrDgMCGgMVAA9UX0q/L+thMJX0rozPt72QIBXRoIGDMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQACBQDg2NPEMCIY
# DzIwMTkwNzE3MDY1MjUyWhgPMjAxOTA3MTgwNjUyNTJaMHcwPQYKKwYBBAGEWQoE
# ATEvMC0wCgIFAODY08QCAQAwCgIBAAICIjQCAf8wBwIBAAICEYQwCgIFAODaJUQC
# AQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEK
# MAgCAQACAwGGoDANBgkqhkiG9w0BAQUFAAOBgQBlNpEdpWGf/B83X8hAVPxRTgW4
# 0prA9h6EG/xUWfp2c40h4vr0I2ee2oPbLNa9PTdTPO0deSBDcwM/J1lV7XV/5TgI
# AxLLJgfSHdaIrZmiV38CZyd2vCQP6beG2TydK/aHkZpIApUQY54kQyB9X4QW5uPh
# lis3qUZwulqZ4VaICjGCAw0wggMJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAAA1p5lgY4NGKM7AAAAAADWMA0GCWCGSAFlAwQCAQUAoIIB
# SjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIP5z
# azPb5aBR/KZQlipF+nKTJNp041jk7Yld+TnbBe99MIH6BgsqhkiG9w0BCRACLzGB
# 6jCB5zCB5DCBvQQgDKcXGy85Pqmxmt5kRTcsOqGjceOxduVb/tGYJy6USM4wgZgw
# gYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAANaeZYGODRij
# OwAAAAAA1jAiBCBsua44ho7AmDyDQPtF5fHr6CZ0JRmATzJfI/y++JB4GzANBgkq
# hkiG9w0BAQsFAASCAQCBHgNjNO2+pFexw7gNQkDtrTM/I0APnvHsVOXLFSVTSj5P
# HMrq+jR+IBnm8WCP9rRij/XZ2d/yM//JAzajALNk0mX2G6xuJx56xX8r2Q6Xvns3
# a2v6a31u2bA+jaBWUK5089uIoLARpDOIlibuY0HSWavr0TntPL4c9oj5ZrWGVHDf
# m36zM9J4wobjmzCjQBTBCtik3TZ1QPIpGErjEV6MyRP3cEDFBg6TLK11IPVpE0YE
# N/aAHifwolmj9n5vqnMiWgKhiN7C7uIbOo0ytbeYu2dzRzIQvwuyWsgy5RJYkpkp
# UUHb1YVGyl3yhOqan9rU68Qiza/tgULbBhXYn68L
# SIG # End signature block