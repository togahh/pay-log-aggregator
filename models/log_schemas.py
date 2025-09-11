from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any, List
from enum import Enum

class LogLevel(str, Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"

class LogEntry(BaseModel):
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    level: LogLevel
    message: str
    source: str
    service: Optional[str] = None
    trace_id: Optional[str] = None
    span_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class LogBatch(BaseModel):
    logs: List[LogEntry]
    batch_id: Optional[str] = None

class SearchQuery(BaseModel):
    query: str
    level: Optional[LogLevel] = None
    source: Optional[str] = None
    service: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    limit: int = Field(default=100, le=1000)
    offset: int = Field(default=0, ge=0)

class LogSearchResponse(BaseModel):
    logs: List[LogEntry]
    total_count: int
    took_ms: float
    
class ErrorPattern(BaseModel):
    pattern: str
    count: int
    first_seen: datetime
    last_seen: datetime
    services: List[str]
