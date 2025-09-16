variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "pay-log-aggregator-staging"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "stable"
}

variable "elasticsearch_host" {
  description = "Elasticsearch host"
  type        = string
  default     = "elasticsearch-staging"
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
  default     = "pay-log-aggregator-staging.example.com"
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
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 6
}

variable "cpu_request" {
  description = "CPU request for containers"
  type        = string
  default     = "200m"
}

variable "memory_request" {
  description = "Memory request for containers"
  type        = string
  default     = "256Mi"
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