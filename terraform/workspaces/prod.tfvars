namespace = "pay-log-aggregator"

image_tag         = "1.0.0"
image_pull_policy = "IfNotPresent"

replica_count       = 3
enable_autoscaling  = true
min_replicas        = 3
max_replicas        = 10
target_cpu_utilization    = 80
target_memory_utilization = 85

cpu_request    = "200m"
memory_request = "256Mi"
cpu_limit      = "500m"
memory_limit   = "512Mi"

service_type = "ClusterIP"
service_port = 8000
service_annotations = {
  "service.beta.kubernetes.io/aws-load-balancer-type"                = "nlb"
  "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
}

enable_ingress      = true
ingress_class_name  = "nginx"
ingress_host        = "pay-log-aggregator.example.com"
enable_tls          = true
tls_secret_name     = "pay-log-aggregator-prod-tls"
ingress_annotations = {
  "nginx.ingress.kubernetes.io/rewrite-target"           = "/"
  "nginx.ingress.kubernetes.io/ssl-redirect"             = "true"
  "nginx.ingress.kubernetes.io/force-ssl-redirect"       = "true"
  "cert-manager.io/cluster-issuer"                       = "letsencrypt-prod"
  "nginx.ingress.kubernetes.io/rate-limit"               = "200"
  "nginx.ingress.kubernetes.io/rate-limit-window"        = "1m"
  "nginx.ingress.kubernetes.io/proxy-body-size"          = "10m"
  "nginx.ingress.kubernetes.io/proxy-read-timeout"       = "60"
  "nginx.ingress.kubernetes.io/proxy-send-timeout"       = "60"
}

elasticsearch_enabled  = true
elasticsearch_host     = "elasticsearch-prod"
elasticsearch_port     = 9200
elasticsearch_protocol = "https"
elasticsearch_username = "elastic"

enable_monitoring = true
prometheus_path   = "/metrics"

enable_security_context = true
enable_network_policy   = true
run_as_user             = 1000
run_as_group            = 3000
fs_group                = 2000

log_level  = "INFO"
debug_mode = false

extra_env_vars = {
  ENVIRONMENT     = "production"
  ENABLE_CORS     = "true"
  CORS_ORIGINS    = "https://app.example.com"
  API_RATE_LIMIT  = "1000"
  CACHE_TTL       = "900"
  METRICS_ENABLED = "true"
  TRACING_ENABLED = "true"
}

extra_labels = {
  cost-center = "engineering"
  team        = "platform"
  purpose     = "production"
  backup      = "hourly"
  monitoring  = "critical"
}

extra_annotations = {
  "production.kubernetes.io/environment" = "production"
  "monitoring.coreos.com/scrape"         = "true"
  "backup.kubernetes.io/schedule"        = "hourly"
  "security.kubernetes.io/policy"        = "restricted"
  "alerting.kubernetes.io/critical"      = "true"
}

helm_timeout         = 900
helm_wait            = true
helm_atomic          = true
helm_cleanup_on_fail = true
helm_max_history     = 20