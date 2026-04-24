#
# Install-PyForMLS.ps1
# Copyright (C) Microsoft.  All rights reserved.
#

# See: https://learn.microsoft.com/sql/machine-learning/python/setup-python-client-tools-sql

# Command-line parameters
param
(
    [string]$InstallFolder = "$Env:ProgramFiles\Microsoft\PyForMLS",
    [string]$CacheFolder = $Env:Temp,
    [string]$JupyterShortcut = "$Env:ProgramData\Microsoft\Windows\Start Menu\Jupyter Notebook for Microsoft Machine Learning Server.lnk"
)

# Verify script is being run with elevated privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "This script must be run as Administrator"
    Exit 1
}

# Product version to install
$productVersion = '9.3.0.0'

# Default language to install (en-us)
$productLcid = '1033'

# Component names and their corresponding fwlink IDs
$components = @{ 'SPO' = '859054'; 'SPS' = '859056'; }

# Helper function which outputs the specified message to the console and prepends the current date and time
function WriteMessage($message)
{
    Write-Host ("[{0}] {1}" -f (Get-Date -format u), $message)
}

# Helper function which generates a fwlink for the specified component
function GenerateFwlink($componentName)
{
    return 'https://go.microsoft.com/fwlink/?LinkId={0}&clcid={1}' -f $components[$componentName], $productLcid
}

# Helper function which generates the absolute CAB path of the specified component 
function GenerateCabPath($componentName)
{
    return "{0}\{1}_{2}_1033.cab" -f $cacheFolder, $componentName, $productVersion
}

# Helper function which returns true if the specified CAB file is found in the cache
function IsCachedCabValid($cabFile, $cabUrl)
{
    $isValid = $false

    # Does CAB file exist?
    if (Test-Path $cabFile)
    {
        # Retrieve headers from CAB URL
        $response = Invoke-WebRequest -Method Head -Uri $cabUrl

        # Compare last modified date of cached file against the remote file
        if ([datetime](Get-ItemProperty -Path $cabFile).LastWriteTime -ge $response.Headers['Last-Modified'])
        {
            WriteMessage "Cached $cabFile is up-to-date"
            $isValid = $true
        }
        else
        {
            WriteMessage "Cached $cabFile is expired"
            $isValid = $false
        }
    }
    else
    {
        WriteMessage "$cabFile not found in cache"
        $isValid = $false
    }

    return $isValid
}

WriteMessage "Starting installation"

# Create install folder, if necessary
if (-not (Test-Path $installFolder))
{   
    WriteMessage "Creating install folder $installFolder"
    New-Item -ItemType directory -Path $installFolder > $null
}

# Download the CAB file for each component
foreach ($componentName in $components.Keys)
{
    $cabUrl = GenerateFwlink($componentName)
    $cabFile = GenerateCabPath($componentName)
        
    # Download CAB file, if necessary
    if (-not (IsCachedCabValid $cabFile $cabUrl))
    {
        WriteMessage "Downloading $cabUrl to $cabFile"
        Invoke-WebRequest -Uri $cabUrl -OutFile $cabFile
    }
}
    
# Extract the contents of each CAB file
foreach ($componentName in $components.Keys)
{
    $cabFile = GenerateCabPath($componentName)

    # Extract all files using the built-in expand.exe tool
    WriteMessage "Extracting $cabFile to $installFolder (this may take several minutes)"
    &"$Env:WinDir\System32\expand.exe" $cabFile -F:* $installFolder > $null
}

