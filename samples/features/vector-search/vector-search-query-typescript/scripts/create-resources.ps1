<#
.SYNOPSIS
    Create Azure SQL Database + Azure OpenAI resources for vector search quickstart.

.DESCRIPTION
    Creates a resource group, Azure OpenAI account with text-embedding-3-small,
    Azure SQL Server with Microsoft Entra admin, Azure SQL Database, and writes .env.

.PARAMETER ResourceGroup
    Name of the resource group. Default: rg-sql-vector-quickstart

.PARAMETER Location
    Azure region. Default: eastus2

.EXAMPLE
    ./scripts/create-resources.ps1
    ./scripts/create-resources.ps1 -ResourceGroup "my-rg" -Location "swedencentral"
#>
param(
    [string]$ResourceGroup = "rg-sql-vector-quickstart",
    [string]$Location = "eastus2"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================"
Write-Host "Azure SQL Vector Search - Resource Setup"
Write-Host "============================================================"

# ---- Current identity and subscription ----
$SubscriptionId = az account show --query id -o tsv
$UserObjectId   = az ad signed-in-user show --query id -o tsv
$UserUpn        = az ad signed-in-user show --query userPrincipalName -o tsv

Write-Host "Subscription:   $SubscriptionId"
Write-Host "User:           $UserUpn ($UserObjectId)"
Write-Host "Resource group: $ResourceGroup"
Write-Host "Location:       $Location"
Write-Host ""

# ---- Generate unique suffix ----
$HashInput = "$SubscriptionId$ResourceGroup"
$Hasher = [System.Security.Cryptography.MD5]::Create()
$HashBytes = $Hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($HashInput))
$Suffix = [BitConverter]::ToString($HashBytes).Replace("-", "").Substring(0, 8).ToLower()

$SqlServerName    = "sql-vector-$Suffix"
$OpenAiName       = "oai-vector-$Suffix"
$SqlDatabaseName  = "vectordb"

$TotalSteps = 9
$Step = 0

function Next-Step { $script:Step++ }

# ---- 1. Create resource group ----
Next-Step
Write-Host "$Step/$TotalSteps  Creating resource group: $ResourceGroup..."
az group create `
    --name $ResourceGroup `
    --location $Location `
    --output none

# ---- 2. Assign Contributor role to current user ----
Next-Step
Write-Host "$Step/$TotalSteps  Assigning Contributor role to current user..."
az role assignment create `
    --assignee-object-id $UserObjectId `
    --assignee-principal-type "User" `
    --role "Contributor" `
    --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup" `
    --output none 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "     (Already assigned or inherited)" }

# ---- 3. Create Azure OpenAI account ----
Next-Step
Write-Host "$Step/$TotalSteps  Creating Azure OpenAI account: $OpenAiName..."
az cognitiveservices account create `
    --name $OpenAiName `
    --resource-group $ResourceGroup `
    --location $Location `
    --kind "OpenAI" `
    --sku "S0" `
    --custom-domain $OpenAiName `
    --output none

# ---- 4. Deploy text-embedding-3-small model ----
Next-Step
Write-Host "$Step/$TotalSteps  Deploying text-embedding-3-small model..."
az cognitiveservices account deployment create `
    --name $OpenAiName `
    --resource-group $ResourceGroup `
    --deployment-name "text-embedding-3-small" `
    --model-name "text-embedding-3-small" `
    --model-version "1" `
    --model-format "OpenAI" `
    --sku-name "Standard" `
    --sku-capacity 10 `
    --output none

# ---- 5. Assign Cognitive Services OpenAI User role ----
Next-Step
Write-Host "$Step/$TotalSteps  Assigning Cognitive Services OpenAI User role..."
$OpenAiResourceId = az cognitiveservices account show `
    --name $OpenAiName `
    --resource-group $ResourceGroup `
    --query id -o tsv

az role assignment create `
    --assignee-object-id $UserObjectId `
    --assignee-principal-type "User" `
    --role "Cognitive Services OpenAI User" `
    --scope $OpenAiResourceId `
    --output none 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "     (Already assigned)" }

# ---- 6. Create Azure SQL Server with Microsoft Entra admin ----
Next-Step
Write-Host "$Step/$TotalSteps  Creating Azure SQL Server: $SqlServerName..."
az sql server create `
    --name $SqlServerName `
    --resource-group $ResourceGroup `
    --location $Location `
    --enable-ad-only-auth `
    --external-admin-principal-type "User" `
    --external-admin-name $UserUpn `
    --external-admin-sid $UserObjectId `
    --output none

# ---- 7. Create Azure SQL Database ----
Next-Step
Write-Host "$Step/$TotalSteps  Creating Azure SQL Database: $SqlDatabaseName..."
az sql db create `
    --server $SqlServerName `
    --resource-group $ResourceGroup `
    --name $SqlDatabaseName `
    --service-objective "S0" `
    --output none

# ---- 8. Add client IP to firewall ----
Next-Step
Write-Host "$Step/$TotalSteps  Adding client IP to SQL Server firewall..."
$ClientIp = (Invoke-RestMethod -Uri "https://api.ipify.org" -UseBasicParsing)

az sql server firewall-rule create `
    --server $SqlServerName `
    --resource-group $ResourceGroup `
    --name "AllowClientIP" `
    --start-ip-address $ClientIp `
    --end-ip-address $ClientIp `
    --output none

az sql server firewall-rule create `
    --server $SqlServerName `
    --resource-group $ResourceGroup `
    --name "AllowAzureServices" `
    --start-ip-address "0.0.0.0" `
    --end-ip-address "0.0.0.0" `
    --output none

# ---- 9. Write .env file ----
Next-Step
$OpenAiEndpoint = az cognitiveservices account show `
    --name $OpenAiName `
    --resource-group $ResourceGroup `
    --query "properties.endpoint" -o tsv

$SqlFqdn = "$SqlServerName.database.windows.net"
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "$Step/$TotalSteps  Writing .env file..."
@"
# Generated by scripts/create-resources.ps1 - $Timestamp
AZURE_SQL_SERVER=$SqlFqdn
AZURE_SQL_DATABASE=$SqlDatabaseName
AZURE_OPENAI_ENDPOINT=$OpenAiEndpoint
AZURE_OPENAI_EMBEDDING_DEPLOYMENT=text-embedding-3-small
"@ | Set-Content -Path ".env" -Encoding UTF8

Write-Host ""
Write-Host "============================================================"
Write-Host "Setup complete"
Write-Host "============================================================"
Write-Host ""
Write-Host "  SQL Server:       $SqlFqdn"
Write-Host "  SQL Database:     $SqlDatabaseName"
Write-Host "  OpenAI endpoint:  $OpenAiEndpoint"
Write-Host "  .env file:        written"
Write-Host ""
Write-Host "  Auth: Microsoft Entra (passwordless) - admin: $UserUpn"
Write-Host ""
Write-Host "Next:"
Write-Host "  npm install"
Write-Host "  npm start"
