from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import structlog
import os
import uuid
import asyncio
from typing import List
from datetime import datetime

from models.log_schemas import LogEntry, SearchQuery, LogSearchResponse, ErrorPattern, IngestResponse
from services.search_engine import SearchEngine
from config.otel_config import setup_telemetry, instrument_app

# Setup structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Initialize services
search_engine = SearchEngine()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Log Aggregator API...")
    await search_engine.initialize()
    logger.info("Services initialized")
    yield
    # Shutdown
    logger.info("Shutting down Log Aggregator API...")

app = FastAPI(
    title="Pay Log Aggregator",
    description="High-performance log aggregation and search system",
    version="1.0.0",
    lifespan=lifespan
)

# Setup OpenTelemetry
tracer = setup_telemetry()
app = instrument_app(app)

# Simple CORS for development
app.add_middleware(CORSMiddleware, allow_origins=["*"])

@app.get("/")
async def root():
    logger.info("Health check accessed", endpoint="/")
    return {"message": "Log Aggregator is alive!", "timestamp": datetime.utcnow().isoformat()}

@app.get("/health")
async def health_check():
    logger.info("Health check")
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "elasticsearch": "connected"
    }

@app.post("/logs/ingest", response_model=IngestResponse)
async def ingest_log(log_entry: LogEntry) -> IngestResponse:
    """Ingest a single log entry"""
    with tracer.start_as_current_span("ingest_log") as span:
        try:
            # Add correlation ID for tracing
            correlation_id = str(uuid.uuid4())
            log_entry_dict = log_entry.model_dump()
            log_entry_dict["correlation_id"] = correlation_id
            
            span.set_attribute("correlation_id", correlation_id)
            span.set_attribute("log_level", log_entry.level)
            span.set_attribute("log_source", log_entry.source)
            
            # Process log immediately in background
            asyncio.create_task(process_log_entry(log_entry_dict))
            
            logger.info(
                "Log entry received",
                correlation_id=correlation_id,
                source=log_entry.source,
                level=log_entry.level
            )
            
            return IngestResponse(
                success=True,
                message="Log entry queued for processing",
                correlation_id=correlation_id
            )
            
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            logger.error("Failed to ingest log", error=str(e))
            raise HTTPException(status_code=500, detail=f"Failed to ingest log: {str(e)}")


async def process_log_entry(log_entry_dict: dict):
    """Process a single log entry in the background"""
    try:
        # Store in Elasticsearch
        await search_engine.index_log(log_entry_dict)
        logger.info(
            "Log entry processed",
            correlation_id=log_entry_dict.get("correlation_id"),
            source=log_entry_dict.get("source")
        )
    except Exception as e:
        logger.error(
            "Failed to process log entry",
            correlation_id=log_entry_dict.get("correlation_id"),
            error=str(e)
        )

@app.post("/logs/batch-ingest", response_model=IngestResponse)
async def batch_ingest_logs(logs: List[LogEntry]) -> IngestResponse:
    """Ingest multiple log entries"""
    with tracer.start_as_current_span("batch_ingest_logs") as span:
        try:
            correlation_id = str(uuid.uuid4())
            span.set_attribute("correlation_id", correlation_id)
            span.set_attribute("batch_size", len(logs))
            
            # Process all logs in background
            tasks = []
            for log_entry in logs:
                log_entry_dict = log_entry.model_dump()
                log_entry_dict["correlation_id"] = correlation_id
                tasks.append(process_log_entry(log_entry_dict))
            
            asyncio.create_task(asyncio.gather(*tasks))
            
            logger.info(
                "Batch logs received",
                correlation_id=correlation_id,
                count=len(logs)
            )
            
            return IngestResponse(
                success=True,
                message=f"Batch of {len(logs)} log entries queued for processing",
                correlation_id=correlation_id
            )
            
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            logger.error("Failed to ingest batch logs", error=str(e))
            raise HTTPException(status_code=500, detail=f"Failed to ingest batch logs: {str(e)}")

@app.get("/logs/search", response_model=LogSearchResponse)
async def search_logs(
    query: str = "",
    level: str = None,
    source: str = None,
    service: str = None,
    start_time: str = None,
    end_time: str = None,
    limit: int = 100,
    offset: int = 0
):
    """Search logs with various filters"""
    with tracer.start_as_current_span("search_logs") as span:
        # Parse datetime strings
        start_dt = datetime.fromisoformat(start_time) if start_time else None
        end_dt = datetime.fromisoformat(end_time) if end_time else None
        
        search_query = SearchQuery(
            query=query,
            level=level,
            source=source,
            service=service,
            start_time=start_dt,
            end_time=end_dt,
            limit=min(limit, 1000),
            offset=max(offset, 0)
        )
        
        span.set_attribute("search.query", query)
        span.set_attribute("search.limit", search_query.limit)
        
        result = await search_engine.search_logs(search_query)
        
        logger.info("Search executed",
                   query=query,
                   results_count=len(result.logs),
                   total_count=result.total_count,
                   took_ms=result.took_ms)
        
        return result

@app.get("/logs/patterns", response_model=List[ErrorPattern])
async def get_error_patterns(hours: int = 24):
    """Get common error patterns from recent logs"""
    with tracer.start_as_current_span("get_error_patterns") as span:
        span.set_attribute("analysis.hours", hours)
        
        patterns = await search_engine.find_error_patterns(hours)
        
        logger.info("Error patterns analyzed",
                   patterns_found=len(patterns),
                   hours_analyzed=hours)
        
        return patterns

@app.get("/metrics")
async def get_metrics():
    """Get service metrics"""
    
    # In a real implementation, you'd integrate with Prometheus metrics
    return {
        "service": "log-aggregator",
        "timestamp": datetime.utcnow().isoformat(),
        "status": "running"
    }

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Log Aggregator API server...")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_config=None)
