output "workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

output "environment" {
  description = "Environment name"
  value       = local.environment
}

output "release_name" {
  description = "Name of the Helm release"
  value       = module.pay_log_aggregator.release_name
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = module.pay_log_aggregator.namespace_name
}

output "service_url" {
  description = "Internal service URL"
  value       = module.pay_log_aggregator.service_url
}

output "service_name" {
  description = "Kubernetes service name"
  value       = module.pay_log_aggregator.service_name
}

output "service_port" {
  description = "Service port"
  value       = var.service_port
}

output "ingress_enabled" {
  description = "Whether ingress is enabled"
  value       = var.enable_ingress
}

output "ingress_host" {
  description = "Ingress hostname (if enabled)"
  value       = var.enable_ingress ? var.ingress_host : null
}

output "ingress_url" {
  description = "External ingress URL (if enabled)"
  value       = var.enable_ingress && var.ingress_host != "" ? "http${var.enable_tls ? "s" : ""}://${var.ingress_host}" : null
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "autoscaling_enabled" {
  description = "Whether autoscaling is enabled"
  value       = var.enable_autoscaling
}

output "autoscaling_config" {
  description = "Autoscaling configuration"
  value = var.enable_autoscaling ? {
    min_replicas                         = var.min_replicas
    max_replicas                         = var.max_replicas
    target_cpu_utilization_percentage    = var.target_cpu_utilization
    target_memory_utilization_percentage = var.target_memory_utilization
  } : null
}

output "elasticsearch_config" {
  description = "Elasticsearch configuration (non-sensitive)"
  value = {
    enabled  = var.elasticsearch_enabled
    host     = var.elasticsearch_host
    port     = var.elasticsearch_port
    protocol = var.elasticsearch_protocol
  }
}

output "security_enabled" {
  description = "Whether security features are enabled"
  value = {
    security_context  = var.enable_security_context
    network_policy    = var.enable_network_policy
  }
}

output "helm_release_info" {
  description = "Helm release information"
  value = {
    name      = module.pay_log_aggregator.release_name
    namespace = module.pay_log_aggregator.namespace_name
    version   = module.pay_log_aggregator.release_version
    status    = module.pay_log_aggregator.release_status
  }
}