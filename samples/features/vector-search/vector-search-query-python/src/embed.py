"""Generate precomputed embeddings for the hotels dataset (Python quickstart).

Reads data/HotelsData.JSON (no vectors), calls Azure OpenAI in batches to
generate a text-embedding-3-small embedding per hotel description, and
writes data/HotelsData_Vector.json — mirroring the TypeScript reference
sample's embed.ts. Run this only if you need to regenerate the shipped
vector data (for example, after changing the embedding model).
"""

from __future__ import annotations

import json
from pathlib import Path

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import AzureOpenAI

from config import load_config

BATCH_SIZE = 20


def main() -> None:
    load_dotenv()
    config = load_config(require_sql=False)

    base = Path(__file__).resolve().parent.parent.parent / "data"
    input_path = base / "HotelsData.JSON"
    output_path = base / "HotelsData_Vector.json"

    with input_path.open("r", encoding="utf-8") as f:
        hotels = json.load(f)
    print(f"Generating embeddings for {len(hotels)} hotels...")

    credential = DefaultAzureCredential()
    token_provider = get_bearer_token_provider(credential, "https://cognitiveservices.azure.com/.default")
    client = AzureOpenAI(
        azure_endpoint=config.azure_openai_endpoint,
        azure_ad_token_provider=token_provider,
        api_version="2024-10-21",
        timeout=30.0,
        max_retries=3,
    )

    descriptions = [hotel["Description"] for hotel in hotels]
    all_embeddings: list[list[float]] = []

    for start in range(0, len(descriptions), BATCH_SIZE):
        batch = descriptions[start : start + BATCH_SIZE]
        response = client.embeddings.create(model=config.azure_openai_embedding_deployment, input=batch)
        all_embeddings.extend(item.embedding for item in response.data)
        done = min(start + BATCH_SIZE, len(descriptions))
        print(f"  Embedded {done}/{len(descriptions)}")

    hotels_with_vectors = [
        {**hotel, "DescriptionVector": all_embeddings[idx]} for idx, hotel in enumerate(hotels)
    ]

    with output_path.open("w", encoding="utf-8") as f:
        json.dump(hotels_with_vectors, f, indent=2)
    print("Done. Wrote HotelsData_Vector.json")


if __name__ == "__main__":
    main()
