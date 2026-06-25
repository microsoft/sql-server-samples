![](../../../media/solutions-microsoft-logo-small.png)

# Azure SQL MCP Server with Connector Namespace

Deploy a hosted Azure SQL Model Context Protocol (MCP) server to [Azure Connector Namespace](https://learn.microsoft.com/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp). The sample provisions Azure SQL Database, exposes a `BlogPost` table through Data API Builder MCP, and configures managed identity access so MCP clients such as GitHub Copilot in Visual Studio Code can query the database.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Clean up](#clean-up)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** Azure SQL Database
- **Key features:** Azure Connector Namespace, hosted MCP server, Data API Builder, managed identity, Application Insights
- **Workload:** AI agent data access
- **Programming Language:** Bicep, PowerShell, Bash, JSON

This sample deploys a hosted `mcp-sql` server in Azure Connector Namespace. The hosted MCP server uses Data API Builder configuration to expose a SQL table through MCP tools. The SQL database is seeded with a `dbo.BlogPosts` table containing links to Microsoft Learn and .NET Blog posts. For more background, see [Hosted MCP servers in Azure Connector Namespace](https://learn.microsoft.com/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp).

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az`)
1. [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (`azd`)
1. PowerShell 7+ on Windows, or Bash on Linux/macOS

**Azure prerequisites:**

1. An Azure subscription with permissions to create resource groups and resources.
1. Permission to create Azure SQL Database, Application Insights, Log Analytics workspace, and Connector Namespace resources.
1. Permission to create an Azure SQL Microsoft Entra administrator for the signed-in user.

<a name=run-this-sample></a>

## Run this sample

From this folder:

```bash
azd auth login
azd init
azd up
```

#### `azd init` prompts

When you run `azd init` for the first time, it detects the existing `azure.yaml` and Bicep templates:

1. **"How do you want to initialize your app?"** — Select **Use code in the current directory**.
2. **"Confirm and continue initializing this app"** — Press **Enter** to confirm the detected services.
3. **"Enter a new environment name"** — Pick any name, for example `mcp-dev`. This name is used as a prefix for Azure resource names.

You only need to run `azd init` once. Subsequent deployments only require `azd up`.

#### `azd up` prompts

When you run `azd up`, you are prompted for:

- **Azure Subscription:** Select the Azure subscription to deploy to.
- **Azure location:** Choose a supported region (e.g. `eastasia`, `westcentralus`).
- **`deployerLoginName` infrastructure parameter:** Enter your Azure sign-in email or user principal name, for example `user@contoso.com`. If you don't know the value, run the following command in a different terminal instance and use the result:

  ```bash
  az account show --query user.name -o tsv
  ```
- **`connectorNamespaceIdentityType` infrastructure parameter:** Enter `SystemAssigned` for the default Connector Namespace managed identity, or `UserAssigned` to create and attach a user-assigned managed identity.

The `deployerLoginName` value is used to create the Azure SQL server with Microsoft Entra-only authentication and set you as the SQL Entra admin.

### Optional: use a user-assigned managed identity

When `azd up` prompts for `connectorNamespaceIdentityType`, enter `UserAssigned` to test with a user-assigned managed identity.

When set to `UserAssigned`, the template creates a user-assigned managed identity, attaches it to the Connector Namespace, passes its client ID to the hosted MCP server, and grants that identity access to Azure SQL.

Choose the identity type before the first deployment. Connector Namespace doesn't allow changing attached user-assigned identities after the namespace is created. To switch between `SystemAssigned` and `UserAssigned`, create a new azd environment or run `azd down --purge` and deploy again.

### Connect from Visual Studio Code

After `azd up` completes, the MCP endpoint URL is printed. Add it to VS Code using the UI:

1. In VS Code, open the Command Palette:
   - Windows/Linux: <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
   - macOS: <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
1. Run **MCP: Add Server**.
1. Choose **HTTP** as the server type.
1. Paste the MCP endpoint URL printed by `azd up`.
1. Enter a server name, for example `sql-mcp`.
1. Choose whether to save the server in user settings or workspace settings.
1. Start the `sql-mcp` server when VS Code prompts you.

VS Code prompts you to sign in with Microsoft. Then use Copilot Chat to query your database, for example: *"List the blog posts in the database."*

<a name=sample-details></a>

## Sample details

### Architecture

```
┌─────────────────────────────────────┐
│         Connector Namespace         │
│  (Microsoft.Web/connectorGateways)  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Hosted SQL MCP Server       │  │
│  │   (Data API Builder)          │  │
│  │                               │  │
│  │    MI ───► Azure SQL DB       │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
         ▲
         │  MCP (HTTP + SSE)
         │
    VS Code / Copilot / MCP Client
```

### Resources deployed

| Resource | Purpose |
|----------|---------|
| **Resource Group** | Container for all deployed resources |
| **Azure SQL Server** | Entra-only auth, with you as SQL admin |
| **Azure SQL Database** | Basic SKU database with a `BlogPost` sample table used by the MCP server |
| **SQL Firewall Rules** | Allows Azure services/resources, Azure Portal Query Editor, and your public IP for setup |
| **Log Analytics Workspace** | Stores Application Insights telemetry |
| **Application Insights** | Collects telemetry from the hosted MCP server |
| **Connector Namespace** | Hosts MCP servers with system-assigned managed identity by default, or user-assigned managed identity when configured |
| **Hosted SQL MCP Server** | `mcp-sql` server config on the namespace |
| **MCP Access Policy** | Grants you access to invoke MCP tools |

Resource names use the pattern `<type>-<environment-name>-<short-suffix>` where possible, for example `sql-mcp-dev-a1b2c3d4`. The suffix is deterministic for the subscription, environment name, and location so names are readable and stable across redeployments.

### What `azd up` does

| Step | Action |
|------|--------|
| **Provision** | Deploys Azure SQL, SQL firewall rules, Log Analytics, Application Insights, Connector Namespace, hosted `mcp-sql`, and MCP access policy. |
| **Post-provision** | Allows your public IP through the SQL firewall, creates and seeds `dbo.BlogPosts`, creates the Connector Namespace managed identity SQL user, grants SQL permissions, generates `dab-config.generated.json`, and prints the MCP endpoint plus Azure Portal resource group link. |

The hosted MCP server receives:

- the included `dab-config.json` as `properties.hostedMcpServer.configuration.configFile`
- the generated SQL connection string as `SQL_CONNECTION_STRING`
- the Application Insights connection string as `APPLICATIONINSIGHTS_CONNECTION_STRING`
- `AZURE_CLIENT_ID` when the sample is configured to use a user-assigned managed identity

No SQL or Application Insights connection string is checked in.

This sample includes a ready-to-use `dab-config.json`. If you want to create or customize a Data API Builder configuration from scratch, install the DAB CLI and use it to generate a config file. For more information, see [Install the Data API Builder CLI](https://learn.microsoft.com/azure/data-api-builder/command-line/install).

For details about the hosted MCP server resource model and supported server types, see [Hosted MCP servers in Azure Connector Namespace](https://learn.microsoft.com/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp). For a walkthrough focused on the SQL hosted MCP server, see [Hosted MCP server quickstart for SQL](https://learn.microsoft.com/azure/logic-apps/connector-namespace/hosted-mcp-quickstart?pivots=sql).

### Inspect resources in Azure Portal

After deployment, the post-provision output includes a link to the Azure resource group in the Azure Portal. Use that page to inspect the SQL server, Application Insights resource, Log Analytics workspace, Connector Namespace, and hosted MCP server.

To allow additional users to connect to the MCP server:

1. Open the deployed **Connector Namespace** resource in the Azure Portal.
1. Open the hosted MCP server configuration, for example `sql-mcp`.
1. Add an access policy for each additional user or group that should be allowed to invoke the MCP server.

### Sample data

The post-provision hook creates and seeds `dbo.BlogPosts` with these entries:

| Title | Source |
|-------|--------|
| Hosted MCP servers in Azure Connector Namespace | Microsoft Learn |
| Durable Workflows in Microsoft Agent Framework | .NET Blog |

### SQL firewall access

The deployment configures two SQL firewall paths:

| Rule | When | Purpose |
|------|------|---------|
| `AllowAzureServices` | During Bicep provisioning | Allows Azure services/resources, including Azure Portal Query Editor, to reach the SQL server. |
| `AllowDeployerIp` | During post-provision | Detects your current public IP and allows your local machine to seed and query the database. |

If SQL reports a different blocked client IP during post-provision, the script adds that IP and retries.

<a name=clean-up></a>

## Clean up

Using azd:

```bash
azd down --purge
```

Or with Azure CLI:

```bash
# Replace <environment-name> with your azd environment name.
az group delete --name rg-<environment-name> --yes --no-wait

# Optional: remove the subscription-scope deployment record.
az deployment sub delete --name <environment-name>
```

<a name=related-links></a>

## Related links

- [Hosted MCP servers in Azure Connector Namespace](https://learn.microsoft.com/azure/logic-apps/connector-namespace/connector-namespace-hosted-mcp)
- [Hosted MCP server quickstart for SQL](https://learn.microsoft.com/azure/logic-apps/connector-namespace/hosted-mcp-quickstart?pivots=sql)
- [Azure SQL MCP server support in Data API Builder](https://learn.microsoft.com/azure/data-api-builder/mcp/overview)
- [Install the Data API Builder CLI](https://learn.microsoft.com/azure/data-api-builder/command-line/install)
- [Connector Namespace overview](https://learn.microsoft.com/azure/logic-apps/connector-namespace/connector-namespace-overview)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
