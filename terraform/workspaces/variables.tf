# Environment and workspace configuration
variable "environment" {
  description = "Environment name (automatically set based on workspace)"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
}

variable "chart_version" {
  description = "Version of the Helm chart to deploy"
  type        = string
  default     = "0.1.0"
}

# Image configuration
variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "pay-log-aggregator"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
  
  validation {
    condition     = contains(["Always", "IfNotPresent", "Never"], var.image_pull_policy)
    error_message = "Image pull policy must be one of: Always, IfNotPresent, Never."
  }
}

# Scaling configuration
variable "replica_count" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = false
}

variable "min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 5
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization percentage for autoscaling"
  type        = number
  default     = 80
}

variable "target_memory_utilization" {
  description = "Target memory utilization percentage for autoscaling"
  type        = number
  default     = 80
}

# Resource configuration
variable "cpu_request" {
  description = "CPU request for containers"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for containers"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "512Mi"
}

# Service configuration
variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
  
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be one of: ClusterIP, NodePort, LoadBalancer."
  }
}

variable "service_port" {
  description = "Service port"
  type        = number
  default     = 8000
}

variable "service_annotations" {
  description = "Service annotations"
  type        = map(string)
  default     = {}
}

# Ingress configuration
variable "enable_ingress" {
  description = "Enable ingress for external access"
  type        = bool
  default     = false
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Ingress host for the application"
  type        = string
  default     = ""
}

variable "ingress_annotations" {
  description = "Ingress annotations"
  type        = map(string)
  default     = {}
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

variable "tls_secret_name" {
  description = "TLS secret name for ingress"
  type        = string
  default     = ""
}

# Elasticsearch configuration
variable "elasticsearch_enabled" {
  description = "Enable Elasticsearch integration"
  type        = bool
  default     = true
}

variable "elasticsearch_host" {
  description = "Elasticsearch host"
  type        = string
  default     = "elasticsearch"
}

variable "elasticsearch_port" {
  description = "Elasticsearch port"
  type        = number
  default     = 9200
}

variable "elasticsearch_protocol" {
  description = "Elasticsearch protocol"
  type        = string
  default     = "http"
}

variable "elasticsearch_username" {
  description = "Elasticsearch username"
  type        = string
  default     = ""
}

variable "elasticsearch_password" {
  description = "Elasticsearch password"
  type        = string
  default     = ""
  sensitive   = true
}

# Monitoring configuration
variable "enable_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "prometheus_path" {
  description = "Prometheus metrics path"
  type        = string
  default     = "/metrics"
}

variable "prometheus_port" {
  description = "Prometheus metrics port name"
  type        = string
  default     = "http"
}

# Security configuration
variable "enable_security_context" {
  description = "Enable security context"
  type        = bool
  default     = true
}

variable "run_as_user" {
  description = "User ID to run containers as"
  type        = number
  default     = 1000
}

variable "run_as_group" {
  description = "Group ID to run containers as"
  type        = number
  default     = 3000
}

variable "fs_group" {
  description = "File system group ID"
  type        = number
  default     = 2000
}

variable "enable_network_policy" {
  description = "Enable network policies"
  type        = bool
  default     = false
}

# Application configuration
variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR."
  }
}

variable "debug_mode" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

variable "extra_env_vars" {
  description = "Additional environment variables"
  type        = map(string)
  default     = {}
}

variable "extra_labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "extra_annotations" {
  description = "Additional annotations to apply to resources"
  type        = map(string)
  default     = {}
}

# Helm configuration
variable "helm_timeout" {
  description = "Timeout for Helm operations (seconds)"
  type        = number
  default     = 300
}

variable "helm_wait" {
  description = "Wait for all resources to be ready"
  type        = bool
  default     = true
}

variable "helm_atomic" {
  description = "Perform an atomic installation"
  type        = bool
  default     = true
}

variable "helm_cleanup_on_fail" {
  description = "Delete new resources created during a failed release"
  type        = bool
  default     = true
}

variable "helm_max_history" {
  description = "Maximum number of release revisions to keep"
  type        = number
  default     = 10
}