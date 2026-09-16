// Package hotels loads and validates the shared hotels dataset, and
// serializes embedding vectors into the JSON-array string form Azure
// SQL's VECTOR type accepts (see constitution ASV-LANG-GO-8).
package hotels

import (
	"encoding/json"
	"fmt"
	"os"
)

// VectorDimensions is the output size of the text-embedding-3-small model
// used by every language sample for cross-language parity.
const VectorDimensions = 1536

// Hotel is the subset of fields this sample reads from the shared dataset.
type Hotel struct {
	HotelID           string    `json:"HotelId"`
	HotelName         string    `json:"HotelName"`
	Description       string    `json:"Description"`
	Category          string    `json:"Category"`
	Rating            float64   `json:"Rating"`
	DescriptionVector []float64 `json:"DescriptionVector,omitempty"`
}

// VectorToJSON serializes an embedding as the JSON-array string that
// Azure SQL's VECTOR type accepts when cast, e.g. CAST(? AS VECTOR(1536)).
func VectorToJSON(embedding []float64) (string, error) {
	b, err := json.Marshal(embedding)
	if err != nil {
		return "", fmt.Errorf("serializing vector: %w", err)
	}
	return string(b), nil
}

// Load reads the hotels dataset from path and validates that every hotel's
// DescriptionVector has exactly VectorDimensions entries.
func Load(path string) ([]Hotel, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}

	var loaded []Hotel
	if err := json.Unmarshal(data, &loaded); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}

	var bad []string
	for i, h := range loaded {
		if len(h.DescriptionVector) != VectorDimensions {
			bad = append(bad, fmt.Sprintf("  Hotel %s (index %d): %d", h.HotelID, i, len(h.DescriptionVector)))
			if len(bad) >= 3 {
				break
			}
		}
	}
	if len(bad) > 0 {
		return nil, fmt.Errorf(
			"error: hotel(s) have invalid or missing vector dimensions (expected %d):\n%s\n"+
				"re-run 'go run ./cmd/embed' with a %d-dimension model, or update the VECTOR column size",
			VectorDimensions, joinLines(bad), VectorDimensions,
		)
	}

	return loaded, nil
}

func joinLines(lines []string) string {
	out := ""
	for i, l := range lines {
		if i > 0 {
			out += "\n"
		}
		out += l
	}
	return out
}
