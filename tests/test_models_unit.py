"""
Unit tests for Pydantic models
Demonstrates validation testing skills
"""
import pytest
from datetime import datetime
from pydantic import ValidationError
from models.log_schemas import LogEntry, LogLevel, SearchQuery, IngestResponse


class TestLogEntry:
    """Test LogEntry model validation"""
    
    def test_valid_log_entry(self):
        """Test creating a valid log entry"""
        log = LogEntry(
            level=LogLevel.INFO,
            message="Test message",
            source="test-app",
            service="demo-service"
        )
        assert log.level == LogLevel.INFO
        assert log.message == "Test message"
        assert log.source == "test-app"
        assert isinstance(log.timestamp, datetime)
    
    def test_invalid_log_level(self):
        """Test invalid log level raises validation error"""
        with pytest.raises(ValidationError) as exc:
            LogEntry(
                level="INVALID",
                message="Test message",
                source="test-app"
            )
        assert "Input should be" in str(exc.value)
    
    def test_missing_required_fields(self):
        """Test missing required fields"""
        with pytest.raises(ValidationError):
            LogEntry(level=LogLevel.INFO)  # Missing message and source


class TestSearchQuery:
    """Test SearchQuery model validation"""
    
    def test_valid_search_query(self):
        """Test valid search query"""
        query = SearchQuery(
            query="error",
            level=LogLevel.ERROR,
            limit=50
        )
        assert query.query == "error"
        assert query.level == LogLevel.ERROR
        assert query.limit == 50
    
    def test_limit_validation(self):
        """Test limit validation boundaries"""
        # Valid limit
        query = SearchQuery(query="test", limit=100)
        assert query.limit == 100
        
        # Invalid limit (too high)
        with pytest.raises(ValidationError):
            SearchQuery(query="test", limit=2000)  # Over 1000 limit


class TestIngestResponse:
    """Test IngestResponse model"""
    
    def test_successful_response(self):
        """Test successful ingest response"""
        response = IngestResponse(
            success=True,
            message="Log processed",
            correlation_id="test-123"
        )
        assert response.success is True
        assert response.correlation_id == "test-123"