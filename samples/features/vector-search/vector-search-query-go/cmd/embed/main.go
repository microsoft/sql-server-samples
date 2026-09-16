// Command embed regenerates precomputed embeddings for the hotels
// dataset. Reads data/HotelsData.JSON (no vectors), calls Azure OpenAI in
// batches to generate a text-embedding-3-small embedding per hotel
// description, and writes data/HotelsData_Vector.json — mirroring the
// TypeScript reference sample's embed.ts. Run this only if you need to
// regenerate the shipped vector data (for example, after changing the
// embedding model).
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/joho/godotenv"
	"github.com/openai/openai-go/v3"
	"github.com/openai/openai-go/v3/azure"

	"vector-search-query-go/internal/config"
)

const (
	openAIAPIVersion = "2024-10-21"
	batchSize        = 20
)

func dataDir() string {
	_, thisFile, _, _ := runtime.Caller(0)
	// this file lives at <sample-root>/cmd/embed/main.go
	sampleRoot := filepath.Dir(filepath.Dir(filepath.Dir(thisFile)))
	return filepath.Join(sampleRoot, "data")
}

func run() error {
	_ = godotenv.Load()

	cfg, err := config.Load(false)
	if err != nil {
		return err
	}

	inputPath := filepath.Join(dataDir(), "HotelsData.JSON")
	outputPath := filepath.Join(dataDir(), "HotelsData_Vector.json")

	data, err := os.ReadFile(inputPath)
	if err != nil {
		return fmt.Errorf("reading %s: %w", inputPath, err)
	}

	var rawHotels []map[string]any
	if err := json.Unmarshal(data, &rawHotels); err != nil {
		return fmt.Errorf("parsing %s: %w", inputPath, err)
	}
	fmt.Printf("Generating embeddings for %d hotels...\n", len(rawHotels))

	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return fmt.Errorf("creating credential: %w", err)
	}
	client := openai.NewClient(
		azure.WithEndpoint(cfg.AzureOpenAIEndpoint, openAIAPIVersion),
		azure.WithTokenCredential(credential),
	)

	ctx := context.Background()
	descriptions := make([]string, len(rawHotels))
	for i, h := range rawHotels {
		desc, _ := h["Description"].(string)
		descriptions[i] = desc
	}

	allEmbeddings := make([][]float64, 0, len(descriptions))
	for start := 0; start < len(descriptions); start += batchSize {
		end := start + batchSize
		if end > len(descriptions) {
			end = len(descriptions)
		}
		batch := descriptions[start:end]

		resp, err := client.Embeddings.New(ctx, openai.EmbeddingNewParams{
			Model: openai.EmbeddingModel(cfg.AzureOpenAIEmbeddingDeployment),
			Input: openai.EmbeddingNewParamsInputUnion{OfArrayOfStrings: batch},
		})
		if err != nil {
			return fmt.Errorf("generating embeddings for batch starting at %d: %w", start, err)
		}
		for _, item := range resp.Data {
			allEmbeddings = append(allEmbeddings, item.Embedding)
		}
		fmt.Printf("  Embedded %d/%d\n", end, len(descriptions))
	}

	for i, h := range rawHotels {
		h["DescriptionVector"] = allEmbeddings[i]
	}

	out, err := json.MarshalIndent(rawHotels, "", "  ")
	if err != nil {
		return fmt.Errorf("serializing output: %w", err)
	}
	if err := os.WriteFile(outputPath, out, 0o644); err != nil {
		return fmt.Errorf("writing %s: %w", outputPath, err)
	}
	fmt.Println("Done. Wrote HotelsData_Vector.json")
	return nil
}

func main() {
	if err := run(); err != nil {
		log.Println("Error:", err)
		os.Exit(1)
	}
}
