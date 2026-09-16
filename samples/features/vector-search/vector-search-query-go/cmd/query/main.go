// Command query implements the Azure SQL vector search quickstart scenario
// for Go: create a table with a VECTOR(1536) column, bulk-load 50 hotels
// with precomputed embeddings, generate one fresh query embedding via
// Azure OpenAI, and run a similarity search using either exact kNN
// (VECTOR_DISTANCE) or approximate ANN (VECTOR_SEARCH with a DiskANN
// index), selected via VECTOR_SEARCH_ALGORITHM.
//
// Per constitution ASV-VS-4: DiskANN requires >= 1,000 rows with
// non-null vectors. Below that threshold this command falls back to
// exact search automatically and logs a warning, identical to the
// TypeScript reference sample.
package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/joho/godotenv"
	_ "github.com/microsoft/go-mssqldb/azuread"
	"github.com/openai/openai-go/v3"
	"github.com/openai/openai-go/v3/azure"

	"vector-search-query-go/internal/config"
	"vector-search-query-go/internal/hotels"
)

const (
	openAIAPIVersion = "2024-10-21" // See https://learn.microsoft.com/azure/ai-services/openai/api-version-deprecation
	searchQuery      = "luxury beachfront hotel with ocean views and spa"
)

func dataPath(filename string) string {
	_, thisFile, _, _ := runtime.Caller(0)
	// this file lives at <sample-root>/cmd/query/main.go
	sampleRoot := filepath.Dir(filepath.Dir(filepath.Dir(thisFile)))
	return filepath.Join(sampleRoot, "data", filename)
}

func openSQL(cfg config.AppConfig) (*sql.DB, error) {
	dsn := fmt.Sprintf(
		"sqlserver://%s?database=%s&fedauth=ActiveDirectoryDefault&encrypt=true&TrustServerCertificate=false",
		cfg.AzureSQLServer, cfg.AzureSQLDatabase,
	)
	// azuread.DriverName ("azuresql") wraps the standard driver and
	// performs Microsoft Entra authentication via the fedauth DSN
	// parameter above — no manual token acquisition is needed for SQL.
	db, err := sql.Open("azuresql", dsn)
	if err != nil {
		return nil, fmt.Errorf("opening connection: %w", err)
	}
	if err := db.Ping(); err != nil {
		_ = db.Close()
		return nil, fmt.Errorf(
			"authentication or connection failure: %w\n"+
				"Ensure:\n"+
				"  1. You are signed in: az login\n"+
				"  2. Your identity is set as Microsoft Entra admin on the SQL server\n"+
				"  3. Your client IP is in the SQL server firewall rules",
			err,
		)
	}
	return db, nil
}

func createTable(ctx context.Context, db *sql.DB, tableName string) error {
	_, err := db.ExecContext(ctx, fmt.Sprintf(`
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'%s' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.[%s] (
    id NVARCHAR(50) PRIMARY KEY,
    name NVARCHAR(200) NOT NULL,
    description NVARCHAR(MAX) NOT NULL,
    category NVARCHAR(100) NULL,
    rating FLOAT NULL,
    embedding VECTOR(1536) NULL
  );
END`, tableName, tableName))
	return err
}

func insertHotels(ctx context.Context, tx *sql.Tx, tableName string, all []hotels.Hotel) error {
	if _, err := tx.ExecContext(ctx, fmt.Sprintf("DELETE FROM dbo.[%s]", tableName)); err != nil {
		return err
	}

	insertSQL := fmt.Sprintf(
		"INSERT INTO dbo.[%s] (id, name, description, category, rating, embedding) "+
			"VALUES (@ID, @Name, @Description, @Category, @Rating, CAST(@Embedding AS VECTOR(1536)))",
		tableName,
	)
	stmt, err := tx.PrepareContext(ctx, insertSQL)
	if err != nil {
		return err
	}
	defer stmt.Close()

	for _, h := range all {
		vectorJSON, err := hotels.VectorToJSON(h.DescriptionVector)
		if err != nil {
			return err
		}
		if _, err := stmt.ExecContext(ctx,
			sql.Named("ID", h.HotelID),
			sql.Named("Name", h.HotelName),
			sql.Named("Description", h.Description),
			sql.Named("Category", h.Category),
			sql.Named("Rating", h.Rating),
			sql.Named("Embedding", vectorJSON),
		); err != nil {
			return fmt.Errorf("inserting hotel %s: %w", h.HotelID, err)
		}
	}
	return nil
}

