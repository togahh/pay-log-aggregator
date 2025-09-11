from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import structlog
import os
from typing import List
from datetime import datetime

from models.log_schemas import LogEntry, LogBatch, SearchQuery, LogSearchResponse, ErrorPattern
from services.search_engine import SearchEngine
from services.log_collector import LogCollector
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
log_collector = LogCollector()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Log Aggregator API...")
    await search_engine.initialize()
    await log_collector.initialize()
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

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    logger.info("Health check accessed", endpoint="/")
    return {"message": "Log Aggregator is alive!", "timestamp": datetime.utcnow().isoformat()}

@app.get("/health")
async def health_check():
    queue_size = await log_collector.get_queue_size()
    logger.info("Health check", queue_size=queue_size)
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "queue_size": queue_size
    }

@app.post("/logs/ingest")
async def ingest_log(log: LogEntry, background_tasks: BackgroundTasks):
    """Ingest a single log entry"""
    with tracer.start_as_current_span("ingest_log") as span:
        span.set_attribute("log.level", log.level)
        span.set_attribute("log.source", log.source)
        
        # Queue for processing
        success = await log_collector.queue_log(log)
        if not success:
            logger.error("Failed to queue log", log_id=log.trace_id)
            raise HTTPException(status_code=500, detail="Failed to queue log")
        
        # Index in background
        background_tasks.add_task(index_log_async, log)
        
        logger.info("Log ingested", 
                   level=log.level, 
                   source=log.source, 
                   trace_id=log.trace_id)
        
        return {"message": "Log ingested successfully", "trace_id": log.trace_id}

@app.post("/logs/batch-ingest")
async def ingest_logs_batch(batch: LogBatch, background_tasks: BackgroundTasks):
    """Ingest multiple logs in batch"""
    with tracer.start_as_current_span("ingest_logs_batch") as span:
        span.set_attribute("batch.size", len(batch.logs))
        
        # Queue for processing
        queued_count = await log_collector.queue_logs_batch(batch.logs)
        
        # Index in background
        background_tasks.add_task(index_logs_batch_async, batch.logs)
        
        logger.info("Batch ingested", 
                   batch_size=len(batch.logs), 
                   queued=queued_count,
                   batch_id=batch.batch_id)
        
        return {
            "message": "Batch ingested successfully",
            "batch_id": batch.batch_id,
            "logs_count": len(batch.logs),
            "queued_count": queued_count
        }

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
    queue_size = await log_collector.get_queue_size()
    
    # In a real implementation, you'd integrate with Prometheus metrics
    return {
        "queue_size": queue_size,
        "timestamp": datetime.utcnow().isoformat(),
        "service": "log-aggregator"
    }

# Background tasks
async def index_log_async(log: LogEntry):
    """Background task to index a single log"""
    await search_engine.index_log(log)

async def index_logs_batch_async(logs: List[LogEntry]):
    """Background task to index logs batch"""
    await search_engine.index_logs_batch(logs)

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Log Aggregator API server...")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_config=None)
