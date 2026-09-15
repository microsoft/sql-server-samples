"""Unit tests for pure functions in index.py — no Azure/network access required."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from index import VECTOR_DIMENSIONS, load_hotels, vector_to_json  # noqa: E402


def test_vector_to_json_roundtrips() -> None:
    embedding = [0.1, 0.2, 0.3]
    serialized = vector_to_json(embedding)
    assert json.loads(serialized) == embedding


def test_load_hotels_valid(tmp_path: Path) -> None:
    data = [
        {
            "HotelId": "1",
            "HotelName": "Test Hotel",
            "Description": "A test hotel.",
            "Category": "Luxury",
            "Rating": 4.5,
            "DescriptionVector": [0.0] * VECTOR_DIMENSIONS,
        }
    ]
    data_path = tmp_path / "hotels.json"
    data_path.write_text(json.dumps(data), encoding="utf-8")

    hotels = load_hotels(data_path)
    assert len(hotels) == 1
    assert hotels[0]["HotelId"] == "1"


def test_load_hotels_rejects_wrong_dimensions(tmp_path: Path) -> None:
    data = [
        {
            "HotelId": "1",
            "HotelName": "Test Hotel",
            "Description": "A test hotel.",
            "DescriptionVector": [0.0] * 10,  # wrong dimension count
        }
    ]
    data_path = tmp_path / "hotels.json"
    data_path.write_text(json.dumps(data), encoding="utf-8")

    with pytest.raises(RuntimeError, match="invalid or missing vector dimensions"):
        load_hotels(data_path)
