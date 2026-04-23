# Vector Search Samples for Azure SQL Database

Native vector search samples demonstrating the `VECTOR()` data type and `VECTOR_DISTANCE()` function in Azure SQL Database.

## Prerequisites

- Azure subscription — [Create one free](https://azure.microsoft.com/pricing/purchase-options/azure-account)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)

## Quick start with Azure Developer CLI

Deploy all required Azure resources (Azure SQL Database + Azure OpenAI) with one command:

```bash
azd up --cwd samples/features/vector-search
```

This provisions:
- **Azure SQL Database** with native vector support
- **Azure OpenAI** with `text-embedding-3-small` deployment
- **Managed Identity** with appropriate role assignments

After deployment, create the `.env` file for the language samples:

```bash
azd env get-values --cwd samples/features/vector-search > samples/features/vector-search/vector-search-query-typescript/.env
```

This writes the deployment outputs (`AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_EMBEDDING_DEPLOYMENT`, `AZURE_SQL_SERVER`, `AZURE_SQL_DATABASE`, etc.) directly into the `.env` file that the samples read at runtime.

## Language samples

| Language | Folder | Description |
|----------|--------|-------------|
| TypeScript | [vector-search-query-typescript/](./vector-search-query-typescript/) | Vector search with Node.js, tedious driver, and Azure OpenAI |

## Infrastructure only

The `infra/` folder contains Bicep templates that can be deployed independently:

```bash
azd up --cwd infra  # deploy infrastructure only
```

Or used as a module in your own Bicep templates.

## Contributing

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Related content

- [Vectors in Azure SQL and SQL Server](https://learn.microsoft.com/sql/relational-databases/vectors/vectors-sql-server)
- [VECTOR_DISTANCE (Transact-SQL)](https://learn.microsoft.com/sql/t-sql/functions/vector-distance-transact-sql)
- [Azure OpenAI text embeddings](https://learn.microsoft.com/azure/ai-services/openai/concepts/models#embeddings)
