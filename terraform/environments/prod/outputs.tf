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

output "ingress_host" {
  description = "Ingress hostname (if enabled)"
  value       = var.enable_ingress ? var.ingress_host : null
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "autoscaling_enabled" {
  description = "Whether autoscaling is enabled"
  value       = var.enable_autoscaling
}

output "environment" {
  description = "Environment name"
  value       = module.pay_log_aggregator.environment
}

output "elasticsearch_config" {
  description = "Elasticsearch configuration"
  value = {
    host = var.elasticsearch_host
    port = var.elasticsearch_port
  }
  sensitive = false
}

output "deployment_info" {
  description = "Production deployment information"
  value = {
    image_tag    = var.image_tag
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
    namespace    = var.namespace
  }
}