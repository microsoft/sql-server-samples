export type VectorSearchAlgorithm = "exact" | "diskann";

export interface AppConfig {
  azureOpenAiEndpoint: string;
  azureOpenAiEmbeddingDeployment: string;
  azureSqlServer?: string;
  azureSqlDatabase?: string;
  vectorSearchAlgorithm: VectorSearchAlgorithm;
  tableName: string;
  dropTable: boolean;
}

export function loadConfig(requireSql: boolean = true): AppConfig {
  const required = (key: string): string => {
    const value = process.env[key];
    if (!value) {
      throw new Error(
        `Missing required environment variable: ${key}. ` +
          "Copy sample.env to .env and fill in your values."
      );
    }
    return value;
  };

  const optional = (key: string): string | undefined => process.env[key];

  const algorithmRaw = (optional("VECTOR_SEARCH_ALGORITHM") ?? "exact").toLowerCase();
  if (algorithmRaw !== "exact" && algorithmRaw !== "diskann") {
    throw new Error(
      `Invalid VECTOR_SEARCH_ALGORITHM: "${algorithmRaw}". Must be "exact" or "diskann".`
    );
  }

  const tableName = optional("AZURE_SQL_TABLE_NAME") ?? "hotels_typescript";
  // Max 115 chars to accommodate index naming (ix_{name}_embedding = +13 chars, SQL Server limit 128)
  if (!/^[a-zA-Z_][a-zA-Z0-9_]{0,114}$/.test(tableName)) {
    throw new Error(
      `Invalid AZURE_SQL_TABLE_NAME: "${tableName}". ` +
      "Must start with a letter or underscore, contain only letters, numbers, and underscores, " +
      "and be at most 115 characters."
    );
  }

  const config: AppConfig = {
    azureOpenAiEndpoint: required("AZURE_OPENAI_ENDPOINT"),
    azureOpenAiEmbeddingDeployment: required(
      "AZURE_OPENAI_EMBEDDING_DEPLOYMENT"
    ),
    vectorSearchAlgorithm: algorithmRaw as VectorSearchAlgorithm,
    tableName,
    dropTable: (optional("SQL_DROP_TABLE") ?? "false").toLowerCase() === "true",
  };

  if (requireSql) {
    config.azureSqlServer = required("AZURE_SQL_SERVER");
    config.azureSqlDatabase = required("AZURE_SQL_DATABASE");
  } else {
    config.azureSqlServer = optional("AZURE_SQL_SERVER");
    config.azureSqlDatabase = optional("AZURE_SQL_DATABASE");
  }

  return config;
}
