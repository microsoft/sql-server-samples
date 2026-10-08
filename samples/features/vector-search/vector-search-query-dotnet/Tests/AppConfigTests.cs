using System.Globalization;
using Microsoft.Extensions.Configuration;
using VectorSearchSample;

namespace VectorSearchSample.Tests;

public class AppConfigTests
{
    private static IConfiguration BuildValidConfiguration(Dictionary<string, string?>? overrides = null)
    {
        var values = new Dictionary<string, string?>
        {
            ["AZURE_OPENAI_ENDPOINT"] = "https://example.openai.azure.com",
            ["AZURE_OPENAI_EMBEDDING_DEPLOYMENT"] = "text-embedding-3-small",
            ["AZURE_SQL_SERVER"] = "example.database.windows.net",
            ["AZURE_SQL_DATABASE"] = "db",
        };

        if (overrides is not null)
        {
            foreach (var pair in overrides)
            {
                values[pair.Key] = pair.Value;
            }
        }

        return new ConfigurationBuilder().AddInMemoryCollection(values).Build();
    }

    [Fact]
    public void Load_RejectsInvalidAlgorithm()
    {
        var config = BuildValidConfiguration(new() { ["VECTOR_SEARCH_ALGORITHM"] = "bogus" });

        var ex = Assert.Throws<InvalidOperationException>(() => AppConfig.Load(config));
        Assert.Contains("VECTOR_SEARCH_ALGORITHM", ex.Message);
    }

    [Fact]
    public void Load_ValidatesTableName()
    {
        var config = BuildValidConfiguration(new() { ["AZURE_SQL_TABLE_NAME"] = "bad-name" });

        var ex = Assert.Throws<InvalidOperationException>(() => AppConfig.Load(config));
        Assert.Contains("AZURE_SQL_TABLE_NAME", ex.Message);
    }

    [Theory]
    [InlineData("http://example.openai.azure.com")]
    [InlineData("not-a-uri")]
    [InlineData("<your-resource>")]
    public void Load_RejectsInvalidOpenAiEndpoint(string endpoint)
    {
        var config = BuildValidConfiguration(new() { ["AZURE_OPENAI_ENDPOINT"] = endpoint });

        Assert.Throws<InvalidOperationException>(() => AppConfig.Load(config));
    }

    [Theory]
    [InlineData("https://example.database.windows.net")]
    [InlineData("example server.database.windows.net")]
    public void Load_RejectsInvalidSqlServer(string server)
    {
        var config = BuildValidConfiguration(new() { ["AZURE_SQL_SERVER"] = server });

        Assert.Throws<InvalidOperationException>(() => AppConfig.Load(config));
    }
}

public class HotelDataTests
{
    [Fact]
    public void Load_ParsesHotelDataset()
    {
        var datasetPath = HotelData.ResolveDataFilePath();
        var hotels = HotelData.Load(datasetPath);

        Assert.Equal(50, hotels.Count);
        Assert.All(hotels, hotel => Assert.Equal(1536, hotel.DescriptionVector.Length));
    }

    [Fact]
    public void ToVectorString_UsesInvariantJsonArrayFormat()
    {
        var originalCulture = CultureInfo.CurrentCulture;
        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("fr-FR");
            Assert.Equal("[1.5,-2.25]", VectorUtilities.ToVectorString(new[] { 1.5f, -2.25f }));
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
        }
    }
}

public class SearchUtilitiesTests
{
    [Theory]
    [InlineData(99, "exact")]
    [InlineData(100, "diskann")]
    public void ResolveAlgorithm_EnforcesDiskAnnMinimumRowCount(int rowCount, string expected)
    {
        Assert.Equal(expected, SearchUtilities.ResolveAlgorithm("diskann", rowCount));
    }

    [Fact]
    public void ResolveAlgorithm_PreservesExactSearch()
    {
        Assert.Equal("exact", SearchUtilities.ResolveAlgorithm("exact", 5000));
    }

    [Fact]
    public void BuildDiskAnnQuery_UsesCurrentVectorSearchContract()
    {
        var sql = SearchUtilities.BuildDiskAnnQuery("hotels_dotnet");

        Assert.Contains("SELECT TOP (3) WITH APPROXIMATE", sql, StringComparison.Ordinal);
        Assert.Contains("TABLE = dbo.[hotels_dotnet] AS h", sql, StringComparison.Ordinal);
        Assert.Contains("COLUMN = embedding", sql, StringComparison.Ordinal);
        Assert.Contains("SIMILAR_TO = @queryVectorTyped", sql, StringComparison.Ordinal);
        Assert.Contains("METRIC = 'cosine'", sql, StringComparison.Ordinal);
        Assert.DoesNotContain("TOP_N", sql, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("$rowid", sql, StringComparison.OrdinalIgnoreCase);
    }
}
