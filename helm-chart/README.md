# Pay Log Aggregator Helm Chart

A standalone Helm chart for deploying the Pay Log Aggregator application on Kubernetes.

## Overview

This Helm chart deploys a FastAPI-based log aggregation service that provides endpoints for log ingestion, searching, and monitoring. The chart includes all necessary Kubernetes resources for a production-ready deployment.

## Features

- **Scalable Deployment**: Horizontal Pod Autoscaler (HPA) for automatic scaling
- **Health Monitoring**: Liveness and readiness probes
- **Security**: RBAC, Network Policies, Pod Security Context
- **Monitoring**: Prometheus metrics integration
- **High Availability**: Pod Disruption Budget and topology spread constraints
- **Configuration Management**: ConfigMaps and environment variables
- **External Dependencies**: Elasticsearch integration for log storage

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Elasticsearch cluster (external or deployed separately)

## Installation

### Quick Start

```bash
# Add your container registry and update image repository in values.yaml
helm install pay-log-aggregator ./helm-chart \
  --set image.repository=your-registry/pay-log-aggregator \
  --set image.tag=latest
```

### With Custom Values

```bash
# Create custom values file
cat > my-values.yaml <<EOF
image:
  repository: your-registry/pay-log-aggregator
  tag: "v1.0.0"

elasticsearch:
  host: "elasticsearch.elastic.svc.cluster.local"
  port: 9200

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
EOF

# Install with custom values
helm install pay-log-aggregator ./helm-chart -f my-values.yaml
```

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `pay-log-aggregator` |
| `image.tag` | Container image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `5` |
| `elasticsearch.host` | Elasticsearch host | `elasticsearch` |
| `elasticsearch.port` | Elasticsearch port | `9200` |
| `prometheus.enabled` | Enable Prometheus metrics | `true` |
| `rbac.create` | Create RBAC resources | `true` |
| `networkPolicy.enabled` | Enable network policies | `true` |

### Environment Variables

The application supports the following environment variables:

- `ELASTICSEARCH_HOST`: Elasticsearch server hostname
- `ELASTICSEARCH_PORT`: Elasticsearch server port
- `LOG_LEVEL`: Application log level (DEBUG, INFO, WARNING, ERROR)
- `PORT`: Application port (default: 8000)

### Security Configuration

```yaml
security:
  enabled: true
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  
podSecurityContext:
  fsGroup: 1000
```

### Resource Configuration

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## Elasticsearch Integration

This chart can work with external Elasticsearch clusters. Configure the connection:

```yaml
elasticsearch:
  host: "your-elasticsearch-host"
  port: 9200
  username: "elastic"
  password: "your-password"
  ssl: true
```

For external Elasticsearch with authentication, create a secret:

```bash
kubectl create secret generic elasticsearch-credentials \
  --from-literal=username=elastic \
  --from-literal=password=your-password
```

## Monitoring

### Prometheus Integration

The chart includes ServiceMonitor configuration for Prometheus:

```yaml
prometheus:
  enabled: true
  port: 8000
  path: "/metrics"
  interval: "30s"
```

### Health Checks

Health check endpoints:
- Liveness: `/health`
- Readiness: `/health/ready`
- Metrics: `/metrics`

## Networking

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: pay-log-aggregator.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: pay-log-aggregator-tls
      hosts:
        - pay-log-aggregator.example.com
```

### Network Policies

Network policies are enabled by default and allow:
- Ingress from any pod with label `access: pay-log-aggregator`
- Egress to Elasticsearch and DNS

## Testing

### Helm Tests

Run built-in tests:

```bash
helm test pay-log-aggregator
```

### Manual Testing

```bash
# Port forward to access the service
kubectl port-forward svc/pay-log-aggregator 8080:80

# Test health endpoint
curl http://localhost:8080/health

# Test log ingestion
curl -X POST "http://localhost:8080/logs/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "message": "Test log message",
    "source": "test",
    "timestamp": "2025-01-01T12:00:00Z"
  }'

# Search logs
curl -X POST "http://localhost:8080/logs/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "test",
    "limit": 10
  }'
```

## Upgrading

```bash
# Upgrade to new version
helm upgrade pay-log-aggregator ./helm-chart \
  --set image.tag=v2.0.0

# Upgrade with new values
helm upgrade pay-log-aggregator ./helm-chart -f my-values.yaml
```

## Uninstalling

```bash
helm uninstall pay-log-aggregator
```

## Troubleshooting

### Common Issues

1. **Pod fails to start**: Check resource limits and image availability
   ```bash
   kubectl describe pod -l app.kubernetes.io/name=pay-log-aggregator
   ```

2. **Cannot connect to Elasticsearch**: Verify Elasticsearch configuration
   ```bash
   kubectl logs deployment/pay-log-aggregator
   ```

3. **HPA not scaling**: Check metrics server and resource requests
   ```bash
   kubectl get hpa
   kubectl top pods
   ```

### Debug Commands

```bash
# Check all resources
kubectl get all -l app.kubernetes.io/name=pay-log-aggregator

# View configuration
helm get values pay-log-aggregator

# Check generated manifests
helm template pay-log-aggregator ./helm-chart

# Validate chart
helm lint ./helm-chart
```

## Contributing

1. Make changes to the chart
2. Update version in `Chart.yaml`
3. Test with `helm lint` and `helm template`
4. Validate with `helm install --dry-run`

## License

This Helm chart is licensed under the MIT License.