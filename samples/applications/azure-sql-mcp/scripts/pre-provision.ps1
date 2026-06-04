#!/usr/bin/env pwsh
# pre-provision.ps1 — Auto-detect deployer login and public IP before provisioning.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Auto-detect deployer login (email) if not already set
$currentLogin = azd env get-value AZURE_DEPLOYER_LOGIN 2>$null
if (-not $currentLogin) {
    Write-Host "Detecting deployer login from Azure CLI..." -ForegroundColor Yellow
    $login = az account show --query user.name -o tsv
    if ($login) {
        azd env set AZURE_DEPLOYER_LOGIN $login
        Write-Host "  Set AZURE_DEPLOYER_LOGIN=$login" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Could not detect login. Run: azd env set AZURE_DEPLOYER_LOGIN your-email@example.com" -ForegroundColor Red
        exit 1
    }
}

# Auto-detect deployer public IP for SQL firewall
$currentIp = azd env get-value AZURE_DEPLOYER_IP 2>$null
if (-not $currentIp) {
    Write-Host "Detecting deployer public IP..." -ForegroundColor Yellow
    try {
        $ip = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 10)
        azd env set AZURE_DEPLOYER_IP $ip
        Write-Host "  Set AZURE_DEPLOYER_IP=$ip" -ForegroundColor Green
    } catch {
        Write-Host "WARNING: Could not detect public IP. SQL post-provision scripts may fail." -ForegroundColor Yellow
        azd env set AZURE_DEPLOYER_IP ''
    }
}
