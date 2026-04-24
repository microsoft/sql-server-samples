# Learn more at https://learn.microsoft.com/en-us/windows-server/security/tls/tls-registry-settings?tabs=diffie-hellman
Set-StrictMode -Version Latest

$base = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\'
$protocols = [ordered]@{
    "SSL 2.0" = $false
    "SSL 3.0" = $false
    "TLS 1.0" = $false
    "TLS 1.1" = $false
    "TLS 1.2" = $true
    "TLS 1.3" = $true
}

foreach ($version in $protocols.Keys) {

    $enabledValue = $protocols[$version]
    $path = $base + $version + '\Server'

    New-Item $path -Force | Out-Null
    New-ItemProperty -Path $path `
                     -Name 'Enabled' `
                     -Value $enabledValue `
                     -PropertyType 'DWord' `
                     -Force | Out-Null
                     
    Write-Host "$version is $enabledValue."
}