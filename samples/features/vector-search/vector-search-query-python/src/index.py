"""Azure SQL Database vector search — Python quickstart.

Mirrors the scenario implemented by the TypeScript reference sample
(vector-search-query-typescript): create a table with a VECTOR(1536)
column, bulk-load 50 hotels with precomputed embeddings, generate one
fresh query embedding via Azure OpenAI, and run a similarity search using
either exact kNN (VECTOR_DISTANCE) or approximate ANN (VECTOR_SEARCH with
a DiskANN index), selected via VECTOR_SEARCH_ALGORITHM.

Per constitution ASV-VS-4: DiskANN requires >= 1,000 rows with non-null
vectors. Below that threshold this script falls back to exact search
automatically and logs a warning, identical to the TypeScript reference.
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path
from typing import Any

import pyodbc
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import AzureOpenAI

from config import load_config

VECTOR_DIMENSIONS = 1536  # text-embedding-3-small output dimensions
SQL_COPT_SS_ACCESS_TOKEN = 1256  # pyodbc/ODBC driver attribute for an Entra access token
SEARCH_QUERY = "luxury beachfront hotel with ocean views and spa"


def _access_token_struct(token: str) -> bytes:
    """Pack an Entra access token into the byte structure pyodbc/ODBC expects."""
    token_bytes = token.encode("utf-16-le")
    return struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)


def connect_to_sql(server: str, database: str, credential: DefaultAzureCredential) -> pyodbc.Connection:
    token = credential.get_token("https://database.windows.net/.default").token
    conn_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{server},1433;"
        f"Database={database};"
        "Encrypt=yes;TrustServerCertificate=no;"
    )
    try:
        return pyodbc.connect(
            conn_str,
            attrs_before={SQL_COPT_SS_ACCESS_TOKEN: _access_token_struct(token)},
            autocommit=False,
        )
    except pyodbc.Error as err:
        message = str(err)
        if "Login failed" in message or "IM002" in message:
            print(
                "Authentication or driver failure. Ensure:\n"
                "  1. You are signed in: az login\n"
                "  2. Your identity is set as Microsoft Entra admin on the SQL server\n"
                "  3. Your client IP is in the SQL server firewall rules\n"
                "  4. ODBC Driver 18 for SQL Server is installed\n",
                file=sys.stderr,
            )
        raise


def vector_to_json(embedding: list[float]) -> str:
    """Serialize an embedding as the JSON-array string Azure SQL's VECTOR type accepts."""
    return json.dumps(embedding)


def generate_query_embedding(client: AzureOpenAI, deployment: str, text: str) -> list[float]:
    response = client.embeddings.create(model=deployment, input=[text])
    return list(response.data[0].embedding)


def load_hotels(data_path: Path) -> list[dict[str, Any]]:
    with data_path.open("r", encoding="utf-8") as f:
        hotels: list[dict[str, Any]] = json.load(f)
    bad = [
        (i, h.get("HotelId"), len(h.get("DescriptionVector") or []))
        for i, h in enumerate(hotels)
        if len(h.get("DescriptionVector") or []) != VECTOR_DIMENSIONS
    ]
    if bad:
        examples = "\n".join(f"  Hotel {hid} (index {i}): {dim}" for i, hid, dim in bad[:3])
        raise RuntimeError(
            f"Error: {len(bad)} hotel(s) have invalid or missing vector dimensions "
            f"(expected {VECTOR_DIMENSIONS}):\n{examples}\n"
            f"Re-run 'python src/embed.py' with a {VECTOR_DIMENSIONS}-dimension model, "
            "or update the VECTOR column size."
        )
    return hotels


def create_table(cursor: pyodbc.Cursor, table_name: str) -> None:
    cursor.execute(
        f"""
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'{table_name}' AND schema_id = SCHEMA_ID('dbo'))
        BEGIN
          CREATE TABLE dbo.[{table_name}] (
            id NVARCHAR(50) PRIMARY KEY,
            name NVARCHAR(200) NOT NULL,
            description NVARCHAR(MAX) NOT NULL,
            category NVARCHAR(100) NULL,
            rating FLOAT NULL,
            embedding VECTOR(1536) NULL
          );
        END
        """
    )


