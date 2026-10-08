// Package config loads and validates configuration from environment
// variables (populated from a local .env file). Mirrors the
// required/optional variable set and defaults defined in the repository
// constitution (ASV-LANG-TS-3 / ASV-LANG-GO-6): AZURE_SQL_SERVER,
// AZURE_SQL_DATABASE, AZURE_OPENAI_ENDPOINT,
// AZURE_OPENAI_EMBEDDING_DEPLOYMENT are required; AZURE_SQL_TABLE_NAME,
// VECTOR_SEARCH_ALGORITHM, and SQL_DROP_TABLE are optional with defaults.
package config

import (
	"fmt"
	"os"
	"regexp"
	"strings"
)

var tableNamePattern = regexp.MustCompile(`^[a-zA-Z_][a-zA-Z0-9_]{0,114}$`)

// AppConfig holds the resolved, validated sample configuration.
type AppConfig struct {
	AzureSQLServer                 string
	AzureSQLDatabase               string
	AzureOpenAIEndpoint            string
	AzureOpenAIEmbeddingDeployment string
	TableName                      string
	VectorSearchAlgorithm          string
	DropTable                      bool
}

func required(key string) (string, error) {
	value := os.Getenv(key)
	if value == "" {
		return "", fmt.Errorf(
			"missing required environment variable: %s. Copy sample.env to .env and fill in your values",
			key,
		)
	}
	return value, nil
}

// Load reads and validates configuration from the environment.
//
// requireSQL controls whether AZURE_SQL_SERVER and AZURE_SQL_DATABASE must
// be set. Pass false for tooling (such as the embedding-generation
// command) that does not connect to SQL.
func Load(requireSQL bool) (AppConfig, error) {
	algorithmRaw := strings.ToLower(orDefault(os.Getenv("VECTOR_SEARCH_ALGORITHM"), "exact"))
	if algorithmRaw != "exact" && algorithmRaw != "diskann" {
		return AppConfig{}, fmt.Errorf(
			`invalid VECTOR_SEARCH_ALGORITHM: %q. must be "exact" or "diskann"`, algorithmRaw,
		)
	}

	tableName := orDefault(os.Getenv("AZURE_SQL_TABLE_NAME"), "hotels_go")
	if !tableNamePattern.MatchString(tableName) {
		return AppConfig{}, fmt.Errorf(
			"invalid AZURE_SQL_TABLE_NAME: %q. must start with a letter or underscore, "+
				"contain only letters, numbers, and underscores, and be at most 115 characters",
			tableName,
		)
	}

	dropTable := strings.ToLower(os.Getenv("SQL_DROP_TABLE")) == "true"

	var sqlServer, sqlDatabase string
	var err error
	if requireSQL {
		if sqlServer, err = required("AZURE_SQL_SERVER"); err != nil {
			return AppConfig{}, err
		}
		if sqlDatabase, err = required("AZURE_SQL_DATABASE"); err != nil {
			return AppConfig{}, err
		}
	} else {
		sqlServer = os.Getenv("AZURE_SQL_SERVER")
		sqlDatabase = os.Getenv("AZURE_SQL_DATABASE")
	}

	openAIEndpoint, err := required("AZURE_OPENAI_ENDPOINT")
	if err != nil {
		return AppConfig{}, err
	}
	openAIDeployment, err := required("AZURE_OPENAI_EMBEDDING_DEPLOYMENT")
	if err != nil {
		return AppConfig{}, err
	}

	return AppConfig{
		AzureSQLServer:                 sqlServer,
		AzureSQLDatabase:               sqlDatabase,
		AzureOpenAIEndpoint:            openAIEndpoint,
		AzureOpenAIEmbeddingDeployment: openAIDeployment,
		TableName:                      tableName,
		VectorSearchAlgorithm:          algorithmRaw,
		DropTable:                      dropTable,
	}, nil
}

func orDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
