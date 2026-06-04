#!/usr/bin/env bash
# post-provision.sh — Runs after `azd provision` to seed the database and
# generate the DAB config file.

set -euo pipefail

add_sql_firewall_rule_for_ip() {
    local ip_address="$1"
    local rule_name="$2"

    az sql server firewall-rule create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --server "$SQL_SERVER_NAME" \
        --name "$rule_name" \
        --start-ip-address "$ip_address" \
        --end-ip-address "$ip_address" \
        --only-show-errors >/dev/null
}

run_sqlcmd_with_firewall_retry() {
    local query="$1"
    local output
    local max_attempts=20
    local attempt=1

    while [ "$attempt" -le "$max_attempts" ]; do
        set +e
        output=$(echo "$query" | sqlcmd -S "$SQL_SERVER_FQDN" -d "$DATABASE_NAME" -G 2>&1)
        local exit_code=$?
        set -e

        if [ "$exit_code" -eq 0 ]; then
            echo "$output"
            return 0
        fi

        if [[ "$output" =~ Client\ with\ IP\ address\ \'([0-9.]+)\'\ is\ not\ allowed ]]; then
            local blocked_ip="${BASH_REMATCH[1]}"
            echo "  SQL reported blocked client IP $blocked_ip; adding firewall rule and retrying ($attempt/$max_attempts)..."
            add_sql_firewall_rule_for_ip "$blocked_ip" "AllowSqlClientIp"
            sleep 15
            attempt=$((attempt + 1))
            continue
        fi

        echo "$output"
        return "$exit_code"
    done

    echo "Timed out waiting for SQL firewall rules to allow this client."
    return 1
}

# Read outputs from azd
RESOURCE_GROUP_NAME=$(azd env get-value RESOURCE_GROUP_NAME)
SQL_SERVER_NAME=$(azd env get-value SQL_SERVER_NAME)
SQL_SERVER_FQDN=$(azd env get-value SQL_SERVER_FQDN)
DATABASE_NAME=$(azd env get-value SQL_DATABASE_NAME)
CONNECTOR_NS_NAME=$(azd env get-value CONNECTOR_NAMESPACE_NAME)
CONNECTOR_NS_PRINCIPAL=$(azd env get-value CONNECTOR_NAMESPACE_PRINCIPAL_ID)
SQL_IDENTITY_NAME=$(azd env get-value SQL_IDENTITY_NAME || true)
SQL_IDENTITY_PRINCIPAL=$(azd env get-value SQL_IDENTITY_PRINCIPAL_ID || true)
DAB_CONNECTION_STRING=$(azd env get-value DAB_CONNECTION_STRING)

if [ -z "$SQL_IDENTITY_NAME" ]; then
    SQL_IDENTITY_NAME="$CONNECTOR_NS_NAME"
fi
if [ -z "$SQL_IDENTITY_PRINCIPAL" ]; then
    SQL_IDENTITY_PRINCIPAL="$CONNECTOR_NS_PRINCIPAL"
fi

echo ""
echo "============================================================"
echo " Post-Provision Setup"
echo "============================================================"
echo ""
echo "SQL Server:             $SQL_SERVER_FQDN"
echo "Database:               $DATABASE_NAME"
echo "Connector Namespace:    $CONNECTOR_NS_NAME"
echo "Connector NS SAMI ID:   $CONNECTOR_NS_PRINCIPAL"
echo "SQL MI User:            $SQL_IDENTITY_NAME"
echo "SQL MI Principal ID:    $SQL_IDENTITY_PRINCIPAL"
echo ""

# --- Step 1: Allow this machine through the SQL firewall ---
echo "[1/4] Configuring SQL firewall for this machine..."
DETECTED_IPS=()
for IP_ENDPOINT in "https://api.ipify.org" "https://ifconfig.me/ip"; do
    DETECTED_IP=$(curl -s --max-time 10 "$IP_ENDPOINT" || true)
    if [[ "$DETECTED_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        DETECTED_IPS+=("$DETECTED_IP")
    fi
done

if [ "${#DETECTED_IPS[@]}" -eq 0 ]; then
    echo "  WARNING: Could not detect public IP. SQL commands may need to be run manually."
else
    INDEX=0
    printf "%s\n" "${DETECTED_IPS[@]}" | sort -u | while read -r DEPLOYER_IP; do
        INDEX=$((INDEX + 1))
        RULE_NAME="AllowDeployerIp"
        if [ "$INDEX" -gt 1 ]; then
            RULE_NAME="AllowDeployerIp$INDEX"
        fi
        add_sql_firewall_rule_for_ip "$DEPLOYER_IP" "$RULE_NAME"
        echo "  Allowed public IP: $DEPLOYER_IP"
    done
fi

# --- Step 2: Get an access token for Azure SQL ---
echo "[2/4] Getting access token for Azure SQL..."
TOKEN=$(az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv)
if [ -z "$TOKEN" ]; then
    echo "ERROR: Failed to get access token. Make sure you are logged in with 'az login'."
    exit 1
fi

# --- Step 3: Seed the database ---
echo "[3/4] Seeding the database with BlogPost table..."

SEED_SQL="IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BlogPost')
BEGIN
    CREATE TABLE dbo.BlogPost (
        Id int IDENTITY(1,1) PRIMARY KEY,
        Title nvarchar(300) NOT NULL,
        Url nvarchar(1000) NOT NULL,
        Source nvarchar(100) NOT NULL
    );
END;
IF NOT EXISTS (SELECT 1 FROM dbo.BlogPost WHERE Url = N'https://learn.microsoft.com/en-us/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp')
BEGIN
    INSERT INTO dbo.BlogPost (Title, Url, Source)
    VALUES (N'Hosted MCP servers in Azure Connector Namespace', N'https://learn.microsoft.com/en-us/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp', N'Microsoft Learn');
END;
IF NOT EXISTS (SELECT 1 FROM dbo.BlogPost WHERE Url = N'https://devblogs.microsoft.com/dotnet/durable-workflows-in-microsoft-agent-framework/')
BEGIN
    INSERT INTO dbo.BlogPost (Title, Url, Source)
    VALUES (N'Durable Workflows in Microsoft Agent Framework', N'https://devblogs.microsoft.com/dotnet/durable-workflows-in-microsoft-agent-framework/', N'.NET Blog');
END;"

GRANT_SQL="IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${SQL_IDENTITY_NAME}')
BEGIN
    CREATE USER [${SQL_IDENTITY_NAME}] FROM EXTERNAL PROVIDER;
END;
IF ISNULL(IS_ROLEMEMBER('db_datareader', '${SQL_IDENTITY_NAME}'), 0) = 0
    ALTER ROLE db_datareader ADD MEMBER [${SQL_IDENTITY_NAME}];
IF ISNULL(IS_ROLEMEMBER('db_datawriter', '${SQL_IDENTITY_NAME}'), 0) = 0
    ALTER ROLE db_datawriter ADD MEMBER [${SQL_IDENTITY_NAME}];
GRANT VIEW DEFINITION TO [${SQL_IDENTITY_NAME}];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${SQL_IDENTITY_NAME}')
    THROW 51000, 'Connector Namespace managed identity SQL user was not created.', 1;
IF ISNULL(IS_ROLEMEMBER('db_datareader', '${SQL_IDENTITY_NAME}'), 0) <> 1
    THROW 51001, 'Connector Namespace managed identity is not a member of db_datareader.', 1;
IF ISNULL(IS_ROLEMEMBER('db_datawriter', '${SQL_IDENTITY_NAME}'), 0) <> 1
    THROW 51002, 'Connector Namespace managed identity is not a member of db_datawriter.', 1;"

if command -v sqlcmd &> /dev/null; then
    run_sqlcmd_with_firewall_retry "$SEED_SQL"
    echo "  Database seeded."
    echo "[4/4] Granting managed identity access..."
    run_sqlcmd_with_firewall_retry "$GRANT_SQL"
    echo "  Managed identity access granted."
else
    echo "WARNING: sqlcmd not found. Please run these SQL commands in the Azure Portal Query Editor:"
    echo ""
    echo "$SEED_SQL"
    echo ""
    echo "$GRANT_SQL"
    exit 1
fi

# --- Generate DAB config ---
echo ""
echo "Generating dab-config.generated.json..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cat > "$SCRIPT_DIR/../dab-config.generated.json" <<EOF
{
  "\$schema": "https://github.com/Azure/data-api-builder/releases/download/v1.7.93/dab.draft.schema.json",
  "data-source": {
    "database-type": "mssql",
    "connection-string": "${DAB_CONNECTION_STRING}",
    "options": { "set-session-context": false }
  },
  "runtime": {
    "rest": { "enabled": false, "path": "/api", "request-body-strict": true },
    "graphql": { "enabled": false, "path": "/graphql", "allow-introspection": true },
    "mcp": { "enabled": true, "path": "/mcp" },
    "host": {
      "cors": { "origins": [], "allow-credentials": false },
      "authentication": { "provider": "AppService" },
      "mode": "development"
    }
  },
  "entities": {
    "BlogPost": {
      "source": { "object": "dbo.BlogPost", "type": "table" },
      "graphql": { "enabled": true, "type": { "singular": "BlogPost", "plural": "BlogPosts" } },
      "rest": { "enabled": true },
      "permissions": [{ "role": "anonymous", "actions": [{ "action": "*" }] }]
    }
  }
}
EOF
echo "  Created dab-config.generated.json"

# --- Final output ---
MCP_ENDPOINT_URL=$(azd env get-value MCP_ENDPOINT_URL)
SUBSCRIPTION_ID=$(azd env get-value AZURE_SUBSCRIPTION_ID)
if [ -z "$SUBSCRIPTION_ID" ]; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
fi
RESOURCE_GROUP_URL="https://portal.azure.com/#@/resource/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/overview"

echo ""
echo "============================================================"
echo " Deployment Complete!"
echo "============================================================"
echo ""
echo "MCP Endpoint: $MCP_ENDPOINT_URL"
echo "Azure Portal: $RESOURCE_GROUP_URL"
echo ""
echo "Use the MCP endpoint with any MCP client that supports HTTP transport."
echo ""
