locals {
  environment = var.environment != "" ? var.environment : terraform.workspace
  chart_path  = "../../helm-chart"
  
  common_labels = merge({
    environment = local.environment
    project     = "pay-log-aggregator"
    managed-by  = "terraform"
    workspace   = terraform.workspace
  }, var.extra_labels)

  common_annotations = merge({
    "terraform.io/workspace"   = terraform.workspace
    "terraform.io/environment" = local.environment
    "terraform.io/managed-by"  = "terraform"
  }, var.extra_annotations)

  app_env_vars = merge({
    ENVIRONMENT = local.environment
    LOG_LEVEL   = var.log_level
    DEBUG       = tostring(var.debug_mode)
  }, var.extra_env_vars)
}

module "pay_log_aggregator" {
  source = "../modules/helm-chart"

  chart_name       = "pay-log-aggregator"
  chart_version    = var.chart_version
  chart_path       = local.chart_path
  namespace        = var.namespace
  create_namespace = true
  environment      = local.environment

  image_repository  = var.image_repository
  image_tag         = var.image_tag
  image_pull_policy = var.image_pull_policy

  replica_count = var.replica_count

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

  autoscaling = {
    enabled                              = var.enable_autoscaling
    min_replicas                         = var.min_replicas
    max_replicas                         = var.max_replicas
    target_cpu_utilization_percentage    = var.target_cpu_utilization
    target_memory_utilization_percentage = var.target_memory_utilization
  }

  service = {
    type        = var.service_type
    port        = var.service_port
    annotations = merge(local.common_annotations, var.service_annotations)
  }

  ingress = {
    enabled     = var.enable_ingress
    class_name  = var.ingress_class_name
    annotations = merge(local.common_annotations, var.ingress_annotations)
    hosts = var.enable_ingress && var.ingress_host != "" ? [
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
    tls = var.enable_tls && var.tls_secret_name != "" ? [
      {
        secret_name = var.tls_secret_name
        hosts       = [var.ingress_host]
      }
    ] : []
  }

  elasticsearch = {
    enabled  = var.elasticsearch_enabled
    host     = var.elasticsearch_host
    port     = var.elasticsearch_port
    protocol = var.elasticsearch_protocol
    username = var.elasticsearch_username
    password = var.elasticsearch_password
  }

  monitoring = {
    enabled = var.enable_monitoring
    prometheus = {
      enabled = var.enable_monitoring
      path    = var.prometheus_path
      port    = var.prometheus_port
    }
  }

  security = {
    security_context = var.enable_security_context ? {
      run_as_non_root = true
      run_as_user     = var.run_as_user
      run_as_group    = var.run_as_group
      fs_group        = var.fs_group
    } : {
      run_as_non_root = null
      run_as_user = null
      run_as_group = null
      fs_group = null
    }
    container_security_context = var.enable_security_context ? {
      allow_privilege_escalation = false
      drop_capabilities          = ["ALL"]
      read_only_root_filesystem  = true
    } : {
      allow_privilege_escalation = null
      drop_capabilities = null
      read_only_root_filesystem = null
    }
    network_policy = {
      enabled = var.enable_network_policy
    }
  }

  extra_values = {
    env = local.app_env_vars

    podLabels      = local.common_labels
    podAnnotations = local.common_annotations

    config = {
      workspace   = terraform.workspace
      environment = local.environment
      log_level   = var.log_level
      debug       = var.debug_mode
    }
  }

  timeout         = var.helm_timeout
  wait            = var.helm_wait
  wait_for_jobs   = true
  cleanup_on_fail = var.helm_cleanup_on_fail
  atomic          = var.helm_atomic
  recreate_pods   = false
  max_history     = var.helm_max_history
}