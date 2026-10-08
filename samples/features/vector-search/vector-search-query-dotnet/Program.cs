using System.Data;
using System.Globalization;
using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using OpenAI;
using OpenAI.Embeddings;
using VectorSearchSample;

var configuration = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables()
    .Build();

if (args.Contains("--self-check", StringComparer.OrdinalIgnoreCase))
{
    var selfCheckHotels = HotelData.Load(HotelData.ResolveDataFilePath());
    var serializedVector = VectorUtilities.ToVectorString(selfCheckHotels[0].DescriptionVector);
    using var vectorDocument = System.Text.Json.JsonDocument.Parse(serializedVector);
    if (vectorDocument.RootElement.GetArrayLength() != 1536)
    {
        throw new InvalidOperationException("Vector serialization self-check failed.");
    }

    Console.WriteLine($"Self-check passed: loaded {selfCheckHotels.Count} hotels and serialized a 1536-dimension vector.");
    return;
}

var config = AppConfig.Load(configuration);

Console.WriteLine("=== Azure SQL Vector Search — .NET Quickstart ===");
Console.WriteLine($"Server:     {config.AzureSqlServer}");
Console.WriteLine($"Database:   {config.AzureSqlDatabase}");
Console.WriteLine($"OpenAI:     {config.AzureOpenAiEndpoint}");
Console.WriteLine($"Deployment: {config.AzureOpenAiEmbeddingDeployment}");
Console.WriteLine($"Algorithm:  {config.VectorSearchAlgorithm}");
Console.WriteLine($"Table:      dbo.{config.TableName}");

var dataFilePath = HotelData.ResolveDataFilePath();
var hotels = HotelData.Load(dataFilePath);
Console.WriteLine($"Loaded {hotels.Count} hotels from data file.");

var credential = new DefaultAzureCredential();
var connectionString = BuildConnectionString(config);

await using var connection = new SqlConnection(connectionString);
Console.WriteLine();
Console.WriteLine("Connecting to Azure SQL Database...");
await connection.OpenAsync();
Console.WriteLine("Connected.");

