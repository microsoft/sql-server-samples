package config

import (
	"strings"
	"testing"
)

// clearEnv removes every variable this package reads, so tests don't leak
// state between each other or depend on the host environment.
func clearEnv(t *testing.T) {
	t.Helper()
	for _, key := range []string{
		"AZURE_SQL_SERVER",
		"AZURE_SQL_DATABASE",
		"AZURE_OPENAI_ENDPOINT",
		"AZURE_OPENAI_EMBEDDING_DEPLOYMENT",
		"AZURE_SQL_TABLE_NAME",
		"VECTOR_SEARCH_ALGORITHM",
		"SQL_DROP_TABLE",
	} {
		t.Setenv(key, "")
		// t.Setenv sets an empty string rather than unsetting; that's
		// equivalent for this package's purposes (os.Getenv("") == "").
	}
}

func setRequired(t *testing.T) {
	t.Helper()
	t.Setenv("AZURE_SQL_SERVER", "example.database.windows.net")
	t.Setenv("AZURE_SQL_DATABASE", "exampledb")
	t.Setenv("AZURE_OPENAI_ENDPOINT", "https://example.openai.azure.com")
	t.Setenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT", "text-embedding-3-small")
}

func TestLoadDefaults(t *testing.T) {
	clearEnv(t)
	setRequired(t)

	cfg, err := Load(true)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.TableName != "hotels_go" {
		t.Errorf("TableName = %q, want %q", cfg.TableName, "hotels_go")
	}
	if cfg.VectorSearchAlgorithm != "exact" {
		t.Errorf("VectorSearchAlgorithm = %q, want %q", cfg.VectorSearchAlgorithm, "exact")
	}
	if cfg.DropTable {
		t.Errorf("DropTable = true, want false")
	}
}

func TestLoadMissingRequiredReturnsError(t *testing.T) {
	clearEnv(t)

	_, err := Load(true)
	if err == nil || !strings.Contains(err.Error(), "AZURE_SQL_SERVER") {
		t.Fatalf("expected error mentioning AZURE_SQL_SERVER, got %v", err)
	}
}

func TestLoadRequireSQLFalseAllowsMissingSQLVars(t *testing.T) {
	clearEnv(t)
	t.Setenv("AZURE_OPENAI_ENDPOINT", "https://example.openai.azure.com")
	t.Setenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT", "text-embedding-3-small")

	cfg, err := Load(false)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.AzureSQLServer != "" || cfg.AzureSQLDatabase != "" {
		t.Errorf("expected empty SQL fields, got server=%q database=%q", cfg.AzureSQLServer, cfg.AzureSQLDatabase)
	}
}

func TestInvalidAlgorithmReturnsError(t *testing.T) {
	clearEnv(t)
	setRequired(t)
	t.Setenv("VECTOR_SEARCH_ALGORITHM", "bogus")

	_, err := Load(true)
	if err == nil || !strings.Contains(err.Error(), "VECTOR_SEARCH_ALGORITHM") {
		t.Fatalf("expected VECTOR_SEARCH_ALGORITHM error, got %v", err)
	}
}

func TestAlgorithmCaseInsensitive(t *testing.T) {
	for _, algorithm := range []string{"exact", "EXACT", "diskann", "DiskANN"} {
		t.Run(algorithm, func(t *testing.T) {
			clearEnv(t)
			setRequired(t)
			t.Setenv("VECTOR_SEARCH_ALGORITHM", algorithm)

			cfg, err := Load(true)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if cfg.VectorSearchAlgorithm != strings.ToLower(algorithm) {
				t.Errorf("VectorSearchAlgorithm = %q, want %q", cfg.VectorSearchAlgorithm, strings.ToLower(algorithm))
			}
		})
	}
}

func TestTableNameValidation(t *testing.T) {
	cases := []struct {
		name       string
		tableName  string
		shouldFail bool
	}{
		{"valid default-like", "hotels_go", false},
		{"valid leading underscore", "_valid_name", false},
		{"valid mixed case", "Valid123", false},
		{"invalid leading digit", "1invalid", true},
		{"invalid hyphen", "invalid-name", true},
		{"invalid too long", strings.Repeat("a", 116), true},
		{"valid at cap", strings.Repeat("a", 115), false},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			clearEnv(t)
			setRequired(t)
			t.Setenv("AZURE_SQL_TABLE_NAME", tc.tableName)

			cfg, err := Load(true)
			if tc.shouldFail {
				if err == nil {
					t.Fatalf("expected error for table name %q, got none", tc.tableName)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error for table name %q: %v", tc.tableName, err)
			}
			if cfg.TableName != tc.tableName {
				t.Errorf("TableName = %q, want %q", cfg.TableName, tc.tableName)
			}
		})
	}
}

func TestDropTableFlag(t *testing.T) {
	cases := []struct {
		value    string
		expected bool
	}{
		{"true", true},
		{"TRUE", true},
		{"false", false},
		{"", false},
	}

	for _, tc := range cases {
		t.Run(tc.value, func(t *testing.T) {
			clearEnv(t)
			setRequired(t)
			if tc.value != "" {
				t.Setenv("SQL_DROP_TABLE", tc.value)
			}

			cfg, err := Load(true)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if cfg.DropTable != tc.expected {
				t.Errorf("DropTable = %v, want %v", cfg.DropTable, tc.expected)
			}
		})
	}
}
