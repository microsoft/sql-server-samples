"""Configuration loading and validation for the Azure SQL vector search sample.

Reads settings from environment variables (populated from a local .env file
via python-dotenv). Mirrors the required/optional variable set and defaults
defined in the repository constitution (ASV-LANG-TS-3 / ASV-LANG-PY-4):
AZURE_SQL_SERVER, AZURE_SQL_DATABASE, AZURE_OPENAI_ENDPOINT,
AZURE_OPENAI_EMBEDDING_DEPLOYMENT are required; AZURE_SQL_TABLE_NAME,
VECTOR_SEARCH_ALGORITHM, and SQL_DROP_TABLE are optional with defaults.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass

_TABLE_NAME_PATTERN = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_]{0,114}$")


@dataclass(frozen=True)
class AppConfig:
    azure_sql_server: str | None
    azure_sql_database: str | None
    azure_openai_endpoint: str
    azure_openai_embedding_deployment: str
    table_name: str
    vector_search_algorithm: str
    drop_table: bool


def _required(key: str) -> str:
    value = os.environ.get(key)
    if not value:
        raise RuntimeError(
            f"Missing required environment variable: {key}. Copy sample.env to .env and fill in your values."
        )
    return value


def _optional(key: str) -> str | None:
    return os.environ.get(key)


def load_config(require_sql: bool = True) -> AppConfig:
    """Load and validate configuration from environment variables.

    Args:
        require_sql: When True (the default), AZURE_SQL_SERVER and
            AZURE_SQL_DATABASE must be set. Pass False for tooling (such as
            the embedding-generation script) that does not connect to SQL.
    """
    algorithm_raw = (_optional("VECTOR_SEARCH_ALGORITHM") or "exact").lower()
    if algorithm_raw not in ("exact", "diskann"):
        raise RuntimeError(
            f'Invalid VECTOR_SEARCH_ALGORITHM: "{algorithm_raw}". Must be "exact" or "diskann".'
        )

    table_name = _optional("AZURE_SQL_TABLE_NAME") or "hotels_python"
    if not _TABLE_NAME_PATTERN.match(table_name):
        raise RuntimeError(
            f'Invalid AZURE_SQL_TABLE_NAME: "{table_name}". '
            "Must start with a letter or underscore, contain only letters, "
            "numbers, and underscores, and be at most 115 characters."
        )

    drop_table = (_optional("SQL_DROP_TABLE") or "false").lower() == "true"

    azure_sql_server = _required("AZURE_SQL_SERVER") if require_sql else _optional("AZURE_SQL_SERVER")
    azure_sql_database = _required("AZURE_SQL_DATABASE") if require_sql else _optional("AZURE_SQL_DATABASE")

    return AppConfig(
        azure_sql_server=azure_sql_server,
        azure_sql_database=azure_sql_database,
        azure_openai_endpoint=_required("AZURE_OPENAI_ENDPOINT"),
        azure_openai_embedding_deployment=_required("AZURE_OPENAI_EMBEDDING_DEPLOYMENT"),
        table_name=table_name,
        vector_search_algorithm=algorithm_raw,
        drop_table=drop_table,
    )
