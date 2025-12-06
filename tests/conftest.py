"""Pytest configuration and fixtures."""

import pytest
from pathlib import Path


@pytest.fixture
def fixtures_dir() -> Path:
    """Return the path to the fixtures directory."""
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def sample_project_dir(fixtures_dir: Path) -> Path:
    """Return the path to the sample project directory."""
    return fixtures_dir / "sample_project"
