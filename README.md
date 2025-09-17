# Pay Log Aggregator

A FastAPI-based log aggregation service that provides endpoints for log ingestion, searching, and monitoring with Elasticsearch backend and observability features.

## 📁 Project Structure

```
pay-log-aggregator/
├── app/                     # Application code and configuration
│   ├── main.py             # FastAPI application entry point
│   ├── models/             # Data models and schemas
│   ├── services/           # Business logic and services
│   ├── config/             # Configuration files
│   ├── tests/              # Unit and integration tests
│   ├── observability/      # Monitoring and observability setup
│   ├── Dockerfile          # Container image definition
│   ├── docker-compose.yml  # Local development environment
│   ├── requirements.txt    # Python dependencies
│   ├── pytest.ini         # Test configuration
│   └── wait-for-it.py     # Service dependency wait script
├── helm-chart/             # Kubernetes Helm chart
│   ├── Chart.yaml          # Chart metadata
│   ├── values.yaml         # Default configuration values
│   ├── templates/          # Kubernetes resource templates
│   ├── .helmignore         # Helm package exclusions
│   └── README.md           # Chart documentation
├── terraform/              # Infrastructure as Code
│   ├── modules/            # Reusable Terraform modules
│   │   └── helm-chart/     # Helm deployment module
│   ├── workspaces/         # Environment configurations
│   │   ├── main.tf         # Main configuration
│   │   ├── variables.tf    # Variable definitions
│   │   ├── providers.tf    # Provider configurations
│   │   ├── dev.tfvars      # Development environment
│   │   ├── staging.tfvars  # Staging environment
│   │   └── prod.tfvars     # Production environment
│   ├── scripts/            # Helper scripts
│   └── README.md           # Infrastructure documentation
├── logs/                   # Application logs (runtime)
├── .gitignore             # Git ignore patterns
└── README.md              # This file
```

## 🚀 Quick Start

### Local Development

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd pay-log-aggregator
   ```

2. **Start the development environment:**
   ```bash
   cd app
   docker-compose up -d
   ```

3. **Access the application:**
   - API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs
   - Elasticsearch: http://localhost:9200
   - Jaeger UI: http://localhost:16686
   - Prometheus: http://localhost:9090

### Kubernetes Deployment

1. **Deploy using Helm:**
   ```bash
   helm install pay-log-aggregator ./helm-chart
   ```

2. **Deploy using Terraform:**
   ```bash
   cd terraform/workspaces
   terraform init
   terraform workspace new dev
   terraform apply -var-file=dev.tfvars
   ```

## 📖 Component Documentation

### 🏗️ Application (`app/`)

The core FastAPI application with:
- **RESTful API** for log ingestion and search
- **Elasticsearch integration** for log storage
- **Prometheus metrics** for monitoring
- **Jaeger tracing** for observability
- **Health checks** and graceful shutdown

**Key Files:**
- `main.py` - Application entry point and API routes
- `models/` - Pydantic models for request/response validation
- `services/` - Business logic and external service integrations
- `config/` - Application configuration and settings

### ⛵ Helm Chart (`helm-chart/`)

Production-ready Kubernetes deployment with:
- **Scalable deployment** with HPA support
- **Service mesh ready** with proper labeling
- **Security hardened** with security contexts
- **Monitoring integrated** with ServiceMonitor
- **Configurable** for multiple environments

### 🏗️ Infrastructure (`terraform/`)

Infrastructure as Code using:
- **Terraform workspaces** for environment management
- **Modular design** with reusable components
- **Multi-environment** support (dev/staging/prod)
- **Helm provider** for Kubernetes deployments
- **Best practices** with proper state management

## 🛠️ Development Workflow

### Application Development

1. **Set up local environment:**
   ```bash
   cd app
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Run tests:**
   ```bash
   pytest
   ```

3. **Start local services:**
   ```bash
   docker-compose up elasticsearch jaeger prometheus
   ```

4. **Run application:**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### Infrastructure Development

1. **Helm chart development:**
   ```bash
   cd helm-chart
   helm lint .
   helm template . --debug
   ```

2. **Terraform development:**
   ```bash
   cd terraform/workspaces
   terraform fmt -recursive
   terraform validate
   terraform plan -var-file=dev.tfvars
   ```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ELASTICSEARCH_URL` | Elasticsearch connection URL | `http://localhost:9200` |
| `LOG_LEVEL` | Application log level | `INFO` |
| `JAEGER_AGENT_HOST` | Jaeger agent hostname | `localhost` |
| `PORT` | Application port | `8000` |

### Kubernetes Configuration

Environment-specific values are managed through:
- **Helm values** in `helm-chart/values.yaml`
- **Terraform variables** in `terraform/workspaces/*.tfvars`

## 📊 Monitoring and Observability

### Metrics
- **Prometheus** metrics at `/metrics` endpoint
- **Custom metrics** for log ingestion rates and search performance
- **Health checks** at `/health` and `/health/ready`

### Tracing
- **Jaeger** distributed tracing integration
- **OpenTelemetry** instrumentation
- **Request correlation** across services

### Logging
- **Structured logging** with JSON format
- **Log levels** configurable via environment
- **Centralized collection** via Elasticsearch

## 🧪 Testing

```bash
cd app

# Run all tests
pytest

# Run with coverage
pytest --cov=. --cov-report=html

# Run specific test categories
pytest -m unit
pytest -m integration
```

## 🚀 Deployment

### Development
```bash
cd terraform/workspaces
terraform workspace select dev
terraform apply -var-file=dev.tfvars
```

### Staging
```bash
terraform workspace select staging
terraform apply -var-file=staging.tfvars
```

### Production
```bash
terraform workspace select prod
terraform apply -var-file=prod.tfvars
```

## 🤝 Contributing

1. Follow the project structure guidelines
2. Add tests for new features
3. Update documentation for changes
4. Use conventional commit messages
5. Test in development environment first

## 📄 License

This project is licensed under the MIT License.