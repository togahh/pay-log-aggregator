namespace = "pay-log-aggregator-staging"

image_tag         = "staging"
image_pull_policy = "IfNotPresent"

replica_count       = 2
enable_autoscaling  = true
min_replicas        = 2
max_replicas        = 5
target_cpu_utilization    = 70
target_memory_utilization = 75

cpu_request    = "100m"
memory_request = "128Mi"
cpu_limit      = "300m"
memory_limit   = "384Mi"

service_type = "ClusterIP"
service_port = 8000
service_annotations = {
  "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
}

enable_ingress      = true
ingress_class_name  = "nginx"
ingress_host        = "pay-log-aggregator-staging.example.com"
enable_tls          = true
tls_secret_name     = "pay-log-aggregator-staging-tls"
ingress_annotations = {
  "nginx.ingress.kubernetes.io/rewrite-target"           = "/"
  "nginx.ingress.kubernetes.io/ssl-redirect"             = "true"
  "nginx.ingress.kubernetes.io/force-ssl-redirect"       = "true"
  "cert-manager.io/cluster-issuer"                       = "letsencrypt-staging"
  "nginx.ingress.kubernetes.io/rate-limit"               = "100"
  "nginx.ingress.kubernetes.io/rate-limit-window"        = "1m"
}

elasticsearch_enabled  = true
elasticsearch_host     = "elasticsearch-staging"
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
  ENVIRONMENT     = "staging"
  ENABLE_CORS     = "true"
  CORS_ORIGINS    = "https://app-staging.example.com"
  API_RATE_LIMIT  = "500"
  CACHE_TTL       = "600"
  METRICS_ENABLED = "true"
}

extra_labels = {
  cost-center = "engineering"
  team        = "platform"
  purpose     = "staging"
  backup      = "daily"
}

extra_annotations = {
  "staging.kubernetes.io/environment"  = "staging"
  "monitoring.coreos.com/scrape"       = "true"
  "backup.kubernetes.io/schedule"      = "daily"
  "security.kubernetes.io/policy"      = "restricted"
}

helm_timeout         = 600
helm_wait            = true
helm_atomic          = true
helm_cleanup_on_fail = true
helm_max_history     = 10