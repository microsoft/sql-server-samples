#!/usr/bin/env pwsh
# post-provision.ps1 — Runs after `azd provision` to seed the database and
# generate the DAB config file.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-SqlFirewallRuleForIp {
    param(
        [Parameter(Mandatory)]
        [string]$IpAddress,

        [Parameter(Mandatory)]
        [string]$RuleName
    )

    az sql server firewall-rule create `
        --resource-group $resourceGroupName `
        --server $sqlServerName `
        --name $RuleName `
        --start-ip-address $IpAddress `
        --end-ip-address $IpAddress `
        --only-show-errors | Out-Null
}

function Invoke-SqlcmdWithFirewallRetry {
    param(
        [Parameter(Mandatory)]
        [string]$Query
    )

    $maxAttempts = 20
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            Invoke-Sqlcmd -ServerInstance $sqlServerFqdn -Database $databaseName -AccessToken $token -Query $Query
            return
        } catch {
            $message = $_.Exception.Message
            if ($message -match "Client with IP address '([^']+)' is not allowed") {
                $blockedIp = $Matches[1]
                Write-Host "  SQL reported blocked client IP $blockedIp; adding firewall rule and retrying ($attempt/$maxAttempts)..." -ForegroundColor Yellow
                Add-SqlFirewallRuleForIp -IpAddress $blockedIp -RuleName 'AllowSqlClientIp'
                Start-Sleep -Seconds 15
                continue
            }

            throw
        }
    }

    throw "Timed out waiting for SQL firewall rules to allow this client."
}

# Read outputs from azd
$resourceGroupName   = (azd env get-value RESOURCE_GROUP_NAME)
$sqlServerName       = (azd env get-value SQL_SERVER_NAME)
$sqlServerFqdn       = (azd env get-value SQL_SERVER_FQDN)
$databaseName        = (azd env get-value SQL_DATABASE_NAME)
$connectorNsName     = (azd env get-value CONNECTOR_NAMESPACE_NAME)
$connectorNsPrincipal = (azd env get-value CONNECTOR_NAMESPACE_PRINCIPAL_ID)
$sqlIdentityName     = (azd env get-value SQL_IDENTITY_NAME)
$sqlIdentityPrincipal = (azd env get-value SQL_IDENTITY_PRINCIPAL_ID)
$dabConnectionString = (azd env get-value DAB_CONNECTION_STRING)