# Create shortcut
WriteMessage "Creating shortcut $jupyterShortcut"
$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut($jupyterShortcut)
$shortcut.TargetPath = "$installFolder\Scripts\jupyter-notebook.exe"
$shortcut.Arguments = "--notebook-dir `"$installFolder\samples`""
$shortcut.Save()

# Force shortcut to launch as admin
$bytes = [System.IO.File]::ReadAllBytes($jupyterShortcut)
$bytes[0x15] = $bytes[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes($JupyterShortcut, $bytes)

WriteMessage "Installation complete"

# SIG # Begin signature block
# MIIj7gYJKoZIhvcNAQcCoIIj3zCCI9sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCcQAtZ7Zu4h+GZ
# d5+6oKbm+wLBylyrt7Epkx69JtzklaCCDYMwggYBMIID6aADAgECAhMzAAAAxOmJ
# +HqBUOn/AAAAAADEMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTcwODExMjAyMDI0WhcNMTgwODExMjAyMDI0WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCIirgkwwePmoB5FfwmYPxyiCz69KOXiJZGt6PLX4kvOjMuHpF4+nypH4IBtXrL
# GrwDykbrxZn3+wQd8oUK/yJuofJnPcUnGOUoH/UElEFj7OO6FYztE5o13jhwVG87
# 7K1FCTBJwb6PMJkMy3bJ93OVFnfRi7uUxwiFIO0eqDXxccLgdABLitLckevWeP6N
# +q1giD29uR+uYpe/xYSxkK7WryvTVPs12s1xkuYe/+xxa8t/CHZ04BBRSNTxAMhI
# TKMHNeVZDf18nMjmWuOF9daaDx+OpuSEF8HWyp8dAcf9SKcTkjOXIUgy+MIkogCy
# vlPKg24pW4HvOG6A87vsEwvrAgMBAAGjggGAMIIBfDAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUy9ZihM9gOer/Z8Jc0si7q7fDE5gw
# UgYDVR0RBEswSaRHMEUxDTALBgNVBAsTBE1PUFIxNDAyBgNVBAUTKzIzMDAxMitj
# ODA0YjVlYS00OWI0LTQyMzgtODM2Mi1kODUxZmEyMjU0ZmMwHwYDVR0jBBgwFoAU
# SG5k5VAF04KqFzc3IrVtqMp1ApUwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljQ29kU2lnUENBMjAxMV8yMDEx
# LTA3LTA4LmNybDBhBggrBgEFBQcBAQRVMFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljQ29kU2lnUENBMjAxMV8y
# MDExLTA3LTA4LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQAG
# Fh/bV8JQyCNPolF41+34/c291cDx+RtW7VPIaUcF1cTL7OL8mVuVXxE4KMAFRRPg
# mnmIvGar27vrAlUjtz0jeEFtrvjxAFqUmYoczAmV0JocRDCppRbHukdb9Ss0i5+P
# WDfDThyvIsoQzdiCEKk18K4iyI8kpoGL3ycc5GYdiT4u/1cDTcFug6Ay67SzL1BW
# XQaxFYzIHWO3cwzj1nomDyqWRacygz6WPldJdyOJ/rEQx4rlCBVRxStaMVs5apao
# pIhrlihv8cSu6r1FF8xiToG1VBpHjpilbcBuJ8b4Jx/I7SCpC7HxzgualOJqnWmD
# oTbXbSD+hdX/w7iXNgn+PRTBmBSpwIbM74LBq1UkQxi1SIV4htD50p0/GdkUieeN
# n2gkiGg7qceATibnCCFMY/2ckxVNM7VWYE/XSrk4jv8u3bFfpENryXjPsbtrj4Ns
# h3Kq6qX7n90a1jn8ZMltPgjlfIOxrbyjunvPllakeljLEkdi0iHv/DzEMQv3Lz5k
# pTdvYFA/t0SQT6ALi75+WPbHZ4dh256YxMiMy29H4cAulO2x9rAwbexqSajplnbI
# vQjE/jv1rnM3BrJWzxnUu/WUyocc8oBqAU+2G4Fzs9NbIj86WBjfiO5nxEmnL9wl
# iz1e0Ow0RJEdvJEMdoI+78TYLaEEAo5I+e/dAs8DojCCB3owggVioAMCAQICCmEO
# kNIAAAAAAAMwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkw
# OVowfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UE
# AxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCq
# uAY4GgRJun/DDB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOlo
# XtLfm1OyCizDr9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3Wr
# aPPLbfM6XKEW9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ9
# 7/vjK1oQH01WKKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7
# La4zWMW3Pv4y07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOG
# jfdf8NBSv4yUh7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I
# 4iVd0yFLPlLEtVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5
# oQ/pI0m8GLhEfEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm
# 4sGXgXvt1u1L50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B
# 4YVEicQJTMXUpUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDW
# iIwLAgMBAAGjggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k
# 5VAF04KqFzc3IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYD
# VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kU
# BU7h6qfHMdEjiTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAz
# XzIyLmNybDBeBggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAz
# XzIyLmNydDCBnwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUH
# AgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5
# Y3BzLmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMA
# eQBfAHMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KG
# pZjgVHkaLtPYdGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79H
# qaPzadtjvyI1pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XU
# tR13lDni6WTJRD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPypr
# WEljHwlpblqYluSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ
# 1h/DMhji8MUtzluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiy
# WYlobm+nt3TDQAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobD
# HWM2l4bf2vP48hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+
# 30HHDiju3mUv7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKi
# n3p6IvpIlR+r+0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4Dq
# aTuv/DDtBEyO3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FW
# TkhFwELJm3ZbCoBIa/15n8G9bW1qyVJzEw16UM0xghXBMIIVvQIBATCBlTB+MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNy
# b3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExAhMzAAAAxOmJ+HqBUOn/AAAAAADE
# MA0GCWCGSAFlAwQCAQUAoIGwMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBFICAp
# M2j0TOGgkpBNkVd+X/ZevrIdRG1Kc4YxAZ0uLjBEBgorBgEEAYI3AgEMMTYwNKAU
# gBIATQBpAGMAcgBvAHMAbwBmAHShHIAaaHR0cHM6Ly93d3cubWljcm9zb2Z0LmNv
# bSAwDQYJKoZIhvcNAQEBBQAEggEAX4lloFuwEEraoxJFk/wnE107hYIp7veGKPhB
# Fd7aUOll/FY7emZeZ7Dbz2b1qbV6DmKboiSNRfqgfB0F3dMVUiBVtvtRdw5MAUqx
# o/PKCD82KDZudLvcOkXDZLgfQSe2EKsrme96HFJ7D+s/vrGACewiixNXsZ7MMJ/K
# pKwJF7kqD5/W7V+QzpgaYa9qYG4Iomrybua7VEeGhUg4islCHIwvX0naAAPY11gZ
# ubZFGnC+w11dl1lQ1IzNga6Kxl857DygTiJIV7ODUP8eCELDCTgIUj3PXq04hTzn
# mW1hzCBoqCTYinYSDZjVyg6mFxQUMIlp4w/210hSKivxCA8o0aGCE0kwghNFBgor
# BgEEAYI3AwMBMYITNTCCEzEGCSqGSIb3DQEHAqCCEyIwghMeAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggE8BgsqhkiG9w0BCRABBKCCASsEggEnMIIBIwIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCBz8XcAnPXHLROng3eOI0UaWfW0nM5svgvd
# BWnWX9tULAIGWwMpKo8OGBMyMDE4MDUyNDIwMDA1NS44NDRaMAcCAQGAAgPnoIG4
# pIG1MIGyMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMQwwCgYD
# VQQLEwNBT0MxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjo4NDNELTM3RjYtRjEw
# NDElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCDs0wggZx
# MIIEWaADAgECAgphCYEqAAAAAAACMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQg
# Um9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3MDEyMTM2NTVa
# Fw0yNTA3MDEyMTQ2NTVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcRijog7PwTl/X6f2mU
# a3RUENWlCgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AVUycEMR9BGxqVHc4JE458YTBZ
# sTBED/FgiIRUQwzXTbg4CLNC3ZOs1nMwVyaCo0UN0Or1R4HNvyRgMlhgRvJYR4Yy
# hB50YWeRX4FUsc+TTJLBxKZd0WETbijGGvmGgLvfYfxGwScdJGcSchohiq9LZIlQ
# YrFd/XcfPfBXday9ikJNQFHRD5wGPmd/9WbAA5ZEfu/QS/1u5ZrKsajyeioKMfDa
# TgaRtogINeh4HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJRF1eFpwBBU8iTQID
# AQABo4IB5jCCAeIwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNVjOlyKMZDz
# Q3t8RhvFM2hahW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQ
# W9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNv
# bS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBa
# BggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGgBgNV
# HSABAf8EgZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggr
# BgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQA
# ZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aIUQ3ixuCYP4FxAz2d
# o6Ehb7Prpsz1Mb7PBeKp/vpXbRkws8LFZslq3/Xn8Hi9x6ieJeP5vO1rVFcIK1GC
# RBL7uVOMzPRgEop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMivv3/Gf/I3fVo/HPKZ
# eUqRUgCvOA8X9S95gWXZqbVr5MfO9sp6AG9LMEQkIjzP7QOllo9ZKby2/QThcJ8y
# Sif9Va8v/rbljjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbiOewZSnFjnXshbcOc
# o6I8+n99lmqQeKZt0uGc+R38ONiU9MalCpaGpL2eGq4EQoO4tYCbIjggtSXlZOz3
# 9L9+Y1klD3ouOVd2onGqBooPiRa6YacRy5rYDkeagMXQzafQ732D8OE7cQnfXXSY
# Ighh2rBQHm+98eEA3+cxB6STOvdlR3jo+KhIq/fecn5ha293qYHLpwmsObvsxsvY
# grRyzR30uIUBHoD7G4kqVDmyW9rIDVWZeodzOwjmmC3qjeAzLhIp9cAvVCch98is
# TtoouLGp25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99je/WZii8bxyGvWbWu3EQ8
# l1Bx16HSxVXjad5XwdHeMMD9zOZN+w2/XU/pnR4ZOC+8z1gFLu8NoFA12u8JJxzV
# s341Hgi62jbb01+P3nSISRIwggTZMIIDwaADAgECAhMzAAAAqVRw2XnAhGXiAAAA
# AACpMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTE2MDkwNzE3NTY1M1oXDTE4MDkwNzE3NTY1M1owgbIxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDDAKBgNVBAsTA0FPQzEnMCUGA1UECxMe
# bkNpcGhlciBEU0UgRVNOOjg0M0QtMzdGNi1GMTA0MSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEArJSFGKblVtOd3wNnLtuYkUePlYlyTZp08zRA3msRp9THkn4O/581On+n
# ZIxxm2HFGVk+lF2RL07A7cFAbicHkdTlrPYePM5QEVMnaITS0makH24deymLJuMJ
# rnTnTPyfg7dGDdsVqQ37V/ezmxDeDBykTRrDliRGNimQXN4dR9aXP0KNB/+oLyeO
# 6xIQsUdC9wS9OTbExbvA7La8joGcyd2yQDw9o+sbvTB1/lsFcx0UMRHU8Dq/7NET
# 3kTJxP5I4VfELngIFX7zRQY2Sba1/VgdEd2IZANCEDnvrlMWRhFbXH0SWndIdnAp
# YSEak1OcImlunLR5eo5MOIQVGWxfoQIDAQABo4IBGzCCARcwHQYDVR0OBBYEFA/V
# Qfu78530vklS2ow3V85kD/N9MB8GA1UdIwQYMBaAFNVjOlyKMZDzQ3t8RhvFM2ha
# hW1VMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9w
# a2kvY3JsL3Byb2R1Y3RzL01pY1RpbVN0YVBDQV8yMDEwLTA3LTAxLmNybDBaBggr
# BgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2kvY2VydHMvTWljVGltU3RhUENBXzIwMTAtMDctMDEuY3J0MAwGA1UdEwEB
# /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQADggEBAAiZ
# GKUHiy9yJHUsjiCEAv0Koa8O4bAyEYaqxYYgnbvoRDuVzLU654tGpRPTjCAbqDpX
# HBX3c22NC7IHRW6GRXYkRrp0TPE2b1KdtuTklIzJKauJqr5ygtO6m1WroII54Bku
# 2BGtRYkDS8Av4gCeuHuH28rXdbguBLSMkzeKHiZE5NlBZY7RQrleExC8GWd1u86E
# qekfjnvPG5S4OV1tV1nsCn7G1pUNO+f6iC9WrFUEUHJnP7IAA8OOwvw+yJWr4NRn
# tqY0bbRgCLJCid5/YNpYIbzTjDgyU/IKzNvfJLcA65NKPwl6NDtLwHNralKEU6Gb
# BERZYUKtcvBAwG78mrKhggN3MIICXwIBATCB4qGBuKSBtTCBsjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQL
# Ex5uQ2lwaGVyIERTRSBFU046ODQzRC0zN0Y2LUYxMDQxJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiJQoBATAJBgUrDgMCGgUAAxUAXTq/Vr3h
# DynKcg5k93U7eBoi6/SggcEwgb6kgbswgbgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xDDAKBgNVBAsTA0FPQzEnMCUGA1UECxMebkNpcGhlciBO
# VFMgRVNOOjI2NjUtNEMzRi1DNURFMSswKQYDVQQDEyJNaWNyb3NvZnQgVGltZSBT
# b3VyY2UgTWFzdGVyIENsb2NrMA0GCSqGSIb3DQEBBQUAAgUA3rEC7DAiGA8yMDE4
# MDUyNDA5MjI1MloYDzIwMTgwNTI1MDkyMjUyWjB3MD0GCisGAQQBhFkKBAExLzAt
# MAoCBQDesQLsAgEAMAoCAQACAhmJAgH/MAcCAQACAhmrMAoCBQDeslRsAgEAMDYG
# CisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwGgCjAIAgEAAgMegJihCjAIAgEA
# AgMehIAwDQYJKoZIhvcNAQEFBQADggEBACCC4U8Xw3EV8c3XIrkUGCA5fOqq33GG
# gvCw8gXTlTglImU6Z5JbrziEP+02wW6RN/uvuWpfu+ErTvN5E7vxxj5Og/IFWmif
# swF/N40pWeTJU1fyvo4BVYHygLyRpnGFCEeXT4sjXQSa1YLoaFcamTG/r7vt9W1s
# nvJUfyW5KMX8xlnivFKM65RUYHZ1/zB/fA9K9MQtIFU0Jr3jYwCd0JVcnuysaN66
# aU2EnpsoiTYmBL138s4hM7cK5vymzofp0eYVTd/83PP8H2ZTRGEm9sOglOewtNMs
# fHwkpm7cZxPF5fsbxxYUGwM/mCl89dBGsdU+vjlIaiovX8yJKHUznnkxggL1MIIC
# 8QIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAKlUcNl5
# wIRl4gAAAAAAqTANBglghkgBZQMEAgEFAKCCATIwGgYJKoZIhvcNAQkDMQ0GCyqG
# SIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDEz3JAIekNn0Gtr62/eNmLmZoYbCcR
# rmhTOaiTywyovDCB4gYLKoZIhvcNAQkQAgwxgdIwgc8wgcwwgbEEFF06v1a94Q8p
# ynIOZPd1O3gaIuv0MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAACpVHDZecCEZeIAAAAAAKkwFgQUsmMPwmVuSiBbNg4ZDFfesXTSyM8w
# DQYJKoZIhvcNAQELBQAEggEAgVub0c34ntVQ3x1wpzKcQgN+UswIw5fkKgkAjKNK
# 4dRCJpcja9P15d3t72KA/dJOoGBNagloOyewROaGSaoKjBKzBsSEX9ADdAFicYgW
# Oywr8cfChXdrwZNRHlOAcZV0G1TGWtaY5/Hb46KS2WZamBeraQ7+eqGsIoYrQyl5
# quKcDvd+Msa8NQelc/ypudesYKUnE+96RIvJACR2CD99aYq22uWgXX75q9RgcUuE
# PNCIfqdw36oeC6bz9/fHCORlfPMnzZYebJE7rw7utrg7m6SnL5dLQM2v3OnFwccq
# jSE2VAQNJk/Z3FZnpXquy5pNbtuNcd3sYki5+d0OV4fcpQ==
# SIG # End signature block
