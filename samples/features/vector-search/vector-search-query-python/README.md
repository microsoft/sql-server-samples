# Quickstart: Vector search with Python in Azure SQL Database

This sample demonstrates how to perform **native vector search** in Azure SQL Database using Python.

It uses:

- **[pyodbc](https://pypi.org/project/pyodbc/)**—the ODBC-based Python driver for SQL Server and Azure SQL Database, with Microsoft Entra token authentication (requires **ODBC Driver 18 for SQL Server** installed on the host)
- **[openai](https://pypi.org/project/openai/)**—the OpenAI Python client library for generating embeddings (via the `AzureOpenAI` class); published by OpenAI, not an Azure SDK package, though it has built-in Azure OpenAI support
- **[azure-identity](https://pypi.org/project/azure-identity/)**—`DefaultAzureCredential` for passwordless authentication to both Azure SQL and Azure OpenAI

## What the sample does

1. Loads 50 hotels with precomputed embeddings from `data/HotelsData_Vector.json`
2. Connects to Azure SQL Database using an Entra access token obtained from `DefaultAzureCredential` (no passwords or API keys)
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
> DiskANN index creation requires at least **1,000 rows** with non-null vectors. The 50-hotel sample dataset is too small—load a larger dataset before using `VECTOR_SEARCH_ALGORITHM=diskann`. This sample detects the row count at runtime and automatically falls back to exact search below that threshold.

## Prerequisites

- **Azure subscription**—[Create one free](https://azure.microsoft.com/free/)
- **Azure SQL Database** with native vector support—[Quickstart: Create a single database](https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart)
- **Azure OpenAI resource** with a `text-embedding-3-small` deployment—[Create and deploy an Azure OpenAI Service resource](https://learn.microsoft.com/azure/ai-services/openai/how-to/create-resource)
- **Python 3.13+**—[Download Python](https://www.python.org/downloads/)
- **ODBC Driver 18 for SQL Server**—[Download the ODBC driver](https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server) (required by `pyodbc`; install per your OS)
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
cd sql-server-samples/samples/features/vector-search/vector-search-query-python
```

### 2. Create a virtual environment and install dependencies

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
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
| `AZURE_SQL_TABLE_NAME` | No | Table name (default: `hotels_python`) |
| `AZURE_OPENAI_ENDPOINT` | Yes | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_EMBEDDING_DEPLOYMENT` | Yes | Embedding model deployment name |
| `VECTOR_SEARCH_ALGORITHM` | No | `exact` (default) or `diskann` |
| `SQL_DROP_TABLE` | No | `true` to drop table after run (default: `false`) |

> [!NOTE]
> No API keys are needed. The sample uses `DefaultAzureCredential`, which automatically uses your Azure CLI login, managed identity, or other credential sources.

### 4. Run the sample

```bash
python src/index.py
```

## Expected output

> [!IMPORTANT]
> **No live Azure environment was available while authoring this sample**, so no real end-to-end run has been captured yet. The section below documents the *shape* of the expected output based on the identical, already-validated TypeScript reference implementation's real captured run — it is **not** a captured Python run and must not be treated as validated evidence. See [`output/sample-output.txt`](./output/sample-output.txt) for the same explicit disclosure. Replace this section and that file with a real captured run before relying on this sample as validated.

```
=== Azure SQL Vector Search—Python Quickstart ===

Server:     <your-server>.database.windows.net
Database:   <your-database>
OpenAI:     https://<your-resource>.openai.azure.com
Deployment: text-embedding-3-small
Algorithm:  exact
Table:      dbo.hotels_python

Loaded 50 hotels from data file.

Connecting to Azure SQL Database...
Connected.

Creating table dbo.hotels_python (if not exists)...
Table ready.

Inserting hotel data with precomputed embeddings...
Inserted 50 hotels.

Searching for: "luxury beachfront hotel with ocean views and spa"

--- Search Results—Exact (kNN) via VECTOR_DISTANCE (Top 3 by Cosine Distance) ---

  Hotel:       <hotel name>
  Category:    <category>
  Rating:      <rating>
  Description: <description>...
  Distance:    <distance>
  Similarity:  <similarity>

Done. Connection closed.
```

> [!NOTE]
> Distance and similarity values depend on the embedding model and may vary slightly across runs. Once a real run is captured, this sample should return the **same top hotel match** as the TypeScript reference (cross-language result parity), per the constitution's canonical-query requirement.

## Understanding the code

### Connection with an Entra access token

`pyodbc` doesn't have a built-in `DefaultAzureCredential` integration like `tedious` or `Microsoft.Data.SqlClient`, so this sample acquires a token explicitly and passes it via the ODBC `SQL_COPT_SS_ACCESS_TOKEN` connection attribute—the standard, Microsoft-documented pattern for Entra authentication with `pyodbc`:

```python
import struct
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
token = credential.get_token("https://database.windows.net/.default").token

SQL_COPT_SS_ACCESS_TOKEN = 1256
token_bytes = token.encode("utf-16-le")
token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)

conn = pyodbc.connect(conn_str, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})
```

### Table with VECTOR column

Azure SQL Database supports the native `VECTOR` type. The table is created with columns for hotel metadata and a `VECTOR(1536)` column to store embeddings:

```sql
CREATE TABLE dbo.hotels_python (
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

```python
with data_path.open("r", encoding="utf-8") as f:
    hotels = json.load(f)
```

### Generating query embeddings

At search time, a fresh embedding is generated for the search query using Azure OpenAI's `text-embedding-3-small` model through the `openai` package's `AzureOpenAI` class with `azure-identity` for authentication:

```python
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI

token_provider = get_bearer_token_provider(
    credential, "https://cognitiveservices.azure.com/.default"
)
client = AzureOpenAI(
    azure_endpoint=config.azure_openai_endpoint,
    azure_ad_token_provider=token_provider,
    api_version="2024-10-21",  # See https://learn.microsoft.com/azure/ai-services/openai/api-version-deprecation
)

response = client.embeddings.create(model=deployment, input=[text])
```

### Vector similarity search

**Exact search (default)**—The `VECTOR_DISTANCE()` function computes cosine distance between the query vector and all stored embeddings:

```sql
SELECT TOP 3
    name, description, category, rating,
    VECTOR_DISTANCE('cosine', embedding, CAST(? AS VECTOR(1536))) AS distance
FROM dbo.hotels_python
ORDER BY distance;
```

**Approximate search (DiskANN)**—The `VECTOR_SEARCH()` function uses a DiskANN index for 10–100× faster queries on large datasets:

```sql
SELECT TOP 3
    vs.distance,
    h.name, h.description, h.category, h.rating
FROM VECTOR_SEARCH(
    dbo.hotels_python, embedding,
    CAST(? AS VECTOR(1536)),
    'cosine', 3
) AS vs
INNER JOIN dbo.hotels_python h ON vs.$rowid = h.$rowid
ORDER BY vs.distance;
```

A lower distance means higher similarity.

### Re-generate embeddings (optional)

If you change embedding models, re-generate the vector data:

```bash
python src/embed.py
```

This reads `data/HotelsData.JSON`, generates new embeddings using your Azure OpenAI deployment, and writes `data/HotelsData_Vector.json`.

## Clean up resources

To remove the sample table from your database:

```sql
DROP INDEX IF EXISTS ix_hotels_python_embedding ON dbo.hotels_python;
DROP TABLE IF EXISTS dbo.hotels_python;
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

### ODBC driver errors

**"Data source name not found" / `IM002` error**—ODBC Driver 18 for SQL Server is not installed. [Install it](https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server) for your OS.

### DiskANN errors

**"DiskANN index requires at least 1,000 rows"**—The 50-hotel sample dataset is too small for DiskANN. The sample automatically detects this and falls back to exact nearest-neighbor search using `VECTOR_DISTANCE` without a vector index. To use DiskANN, load a larger dataset first.

### Vector dimension errors

**"Invalid or missing vector dimensions"**—The precomputed embeddings in `HotelsData_Vector.json` must use 1536 dimensions (matching `text-embedding-3-small`). Re-run `python src/embed.py` if you changed the embedding model.

## Development

This sample includes unit tests for pure logic (configuration validation, vector serialization, dataset validation) that require no Azure connectivity:

```bash
pip install -r requirements-dev.txt
python -m pytest
python -m ruff check .
python -m ruff format --check .
python -m mypy src
```

## Related content

- [Vectors in Azure SQL and SQL Server](https://learn.microsoft.com/sql/sql-server/ai/vectors)
- [VECTOR_DISTANCE (Transact-SQL)](https://learn.microsoft.com/sql/t-sql/functions/vector-distance-transact-sql)
- [Azure OpenAI text embeddings](https://learn.microsoft.com/azure/ai-services/openai/concepts/models#embeddings)
- [pyodbc wiki](https://github.com/mkleehammer/pyodbc/wiki)
