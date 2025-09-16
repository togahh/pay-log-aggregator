# Local values for production environment
locals {
  environment = "prod"
  chart_path  = "../../../helm-chart"
  
  # Production-specific configuration
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

  # Scaling configuration (higher for production)
  replica_count = 3

  # Resource configuration (production-grade resources)
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
    target_cpu_utilization_percentage = 60 # Lower threshold for production
    target_memory_utilization_percentage = 70
  }

  # Service configuration
  service = {
    type = "ClusterIP"
    port = 8000
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"               = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"   = "http"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
    }
  }

  # Ingress configuration
  ingress = {
    enabled    = var.enable_ingress
    class_name = "nginx"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target"       = "/"
      "cert-manager.io/cluster-issuer"                   = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/rate-limit"           = "200"
      "nginx.ingress.kubernetes.io/rate-limit-window"    = "1m"
      "nginx.ingress.kubernetes.io/ssl-redirect"         = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect"   = "true"
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
        secret_name = "pay-log-aggregator-tls-prod"
        hosts       = [var.ingress_host]
      }
    ] : []
  }

  # Elasticsearch configuration
  elasticsearch = {
    enabled  = true
    host     = var.elasticsearch_host
    port     = var.elasticsearch_port
    protocol = "https" # Use HTTPS in production
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

  # Security configuration (strict for production)
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
      enabled = true # Always enabled in production
    }
  }

  # Additional production-specific values
  extra_values = {
    # Production logging configuration
    config = {
      log_level = "WARN"
      debug     = false
    }

    # Production environment variables
    env = {
      ENVIRONMENT = local.environment
      DEBUG       = "false"
      LOG_LEVEL   = "WARN"
    }

    # Production-specific labels
    podLabels = merge(local.common_labels, {
      "version"     = var.image_tag
      "criticality" = "high"
    })

    # Production-specific annotations
    podAnnotations = {
      "kubectl.kubernetes.io/default-container" = "pay-log-aggregator"
      "sidecar.istio.io/inject"                = "true"
      "prometheus.io/scrape"                   = "true"
      "prometheus.io/port"                     = "8000"
      "prometheus.io/path"                     = "/metrics"
    }

    # Enable pod disruption budget for high availability
    podDisruptionBudget = {
      enabled      = true
      minAvailable = "50%" # Ensure at least 50% of pods are always available
    }

    # Production-specific resource quotas and limits
    nodeSelector = {
      "kubernetes.io/arch" = "amd64"
      "node-type"         = "production"
    }

    # Topology spread constraints for better distribution
    topologySpreadConstraints = [
      {
        maxSkew           = 1
        topologyKey       = "kubernetes.io/hostname"
        whenUnsatisfiable = "DoNotSchedule"
        labelSelector = {
          matchLabels = {
            "app.kubernetes.io/name"     = "pay-log-aggregator"
            "app.kubernetes.io/instance" = "pay-log-aggregator"
          }
        }
      },
      {
        maxSkew           = 1
        topologyKey       = "topology.kubernetes.io/zone"
        whenUnsatisfiable = "DoNotSchedule"
        labelSelector = {
          matchLabels = {
            "app.kubernetes.io/name"     = "pay-log-aggregator"
            "app.kubernetes.io/instance" = "pay-log-aggregator"
          }
        }
      }
    ]
  }

  # Helm configuration (more conservative for production)
  timeout         = 900 # Longer timeout for production
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = false # Don't auto-cleanup in production for debugging
  atomic          = false # Don't rollback automatically in production
  recreate_pods   = false
  max_history     = 20 # Keep more history in production
}