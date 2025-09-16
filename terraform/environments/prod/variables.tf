variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "pay-log-aggregator-prod"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  # In production, we should never use 'latest'
  validation {
    condition     = var.image_tag != "latest"
    error_message = "Production deployments must use a specific version tag, not 'latest'."
  }
}

variable "elasticsearch_host" {
  description = "Elasticsearch host"
  type        = string
  default     = "elasticsearch-prod"
}

variable "elasticsearch_port" {
  description = "Elasticsearch port"
  type        = number
  default     = 9200
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

variable "enable_ingress" {
  description = "Enable ingress for external access"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Ingress host for the application"
  type        = string
  default     = "pay-log-aggregator.example.com"
}

variable "enable_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 3
}

variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 10
}

variable "cpu_request" {
  description = "CPU request for containers"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request for containers"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "1Gi"
}