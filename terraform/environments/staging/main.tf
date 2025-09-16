# Local values for staging environment
locals {
  environment = "staging"
  chart_path  = "../../../helm-chart"
  
  # Staging-specific configuration
  common_labels = {
    environment = local.environment
    project     = "pay-log-aggregator"
    managed-by  = "terraform"
  }
}

# Deploy the pay-log-aggregator using the Helm chart module
module "pay_log_aggregator" {
  source = "../../modules/helm-chart"

  # Chart configuration
  chart_name      = "pay-log-aggregator"
  chart_version   = "0.1.0"
  chart_path      = local.chart_path
  namespace       = var.namespace
  create_namespace = true
  environment     = local.environment

  # Image configuration
  image_repository = "pay-log-aggregator"
  image_tag        = var.image_tag
  image_pull_policy = "IfNotPresent"

  # Scaling configuration
  replica_count = 2

  # Resource configuration
  resources = {
    requests = {
      cpu    = var.cpu_request
      memory = var.memory_request
    }
    limits = {
      cpu    = var.cpu_limit
      memory = var.memory_limit
    }
  }

  # Autoscaling configuration
  autoscaling = {
    enabled                        = var.enable_autoscaling
    min_replicas                   = var.min_replicas
    max_replicas                   = var.max_replicas
    target_cpu_utilization_percentage = 70
    target_memory_utilization_percentage = 80
  }

  # Service configuration
  service = {
    type = "ClusterIP"
    port = 8000
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  # Ingress configuration
  ingress = {
    enabled    = var.enable_ingress
    class_name = "nginx"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "cert-manager.io/cluster-issuer"             = "letsencrypt-staging"
      "nginx.ingress.kubernetes.io/rate-limit"     = "100"
    }
    hosts = var.enable_ingress ? [
      {
        host = var.ingress_host
        paths = [
          {
            path      = "/"
            path_type = "Prefix"
          }
        ]
      }
    ] : []
    tls = var.enable_ingress ? [
      {
        secret_name = "pay-log-aggregator-tls-staging"
        hosts       = [var.ingress_host]
      }
    ] : []
  }

  # Elasticsearch configuration
  elasticsearch = {
    enabled  = true
    host     = var.elasticsearch_host
    port     = var.elasticsearch_port
    protocol = "http"
    username = var.elasticsearch_username
    password = var.elasticsearch_password
  }

  # Monitoring configuration
  monitoring = {
    enabled = var.enable_monitoring
    prometheus = {
      enabled = var.enable_monitoring
      path    = "/metrics"
      port    = "http"
    }
  }

  # Security configuration
  security = {
    security_context = {
      run_as_non_root = true
      run_as_user     = 1000
      run_as_group    = 3000
      fs_group        = 2000
    }
    container_security_context = {
      allow_privilege_escalation = false
      drop_capabilities          = ["ALL"]
      read_only_root_filesystem  = true
    }
    network_policy = {
      enabled = true # Enabled in staging for production-like environment
    }
  }

  # Additional staging-specific values
  extra_values = {
    # Standard logging in staging
    config = {
      log_level = "INFO"
      debug     = false
    }

    # Staging-specific environment variables
    env = {
      ENVIRONMENT = local.environment
      DEBUG       = "false"
      LOG_LEVEL   = "INFO"
    }

    # Staging-specific labels
    podLabels = merge(local.common_labels, {
      "version" = var.image_tag
    })

    # Staging-specific annotations
    podAnnotations = {
      "kubectl.kubernetes.io/default-container" = "pay-log-aggregator"
      "sidecar.istio.io/inject"                = "true"
    }

    # Enable pod disruption budget for high availability
    podDisruptionBudget = {
      enabled      = true
      minAvailable = "50%"
    }
  }

  # Helm configuration
  timeout         = 600
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true
  atomic          = true
  recreate_pods   = false
  max_history     = 10
}