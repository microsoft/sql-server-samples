# Quickstart: Vector search with TypeScript in Azure SQL Database

This sample demonstrates how to perform **native vector search** in Azure SQL Database using TypeScript and Node.js.

It uses:

- **[tedious](https://www.npmjs.com/package/tedious)**—Microsoft's Node.js driver for SQL Server, with Azure AD authentication
- **[openai](https://www.npmjs.com/package/openai)**—Azure OpenAI SDK for generating embeddings (via the `AzureOpenAI` class)
- **[@azure/identity](https://www.npmjs.com/package/@azure/identity)**—`DefaultAzureCredential` for passwordless authentication to both Azure SQL and Azure OpenAI

## What the sample does

1. Loads 50 hotels with precomputed embeddings from `data/HotelsData_Vector.json`
2. Connects to Azure SQL Database using `DefaultAzureCredential` (no passwords or API keys)
3. Creates a table with `id`, `name`, `description`, `category`, `rating`, and a `VECTOR(1536)` column
4. Inserts all 50 hotels with their precomputed vector embeddings
5. Generates a fresh query embedding using Azure OpenAI `text-embedding-3-small`
6. Performs a vector similarity search using either **exact kNN** (`VECTOR_DISTANCE`) or **approximate ANN** (`VECTOR_SEARCH` with DiskANN index), based on the `VECTOR_SEARCH_ALGORITHM` environment variable
7. Displays the top matching results with category, rating, and similarity scores

## Vector search algorithms

This sample supports two algorithms, selected via the `VECTOR_SEARCH_ALGORITHM` environment variable:

| | Exact search (default) | Approximate search (DiskANN) |
|---|---|---|
| **Env var value** | `exact` | `diskann` |
| **T-SQL function** | `VECTOR_DISTANCE` | `VECTOR_SEARCH` |
| **Index required** | No | Yes (auto-created) |
| **Recall** | 100% (guaranteed) | ~95–99% (tunable) |
| **Minimum rows** | No minimum | 1,000 non-null vectors |
| **Best for** | < 50,000 rows, prototyping | > 10,000 rows, production |

> [!IMPORTANT]
> DiskANN index creation requires at least **1,000 rows** with non-null vectors. The 50-hotel sample dataset is too small—load a larger dataset before using `VECTOR_SEARCH_ALGORITHM=diskann`.

## Prerequisites

- **Azure subscription**—[Create one free](https://azure.microsoft.com/free/)
- **Azure SQL Database** with native vector support—[Quickstart: Create a single database](https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart)
- **Azure OpenAI resource** with a `text-embedding-3-small` deployment—[Create and deploy an Azure OpenAI Service resource](https://learn.microsoft.com/azure/ai-services/openai/how-to/create-resource)
- **Node.js 20+**—[Download Node.js](https://nodejs.org/)
- **Azure CLI**—[Install the Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), signed in with `az login`

> [!IMPORTANT]
> Your Azure identity must be configured as a **Microsoft Entra admin** on the Azure SQL server. The `azd up` deployment sets this automatically using `deploymentUserPrincipalId`. For the Azure OpenAI resource, you need the **Cognitive Services OpenAI User** role.

> [!IMPORTANT]
> After deploying with `azd up`, you may need to add your client IP to the Azure SQL firewall. Run:
> ```bash
> az sql server firewall-rule create --resource-group <rg-name> --server <server-name> --name AllowMyIP --start-ip-address <your-ip> --end-ip-address <your-ip>
> ```
> Or set `AZURE_CLIENT_IP` in your environment before running `azd up` to have it configured automatically.

## Get started

### 1. Clone the repository

```bash
git clone https://github.com/microsoft/sql-server-samples.git
cd sql-server-samples/samples/features/vector-search/vector-search-query-typescript
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure environment variables

Copy the sample environment file and fill in your values:

```bash
cp sample.env .env
```

Edit `.env` with your Azure resource details:

```env
AZURE_SQL_SERVER=<your-server>.database.windows.net
AZURE_SQL_DATABASE=<your-database>
AZURE_OPENAI_ENDPOINT=https://<your-resource>.openai.azure.com
AZURE_OPENAI_EMBEDDING_DEPLOYMENT=text-embedding-3-small
VECTOR_SEARCH_ALGORITHM=exact
```

| Variable | Required | Description |
|---|---|---|
| `AZURE_SQL_SERVER` | Yes | Azure SQL server FQDN |
| `AZURE_SQL_DATABASE` | Yes | Database name |
| `AZURE_SQL_TABLE_NAME` | No | Table name (default: `hotels_typescript`) |
| `AZURE_OPENAI_ENDPOINT` | Yes | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_EMBEDDING_DEPLOYMENT` | Yes | Embedding model deployment name |
| `VECTOR_SEARCH_ALGORITHM` | No | `exact` (default) or `diskann` |
| `SQL_DROP_TABLE` | No | `true` to drop table after run (default: `false`) |

> [!NOTE]
> No API keys are needed. The sample uses `DefaultAzureCredential`, which automatically uses your Azure CLI login, managed identity, or other credential sources.

### 4. Run the sample

```bash
npm start
```

This runs the TypeScript code directly using `tsx` with Node.js 20+ native env-file loading.

## Expected output

```
=== Azure SQL Vector Search—TypeScript Quickstart ===

Server:     <your-server>.database.windows.net
Database:   <your-database>
OpenAI:     https://<your-resource>.openai.azure.com
Deployment: text-embedding-3-small
Algorithm:  exact
Table:      dbo.hotels_typescript

Loaded 50 hotels from data file.

Connecting to Azure SQL Database...
Connected.

Creating hotels table (if not exists)...
Table ready.

Inserting hotel data with precomputed embeddings...
Inserted 50 hotels.

Searching for: "luxury beachfront hotel with ocean views and spa"

--- Search Results—Exact (kNN) via VECTOR_DISTANCE (Top 3 by Cosine Distance) ---

  Hotel:       Ocean Water Resort & Spa
  Category:    Luxury
  Rating:      4.2
  Description: New Luxury Hotel for the vacation of a lifetime. Bay views from every room, location near the pier, ...
  Distance:    0.4060
  Similarity:  0.5940

  Hotel:       Windy Ocean Motel
  Category:    Suite
  Rating:      3.5
  Description: Oceanfront hotel overlooking the beach features rooms with a private balcony and 2 indoor and outdoo...
  Distance:    0.4600
  Similarity:  0.5400

  Hotel:       Gold View Inn
  Category:    Suite
  Rating:      2.8
  Description: AAA Four Diamond Resort. Nestled on six beautifully landscaped acres, located 2 blocks from the park...
  Distance:    0.5296
  Similarity:  0.4704

Done. Connection closed.
```

> [!NOTE]
> Distance and similarity values depend on the embedding model and may vary slightly across runs.

## Understanding the code

### Connection with DefaultAzureCredential

The sample uses `tedious` with Azure AD token-based authentication. A token is acquired from `DefaultAzureCredential` for the `https://database.windows.net/.default` scope:

```typescript
const credential = new DefaultAzureCredential();
const token = await credential.getToken("https://database.windows.net/.default");
```

### Table with VECTOR column

Azure SQL Database supports the native `VECTOR` type. The table is created with columns for hotel metadata and a `VECTOR(1536)` column to store embeddings:

```sql
CREATE TABLE dbo.hotels_typescript (
    id NVARCHAR(50) PRIMARY KEY,
    name NVARCHAR(200) NOT NULL,
    description NVARCHAR(MAX) NOT NULL,
    category NVARCHAR(100) NULL,
    rating FLOAT NULL,
    embedding VECTOR(1536) NULL
);
```

### Loading precomputed vectors

Hotel data with precomputed embeddings is loaded from `data/HotelsData_Vector.json`. This avoids calling Azure OpenAI for each hotel during the main run, making the demo faster and simpler:

```typescript
const hotels = JSON.parse(readFileSync(dataPath, "utf-8"));
```

### Generating query embeddings

At search time, a fresh embedding is generated for the search query using Azure OpenAI's `text-embedding-3-small` model through the `openai` SDK with `@azure/identity` for authentication:

```typescript
import { getBearerTokenProvider } from "@azure/identity";
import { AzureOpenAI } from "openai";

const azureADTokenProvider = getBearerTokenProvider(
    credential,
    "https://cognitiveservices.azure.com/.default"
);
const openaiClient = new AzureOpenAI({
    endpoint: config.azureOpenAiEndpoint,
    azureADTokenProvider,
    apiVersion: "2024-10-21", // See https://learn.microsoft.com/azure/ai-services/openai/api-version-deprecation
});

const response = await openaiClient.embeddings.create({
    model: deployment,
    input: texts,
});
```

### Vector similarity search

**Exact search (default)**—The `VECTOR_DISTANCE()` function computes cosine distance between the query vector and all stored embeddings:

```sql
SELECT TOP 3
    name, description, category, rating,
    VECTOR_DISTANCE('cosine', embedding, CAST(@queryVector AS VECTOR(1536))) AS distance
FROM dbo.hotels_typescript
ORDER BY distance;
```

**Approximate search (DiskANN)**—The `VECTOR_SEARCH()` function uses a DiskANN index for 10–100× faster queries on large datasets:

```sql
SELECT TOP 3
    vs.distance,
    h.name, h.description, h.category, h.rating
FROM VECTOR_SEARCH(
    dbo.hotels_typescript, embedding,
    CAST(@queryVector AS VECTOR(1536)),
    'cosine', 3
) AS vs
INNER JOIN dbo.hotels_typescript h ON vs.$rowid = h.$rowid
ORDER BY vs.distance;
```

A lower distance means higher similarity.

### Re-generate embeddings (optional)

If you change embedding models, re-generate the vector data:

```bash
npm run embed
```

This reads `data/HotelsData.JSON`, generates new embeddings using your Azure OpenAI deployment, and writes `data/HotelsData_Vector.json`.

## Clean up resources

To remove the sample table from your database:

```sql
DROP INDEX IF EXISTS ix_hotels_typescript_embedding ON dbo.hotels_typescript;
DROP TABLE IF EXISTS dbo.hotels_typescript;
```

To avoid ongoing charges, delete the Azure resources you created if they were only for this quickstart:

- [Delete the Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/single-database-manage#delete-a-single-database)
- [Delete the Azure OpenAI resource](https://learn.microsoft.com/azure/ai-services/openai/how-to/create-resource#delete-a-resource)

## Troubleshooting

### Authentication failures

**"Login failed"**—Ensure your Azure identity is set as Microsoft Entra admin on the SQL server. Run `az login` to refresh your credentials.

**"AuthenticationError" from Azure OpenAI**—Verify you have the **Cognitive Services OpenAI User** role on the Azure OpenAI resource. Check the endpoint URL and deployment name in your `.env` file.

### Firewall errors

**"Cannot open server"**—Your client IP may not be in the SQL firewall rules. Add it:

```bash
az sql server firewall-rule create \
  --resource-group <rg-name> --server <server-name> \
  --name AllowMyIP --start-ip-address <your-ip> --end-ip-address <your-ip>
```

### DiskANN errors

**"DiskANN index requires at least 1,000 rows"**—The 50-hotel sample dataset is too small for DiskANN. The sample automatically detects this and falls back to exact nearest-neighbor search using `VECTOR_DISTANCE` without a vector index. To use DiskANN, load a larger dataset first.

### Vector dimension errors

**"Invalid or missing vector dimensions"**—The precomputed embeddings in `HotelsData_Vector.json` must use 1536 dimensions (matching `text-embedding-3-small`). Re-run `npm run embed` if you changed the embedding model.

## Explore your database

To browse tables, run queries, and inspect vector data directly from VS Code, install the [SQL Server (mssql)](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql) extension. Connect using your Azure AD credentials—the same authentication the sample uses.

## Related content

- [Vectors in Azure SQL and SQL Server](https://learn.microsoft.com/sql/sql-server/ai/vectors)
- [VECTOR_DISTANCE (Transact-SQL)](https://learn.microsoft.com/sql/t-sql/functions/vector-distance-transact-sql)
- [Azure OpenAI text embeddings](https://learn.microsoft.com/azure/ai-services/openai/concepts/models#embeddings)
- [DefaultAzureCredential overview](https://learn.microsoft.com/javascript/api/overview/azure/identity-readme#defaultazurecredential)
