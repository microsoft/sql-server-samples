<#
.SYNOPSIS
    Deploy a Connector Namespace with a hosted SQL MCP Server.

.DESCRIPTION
    Single-script deployment: provisions Azure SQL, Connector Namespace,
    hosted MCP server (mcp-sql), seeds the database, grants managed identity access,
    and prints the MCP endpoint URL ready for VS Code.

.PARAMETER DabConfigPath
    Path to the DAB configuration file. Defaults to dab-config.json in the project root.

.PARAMETER EnvironmentName
    Name for the deployment environment. Used to generate unique resource names.

.PARAMETER Location
    Azure region for SQL and general resources. Default: eastasia.

.PARAMETER ConnectorNamespaceLocation
    Azure region for the Connector Namespace. Must be a preview region.
    Default: eastasia.

.PARAMETER DatabaseName
    Name of the SQL database. Default: mcpdb.

.PARAMETER ConnectorNamespaceIdentityType
    Managed identity type for the Connector Namespace. Default: SystemAssigned.
    Use UserAssigned to create and attach a user-assigned managed identity.

.EXAMPLE
    .\deploy.ps1 -EnvironmentName mcp-dev
    # Uses ./dab-config.json, deploys to eastasia

.EXAMPLE
    .\deploy.ps1 -EnvironmentName mcp-dev -DabConfigPath .\my-custom-dab.json -Location eastasia
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$EnvironmentName,

    [string]$DabConfigPath,

    [string]$Location = 'eastasia',

    [string]$ConnectorNamespaceLocation = 'eastasia',

    [string]$DatabaseName = 'mcpdb',

    [ValidateSet('SystemAssigned', 'UserAssigned')]
    [string]$ConnectorNamespaceIdentityType = 'SystemAssigned'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = $PSScriptRoot

# Resolve DAB config path
if (-not $DabConfigPath) {
    $DabConfigPath = Join-Path $ProjectRoot 'dab-config.json'
}
if (-not (Test-Path $DabConfigPath)) {
    Write-Error "DAB config not found at: $DabConfigPath. Provide -DabConfigPath or place dab-config.json in the project root."
    exit 1
}
$DabConfigPath = Resolve-Path $DabConfigPath
Write-Host "Using DAB config: $DabConfigPath" -ForegroundColor Cyan

# ── Step 1: Detect deployer identity ──────────────────────────────────────────

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Step 1/5: Detecting deployer identity" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

$deployerLogin = az account show --query user.name -o tsv
if (-not $deployerLogin) {
    Write-Error "Not logged in. Run 'az login' first."
    exit 1
}
Write-Host "  Deployer:  $deployerLogin" -ForegroundColor Green

$deployerObjectId = az ad signed-in-user show --query id -o tsv
Write-Host "  Object ID: $deployerObjectId" -ForegroundColor Green

$deployerIp = try { (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 10) } catch { '' }
if ($deployerIp) {
    Write-Host "  Public IP: $deployerIp" -ForegroundColor Green
} else {
    Write-Host "  Public IP: (could not detect — SQL firewall rule skipped)" -ForegroundColor Yellow
}

# ── Step 2: Deploy Bicep ──────────────────────────────────────────────────────

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Step 2/5: Deploying infrastructure (Bicep)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

$bicepFile = Join-Path $ProjectRoot 'infra' 'main.bicep'
if (-not (Test-Path $bicepFile)) {
    Write-Error "Bicep file not found at: $bicepFile"
    exit 1
}

# Copy DAB config to expected location for loadTextContent('../dab-config.json')
$expectedDabPath = Join-Path $ProjectRoot 'dab-config.json'
if ($DabConfigPath -ne (Resolve-Path $expectedDabPath -ErrorAction SilentlyContinue)) {
    Write-Host "  Copying DAB config to project root for Bicep..." -ForegroundColor Yellow
    Copy-Item -Path $DabConfigPath -Destination $expectedDabPath -Force
}

Write-Host "  Deploying to subscription..." -ForegroundColor Yellow

