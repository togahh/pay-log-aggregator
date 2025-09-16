# Pay Log Aggregator - Terraform Infrastructure

This directory contains Terraform configurations for deploying the Pay Log Aggregator Helm chart to Kubernetes clusters across multiple environments.

## Structure

```
terraform/
├── modules/
│   └── helm-chart/          # Reusable Helm chart module
│       ├── main.tf          # Main module logic
│       ├── variables.tf     # Module input variables
│       ├── outputs.tf       # Module outputs
│       └── versions.tf      # Provider requirements
├── environments/
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment
│   └── prod/                # Production environment
├── scripts/                 # Helper scripts
└── README.md               # This file
```

## Prerequisites

- Terraform >= 1.0
- kubectl configured with access to your Kubernetes cluster
- Helm chart built and available in `../helm-chart/`

## Quick Start

### 1. Configure your environment

Navigate to the desired environment directory:

```bash
cd environments/dev
```

### 2. Create a terraform.tfvars file

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Initialize and deploy

```bash
terraform init
terraform plan
terraform apply
```

## Environment Configurations

### Development (dev)

- **Purpose**: Development and testing
- **Features**: Debug logging, minimal resources, no network policies
- **Scaling**: Single replica, optional autoscaling
- **Ingress**: Optional, self-signed certificates

```bash
cd environments/dev
terraform init
terraform apply -var="image_tag=latest"
```

### Staging (staging)

- **Purpose**: Pre-production testing
- **Features**: Production-like setup, moderate resources, network policies enabled
- **Scaling**: 2 replicas minimum, autoscaling enabled
- **Ingress**: Enabled with staging certificates

```bash
cd environments/staging
terraform init
terraform apply -var="image_tag=v1.2.3"
```

### Production (prod)

- **Purpose**: Production workloads
- **Features**: High availability, full security, monitoring
- **Scaling**: 3 replicas minimum, aggressive autoscaling
- **Ingress**: HTTPS enforced, production certificates
- **Validation**: Prevents deployment of 'latest' tag

```bash
cd environments/prod
terraform init
terraform apply -var="image_tag=v1.2.3"
```

## Module Configuration

The `modules/helm-chart` module provides a reusable interface for deploying the Pay Log Aggregator with environment-specific configurations.

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Environment name (dev/staging/prod) | - | Yes |
| `image_tag` | Container image tag to deploy | `latest` | Yes |
| `namespace` | Kubernetes namespace | `default` | No |
| `elasticsearch_host` | Elasticsearch server host | `elasticsearch` | No |
| `enable_autoscaling` | Enable HPA | `false` | No |
| `enable_monitoring` | Enable Prometheus monitoring | `true` | No |
| `enable_ingress` | Enable external access | `false` | No |

### Example Usage

```hcl
module "pay_log_aggregator" {
  source = "../../modules/helm-chart"

  environment     = "prod"
  image_tag       = "v1.2.3"
  namespace       = "pay-log-aggregator-prod"
  
  elasticsearch = {
    host     = "elasticsearch.elastic.svc.cluster.local"
    port     = 9200
    username = var.elasticsearch_username
    password = var.elasticsearch_password
  }

  autoscaling = {
    enabled                        = true
    min_replicas                   = 3
    max_replicas                   = 10
    target_cpu_utilization_percentage = 70
  }
}
```

## Variable Files

Create environment-specific variable files:

### terraform.tfvars.example

```hcl
# Image configuration
image_tag = "v1.2.3"

# Elasticsearch configuration
elasticsearch_host     = "elasticsearch.example.com"
elasticsearch_username = "elastic"
elasticsearch_password = "your-secure-password"

# Ingress configuration
enable_ingress = true
ingress_host   = "pay-log-aggregator.example.com"

# Scaling configuration
enable_autoscaling = true
min_replicas      = 2
max_replicas      = 8

# Resource configuration
cpu_request    = "200m"
memory_request = "256Mi"
cpu_limit      = "500m"
memory_limit   = "512Mi"
```

## Outputs

Each environment provides useful outputs:

```bash
# Get service URL
terraform output service_url

# Get ingress hostname
terraform output ingress_host

# Get all outputs
terraform output
```

## State Management

### Remote State Backend

Configure remote state storage for team collaboration:

1. **AWS S3 + DynamoDB**:
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "pay-log-aggregator/prod/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

2. **Azure Storage**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "pay-log-aggregator/prod/terraform.tfstate"
  }
}
```

3. **Google Cloud Storage**:
```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "pay-log-aggregator/prod"
  }
}
```

## Security Best Practices

### 1. Sensitive Variables

Use environment variables or external secret management:

```bash
export TF_VAR_elasticsearch_password="your-secure-password"
terraform apply
```

### 2. State File Security

- Store state files in encrypted remote backends
- Use state file locking (DynamoDB, Azure Storage, etc.)
- Restrict access to state storage

### 3. Variable Validation

The configuration includes validation rules:

```hcl
variable "environment" {
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

## Deployment Workflows

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Configure kubectl
        run: |
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig
          
      - name: Deploy to staging
        run: |
          cd terraform/environments/staging
          terraform init
          terraform apply -auto-approve \
            -var="image_tag=${{ github.sha }}"
```

### Manual Deployment Steps

1. **Validate configuration**:
```bash
terraform validate
terraform fmt -check
```

2. **Plan deployment**:
```bash
terraform plan -out=tfplan
```

3. **Apply changes**:
```bash
terraform apply tfplan
```

4. **Verify deployment**:
```bash
kubectl get pods -n $(terraform output -raw namespace)
kubectl get svc -n $(terraform output -raw namespace)
```

## Troubleshooting

### Common Issues

1. **Provider Authentication**:
```bash
# Ensure kubectl context is configured
kubectl config current-context

# Test Kubernetes access
kubectl get nodes
```

2. **Helm Release Issues**:
```bash
# Check Helm releases
helm list -A

# Debug failed release
helm status pay-log-aggregator -n namespace
```

3. **Resource Conflicts**:
```bash
# Check for existing resources
kubectl get all -n pay-log-aggregator-dev

# Clean up failed deployments
terraform destroy
```

### Debug Commands

```bash
# Enable Terraform debugging
export TF_LOG=DEBUG
terraform apply

# Check Kubernetes events
kubectl get events -n namespace --sort-by='.lastTimestamp'

# Examine pod logs
kubectl logs -f deployment/pay-log-aggregator -n namespace
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources created by Terraform. Use with caution in production environments.

## Contributing

1. Follow Terraform best practices
2. Use consistent variable naming
3. Add validation rules for inputs
4. Update documentation for new features
5. Test changes in dev environment first

## Support

For issues related to:
- **Terraform configuration**: Check this documentation
- **Helm chart**: See `../helm-chart/README.md`
- **Application**: See `../README.md`