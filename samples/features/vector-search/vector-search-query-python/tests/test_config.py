"""Unit tests for config.py — no Azure/network access required.

These are the "safe no-secret static/unit checks" referenced by the
constitution: pure-function validation that can run in CI without a live
Azure SQL Database or Azure OpenAI resource.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from config import load_config  # noqa: E402


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch: pytest.MonkeyPatch) -> None:
    for key in (
        "AZURE_SQL_SERVER",
        "AZURE_SQL_DATABASE",
        "AZURE_OPENAI_ENDPOINT",
        "AZURE_OPENAI_EMBEDDING_DEPLOYMENT",
        "AZURE_SQL_TABLE_NAME",
        "VECTOR_SEARCH_ALGORITHM",
        "SQL_DROP_TABLE",
    ):
        monkeypatch.delenv(key, raising=False)


def _set_required(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("AZURE_SQL_SERVER", "example.database.windows.net")
    monkeypatch.setenv("AZURE_SQL_DATABASE", "exampledb")
    monkeypatch.setenv("AZURE_OPENAI_ENDPOINT", "https://example.openai.azure.com")
    monkeypatch.setenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT", "text-embedding-3-small")


def test_load_config_defaults(monkeypatch: pytest.MonkeyPatch) -> None:
    _set_required(monkeypatch)
    config = load_config()
    assert config.table_name == "hotels_python"
    assert config.vector_search_algorithm == "exact"
    assert config.drop_table is False


def test_load_config_missing_required_raises(monkeypatch: pytest.MonkeyPatch) -> None:
    with pytest.raises(RuntimeError, match="AZURE_SQL_SERVER"):
        load_config()


def test_load_config_require_sql_false_allows_missing_sql_vars(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("AZURE_OPENAI_ENDPOINT", "https://example.openai.azure.com")
    monkeypatch.setenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT", "text-embedding-3-small")
    config = load_config(require_sql=False)
    assert config.azure_sql_server is None
    assert config.azure_sql_database is None


def test_invalid_algorithm_raises(monkeypatch: pytest.MonkeyPatch) -> None:
    _set_required(monkeypatch)
    monkeypatch.setenv("VECTOR_SEARCH_ALGORITHM", "bogus")
    with pytest.raises(RuntimeError, match="Invalid VECTOR_SEARCH_ALGORITHM"):
        load_config()


@pytest.mark.parametrize("algorithm", ["exact", "EXACT", "diskann", "DiskANN"])
def test_algorithm_case_insensitive(monkeypatch: pytest.MonkeyPatch, algorithm: str) -> None:
    _set_required(monkeypatch)
    monkeypatch.setenv("VECTOR_SEARCH_ALGORITHM", algorithm)
    config = load_config()
    assert config.vector_search_algorithm == algorithm.lower()


@pytest.mark.parametrize(
    "table_name,should_raise",
    [
        ("hotels_python", False),
        ("_valid_name", False),
        ("Valid123", False),
        ("1invalid", True),  # cannot start with a digit
        ("invalid-name", True),  # hyphen not allowed
        ("a" * 116, True),  # exceeds 115-char cap
        ("a" * 115, False),  # exactly at the cap
    ],
)
def test_table_name_validation(monkeypatch: pytest.MonkeyPatch, table_name: str, should_raise: bool) -> None:
    _set_required(monkeypatch)
    monkeypatch.setenv("AZURE_SQL_TABLE_NAME", table_name)
    if should_raise:
        with pytest.raises(RuntimeError, match="Invalid AZURE_SQL_TABLE_NAME"):
            load_config()
    else:
        assert load_config().table_name == table_name


@pytest.mark.parametrize("value,expected", [("true", True), ("TRUE", True), ("false", False), (None, False)])
def test_drop_table_flag(monkeypatch: pytest.MonkeyPatch, value: str | None, expected: bool) -> None:
    _set_required(monkeypatch)
    if value is not None:
        monkeypatch.setenv("SQL_DROP_TABLE", value)
    assert load_config().drop_table is expected