def insert_hotels(cursor: pyodbc.Cursor, table_name: str, hotels: list[dict[str, Any]]) -> None:
    cursor.execute(f"DELETE FROM dbo.[{table_name}]")
    insert_sql = (
        f"INSERT INTO dbo.[{table_name}] (id, name, description, category, rating, embedding) "
        f"VALUES (?, ?, ?, ?, ?, CAST(? AS VECTOR(1536)))"
    )
    cursor.fast_executemany = True
    rows = [
        (
            hotel["HotelId"],
            hotel["HotelName"],
            hotel["Description"],
            hotel.get("Category"),
            hotel.get("Rating"),
            vector_to_json(hotel["DescriptionVector"]),
        )
        for hotel in hotels
    ]
    cursor.executemany(insert_sql, rows)


def determine_algorithm(cursor: pyodbc.Cursor, table_name: str, requested: str) -> str:
    if requested != "diskann":
        return requested

    cursor.execute(f"SELECT COUNT(*) FROM dbo.[{table_name}] WHERE embedding IS NOT NULL")
    row_count = cursor.fetchone()[0]
    if row_count < 1000:
        print(
            f"\u26a0 DiskANN index requires at least 1,000 rows with non-null vectors, "
            f"but table has only {row_count}. Falling back to exact (VECTOR_DISTANCE) search.\n"
        )
        return "exact"

    print("Creating DiskANN vector index (if not exists)...")
    cursor.execute(
        f"""
        IF NOT EXISTS (
          SELECT * FROM sys.indexes
          WHERE name = N'ix_{table_name}_embedding' AND object_id = OBJECT_ID('dbo.[{table_name}]')
        )
        BEGIN
          CREATE VECTOR INDEX [ix_{table_name}_embedding]
          ON dbo.[{table_name}](embedding)
          WITH (type = 'DiskANN', metric = 'cosine');
        END
        """
    )
    print("DiskANN index ready.\n")
    return "diskann"


def run_search(cursor: pyodbc.Cursor, table_name: str, algorithm: str, query_vector_json: str) -> list[tuple]:
    if algorithm == "diskann":
        cursor.execute(
            f"""
            SELECT TOP 3
              vs.distance,
              h.name, h.description, h.category, h.rating
            FROM VECTOR_SEARCH(
              dbo.[{table_name}], embedding,
              CAST(? AS VECTOR(1536)),
              'cosine', 3
            ) AS vs
            INNER JOIN dbo.[{table_name}] h ON vs.$rowid = h.$rowid
            ORDER BY vs.distance
            """,
            query_vector_json,
        )
        return [(r.name, r.description, r.category, r.rating, r.distance) for r in cursor.fetchall()]

    cursor.execute(
        f"""
        SELECT TOP 3
          name, description, category, rating,
          VECTOR_DISTANCE('cosine', embedding, CAST(? AS VECTOR(1536))) AS distance
        FROM dbo.[{table_name}]
        ORDER BY distance
        """,
        query_vector_json,
    )
    return [(r.name, r.description, r.category, r.rating, r.distance) for r in cursor.fetchall()]