if (-not $sqlIdentityName) {
    $sqlIdentityName = $connectorNsName
}
if (-not $sqlIdentityPrincipal) {
    $sqlIdentityPrincipal = $connectorNsPrincipal
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Post-Provision Setup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SQL Server:             $sqlServerFqdn"
Write-Host "Database:               $databaseName"
Write-Host "Connector Namespace:    $connectorNsName"
Write-Host "Connector NS SAMI ID:   $connectorNsPrincipal"
Write-Host "SQL MI User:            $sqlIdentityName"
Write-Host "SQL MI Principal ID:    $sqlIdentityPrincipal"
Write-Host ""

# --- Step 1: Allow this machine through the SQL firewall ---
Write-Host "[1/4] Configuring SQL firewall for this machine..." -ForegroundColor Yellow
try {
    $detectedIps = @()
    foreach ($uri in @('https://api.ipify.org', 'https://ifconfig.me/ip')) {
        try {
            $ip = (Invoke-RestMethod -Uri $uri -TimeoutSec 10)
            if ($ip -and $ip -match '^\d{1,3}(\.\d{1,3}){3}$') {
                $detectedIps += $ip
            }
        } catch {
            Write-Host "  Could not detect public IP from $uri." -ForegroundColor DarkYellow
        }
    }

    $index = 0
    foreach ($deployerIp in ($detectedIps | Select-Object -Unique)) {
        $index++
        $ruleName = if ($index -eq 1) { 'AllowDeployerIp' } else { "AllowDeployerIp$index" }
        Add-SqlFirewallRuleForIp -IpAddress $deployerIp -RuleName $ruleName
        Write-Host "  Allowed public IP: $deployerIp" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Could not detect or configure public IP. SQL commands may need to be run manually." -ForegroundColor Yellow
}

# --- Step 2: Get an access token for Azure SQL ---
Write-Host "[2/4] Getting access token for Azure SQL..." -ForegroundColor Yellow
$token = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
if (-not $token) {
    Write-Host "ERROR: Failed to get access token. Make sure you are logged in with 'az login'." -ForegroundColor Red
    exit 1
}

# --- Step 3: Seed the database ---
Write-Host "[3/4] Seeding the database with BlogPosts table..." -ForegroundColor Yellow

$seedSql = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BlogPosts')
BEGIN
    CREATE TABLE dbo.BlogPosts (
        Id int IDENTITY(1,1) PRIMARY KEY,
        Title nvarchar(300) NOT NULL,
        Url nvarchar(1000) NOT NULL,
        Source nvarchar(100) NOT NULL
    );
END
IF NOT EXISTS (SELECT 1 FROM dbo.BlogPosts WHERE Url = N'https://learn.microsoft.com/en-us/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp')
BEGIN
    INSERT INTO dbo.BlogPosts (Title, Url, Source)
    VALUES (N'Hosted MCP servers in Azure Connector Namespace', N'https://learn.microsoft.com/en-us/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp', N'Microsoft Learn');
END
IF NOT EXISTS (SELECT 1 FROM dbo.BlogPosts WHERE Url = N'https://devblogs.microsoft.com/dotnet/durable-workflows-in-microsoft-agent-framework/')
BEGIN
    INSERT INTO dbo.BlogPosts (Title, Url, Source)
    VALUES (N'Durable Workflows in Microsoft Agent Framework', N'https://devblogs.microsoft.com/dotnet/durable-workflows-in-microsoft-agent-framework/', N'.NET Blog');
END
PRINT 'BlogPosts table seeded.';
"@

$grantSql = @"
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$sqlIdentityName')
BEGIN
    CREATE USER [$sqlIdentityName] FROM EXTERNAL PROVIDER;
END
IF ISNULL(IS_ROLEMEMBER('db_datareader', '$sqlIdentityName'), 0) = 0
    ALTER ROLE db_datareader ADD MEMBER [$sqlIdentityName];
IF ISNULL(IS_ROLEMEMBER('db_datawriter', '$sqlIdentityName'), 0) = 0
    ALTER ROLE db_datawriter ADD MEMBER [$sqlIdentityName];
GRANT VIEW DEFINITION TO [$sqlIdentityName];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$sqlIdentityName')
    THROW 51000, 'Connector Namespace managed identity SQL user was not created.', 1;
IF ISNULL(IS_ROLEMEMBER('db_datareader', '$sqlIdentityName'), 0) <> 1
    THROW 51001, 'Connector Namespace managed identity is not a member of db_datareader.', 1;
IF ISNULL(IS_ROLEMEMBER('db_datawriter', '$sqlIdentityName'), 0) <> 1
    THROW 51002, 'Connector Namespace managed identity is not a member of db_datawriter.', 1;
PRINT 'Granted managed identity access to database.';
"@

if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Invoke-Sqlcmd is required for automatic post-provision database setup." -ForegroundColor Red
    Write-Host "Install the SqlServer PowerShell module or run the SQL commands manually in Azure Portal Query Editor." -ForegroundColor Red
    exit 1
}

Invoke-SqlcmdWithFirewallRetry -Query $seedSql
Write-Host "  Database seeded successfully." -ForegroundColor Green

Write-Host "[4/4] Granting managed identity access to database..." -ForegroundColor Yellow
Invoke-SqlcmdWithFirewallRetry -Query $grantSql
Write-Host "  Managed identity access granted." -ForegroundColor Green

# --- Generate DAB config ---
Write-Host ""
Write-Host "Generating dab-config.json..." -ForegroundColor Yellow

$dabConfig = @{
    '$schema' = 'https://github.com/Azure/data-api-builder/releases/download/v1.7.93/dab.draft.schema.json'
    'data-source' = @{
        'database-type' = 'mssql'
        'connection-string' = $dabConnectionString
        'options' = @{
            'set-session-context' = $false
        }
    }
    'runtime' = @{
        'rest' = @{
            'enabled' = $false
            'path' = '/api'
            'request-body-strict' = $true
        }
        'graphql' = @{
            'enabled' = $false
            'path' = '/graphql'
            'allow-introspection' = $true
        }
        'mcp' = @{
            'enabled' = $true
            'path' = '/mcp'
        }
        'host' = @{
            'cors' = @{
                'origins' = @()
                'allow-credentials' = $false
            }
            'authentication' = @{
                'provider' = 'AppService'
            }
            'mode' = 'development'
        }
    }
    'entities' = @{
        'BlogPosts' = @{
            'source' = @{
                'object' = 'dbo.BlogPosts'
                'type' = 'table'
            }
            'graphql' = @{
                'enabled' = $true
                'type' = @{
                    'singular' = 'BlogPosts'
                    'plural' = 'BlogPosts'
                }
            }
            'rest' = @{
                'enabled' = $true
            }
            'permissions' = @(
                @{
                    'role' = 'anonymous'
                    'actions' = @(
                        @{ 'action' = '*' }
                    )
                }
            )
        }
    }
} | ConvertTo-Json -Depth 10

$dabConfig | Set-Content -Path (Join-Path $PSScriptRoot '..' 'dab-config.generated.json') -Encoding utf8
Write-Host "  Created dab-config.generated.json" -ForegroundColor Green

# --- Print MCP endpoint and portal link ---
$mcpEndpointUrl = (azd env get-value MCP_ENDPOINT_URL)
$subscriptionId = (azd env get-value AZURE_SUBSCRIPTION_ID)
if (-not $subscriptionId) {
    $subscriptionId = az account show --query id -o tsv
}
$resourceGroupUrl = "https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/overview"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Deployment Complete!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "MCP Endpoint: $mcpEndpointUrl" -ForegroundColor Green
Write-Host "Azure Portal: $resourceGroupUrl" -ForegroundColor Green
Write-Host ""
Write-Host "Use the MCP endpoint with any MCP client that supports HTTP transport." -ForegroundColor White
Write-Host ""
