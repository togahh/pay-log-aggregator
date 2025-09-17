# Development environment configuration
namespace = "pay-log-aggregator-dev"

# Image configuration
image_tag         = "latest"
image_pull_policy = "IfNotPresent"

# Scaling configuration
replica_count       = 1
enable_autoscaling  = false
min_replicas        = 1
max_replicas        = 3

# Resource configuration (lighter for dev)
cpu_request    = "50m"
memory_request = "64Mi"
cpu_limit      = "200m"
memory_limit   = "256Mi"

# Service configuration
service_type = "ClusterIP"
service_port = 8000

# Ingress configuration (disabled for dev)
enable_ingress = false
ingress_host   = "pay-log-aggregator-dev.local"
enable_tls     = false

# Elasticsearch configuration
elasticsearch_enabled  = true
elasticsearch_host     = "elasticsearch-dev"
elasticsearch_port     = 9200
elasticsearch_protocol = "http"
elasticsearch_username = ""
elasticsearch_password = ""

# Monitoring configuration
enable_monitoring = true
prometheus_path   = "/metrics"

# Security configuration (relaxed for dev)
enable_security_context = true
enable_network_policy   = false
run_as_user             = 1000
run_as_group            = 3000
fs_group                = 2000

# Application configuration
log_level  = "DEBUG"
debug_mode = true

# Additional environment variables
extra_env_vars = {
  ENVIRONMENT     = "development"
  ENABLE_CORS     = "true"
  CORS_ORIGINS    = "*"
  API_RATE_LIMIT  = "1000"
  CACHE_TTL       = "300"
}

# Additional labels
extra_labels = {
  cost-center = "development"
  team        = "platform"
  purpose     = "development"
}

# Additional annotations
extra_annotations = {
  "dev.kubernetes.io/environment" = "development"
  "monitoring.coreos.com/scrape"  = "true"
}

# Helm configuration
helm_timeout        = 300
helm_wait           = true
helm_atomic         = false  # Allow partial deployments in dev
helm_cleanup_on_fail = false # Keep resources for debugging
helm_max_history    = 5