var tableReady = false;
try
{
    var tableName = config.TableName;
    Console.WriteLine($"Creating table dbo.{tableName} (if not exists)...");
    await ExecuteNonQueryAsync(connection,
        $"IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'{tableName}' AND schema_id = SCHEMA_ID('dbo')) " +
        "BEGIN " +
        $"CREATE TABLE dbo.[{tableName}] ( " +
        "id NVARCHAR(50) PRIMARY KEY, " +
        "name NVARCHAR(200) NOT NULL, " +
        "description NVARCHAR(MAX) NOT NULL, " +
        "category NVARCHAR(100) NULL, " +
        "rating FLOAT NULL, " +
        "embedding VECTOR(1536) NULL " +
        "); END");
    tableReady = true;
    Console.WriteLine("Table ready.");

    Console.WriteLine();
    Console.WriteLine("Inserting hotel data with pre-computed embeddings...");
    await using (var transaction = (SqlTransaction)await connection.BeginTransactionAsync())
    {
        try
        {
            await ExecuteNonQueryAsync(connection, $"DELETE FROM dbo.[{tableName}]", transaction: transaction);

            const int batchSize = 10;
            for (var i = 0; i < hotels.Count; i += batchSize)
            {
                var batch = hotels.Skip(i).Take(batchSize).ToList();
                var parameterList = new List<SqlParameter>();
                var valueClauses = new List<string>();

                for (var j = 0; j < batch.Count; j++)
                {
                    var hotel = batch[j];
                    var idParam = new SqlParameter($"@id{j}", SqlDbType.NVarChar, 50) { Value = hotel.HotelId };
                    var nameParam = new SqlParameter($"@name{j}", SqlDbType.NVarChar, 200) { Value = hotel.HotelName };
                    var descParam = new SqlParameter($"@desc{j}", SqlDbType.NVarChar, -1) { Value = hotel.Description };
                    var categoryParam = new SqlParameter($"@cat{j}", SqlDbType.NVarChar, 100) { Value = hotel.Category };
                    var ratingParam = new SqlParameter($"@rating{j}", SqlDbType.Float) { Value = hotel.Rating };
                    var embeddingParam = new SqlParameter($"@emb{j}", SqlDbType.NVarChar, -1)
                    {
                        Value = VectorUtilities.ToVectorString(hotel.DescriptionVector)
                    };

                    parameterList.AddRange(new[] { idParam, nameParam, descParam, categoryParam, ratingParam, embeddingParam });
                    valueClauses.Add($"(@id{j}, @name{j}, @desc{j}, @cat{j}, @rating{j}, CAST(@emb{j} AS VECTOR(1536)))");
                }

                var insertSql = $"INSERT INTO dbo.[{tableName}] (id, name, description, category, rating, embedding) VALUES {string.Join(", ", valueClauses)}";
                await ExecuteNonQueryAsync(connection, insertSql, parameterList, transaction);
            }

            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    Console.WriteLine($"Inserted {hotels.Count} hotels.");

    const string searchQuery = "luxury beachfront hotel with ocean views and spa";
    Console.WriteLine();
    Console.WriteLine($"Searching for: \"{searchQuery}\"");

    var openAiClient = new AzureOpenAIClient(new Uri(config.AzureOpenAiEndpoint), credential);
    var queryEmbedding = await GetEmbeddingAsync(openAiClient, config.AzureOpenAiEmbeddingDeployment, searchQuery);

    var vectorString = VectorUtilities.ToVectorString(queryEmbedding);
    var effectiveAlgorithm = config.VectorSearchAlgorithm;

    if (effectiveAlgorithm == "diskann")
    {
        var rowCount = await GetRowCountAsync(connection, tableName);
        effectiveAlgorithm = SearchUtilities.ResolveAlgorithm(effectiveAlgorithm, rowCount);
        if (effectiveAlgorithm == "exact")
        {
            Console.WriteLine();
            Console.WriteLine($"Warning: DiskANN index requires at least {SearchUtilities.DiskAnnMinimumRowCount:N0} rows with non-null vectors, but table has only {rowCount}. Falling back to exact search.");
        }
        else
        {
            Console.WriteLine("Creating DiskANN vector index (if not exists)...");
            await ExecuteNonQueryAsync(connection,
                $"IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'ix_{tableName}_embedding' AND object_id = OBJECT_ID('dbo.[{tableName}]')) " +
                "BEGIN " +
                $"CREATE VECTOR INDEX [ix_{tableName}_embedding] ON dbo.[{tableName}](embedding) WITH (type = 'DiskANN', metric = 'cosine'); END");
            Console.WriteLine("DiskANN index ready.");
        }
    }

    Console.WriteLine();
    var results = effectiveAlgorithm == "diskann"
        ? await RunDiskannAsync(connection, tableName, vectorString)
        : await RunExactAsync(connection, tableName, vectorString);

    var algorithmLabel = effectiveAlgorithm == "diskann" ? "Approximate (DiskANN) via VECTOR_SEARCH" : "Exact (kNN) via VECTOR_DISTANCE";
    Console.WriteLine($"--- Search Results — {algorithmLabel} (Top 3 by Cosine Distance) ---");
    foreach (var row in results)
    {
        var distance = row["distance"] is DBNull or null ? 0d : Convert.ToDouble(row["distance"], CultureInfo.InvariantCulture);
        var similarity = 1d - distance;
        Console.WriteLine($"  Hotel:       {row["name"]}");
        Console.WriteLine($"  Category:    {row["category"]}");
        Console.WriteLine($"  Rating:      {row["rating"]}");
        Console.WriteLine($"  Description: {row["description"]}...");
        Console.WriteLine($"  Distance:    {distance:F4}");
        Console.WriteLine($"  Similarity:  {similarity:F4}");
        Console.WriteLine();
    }

    if (!config.DropTable)
    {
        Console.WriteLine($"Table dbo.[{tableName}] retained (set SQL_DROP_TABLE=true to clean up).\n");
    }
}
finally
{
    if (config.DropTable && tableReady && connection.State == ConnectionState.Open)
    {
        Console.WriteLine($"Dropping table dbo.[{config.TableName}]...");
        await ExecuteNonQueryAsync(connection, $"DROP TABLE IF EXISTS dbo.[{config.TableName}]");
        Console.WriteLine("Table dropped — no artifacts left behind.");
    }

    await connection.CloseAsync();
    Console.WriteLine("Done. Connection closed.");
}

static async Task<float[]> GetEmbeddingAsync(AzureOpenAIClient client, string deploymentName, string query)
{
    var embeddingClient = client.GetEmbeddingClient(deploymentName);
    var embedding = await embeddingClient.GenerateEmbeddingAsync(query);
    var values = embedding.Value.ToFloats().ToArray();

    if (values.Length != 1536)
    {
        throw new InvalidOperationException($"Query embedding dimension mismatch: {values.Length}. Expected 1536.");
    }

    return values;
}

static async Task<int> GetRowCountAsync(SqlConnection connection, string tableName)
{
    var result = await ExecuteScalarAsync(connection, $"SELECT COUNT(*) AS cnt FROM dbo.[{tableName}] WHERE embedding IS NOT NULL");
    return Convert.ToInt32(result, CultureInfo.InvariantCulture);
}

static async Task<List<Dictionary<string, object?>>> RunExactAsync(SqlConnection connection, string tableName, string vectorString)
{
    var sql = $"SELECT TOP 3 name, description, category, rating, VECTOR_DISTANCE('cosine', embedding, CAST(@queryVector AS VECTOR(1536))) AS distance FROM dbo.[{tableName}] ORDER BY distance";
    var parameters = new[] { new SqlParameter("@queryVector", SqlDbType.NVarChar, -1) { Value = vectorString } };

    return await ExecuteReaderAsync(connection, sql, parameters);
}

static async Task<List<Dictionary<string, object?>>> RunDiskannAsync(SqlConnection connection, string tableName, string vectorString)
{
    var sql = SearchUtilities.BuildDiskAnnQuery(tableName);
    var parameters = new[] { new SqlParameter("@queryVector", SqlDbType.NVarChar, -1) { Value = vectorString } };

    return await ExecuteReaderAsync(connection, sql, parameters);
}

static async Task<List<Dictionary<string, object?>>> ExecuteReaderAsync(SqlConnection connection, string sql, IEnumerable<SqlParameter>? parameters = null)
{
    var results = new List<Dictionary<string, object?>>();
    await using var command = new SqlCommand(sql, connection);
    if (parameters is not null)
    {
        foreach (var parameter in parameters)
        {
            command.Parameters.Add(parameter);
        }
    }

    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        var row = new Dictionary<string, object?>();
        for (var i = 0; i < reader.FieldCount; i++)
        {
            row[reader.GetName(i)] = reader.IsDBNull(i) ? DBNull.Value : reader.GetValue(i);
        }
        results.Add(row);
    }

    return results;
}

static async Task<object?> ExecuteScalarAsync(SqlConnection connection, string sql, IEnumerable<SqlParameter>? parameters = null)
{
    await using var command = new SqlCommand(sql, connection);
    if (parameters is not null)
    {
        foreach (var parameter in parameters)
        {
            command.Parameters.Add(parameter);
        }
    }

    return await command.ExecuteScalarAsync();
}

static async Task ExecuteNonQueryAsync(
    SqlConnection connection,
    string sql,
    IEnumerable<SqlParameter>? parameters = null,
    SqlTransaction? transaction = null)
{
    await using var command = new SqlCommand(sql, connection);
    command.Transaction = transaction;
    if (parameters is not null)
    {
        foreach (var parameter in parameters)
        {
            command.Parameters.Add(parameter);
        }
    }

    await command.ExecuteNonQueryAsync();
}

static string BuildConnectionString(AppConfig config)
{
    return $"Server=tcp:{config.AzureSqlServer},1433;Database={config.AzureSqlDatabase};Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Default;";
}
