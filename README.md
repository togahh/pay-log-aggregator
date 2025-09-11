# Pay Log Aggregator

A high-performance log aggregation and search system built with FastAPI, Elasticsearch, and OpenTelemetry. This system collects logs from multiple sources, aggregates them, and provides a searchable interface for finding specific patterns or errors.

## 🚀 Features

- **Multi-source log ingestion** with batch processing
- **Real-time search** with Elasticsearch backend
- **Error pattern detection** and analysis
- **Distributed tracing** with OpenTelemetry
- **Structured JSON logging** with correlation IDs
- **Container-ready** with Docker Compose
- **Production observability** with metrics and health checks

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Log Sources   │───▶│   FastAPI App    │───▶│  Elasticsearch  │
│                 │    │                  │    │                 │
│ • Applications  │    │ • Log Ingestion  │    │ • Full-text     │
│ • Services      │    │ • Validation     │    │   Search        │
│ • Infrastructure│    │ • Queuing        │    │ • Aggregations  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                          
                              ▼                          
                       ┌──────────────────┐              
                       │      Redis       │              
                       │                  │              
                       │ • Queue          │              
                       │ • Caching        │              
                       └──────────────────┘              
```

## 📊 Service Level Objectives (SLOs)

### Availability
- **SLO**: 99.9% uptime (8.77 hours downtime/year)
- **SLI**: Ratio of successful health check responses
- **Why**: Log aggregation is critical infrastructure that must be highly available

### Latency
- **SLO**: 95% of log ingestion requests complete within 100ms
- **SLI**: P95 latency of `/logs/ingest` endpoint
- **Why**: Fast ingestion prevents log loss and maintains real-time capabilities

### Search Performance
- **SLO**: 95% of search queries return results within 500ms
- **SLI**: P95 latency of `/logs/search` endpoint
- **Why**: Quick search responses are essential for troubleshooting and monitoring

### Throughput
- **SLO**: Process at least 10,000 logs per second during peak load
- **SLI**: Rate of successful log ingestions per second
- **Why**: System must handle high-volume log streams from multiple services

### Error Rate
- **SLO**: <0.1% error rate for log ingestion
- **SLI**: Ratio of failed vs successful ingestion requests
- **Why**: Log loss is unacceptable for audit and debugging purposes

## 🛠️ Technology Stack

- **FastAPI** - High-performance async web framework
- **Elasticsearch** - Full-text search and analytics engine
- **Redis** - In-memory queue and caching
- **OpenTelemetry** - Distributed tracing and observability
- **Structlog** - Structured logging with JSON output
- **Docker** - Containerization and orchestration
- **Prometheus** - Metrics collection and monitoring
- **Jaeger** - Distributed tracing UI

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Python 3.9+ (for local development)

### Running with Docker Compose

1. **Clone and start services:**
```bash
git clone git@github.com:togahh/pay-log-aggregator.git
cd pay-log-aggregator
docker-compose up -d
```

2. **Verify services are running:**
```bash
# Check service health
curl http://localhost:8000/health

# View Jaeger UI (tracing)
open http://localhost:16686

# View Elasticsearch
curl http://localhost:9200/_cluster/health
```

### Local Development

1. **Setup virtual environment:**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. **Start dependencies:**
```bash
docker-compose up -d elasticsearch redis jaeger
```

3. **Run the application:**
```bash
python main.py
```

## 📡 API Endpoints

### Health & Metrics
- `GET /` - Service status
- `GET /health` - Detailed health check
- `GET /metrics` - Service metrics

### Log Ingestion
- `POST /logs/ingest` - Ingest single log entry
- `POST /logs/batch-ingest` - Batch log ingestion

### Search & Analysis
- `GET /logs/search` - Search logs with filters
- `GET /logs/patterns` - Find error patterns

### Interactive Documentation
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🔍 Usage Examples

### Ingest a Single Log
```bash
curl -X POST "http://localhost:8000/logs/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "ERROR",
    "message": "Database connection failed",
    "source": "web-server-01",
    "service": "user-service",
    "metadata": {
      "error_code": "DB_CONN_TIMEOUT",
      "retry_count": 3
    }
  }'
```

### Batch Ingest Multiple Logs
```bash
curl -X POST "http://localhost:8000/logs/batch-ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "batch_id": "batch-001",
    "logs": [
      {
        "level": "INFO",
        "message": "User login successful",
        "source": "auth-service",
        "service": "authentication"
      },
      {
        "level": "WARNING", 
        "message": "Rate limit exceeded",
        "source": "api-gateway",
        "service": "gateway"
      }
    ]
  }'
```

### Search Logs
```bash
# Search for errors in the last hour
curl "http://localhost:8000/logs/search?query=error&level=ERROR&limit=50"

# Search by service and time range
curl "http://localhost:8000/logs/search?service=user-service&start_time=2024-01-01T00:00:00"
```

### Get Error Patterns
```bash
# Find common error patterns from last 24 hours
curl "http://localhost:8000/logs/patterns?hours=24"
```

## 🏗️ Project Structure

```
├── main.py                 # FastAPI application
├── requirements.txt        # Python dependencies
├── Dockerfile             # Container definition
├── docker-compose.yml     # Multi-service setup
├── config/
│   ├── otel_config.py     # OpenTelemetry configuration
│   └── prometheus.yml     # Prometheus configuration
├── models/
│   └── log_schemas.py     # Pydantic data models
├── services/
│   ├── search_engine.py   # Elasticsearch integration
│   └── log_collector.py   # Redis queue management
└── README.md              # This file
```

## 🔧 Configuration

### Environment Variables
```bash
# Elasticsearch
ELASTICSEARCH_URL=http://localhost:9200

# Redis
REDIS_URL=redis://localhost:6379

# OpenTelemetry
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:14268/api/traces
JAEGER_AGENT_HOST=localhost
```

## 📈 Monitoring & Observability

### Metrics
- Log ingestion rate and latency
- Search query performance
- Queue size and processing rate
- Error rates and patterns

### Tracing
- End-to-end request tracing with OpenTelemetry
- Correlation across service boundaries
- Performance bottleneck identification

### Logging
- Structured JSON logs with correlation IDs
- Configurable log levels
- Centralized log aggregation

## 🔒 Production Considerations

### Security
- Configure CORS origins for production
- Add authentication/authorization
- Enable TLS/SSL encryption
- Implement rate limiting

### Scalability
- Horizontal scaling with load balancer
- Elasticsearch cluster configuration
- Redis clustering for high availability
- Container orchestration (Kubernetes)

### Reliability
- Circuit breakers for external dependencies
- Graceful degradation strategies
- Data backup and recovery procedures
- Multi-region deployment

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details
