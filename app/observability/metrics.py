from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
import time

meter = metrics.get_meter(__name__)

log_ingestion_counter = meter.create_counter(
    name="logs_ingested_total",
    description="Total number of logs ingested",
    unit="1"
)

log_ingestion_duration = meter.create_histogram(
    name="log_ingestion_duration_seconds",
    description="Time taken to ingest logs",
    unit="s"
)

search_duration = meter.create_histogram(
    name="search_duration_seconds", 
    description="Time taken to search logs",
    unit="s"
)

search_results_counter = meter.create_counter(
    name="search_results_total",
    description="Total number of search results returned",
    unit="1"
)

queue_size_gauge = meter.create_up_down_counter(
    name="queue_size",
    description="Current size of log processing queue",
    unit="1"
)

error_counter = meter.create_counter(
    name="errors_total",
    description="Total number of errors",
    unit="1"
)

class MetricsCollector:
    @staticmethod
    def record_log_ingested(count: int = 1, level: str = None, source: str = None):
        """Record log ingestion metrics"""
        attributes = {}
        if level:
            attributes["level"] = level
        if source:
            attributes["source"] = source
        
        log_ingestion_counter.add(count, attributes)
    
    @staticmethod
    def record_ingestion_duration(duration: float, batch_size: int = 1):
        """Record log ingestion duration"""
        log_ingestion_duration.record(duration, {"batch_size": str(batch_size)})
    
    @staticmethod
    def record_search_duration(duration: float, result_count: int):
        """Record search operation metrics"""
        search_duration.record(duration)
        search_results_counter.add(result_count)
    
    @staticmethod
    def update_queue_size(size: int):
        """Update queue size gauge"""
        queue_size_gauge.add(size)
    
    @staticmethod
    def record_error(error_type: str, endpoint: str = None):
        """Record error metrics"""
        attributes = {"error_type": error_type}
        if endpoint:
            attributes["endpoint"] = endpoint
        
        error_counter.add(1, attributes)
