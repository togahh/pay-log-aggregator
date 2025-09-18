# Pay Log Aggregator

A FastAPI log aggregation service with Elasticsearch backend.

## Getting Started

Start the application:
```bash
cd app
docker compose up -d
```

Access:
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Elasticsearch: http://localhost:9200

## Project Structure

```
app/                    # FastAPI application
helm-chart/            # Kubernetes deployment
terraform/             # Infrastructure code
logs/                  # Application logs
```

## API Endpoints

- `POST /logs/ingest` - Add a log entry
- `GET /logs/search` - Search logs
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Deployment

```bash
cd terraform/workspaces
terraform workspace select dev
terraform apply -var-file=dev.tfvars

terraform workspace select prod
terraform apply -var-file=prod.tfvars
```