package hotels

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestVectorToJSONRoundTrips(t *testing.T) {
	embedding := []float64{0.1, 0.2, 0.3}
	serialized, err := VectorToJSON(embedding)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decoded []float64
	if err := json.Unmarshal([]byte(serialized), &decoded); err != nil {
		t.Fatalf("failed to decode serialized vector: %v", err)
	}
	if len(decoded) != len(embedding) {
		t.Fatalf("decoded length = %d, want %d", len(decoded), len(embedding))
	}
	for i := range embedding {
		if decoded[i] != embedding[i] {
			t.Errorf("decoded[%d] = %v, want %v", i, decoded[i], embedding[i])
		}
	}
}

func writeTestData(t *testing.T, hotelsJSON []Hotel) string {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, "hotels.json")
	data, err := json.Marshal(hotelsJSON)
	if err != nil {
		t.Fatalf("failed to marshal test fixture: %v", err)
	}
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatalf("failed to write test fixture: %v", err)
	}
	return path
}

func TestLoadValid(t *testing.T) {
	vector := make([]float64, VectorDimensions)
	path := writeTestData(t, []Hotel{
		{HotelID: "1", HotelName: "Test Hotel", Description: "A test hotel.", DescriptionVector: vector},
	})

	loaded, err := Load(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(loaded) != 1 {
		t.Fatalf("len(loaded) = %d, want 1", len(loaded))
	}
	if loaded[0].HotelID != "1" {
		t.Errorf("HotelID = %q, want %q", loaded[0].HotelID, "1")
	}
}

func TestLoadRejectsWrongDimensions(t *testing.T) {
	path := writeTestData(t, []Hotel{
		{HotelID: "1", HotelName: "Test Hotel", Description: "A test hotel.", DescriptionVector: []float64{0, 0, 0}},
	})

	_, err := Load(path)
	if err == nil || !strings.Contains(err.Error(), "invalid or missing vector dimensions") {
		t.Fatalf("expected dimension-validation error, got %v", err)
	}
}
