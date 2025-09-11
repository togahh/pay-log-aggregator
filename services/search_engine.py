from elasticsearch import AsyncElasticsearch
from typing import List, Dict, Any
import os
import json
from datetime import datetime
from models.log_schemas import LogEntry, SearchQuery, LogSearchResponse, ErrorPattern

class SearchEngine:
    def __init__(self):
        self.es_url = os.getenv("ELASTICSEARCH_URL", "http://localhost:9200")
        self.client = AsyncElasticsearch([self.es_url])
        self.index_name = "logs"
    
    async def initialize(self):
        """Create index if it doesn't exist"""
        if not await self.client.indices.exists(index=self.index_name):
            mapping = {
                "mappings": {
                    "properties": {
                        "timestamp": {"type": "date"},
                        "level": {"type": "keyword"},
                        "message": {"type": "text", "analyzer": "standard"},
                        "source": {"type": "keyword"},
                        "service": {"type": "keyword"},
                        "trace_id": {"type": "keyword"},
                        "span_id": {"type": "keyword"},
                        "metadata": {"type": "object"}
                    }
                }
            }
            await self.client.indices.create(index=self.index_name, body=mapping)
    
    async def index_log(self, log: LogEntry) -> bool:
        """Index a single log entry"""
        try:
            doc = log.dict()
            doc['timestamp'] = log.timestamp.isoformat()
            
            await self.client.index(
                index=self.index_name,
                document=doc
            )
            return True
        except Exception as e:
            print(f"Error indexing log: {e}")
            return False
    
    async def index_logs_batch(self, logs: List[LogEntry]) -> Dict[str, Any]:
        """Index multiple logs in batch"""
        actions = []
        for log in logs:
            doc = log.dict()
            doc['timestamp'] = log.timestamp.isoformat()
            actions.extend([
                {"index": {"_index": self.index_name}},
                doc
            ])
        
        try:
            response = await self.client.bulk(operations=actions)
            return {
                "success": True,
                "indexed": len(logs),
                "errors": len([item for item in response['items'] if 'error' in item.get('index', {})])
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def search_logs(self, search_query: SearchQuery) -> LogSearchResponse:
        """Search logs based on query parameters"""
        query = {"bool": {"must": []}}
        
        # Text search
        if search_query.query:
            query["bool"]["must"].append({
                "multi_match": {
                    "query": search_query.query,
                    "fields": ["message", "source", "service"]
                }
            })
        
        # Filters
        if search_query.level:
            query["bool"]["must"].append({"term": {"level": search_query.level}})
        
        if search_query.source:
            query["bool"]["must"].append({"term": {"source": search_query.source}})
            
        if search_query.service:
            query["bool"]["must"].append({"term": {"service": search_query.service}})
        
        # Time range
        if search_query.start_time or search_query.end_time:
            time_range = {}
            if search_query.start_time:
                time_range["gte"] = search_query.start_time.isoformat()
            if search_query.end_time:
                time_range["lte"] = search_query.end_time.isoformat()
            query["bool"]["must"].append({"range": {"timestamp": time_range}})
        
        try:
            start_time = datetime.utcnow()
            response = await self.client.search(
                index=self.index_name,
                query=query,
                size=search_query.limit,
                from_=search_query.offset,
                sort=[{"timestamp": {"order": "desc"}}]
            )
            
            took_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            logs = []
            for hit in response['hits']['hits']:
                source = hit['_source']
                logs.append(LogEntry(**source))
            
            return LogSearchResponse(
                logs=logs,
                total_count=response['hits']['total']['value'],
                took_ms=took_ms
            )
        except Exception as e:
            return LogSearchResponse(logs=[], total_count=0, took_ms=0.0)
    
    async def find_error_patterns(self, hours: int = 24) -> List[ErrorPattern]:
        """Find common error patterns"""
        time_filter = {
            "range": {
                "timestamp": {
                    "gte": f"now-{hours}h"
                }
            }
        }
        
        query = {
            "bool": {
                "must": [
                    {"terms": {"level": ["ERROR", "CRITICAL"]}},
                    time_filter
                ]
            }
        }
        
        aggs = {
            "error_patterns": {
                "terms": {
                    "field": "message.keyword",
                    "size": 50
                },
                "aggs": {
                    "first_seen": {"min": {"field": "timestamp"}},
                    "last_seen": {"max": {"field": "timestamp"}},
                    "services": {
                        "terms": {"field": "service", "size": 10}
                    }
                }
            }
        }
        
        try:
            response = await self.client.search(
                index=self.index_name,
                query=query,
                aggs=aggs,
                size=0
            )
            
            patterns = []
            for bucket in response['aggregations']['error_patterns']['buckets']:
                services = [s['key'] for s in bucket['services']['buckets']]
                patterns.append(ErrorPattern(
                    pattern=bucket['key'],
                    count=bucket['doc_count'],
                    first_seen=datetime.fromisoformat(bucket['first_seen']['value_as_string'].replace('Z', '+00:00')),
                    last_seen=datetime.fromisoformat(bucket['last_seen']['value_as_string'].replace('Z', '+00:00')),
                    services=services
                ))
            
            return patterns
        except Exception as e:
            print(f"Error finding patterns: {e}")
            return []
