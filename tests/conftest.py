"""
Pytest Configuration - AutoGit

This conftest.py provides shared fixtures and configuration for all tests.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    from collections.abc import Generator

# Add project root to path for imports
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))
sys.path.insert(0, str(PROJECT_ROOT / "services" / "runner-coordinator"))
sys.path.insert(0, str(PROJECT_ROOT / "tools"))


# =============================================================================
# Environment Fixtures
# =============================================================================


@pytest.fixture(scope="session")
def project_root() -> Path:
    """Return the project root directory."""
    return PROJECT_ROOT


@pytest.fixture(scope="session")
def test_data_dir(project_root: Path) -> Path:
    """Return the test data directory."""
    data_dir = project_root / "tests" / "data"
    data_dir.mkdir(exist_ok=True)
    return data_dir


# =============================================================================
# Database Fixtures
# =============================================================================


@pytest.fixture(scope="function")
def in_memory_db():
    """Create an in-memory SQLite database for testing."""
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy.pool import StaticPool

    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    yield {"engine": engine, "session_factory": TestingSessionLocal}


# =============================================================================
# API Client Fixtures
# =============================================================================


@pytest.fixture(scope="function")
def mock_gitlab_token() -> str:
    """Provide a mock GitLab token for testing."""
    return "glpat-test-token-12345"  # pragma: allowlist secret


@pytest.fixture(scope="function")
def mock_gitlab_url() -> str:
    """Provide a mock GitLab URL for testing."""
    return "http://localhost:3000"


# =============================================================================
# FastAPI Test Client Fixtures
# =============================================================================


@pytest.fixture(scope="function")
def test_client(in_memory_db):
    """Create a FastAPI test client with in-memory database."""
    # Import here to avoid circular imports
    from app.main import app, get_db
    from app.models import Base
    from fastapi.testclient import TestClient

    # Create tables
    Base.metadata.create_all(bind=in_memory_db["engine"])

    # Override the database dependency
    def override_get_db() -> Generator:
        db = in_memory_db["session_factory"]()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as client:
        yield client

    # Cleanup
    Base.metadata.drop_all(bind=in_memory_db["engine"])
    app.dependency_overrides.clear()


# =============================================================================
# Markers Configuration
# =============================================================================


def pytest_configure(config):
    """Configure custom markers."""
    config.addinivalue_line("markers", "slow: marks tests as slow running")
    config.addinivalue_line("markers", "integration: marks tests requiring external services")
    config.addinivalue_line("markers", "unit: marks tests as unit tests")


# =============================================================================
# CLI Output Configuration
# =============================================================================


def pytest_collection_modifyitems(config, items):
    """Modify test collection for better output."""
    # Add markers based on test location
    for item in items:
        if "integration" in str(item.fspath):
            item.add_marker(pytest.mark.integration)
        elif "unit" in str(item.fspath):
            item.add_marker(pytest.mark.unit)
