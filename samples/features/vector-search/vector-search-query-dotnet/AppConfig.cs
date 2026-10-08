using Microsoft.Extensions.Configuration;

namespace VectorSearchSample;

public sealed class AppConfig
{
    public string AzureOpenAiEndpoint { get; }
    public string AzureOpenAiEmbeddingDeployment { get; }
    public string AzureSqlServer { get; }
    public string AzureSqlDatabase { get; }
    public string VectorSearchAlgorithm { get; }
    public string TableName { get; }
    public bool DropTable { get; }

    private AppConfig(
        string azureOpenAiEndpoint,
        string azureOpenAiEmbeddingDeployment,
        string azureSqlServer,
        string azureSqlDatabase,
        string vectorSearchAlgorithm,
        string tableName,
        bool dropTable)
    {
        AzureOpenAiEndpoint = azureOpenAiEndpoint;
        AzureOpenAiEmbeddingDeployment = azureOpenAiEmbeddingDeployment;
        AzureSqlServer = azureSqlServer;
        AzureSqlDatabase = azureSqlDatabase;
        VectorSearchAlgorithm = vectorSearchAlgorithm;
        TableName = tableName;
        DropTable = dropTable;
    }

    public static AppConfig Load(IConfiguration configuration)
    {
        var azureOpenAiEndpoint = GetRequired(configuration, "AZURE_OPENAI_ENDPOINT");
        var azureOpenAiEmbeddingDeployment = GetRequired(configuration, "AZURE_OPENAI_EMBEDDING_DEPLOYMENT");
        var azureSqlServer = GetRequired(configuration, "AZURE_SQL_SERVER");
        var azureSqlDatabase = GetRequired(configuration, "AZURE_SQL_DATABASE");

        if (!Uri.TryCreate(azureOpenAiEndpoint, UriKind.Absolute, out var endpointUri) ||
            endpointUri.Scheme != Uri.UriSchemeHttps ||
            endpointUri.Host.Length == 0)
        {
            throw new InvalidOperationException(
                "Invalid AZURE_OPENAI_ENDPOINT. Provide an absolute HTTPS endpoint, for example https://my-resource.openai.azure.com.");
        }

        if (azureSqlServer.Contains("://", StringComparison.Ordinal) ||
            azureSqlServer.Any(char.IsWhiteSpace))
        {
            throw new InvalidOperationException(
                "Invalid AZURE_SQL_SERVER. Provide a server host name without a protocol or whitespace.");
        }

        var algorithm = (configuration["VECTOR_SEARCH_ALGORITHM"] ?? "exact").Trim();
        algorithm = algorithm.ToLowerInvariant();
        if (algorithm is not ("exact" or "diskann"))
        {
            throw new InvalidOperationException($"Invalid VECTOR_SEARCH_ALGORITHM: \"{algorithm}\". Must be \"exact\" or \"diskann\".");
        }

        var tableName = (configuration["AZURE_SQL_TABLE_NAME"] ?? "hotels_dotnet").Trim();
        if (!System.Text.RegularExpressions.Regex.IsMatch(tableName, "^[a-zA-Z_][a-zA-Z0-9_]{0,114}$"))
        {
            throw new InvalidOperationException(
                $"Invalid AZURE_SQL_TABLE_NAME: \"{tableName}\". Must start with a letter or underscore, contain only letters, numbers, and underscores, and be at most 115 characters.");
        }

        var dropTable = bool.TryParse(configuration["SQL_DROP_TABLE"] ?? configuration["dropTable"], out var parsedDropTable) && parsedDropTable;

        return new AppConfig(
            azureOpenAiEndpoint,
            azureOpenAiEmbeddingDeployment,
            azureSqlServer,
            azureSqlDatabase,
            algorithm,
            tableName,
            dropTable);
    }

    private static string GetRequired(IConfiguration configuration, string key)
    {
        var value = configuration[key];
        if (string.IsNullOrWhiteSpace(value) ||
            value.Contains("<your-", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"Missing required configuration value: {key}. Replace the placeholder in appsettings.json or set the environment variable.");
        }

        return value.Trim();
    }
}
