# Azure SQL Vector Search with .NET

This sample demonstrates how to perform native vector search in Azure SQL Database using the .NET SDK and the Azure OpenAI .NET client.

It uses:

- `Microsoft.Data.SqlClient` with Microsoft Entra authentication (`Authentication=Active Directory Default`)
- `Microsoft.Data.SqlClient.Extensions.Azure` for the SQL driver's Active Directory default auth flow
- `Azure.AI.OpenAI` for generating embeddings with a configured Azure OpenAI deployment
- `Azure.Identity` with `DefaultAzureCredential` for passwordless access to Azure SQL and Azure OpenAI

The sample pins the current stable packages available from NuGet: `Microsoft.Data.SqlClient` and
`Microsoft.Data.SqlClient.Extensions.Azure` 7.1.0, `Azure.AI.OpenAI` 2.1.0, and `Azure.Identity` 1.21.0.
SqlClient 7.x requires the Azure extension package when an Entra authentication mode is selected by
connection-string keyword.

## What the sample does

1. Loads 50 hotel rows with precomputed vectors from `data/HotelsData_Vector.json`
2. Connects to Azure SQL Database using Microsoft Entra token authentication from `DefaultAzureCredential`
3. Creates a table with `id`, `name`, `description`, `category`, `rating`, and a `VECTOR(1536)` column
4. Inserts the hotel records and their pretrained vectors
5. Generates a fresh query embedding with Azure OpenAI
6. Performs an exact `VECTOR_DISTANCE` search or an approximate `VECTOR_SEARCH` search with DiskANN when configured
7. Displays the top matches and optionally drops the table at the end

## Prerequisites

- Azure subscription
- Azure SQL Database with native vector support
- Azure OpenAI resource with an embedding deployment such as `text-embedding-3-small`
- .NET 10 SDK
- Azure CLI with `az login`

> [!IMPORTANT]
> Your identity must be a Microsoft Entra admin on the Azure SQL server. For Azure OpenAI, the identity needs the `Cognitive Services OpenAI User` role.

## Get started

### 1. Change to the sample folder

```bash
cd samples/features/vector-search/vector-search-query-dotnet
```

### 2. Configure settings

The sample reads settings from `appsettings.json` and environment variables. Update the values in `appsettings.json` or set equivalent environment variables before running:

```json
{
  "AZURE_SQL_SERVER": "<your-server>.database.windows.net",
  "AZURE_SQL_DATABASE": "<your-database>",
  "AZURE_OPENAI_ENDPOINT": "https://<your-resource>.openai.azure.com",
  "AZURE_OPENAI_EMBEDDING_DEPLOYMENT": "text-embedding-3-small",
  "VECTOR_SEARCH_ALGORITHM": "exact",
  "AZURE_SQL_TABLE_NAME": "hotels_dotnet",
  "SQL_DROP_TABLE": "false"
}
```

Environment variables override the JSON file.

| Variable | Required | Description |
|---|---|---|
| `AZURE_SQL_SERVER` | Yes | Azure SQL server FQDN |
| `AZURE_SQL_DATABASE` | Yes | Database name |
| `AZURE_SQL_TABLE_NAME` | No | Table name (default: `hotels_dotnet`) |
| `AZURE_OPENAI_ENDPOINT` | Yes | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_EMBEDDING_DEPLOYMENT` | Yes | Embedding model deployment name |
| `VECTOR_SEARCH_ALGORITHM` | No | `exact` (default) or `diskann` |
| `SQL_DROP_TABLE` | No | `true` to drop the table after run |

### 3. Run the sample

```bash
dotnet restore
dotnet run
```

To validate the local dataset and vector serialization without connecting to Azure:

```bash
dotnet run -- --self-check
```

## Search algorithms

This sample supports two algorithms:

| Algorithm | T-SQL | Notes |
|---|---|---|
| `exact` | `VECTOR_DISTANCE` | Default and required for the 50-row sample dataset |
| `diskann` | `VECTOR_SEARCH` | Creates a DiskANN index when the table has at least 100 non-null rows; otherwise falls back to exact search |

> [!IMPORTANT]
> DiskANN requires at least 100 rows with non-null vectors. The built-in hotel dataset is small, so `diskann` falls back to exact search automatically unless you load a larger dataset.

## Expected output

> [!IMPORTANT]
> No live Azure environment was available while authoring this sample, so no real end-to-end run has been captured here. This section documents the expected shape of the output based on the already-validated TypeScript reference implementation, and the `output/sample-output.txt` placeholder file makes the same disclosure explicit. Replace this section and the output file with a real captured run before treating the .NET sample as fully validated end-to-end.

```text
=== Azure SQL Vector Search — .NET Quickstart ===
Server:     <your-server>.database.windows.net
Database:   <your-database>
OpenAI:     https://<your-resource>.openai.azure.com
Deployment: text-embedding-3-small
Algorithm:  exact
Table:      dbo.hotels_dotnet

Loaded 50 hotels from data file.

Connecting to Azure SQL Database...
Connected.

Creating table dbo.hotels_dotnet (if not exists)...
Table ready.

Inserting hotel data with pre-computed embeddings...
Inserted 50 hotels.

Searching for: "luxury beachfront hotel with ocean views and spa"

--- Search Results — Exact (kNN) via VECTOR_DISTANCE (Top 3 by Cosine Distance) ---
  Hotel:       <hotel name>
  Category:    <category>
  Rating:      <rating>
  Description: <description>...
  Distance:    <distance>
  Similarity:  <similarity>

Done. Connection closed.
```

## Notes

- This sample does not provision Azure resources.
- No live output is committed as evidence.
- Hotel replacement is transactional, so a failed insert rolls back instead of leaving a partially loaded table.
- When `SQL_DROP_TABLE=true`, cleanup runs even if a later search step fails.
- The sample is intentionally static-only validated until run against a real Azure environment.
