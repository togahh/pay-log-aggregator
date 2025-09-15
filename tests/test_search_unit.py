"""
Mock-based unit tests for SearchEngine
Shows isolation and dependency injection testing
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from services.search_engine import SearchEngine


class TestSearchEngine:
    """Unit tests for SearchEngine class"""
    
    @pytest.fixture
    def mock_es_client(self):
        """Mock Elasticsearch client"""
        mock_client = AsyncMock()
        mock_client.indices.exists.return_value = False
        mock_client.indices.create = AsyncMock()
        mock_client.index = AsyncMock()
        mock_client.search = AsyncMock()
        return mock_client
    
    @patch('services.search_engine.AsyncElasticsearch')
    def test_search_engine_initialization(self, mock_es_class, mock_es_client):
        """Test SearchEngine initialization"""
        mock_es_class.return_value = mock_es_client
        
        search_engine = SearchEngine()
        assert search_engine.es_url == "http://localhost:9200"
        assert search_engine.index_name == "logs"
    
    @patch('services.search_engine.AsyncElasticsearch')
    @pytest.mark.asyncio
    async def test_index_creation(self, mock_es_class, mock_es_client):
        """Test index creation during initialization"""
        mock_es_class.return_value = mock_es_client
        mock_es_client.indices.exists.return_value = False
        
        search_engine = SearchEngine()
        await search_engine.initialize()
        
        # Verify index creation was called
        mock_es_client.indices.create.assert_called_once()
        call_args = mock_es_client.indices.create.call_args
        assert call_args[1]['index'] == 'logs'
    
    @patch('services.search_engine.AsyncElasticsearch')
    @pytest.mark.asyncio
    async def test_log_indexing(self, mock_es_class, mock_es_client):
        """Test log indexing functionality"""
        mock_es_class.return_value = mock_es_client
        mock_es_client.index = AsyncMock()
        
        search_engine = SearchEngine()
        log_data = {
            "level": "INFO",
            "message": "Test log",
            "source": "test-app",
            "timestamp": "2025-09-15T10:00:00"
        }
        
        await search_engine.index_log(log_data)
        
        # Verify indexing was called with correct parameters
        mock_es_client.index.assert_called_once()
        call_args = mock_es_client.index.call_args
        assert call_args[1]['index'] == 'logs'
        assert call_args[1]['body'] == log_data
    
    @patch('services.search_engine.AsyncElasticsearch')
    @pytest.mark.asyncio
    async def test_search_logs(self, mock_es_class, mock_es_client):
        """Test log search functionality"""
        mock_es_class.return_value = mock_es_client
        
        # Mock search response
        mock_response = {
            'hits': {
                'total': {'value': 1},
                'hits': [
                    {
                        '_source': {
                            'level': 'ERROR',
                            'message': 'Test error',
                            'source': 'test-app'
                        }
                    }
                ]
            },
            'took': 15
        }
        mock_es_client.search.return_value = mock_response
        
        search_engine = SearchEngine()
        result = await search_engine.search_logs("error", limit=10)
        
        # Verify search results
        assert result['total_count'] == 1
        assert result['took_ms'] == 15
        assert len(result['logs']) == 1
        assert result['logs'][0]['level'] == 'ERROR'