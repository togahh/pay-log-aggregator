import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock

@pytest.fixture
def mock_search_engine():
    """Mock SearchEngine for testing"""
    mock = MagicMock()
    mock.initialize = AsyncMock()
    mock.index_log = AsyncMock()
    mock.search_logs = AsyncMock()
    return mock

@pytest.fixture
def test_client():
    """Test client with mocked dependencies"""
    from main import app
    return TestClient(app)
