#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# create-resources.sh — Create Azure SQL Database + Azure OpenAI for vector search
#
# Usage:
#   chmod +x scripts/create-resources.sh
#   ./scripts/create-resources.sh                                  # defaults
#   ./scripts/create-resources.sh <resource-group> <location>      # custom
#
# Prerequisites:
#   - Azure CLI installed and logged in (az login)
#   - Active subscription selected (az account set --subscription <id>)
# ---------------------------------------------------------------------------

RESOURCE_GROUP="${1:-rg-sql-vector-quickstart}"
LOCATION="${2:-eastus2}"

echo "============================================================"
echo "Azure SQL Vector Search — Resource Setup"
echo "============================================================"

# ---- Current identity and subscription ----
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
USER_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)

echo "Subscription:   ${SUBSCRIPTION_ID}"
echo "User:           ${USER_UPN} (${USER_OBJECT_ID})"
echo "Resource group: ${RESOURCE_GROUP}"
echo "Location:       ${LOCATION}"
echo ""

# ---- Generate unique suffix for globally unique resource names ----
SUFFIX=$(echo -n "${SUBSCRIPTION_ID}${RESOURCE_GROUP}" | md5sum 2>/dev/null | head -c 8 || printf '%04x%04x' $RANDOM $RANDOM)
SQL_SERVER_NAME="${SQL_SERVER_NAME:-sql-vector-${SUFFIX}}"
OPENAI_ACCOUNT_NAME="${OPENAI_ACCOUNT_NAME:-oai-vector-${SUFFIX}}"
SQL_DATABASE_NAME="vectordb"

TOTAL_STEPS=9
STEP=0
next_step() { STEP=$((STEP + 1)); }

# ---- 1. Create resource group ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Creating resource group: ${RESOURCE_GROUP}..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output none

# ---- 2. Assign Contributor role to current user on resource group ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Assigning Contributor role to current user..."
az role assignment create \
  --assignee-object-id "${USER_OBJECT_ID}" \
  --assignee-principal-type "User" \
  --role "Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" \
  --output none 2>/dev/null || echo "     (Already assigned or inherited)"

# ---- 3. Create Azure OpenAI account ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Creating Azure OpenAI account: ${OPENAI_ACCOUNT_NAME}..."
az cognitiveservices account create \
  --name "${OPENAI_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --kind "OpenAI" \
  --sku "S0" \
  --custom-domain "${OPENAI_ACCOUNT_NAME}" \
  --output none

# ---- 4. Deploy text-embedding-3-small model ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Deploying text-embedding-3-small model..."
az cognitiveservices account deployment create \
  --name "${OPENAI_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --deployment-name "text-embedding-3-small" \
  --model-name "text-embedding-3-small" \
  --model-version "1" \
  --model-format "OpenAI" \
  --sku-name "Standard" \
  --sku-capacity 10 \
  --output none

# ---- 5. Assign Cognitive Services OpenAI User role ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Assigning Cognitive Services OpenAI User role..."
OPENAI_RESOURCE_ID=$(az cognitiveservices account show \
  --name "${OPENAI_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query id -o tsv)

az role assignment create \
  --assignee-object-id "${USER_OBJECT_ID}" \
  --assignee-principal-type "User" \
  --role "Cognitive Services OpenAI User" \
  --scope "${OPENAI_RESOURCE_ID}" \
  --output none 2>/dev/null || echo "     (Already assigned)"

# ---- 6. Create Azure SQL Server with Microsoft Entra admin ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Creating Azure SQL Server: ${SQL_SERVER_NAME}..."
az sql server create \
  --name "${SQL_SERVER_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --enable-ad-only-auth \
  --external-admin-principal-type "User" \
  --external-admin-name "${USER_UPN}" \
  --external-admin-sid "${USER_OBJECT_ID}" \
  --output none

# ---- 7. Create Azure SQL Database ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Creating Azure SQL Database: ${SQL_DATABASE_NAME}..."
az sql db create \
  --server "${SQL_SERVER_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${SQL_DATABASE_NAME}" \
  --service-objective "S0" \
  --output none

# ---- 8. Add client IP to firewall ----
next_step
echo "${STEP}/${TOTAL_STEPS}  Adding client IP to SQL Server firewall..."
CLIENT_IP=$(curl -s https://api.ipify.org)
az sql server firewall-rule create \
  --server "${SQL_SERVER_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --name "AllowClientIP" \
  --start-ip-address "${CLIENT_IP}" \
  --end-ip-address "${CLIENT_IP}" \
  --output none

# Also allow Azure services
az sql server firewall-rule create \
  --server "${SQL_SERVER_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --name "AllowAzureServices" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "0.0.0.0" \
  --output none

# ---- 9. Write .env file ----
next_step
OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name "${OPENAI_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query "properties.endpoint" -o tsv)

SQL_FQDN="${SQL_SERVER_NAME}.database.windows.net"

echo "${STEP}/${TOTAL_STEPS}  Writing .env file..."
cat > .env << EOF
# Generated by scripts/create-resources.sh — $(date -u +"%Y-%m-%dT%H:%M:%SZ")
AZURE_SQL_SERVER=${SQL_FQDN}
AZURE_SQL_DATABASE=${SQL_DATABASE_NAME}
AZURE_OPENAI_ENDPOINT=${OPENAI_ENDPOINT}
AZURE_OPENAI_EMBEDDING_DEPLOYMENT=text-embedding-3-small
EOF

echo ""
echo "============================================================"
echo "Setup complete"
echo "============================================================"
echo ""
echo "  SQL Server:       ${SQL_FQDN}"
echo "  SQL Database:     ${SQL_DATABASE_NAME}"
echo "  OpenAI endpoint:  ${OPENAI_ENDPOINT}"
echo "  .env file:        written"
echo ""
echo "  Auth: Microsoft Entra (passwordless) — admin: ${USER_UPN}"
echo ""
echo "Next:"
echo "  npm install"
echo "  npm start"
