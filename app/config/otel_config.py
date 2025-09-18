import os
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.elasticsearch import ElasticsearchInstrumentor

def setup_telemetry():
    """Initialize OpenTelemetry"""
    
    trace.set_tracer_provider(TracerProvider())
    tracer = trace.get_tracer(__name__)
    
    otlp_exporter = OTLPSpanExporter(
        endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:14268/api/traces"),
        insecure=True
    )
    
    span_processor = BatchSpanProcessor(otlp_exporter)
    trace.get_tracer_provider().add_span_processor(span_processor)
    
    metric_reader = PeriodicExportingMetricReader(
        OTLPMetricExporter(
            endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:14268/api/traces"),
            insecure=True
        )
    )
    metrics.set_meter_provider(MeterProvider(metric_readers=[metric_reader]))
    
    return tracer

def instrument_app(app):
    """Instrument FastAPI app"""
    FastAPIInstrumentor.instrument_app(app)
    ElasticsearchInstrumentor().instrument()
    
    return app
