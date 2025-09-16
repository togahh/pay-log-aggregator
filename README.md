# Pay Log Aggregator

A log aggregation and search system built with FastAPI and Elasticsearch. This was created as an interview exercise to demonstrate skills in large-scale data processing and search functionality.

## What it does

This system collects logs from multiple sources, stores them in Elasticsearch, and provides a searchable interface for finding specific patterns or errors. It follows best practices with containerization, structured logging, and observability.

## Key features

- Multi-source log ingestion with batch processing
- Real-time search using Elasticsearch
- Error pattern detection and analysis
- Distributed tracing with OpenTelemetry
- Structured JSON logging
- Docker containerization
- Health checks and metrics

## Architecture

```
Log Sources → FastAPI App → Elasticsearch
                  ↓
            OpenTelemetry Traces
```

The system accepts logs via HTTP endpoints, validates them, and stores them in Elasticsearch for searching.

## Service Level Objectives (SLOs)

I chose these SLOs because they reflect the core requirements of a log aggregation system:

**Availability: 99.9% uptime**
- Measured by successful health check responses
- Log systems need high availability since they're critical infrastructure

**Ingestion Latency: 95% of requests under 100ms** 
- Measured by P95 latency of the /logs/ingest endpoint
- Fast ingestion prevents log loss during high traffic

**Search Performance: 95% of queries under 500ms**
- Measured by P95 latency of /logs/search endpoint  
- Quick searches are essential for debugging and troubleshooting

**Throughput: Handle 10,000 logs per second**
- Measured by successful ingestions per second
- Must handle high-volume streams from multiple services

**Error Rate: Less than 0.1% ingestion failures**
- Measured by failed vs successful ingestion ratio
- Log loss is unacceptable for audit and debugging

## Tech stack

- FastAPI for the web framework
- Elasticsearch for search and storage
- OpenTelemetry for tracing and observability  
- Structlog for structured JSON logging
- Docker for containerization
- Jaeger for trace visualization

## Getting started

### Prerequisites
- Docker and Docker Compose
- Python 3.9+ (for local development)

### Run with Docker

1. Clone and start:
```bash
git clone git@github.com:togahh/pay-log-aggregator.git
cd pay-log-aggregator
docker compose up -d
```

2. Check it's working:
```bash
curl http://localhost:8000/health
```

### Local development

1. Setup Python environment:
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

2. Start dependencies:
```bash
docker compose up -d elasticsearch jaeger
```

3. Run the app:
```bash
python main.py
```

## API endpoints

**Basic endpoints:**
- GET / - Service status
- GET /health - Health check
- GET /metrics - Service metrics

**Log ingestion:**
- POST /logs/ingest - Add a single log
- POST /logs/batch-ingest - Add multiple logs

**Search:**
- POST /logs/search - Search logs with filters
- GET /logs/patterns - Find error patterns

**Documentation:**
- http://localhost:8000/docs - Interactive API docs
- http://localhost:8000/redoc - Documentation

## Usage examples

### Add a log entry
```bash
curl -X POST "http://localhost:8000/logs/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "ERROR",
    "message": "Database connection failed", 
    "source": "web-server-01",
    "service": "user-service"
  }'
```

### Search logs
```bash
curl -X POST "http://localhost:8000/logs/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "error",
    "level": "ERROR",
    "limit": 50
  }'
```

### Add multiple logs at once
```bash
curl -X POST "http://localhost:8000/logs/batch-ingest" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "level": "INFO",
      "message": "User login successful",
      "source": "auth-service"
    },
    {
      "level": "WARNING",
      "message": "Rate limit exceeded", 
      "source": "api-gateway"
    }
  ]'
```

## Project structure

```
├── main.py                 # Main FastAPI application
├── requirements.txt        # Python dependencies
├── Dockerfile             # Container setup
├── docker-compose.yml     # Multi-service configuration
├── wait-for-it.py         # Service startup coordination
├── config/
│   └── otel_config.py     # OpenTelemetry setup
├── models/
│   └── log_schemas.py     # Data models and validation
├── services/
│   └── search_engine.py   # Elasticsearch integration
└── tests/
    ├── test_simple_demo.py    # Main unit tests
    └── test_models_unit.py    # Model validation tests
```

## Running tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest tests/test_simple_demo.py -v
pytest tests/test_models_unit.py -v
```

## Monitoring

**Available interfaces:**
- http://localhost:8000/docs - API documentation and testing
- http://localhost:16686 - Jaeger tracing UI
- http://localhost:9200 - Elasticsearch cluster info

**What's monitored:**
- Request latency and throughput
- Error rates and patterns  
- Search query performance
- Service health and availability

## Configuration

Key environment variables:
```bash
ELASTICSEARCH_URL=http://localhost:9200
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:14268/api/traces
```

## Production considerations

For production deployment, you'd want to add:

- Authentication and authorization
- HTTPS/TLS encryption
- Rate limiting and input validation
- Elasticsearch cluster setup
- Log retention policies
- Backup and recovery procedures
- Load balancing for high availability