$deployment = az deployment sub create `
    --name "mcp-deploy-$EnvironmentName" `
    --location $Location `
    --template-file $bicepFile `
    --parameters environmentName=$EnvironmentName `
                 location=$Location `
                 connectorNamespaceLocation=$ConnectorNamespaceLocation `
                 deployerLoginName=$deployerLogin `
                 deployerPrincipalId=$deployerObjectId `
                 deployerIpAddress=$deployerIp `
                 databaseName=$DatabaseName `
                 connectorNamespaceIdentityType=$ConnectorNamespaceIdentityType `
    --query "properties.outputs" `
    -o json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host $deployment -ForegroundColor Red
    Write-Error "Bicep deployment failed."
    exit 1
}

$outputs = $deployment | ConvertFrom-Json

$sqlServerFqdn    = $outputs.SQL_SERVER_FQDN.value
$sqlDbName        = $outputs.SQL_DATABASE_NAME.value
$connectorNsName  = $outputs.CONNECTOR_NAMESPACE_NAME.value
$connectorNsSami  = $outputs.CONNECTOR_NAMESPACE_PRINCIPAL_ID.value
$sqlIdentityName  = $outputs.SQL_IDENTITY_NAME.value
$sqlIdentityPrincipal = $outputs.SQL_IDENTITY_PRINCIPAL_ID.value
$mcpEndpointUrl   = $outputs.MCP_ENDPOINT_URL.value
$rgName           = $outputs.RESOURCE_GROUP_NAME.value

Write-Host "  Deployment succeeded!" -ForegroundColor Green
Write-Host "    Resource Group:      $rgName"
Write-Host "    SQL Server:          $sqlServerFqdn"
Write-Host "    Connector Namespace: $connectorNsName"
Write-Host "    SQL MI User:         $sqlIdentityName"
Write-Host "    SQL MI Principal ID: $sqlIdentityPrincipal"
Write-Host "    MCP Endpoint:        $mcpEndpointUrl"

# ── Step 3: Seed the database ─────────────────────────────────────────────────

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Step 3/5: Seeding the database" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

$token = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv

$seedSql = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BlogPost')
BEGIN
    CREATE TABLE dbo.BlogPost (
        Id int IDENTITY(1,1) PRIMARY KEY,
        Title nvarchar(300) NOT NULL,
        Url nvarchar(1000) NOT NULL,
        Source nvarchar(100) NOT NULL
    );
END
IF NOT EXISTS (SELECT 1 FROM dbo.BlogPost WHERE Url = N'https://learn.microsoft.com/en-us/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp')
BEGIN
    INSERT INTO dbo.BlogPost (Title, Url, Source)
    VALUES (N'Hosted MCP servers in Azure Connector Namespace', N'https://learn.microsoft.com/en-us/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp', N'Microsoft Learn');
END
IF NOT EXISTS (SELECT 1 FROM dbo.BlogPost WHERE Url = N'https://devblogs.microsoft.com/dotnet/durable-workflows-in-microsoft-agent-framework/')
BEGIN
    INSERT INTO dbo.BlogPost (Title, Url, Source)
    VALUES (N'Durable Workflows in Microsoft Agent Framework', N'https://devblogs.microsoft.com/dotnet/durable-workflows-in-microsoft-agent-framework/', N'.NET Blog');
END
PRINT 'BlogPost table seeded.';
"@

$sqlSuccess = $false
try {
    Invoke-Sqlcmd -ServerInstance $sqlServerFqdn -Database $sqlDbName -AccessToken $token -Query $seedSql
    Write-Host "  Database seeded." -ForegroundColor Green
    $sqlSuccess = $true
} catch {
    Write-Host "  Invoke-Sqlcmd unavailable, trying sqlcmd CLI..." -ForegroundColor Yellow
    try {
        sqlcmd -S $sqlServerFqdn -d $sqlDbName -Q $seedSql --authentication-method=ActiveDirectoryDefault
        Write-Host "  Database seeded." -ForegroundColor Green
        $sqlSuccess = $true
    } catch {
        Write-Host "  Could not seed automatically." -ForegroundColor Red
    }
}

# ── Step 4: Grant managed identity access ─────────────────────────────────────

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Step 4/5: Granting managed identity database access" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

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
PRINT 'Managed identity access granted.';
"@

if ($sqlSuccess) {
    try {
        Invoke-Sqlcmd -ServerInstance $sqlServerFqdn -Database $sqlDbName -AccessToken $token -Query $grantSql
        Write-Host "  Managed identity access granted." -ForegroundColor Green
    } catch {
        try {
            sqlcmd -S $sqlServerFqdn -d $sqlDbName -Q $grantSql --authentication-method=ActiveDirectoryDefault
            Write-Host "  Managed identity access granted." -ForegroundColor Green
        } catch {
            $sqlSuccess = $false
        }
    }
}

if (-not $sqlSuccess) {
    Write-Host ""
    Write-Host "  Run these SQL commands manually in Azure Portal Query Editor:" -ForegroundColor Yellow
    Write-Host "  (SQL Server → $sqlServerFqdn → Database → $sqlDbName → Query editor)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host $seedSql -ForegroundColor White
    Write-Host ""
    Write-Host $grantSql -ForegroundColor White
    Write-Host ""
}

# ── Step 5: Done ──────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Step 5/5: Deployment Complete!" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  MCP Endpoint: $mcpEndpointUrl" -ForegroundColor Green
$subscriptionId = az account show --query id -o tsv
$resourceGroupUrl = "https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$rgName/overview"
Write-Host "  Azure Portal: $resourceGroupUrl" -ForegroundColor Green
Write-Host ""
Write-Host "  Use the MCP endpoint with any MCP client that supports HTTP transport." -ForegroundColor White
Write-Host ""
Write-Host "  Clean up later with:" -ForegroundColor White
Write-Host "    az group delete --name $rgName --yes" -ForegroundColor Gray
Write-Host ""
