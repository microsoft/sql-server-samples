using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace VectorSearchSample;

public sealed class HotelRecord
{
    [JsonPropertyName("HotelId")]
    public string HotelId { get; set; } = string.Empty;

    [JsonPropertyName("HotelName")]
    public string HotelName { get; set; } = string.Empty;

    [JsonPropertyName("Description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("Category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("Rating")]
    public double Rating { get; set; }

    [JsonPropertyName("DescriptionVector")]
    public float[] DescriptionVector { get; set; } = Array.Empty<float>();
}

public static class HotelData
{
    public static string ResolveDataFilePath()
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);

        while (current is not null)
        {
            var candidate = Path.Combine(current.FullName, "data", "HotelsData_Vector.json");
            if (File.Exists(candidate))
            {
                return candidate;
            }

            current = current.Parent;
        }

        var fallback = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", "data", "HotelsData_Vector.json"));
        if (File.Exists(fallback))
        {
            return fallback;
        }

        throw new FileNotFoundException($"Hotels dataset not found under {AppContext.BaseDirectory}.", "HotelsData_Vector.json");
    }

    public static List<HotelRecord> Load(string filePath)
    {
        if (!File.Exists(filePath))
        {
            throw new FileNotFoundException($"Hotels dataset not found: {filePath}", filePath);
        }

        var json = File.ReadAllText(filePath);
        var hotels = JsonSerializer.Deserialize<List<HotelRecord>>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
        });

        if (hotels is null || hotels.Count == 0)
        {
            throw new InvalidOperationException($"No hotel rows were loaded from {filePath}.");
        }

        foreach (var hotel in hotels)
        {
            if (string.IsNullOrWhiteSpace(hotel.HotelId))
            {
                throw new InvalidOperationException("A hotel row is missing HotelId.");
            }

            if (hotel.DescriptionVector.Length != 1536)
            {
                throw new InvalidOperationException(
                    $"Hotel {hotel.HotelId} has invalid vector dimensions: {hotel.DescriptionVector.Length}. Expected 1536.");
            }
        }

        return hotels;
    }
}

public static class VectorUtilities
{
    public static string ToVectorString(IReadOnlyList<float> values)
    {
        var items = values.Select(v => v.ToString("G9", CultureInfo.InvariantCulture));
        return "[" + string.Join(",", items) + "]";
    }
}

public static class SearchUtilities
{
    public const int DiskAnnMinimumRowCount = 100;

    public static string ResolveAlgorithm(string requestedAlgorithm, int nonNullVectorRowCount)
    {
        return requestedAlgorithm == "diskann" && nonNullVectorRowCount < DiskAnnMinimumRowCount
            ? "exact"
            : requestedAlgorithm;
    }

    public static string BuildDiskAnnQuery(string tableName)
    {
        return $"""
            DECLARE @queryVectorTyped VECTOR(1536) = CAST(@queryVector AS VECTOR(1536));
            SELECT TOP (3) WITH APPROXIMATE
                h.name,
                h.description,
                h.category,
                h.rating,
                vs.distance
            FROM VECTOR_SEARCH(
                TABLE = dbo.[{tableName}] AS h,
                COLUMN = embedding,
                SIMILAR_TO = @queryVectorTyped,
                METRIC = 'cosine'
            ) AS vs
            ORDER BY vs.distance;
            """;
    }
}
