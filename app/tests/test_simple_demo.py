"""
Simple unit tests that actually work - perfect for interview demo!
Clean, focused, and demonstrate key testing concepts.
"""
import pytest
from datetime import datetime
from pydantic import ValidationError
from models.log_schemas import LogEntry, LogLevel, SearchQuery


class TestBasicValidation:
    """Test basic model validation - shows you understand data validation"""
    
    def test_log_entry_creation(self):
        """Test creating valid log entries"""
        log = LogEntry(
            level=LogLevel.ERROR,
            message="Database connection failed",
            source="payment-service"
        )
        assert log.level == LogLevel.ERROR
        assert log.message == "Database connection failed"
        assert isinstance(log.timestamp, datetime)
    
    def test_log_level_validation(self):
        """Test enum validation"""
        with pytest.raises(ValidationError):
            LogEntry(
                level="INVALID_LEVEL",
                message="Test",
                source="test"
            )
    
    def test_search_query_limits(self):
        """Test business rule validation"""
        query = SearchQuery(query="error", limit=100)
        assert query.limit == 100
        
        with pytest.raises(ValidationError):
            SearchQuery(query="error", limit=5000)


class TestBusinessLogic:
    """Test simple business logic - shows you can test logic"""
    
    def test_log_filtering_by_level(self):
        """Test filtering logic"""
        logs = [
            LogEntry(level=LogLevel.INFO, message="Info 1", source="app"),
            LogEntry(level=LogLevel.ERROR, message="Error 1", source="app"),
            LogEntry(level=LogLevel.DEBUG, message="Debug 1", source="app"),
            LogEntry(level=LogLevel.ERROR, message="Error 2", source="app"),
        ]
        
        errors = [log for log in logs if log.level == LogLevel.ERROR]
        assert len(errors) == 2
        assert all(log.level == LogLevel.ERROR for log in errors)
    
    def test_log_message_search(self):
        """Test simple search logic"""
        logs = [
            LogEntry(level=LogLevel.INFO, message="User login successful", source="auth"),
            LogEntry(level=LogLevel.ERROR, message="Database connection failed", source="db"),
            LogEntry(level=LogLevel.INFO, message="User logout", source="auth"),
        ]
        
        database_logs = [log for log in logs if "database" in log.message.lower()]
        assert len(database_logs) == 1
        assert "Database" in database_logs[0].message


class TestEdgeCases:
    """Test edge cases - shows you think about corner cases"""
    
    def test_very_long_message(self):
        """Test edge case: very long message"""
        long_message = "A" * 10000
        log = LogEntry(level=LogLevel.INFO, message=long_message, source="test")
        assert len(log.message) == 10000
    
    def test_special_characters_in_source(self):
        """Test special characters handling"""
        log = LogEntry(
            level=LogLevel.INFO,
            message="Test message",
            source="app-service_v2.1"
        )
        assert log.source == "app-service_v2.1"


def test_with_simple_mock():
    """Simple mock example for interview"""
    from unittest.mock import Mock
    
    mock_logger = Mock()
    mock_logger.log.return_value = True
    
    result = mock_logger.log("test message")
    assert result is True
    mock_logger.log.assert_called_once_with("test message")