def main() -> None:
    print("=== Azure SQL Vector Search\u2014Python Quickstart ===\n")

    load_dotenv()
    config = load_config(require_sql=True)
    print(f"Server:     {config.azure_sql_server}")
    print(f"Database:   {config.azure_sql_database}")
    print(f"OpenAI:     {config.azure_openai_endpoint}")
    print(f"Deployment: {config.azure_openai_embedding_deployment}")
    print(f"Algorithm:  {config.vector_search_algorithm}")
    print(f"Table:      dbo.{config.table_name}\n")

    data_path = Path(__file__).resolve().parent.parent.parent / "data" / "HotelsData_Vector.json"
    hotels = load_hotels(data_path)
    print(f"Loaded {len(hotels)} hotels from data file.\n")

    credential = DefaultAzureCredential()

    print("Connecting to Azure SQL Database...")
    assert config.azure_sql_server is not None
    assert config.azure_sql_database is not None
    conn = connect_to_sql(config.azure_sql_server, config.azure_sql_database, credential)
    print("Connected.\n")

    try:
        cursor = conn.cursor()

        table_name = config.table_name
        print(f"Creating table dbo.{table_name} (if not exists)...")
        create_table(cursor, table_name)
        conn.commit()
        print("Table ready.\n")

        print("Inserting hotel data with precomputed embeddings...")
        try:
            insert_hotels(cursor, table_name, hotels)
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        print(f"Inserted {len(hotels)} hotels.\n")

        print(f'Searching for: "{SEARCH_QUERY}"\n')

        token_provider = get_bearer_token_provider(credential, "https://cognitiveservices.azure.com/.default")
        openai_client = AzureOpenAI(
            azure_endpoint=config.azure_openai_endpoint,
            azure_ad_token_provider=token_provider,
            api_version="2024-10-21",
            timeout=30.0,
            max_retries=3,
        )

        try:
            query_vector = generate_query_embedding(
                openai_client, config.azure_openai_embedding_deployment, SEARCH_QUERY
            )
        except Exception as err:
            message = str(err)
            if "401" in message or "403" in message or "AuthenticationError" in message:
                print(
                    "Azure OpenAI authentication failed. Ensure:\n"
                    "  1. You are signed in: az login\n"
                    "  2. You have the 'Cognitive Services OpenAI User' role on the Azure OpenAI resource\n"
                    f"  3. The endpoint is correct: {config.azure_openai_endpoint}\n"
                    f"  4. The deployment exists: {config.azure_openai_embedding_deployment}\n",
                    file=sys.stderr,
                )
            raise

        if len(query_vector) != VECTOR_DIMENSIONS:
            raise RuntimeError(
                f"Query embedding has unexpected dimensions: {len(query_vector)} "
                f"(expected {VECTOR_DIMENSIONS}). Check your Azure OpenAI deployment "
                f'"{config.azure_openai_embedding_deployment}".'
            )
        query_vector_json = vector_to_json(query_vector)

        algorithm = determine_algorithm(cursor, table_name, config.vector_search_algorithm)
        conn.commit()

        results = run_search(cursor, table_name, algorithm, query_vector_json)

        algorithm_label = (
            "Approximate (DiskANN) via VECTOR_SEARCH"
            if algorithm == "diskann"
            else "Exact (kNN) via VECTOR_DISTANCE"
        )
        print(f"--- Search Results\u2014{algorithm_label} (Top 3 by Cosine Distance) ---\n")
        for name, description, category, rating, distance in results:
            similarity = 1 - distance
            print(f"  Hotel:       {name}")
            print(f"  Category:    {category}")
            print(f"  Rating:      {rating}")
            print(f"  Description: {description[:100]}...")
            print(f"  Distance:    {distance:.4f}")
            print(f"  Similarity:  {similarity:.4f}")
            print()

        if config.drop_table:
            print(f"Dropping table dbo.[{table_name}]...")
            if algorithm == "diskann":
                cursor.execute(f"DROP INDEX IF EXISTS [ix_{table_name}_embedding] ON dbo.[{table_name}]")
            cursor.execute(f"DROP TABLE IF EXISTS dbo.[{table_name}]")
            conn.commit()
            print("Table dropped \u2014 no artifacts left behind.\n")
        else:
            print(f"Table dbo.[{table_name}] retained (set SQL_DROP_TABLE=true to clean up).\n")

    finally:
        conn.close()
        print("Done. Connection closed.")


if __name__ == "__main__":
    main()
