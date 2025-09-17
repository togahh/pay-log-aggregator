"""
Simple unit tests for the Log Aggregator API
Perfect for interview demonstration - focused and clean
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
from models.log_schemas import LogEntry, LogLevel


def test_health_endpoint(test_client):
    """Test the health check endpoint"""
    response = test_client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data


@patch('main.search_engine')
def test_log_ingestion_success(mock_search_engine, test_client):
    """Test successful log ingestion"""
    mock_search_engine.index_log = AsyncMock()
    
    log_data = {
        "level": "INFO",
        "message": "Test log message",
        "source": "test-service",
        "service": "demo"
    }
    
    response = test_client.post("/logs/ingest", json=log_data)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "correlation_id" in data


def test_log_ingestion_invalid_data(test_client):
    """Test log ingestion with invalid data"""
    invalid_log = {
        "level": "INVALID_LEVEL",  # Invalid enum value
        "message": "Test message"
        # Missing required fields
    }
    
    response = test_client.post("/logs/ingest", json=invalid_log)
    assert response.status_code == 422  # Validation error


@patch('main.search_engine')
def test_log_search(mock_search_engine, test_client):
    """Test log search functionality"""
    # Mock search results
    mock_search_engine.search_logs = AsyncMock(return_value={
        "logs": [
            {
                "timestamp": "2025-09-15T10:00:00",
                "level": "INFO",
                "message": "Found log",
                "source": "test-service"
            }
        ],
        "total_count": 1,
        "took_ms": 15.5
    })
    
    search_query = {
        "query": "test",
        "limit": 10
    }
    
    response = test_client.post("/logs/search", json=search_query)
    assert response.status_code == 200
    data = response.json()
    assert len(data["logs"]) == 1
    assert data["total_count"] == 1