// determineAlgorithm checks the non-null embedding row count before
// attempting to create a DiskANN index. Below 1,000 rows it falls back
// to exact search — the same dataset-size gate as every other language.
func determineAlgorithm(ctx context.Context, db *sql.DB, tableName, requested string) (string, error) {
	if requested != "diskann" {
		return requested, nil
	}

	var rowCount int64
	row := db.QueryRowContext(ctx, fmt.Sprintf(
		"SELECT COUNT(*) FROM dbo.[%s] WHERE embedding IS NOT NULL", tableName,
	))
	if err := row.Scan(&rowCount); err != nil {
		return "", err
	}

	if rowCount < 1000 {
		fmt.Printf(
			"\u26a0 DiskANN index requires at least 1,000 rows with non-null vectors, "+
				"but table has only %d. Falling back to exact (VECTOR_DISTANCE) search.\n\n",
			rowCount,
		)
		return "exact", nil
	}

	fmt.Println("Creating DiskANN vector index (if not exists)...")
	_, err := db.ExecContext(ctx, fmt.Sprintf(`
IF NOT EXISTS (
  SELECT * FROM sys.indexes
  WHERE name = N'ix_%s_embedding' AND object_id = OBJECT_ID('dbo.[%s]')
)
BEGIN
  CREATE VECTOR INDEX [ix_%s_embedding]
  ON dbo.[%s](embedding)
  WITH (type = 'DiskANN', metric = 'cosine');
END`, tableName, tableName, tableName, tableName))
	if err != nil {
		return "", err
	}
	fmt.Println("DiskANN index ready.")
	return "diskann", nil
}

type searchResult struct {
	Name        string
	Description string
	Category    string
	Rating      float64
	Distance    float64
}

