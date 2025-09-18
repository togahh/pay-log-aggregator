namespace = "pay-log-aggregator-dev"

image_tag         = "latest"
image_pull_policy = "IfNotPresent"

replica_count       = 1
enable_autoscaling  = false
min_replicas        = 1
max_replicas        = 3

cpu_request    = "50m"
memory_request = "64Mi"
cpu_limit      = "200m"
memory_limit   = "256Mi"

service_type = "ClusterIP"
service_port = 8000

enable_ingress = false
ingress_host   = "pay-log-aggregator-dev.local"
enable_tls     = false

elasticsearch_enabled  = true
elasticsearch_host     = "elasticsearch-dev"
elasticsearch_port     = 9200
elasticsearch_protocol = "http"
elasticsearch_username = ""
elasticsearch_password = ""

enable_monitoring = true
prometheus_path   = "/metrics"

enable_security_context = true
enable_network_policy   = false
run_as_user             = 1000
run_as_group            = 3000
fs_group                = 2000

log_level  = "DEBUG"
debug_mode = true

extra_env_vars = {
  ENVIRONMENT     = "development"
  ENABLE_CORS     = "true"
  CORS_ORIGINS    = "*"
  API_RATE_LIMIT  = "1000"
  CACHE_TTL       = "300"
}

extra_labels = {
  cost-center = "development"
  team        = "platform"
  purpose     = "development"
}

extra_annotations = {
  "dev.kubernetes.io/environment" = "development"
  "monitoring.coreos.com/scrape"  = "true"
}

helm_timeout        = 300
helm_wait           = true
helm_atomic         = false
helm_cleanup_on_fail = false 
helm_max_history    = 5