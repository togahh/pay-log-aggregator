output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.this.namespace
}

output "release_version" {
  description = "Version of the Helm release"
  value       = helm_release.this.version
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "chart_version" {
  description = "Version of the Helm chart"
  value       = helm_release.this.chart
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = "${var.chart_name}"
}

output "service_port" {
  description = "Port of the Kubernetes service"
  value       = var.service.port
}

output "service_url" {
  description = "Internal service URL"
  value       = "http://${var.chart_name}.${var.namespace}.svc.cluster.local:${var.service.port}"
}

output "namespace_name" {
  description = "Name of the Kubernetes namespace"
  value       = var.namespace
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "values" {
  description = "Values passed to the Helm chart"
  value       = local.chart_values
  sensitive   = true
}