func runSearch(ctx context.Context, db *sql.DB, tableName, algorithm, queryVectorJSON string) ([]searchResult, error) {
	var rows *sql.Rows
	var err error

	if algorithm == "diskann" {
		rows, err = db.QueryContext(ctx, fmt.Sprintf(`
SELECT TOP 3
  vs.distance,
  h.name, h.description, h.category, h.rating
FROM VECTOR_SEARCH(
  dbo.[%s], embedding,
  CAST(@Query AS VECTOR(1536)),
  'cosine', 3
) AS vs
INNER JOIN dbo.[%s] h ON vs.[$rowid] = h.[$rowid]
ORDER BY vs.distance`, tableName, tableName),
			sql.Named("Query", queryVectorJSON),
		)
	} else {
		rows, err = db.QueryContext(ctx, fmt.Sprintf(`
SELECT TOP 3
  name, description, category, rating,
  VECTOR_DISTANCE('cosine', embedding, CAST(@Query AS VECTOR(1536))) AS distance
FROM dbo.[%s]
ORDER BY distance`, tableName),
			sql.Named("Query", queryVectorJSON),
		)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []searchResult
	for rows.Next() {
		var r searchResult
		if algorithm == "diskann" {
			if err := rows.Scan(&r.Distance, &r.Name, &r.Description, &r.Category, &r.Rating); err != nil {
				return nil, err
			}
		} else {
			if err := rows.Scan(&r.Name, &r.Description, &r.Category, &r.Rating, &r.Distance); err != nil {
				return nil, err
			}
		}
		results = append(results, r)
	}
	return results, rows.Err()
}

func generateQueryEmbedding(ctx context.Context, client openai.Client, deployment, text string) ([]float64, error) {
	resp, err := client.Embeddings.New(ctx, openai.EmbeddingNewParams{
		Model: openai.EmbeddingModel(deployment),
		Input: openai.EmbeddingNewParamsInputUnion{OfArrayOfStrings: []string{text}},
	})
	if err != nil {
		return nil, err
	}
	if len(resp.Data) == 0 {
		return nil, fmt.Errorf("Azure OpenAI returned no embedding data")
	}
	return resp.Data[0].Embedding, nil
}

func run() error {
	// Load .env if present; ignore the error when it doesn't exist (real
	// environment variables, e.g. from CI, remain valid without a file).
	_ = godotenv.Load()

	fmt.Println("=== Azure SQL Vector Search\u2014Go Quickstart ===")
	fmt.Println()

	cfg, err := config.Load(true)
	if err != nil {
		return err
	}
	fmt.Printf("Server:     %s\n", cfg.AzureSQLServer)
	fmt.Printf("Database:   %s\n", cfg.AzureSQLDatabase)
	fmt.Printf("OpenAI:     %s\n", cfg.AzureOpenAIEndpoint)
	fmt.Printf("Deployment: %s\n", cfg.AzureOpenAIEmbeddingDeployment)
	fmt.Printf("Algorithm:  %s\n", cfg.VectorSearchAlgorithm)
	fmt.Printf("Table:      dbo.%s\n\n", cfg.TableName)

	allHotels, err := hotels.Load(dataPath("HotelsData_Vector.json"))
	if err != nil {
		return err
	}
	fmt.Printf("Loaded %d hotels from data file.\n\n", len(allHotels))

	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return fmt.Errorf("creating credential: %w", err)
	}

	fmt.Println("Connecting to Azure SQL Database...")
	db, err := openSQL(cfg)
	if err != nil {
		return err
	}
	defer db.Close()
	fmt.Println("Connected.")
	fmt.Println()

	ctx := context.Background()

	fmt.Printf("Creating table dbo.%s (if not exists)...\n", cfg.TableName)
	if err := createTable(ctx, db, cfg.TableName); err != nil {
		return err
	}
	fmt.Println("Table ready.")
	fmt.Println()

	fmt.Println("Inserting hotel data with precomputed embeddings...")
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	if err := insertHotels(ctx, tx, cfg.TableName, allHotels); err != nil {
		_ = tx.Rollback()
		return err
	}
	if err := tx.Commit(); err != nil {
		return err
	}
	fmt.Printf("Inserted %d hotels.\n\n", len(allHotels))

	fmt.Printf("Searching for: %q\n\n", searchQuery)

	openAIClient := openai.NewClient(
		azure.WithEndpoint(cfg.AzureOpenAIEndpoint, openAIAPIVersion),
		azure.WithTokenCredential(credential),
	)

	queryVector, err := generateQueryEmbedding(ctx, openAIClient, cfg.AzureOpenAIEmbeddingDeployment, searchQuery)
	if err != nil {
		return fmt.Errorf(
			"%w\nAzure OpenAI authentication or request failed. Ensure:\n"+
				"  1. You are signed in: az login\n"+
				"  2. You have the 'Cognitive Services OpenAI User' role on the Azure OpenAI resource\n"+
				"  3. The endpoint is correct: %s\n"+
				"  4. The deployment exists: %s",
			err, cfg.AzureOpenAIEndpoint, cfg.AzureOpenAIEmbeddingDeployment,
		)
	}
	if len(queryVector) != hotels.VectorDimensions {
		return fmt.Errorf(
			"query embedding has unexpected dimensions: %d (expected %d). Check your Azure OpenAI deployment %q",
			len(queryVector), hotels.VectorDimensions, cfg.AzureOpenAIEmbeddingDeployment,
		)
	}
	queryVectorJSON, err := hotels.VectorToJSON(queryVector)
	if err != nil {
		return err
	}

	algorithm, err := determineAlgorithm(ctx, db, cfg.TableName, cfg.VectorSearchAlgorithm)
	if err != nil {
		return err
	}

	results, err := runSearch(ctx, db, cfg.TableName, algorithm, queryVectorJSON)
	if err != nil {
		return err
	}

	algorithmLabel := "Exact (kNN) via VECTOR_DISTANCE"
	if algorithm == "diskann" {
		algorithmLabel = "Approximate (DiskANN) via VECTOR_SEARCH"
	}
	fmt.Printf("--- Search Results\u2014%s (Top 3 by Cosine Distance) ---\n\n", algorithmLabel)
	for _, r := range results {
		similarity := 1 - r.Distance
		desc := r.Description
		if len(desc) > 100 {
			desc = desc[:100]
		}
		fmt.Printf("  Hotel:       %s\n", r.Name)
		fmt.Printf("  Category:    %s\n", r.Category)
		fmt.Printf("  Rating:      %v\n", r.Rating)
		fmt.Printf("  Description: %s...\n", desc)
		fmt.Printf("  Distance:    %.4f\n", r.Distance)
		fmt.Printf("  Similarity:  %.4f\n", similarity)
		fmt.Println()
	}

	if cfg.DropTable {
		fmt.Printf("Dropping table dbo.[%s]...\n", cfg.TableName)
		if algorithm == "diskann" {
			if _, err := db.ExecContext(ctx, fmt.Sprintf(
				"DROP INDEX IF EXISTS [ix_%s_embedding] ON dbo.[%s]", cfg.TableName, cfg.TableName,
			)); err != nil {
				return err
			}
		}
		if _, err := db.ExecContext(ctx, fmt.Sprintf("DROP TABLE IF EXISTS dbo.[%s]", cfg.TableName)); err != nil {
			return err
		}
		fmt.Println("Table dropped \u2014 no artifacts left behind.")
	} else {
		fmt.Printf("Table dbo.[%s] retained (set SQL_DROP_TABLE=true to clean up).\n", cfg.TableName)
	}

	return nil
}

func main() {
	if err := run(); err != nil {
		log.Println("Error:", err)
		os.Exit(1)
	}
	fmt.Println("Done. Connection closed.")
}
