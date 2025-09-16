variable "chart_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "pay-log-aggregator"
}

variable "chart_version" {
  description = "Version of the Helm chart"
  type        = string
  default     = "0.1.0"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the chart"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_path" {
  description = "Path to the Helm chart directory"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "pay-log-aggregator"
}

variable "image_tag" {
  description = "Docker image tag"
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

variable "replica_count" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "resources" {
  description = "Resource requests and limits"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "100m")
      memory = optional(string, "128Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "500m")
      memory = optional(string, "512Mi")
    }), {})
  })
  default = {}
}

variable "autoscaling" {
  description = "Horizontal Pod Autoscaler configuration"
  type = object({
    enabled                        = optional(bool, false)
    min_replicas                   = optional(number, 1)
    max_replicas                   = optional(number, 10)
    target_cpu_utilization_percentage = optional(number, 80)
    target_memory_utilization_percentage = optional(number, 80)
  })
  default = {}
}

variable "service" {
  description = "Service configuration"
  type = object({
    type = optional(string, "ClusterIP")
    port = optional(number, 8000)
    annotations = optional(map(string), {})
  })
  default = {}
}

variable "ingress" {
  description = "Ingress configuration"
  type = object({
    enabled     = optional(bool, false)
    class_name  = optional(string, "nginx")
    annotations = optional(map(string), {})
    hosts = optional(list(object({
      host = string
      paths = optional(list(object({
        path     = optional(string, "/")
        path_type = optional(string, "Prefix")
      })), [])
    })), [])
    tls = optional(list(object({
      secret_name = string
      hosts       = list(string)
    })), [])
  })
  default = {}
}

variable "elasticsearch" {
  description = "Elasticsearch configuration"
  type = object({
    enabled  = optional(bool, true)
    host     = optional(string, "elasticsearch")
    port     = optional(number, 9200)
    protocol = optional(string, "http")
    username = optional(string)
    password = optional(string)
  })
  default = {}
}

variable "monitoring" {
  description = "Monitoring configuration"
  type = object({
    enabled    = optional(bool, true)
    prometheus = optional(object({
      enabled = optional(bool, true)
      path    = optional(string, "/metrics")
      port    = optional(string, "http")
    }), {})
  })
  default = {}
}

variable "security" {
  description = "Security configuration"
  type = object({
    security_context = optional(object({
      run_as_non_root = optional(bool, true)
      run_as_user     = optional(number, 1000)
      run_as_group    = optional(number, 3000)
      fs_group        = optional(number, 2000)
    }), {})
    container_security_context = optional(object({
      allow_privilege_escalation = optional(bool, false)
      drop_capabilities          = optional(list(string), ["ALL"])
      read_only_root_filesystem  = optional(bool, true)
    }), {})
    network_policy = optional(object({
      enabled = optional(bool, false)
    }), {})
  })
  default = {}
}

variable "extra_values" {
  description = "Additional values to pass to the Helm chart"
  type        = map(any)
  default     = {}
}

variable "timeout" {
  description = "Timeout for Helm operations"
  type        = number
  default     = 300
}

variable "wait" {
  description = "Wait for all resources to be ready"
  type        = bool
  default     = true
}

variable "wait_for_jobs" {
  description = "Wait for all jobs to complete"
  type        = bool
  default     = true
}

variable "cleanup_on_fail" {
  description = "Delete new resources created during a failed release"
  type        = bool
  default     = true
}

variable "atomic" {
  description = "Perform an atomic installation"
  type        = bool
  default     = true
}

variable "recreate_pods" {
  description = "Force recreation of pods"
  type        = bool
  default     = false
}

variable "max_history" {
  description = "Maximum number of release revisions to keep"
  type        = number
  default     = 10
}