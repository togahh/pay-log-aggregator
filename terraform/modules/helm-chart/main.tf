# Create namespace if needed
resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.chart_name
      "app.kubernetes.io/instance"   = var.chart_name
      "app.kubernetes.io/component"  = "namespace"
      "app.kubernetes.io/part-of"    = var.chart_name
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }
}

# Generate values for the Helm chart
locals {
  # Base values that apply to all environments
  base_values = {
    image = {
      repository = var.image_repository
      tag        = var.image_tag
      pullPolicy = var.image_pull_policy
    }

    replicaCount = var.replica_count

    resources = var.resources

    autoscaling = var.autoscaling

    service = var.service

    ingress = var.ingress

    elasticsearch = var.elasticsearch

    monitoring = var.monitoring

    security = var.security

    # Environment-specific labels
    labels = {
      environment = var.environment
    }

    # Environment-specific annotations
    annotations = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform.io/environment"     = var.environment
    }
  }

  # Merge base values with extra values
  chart_values = merge(local.base_values, var.extra_values)
}

# Deploy the Helm chart
resource "helm_release" "this" {
  name       = var.chart_name
  chart      = var.chart_path
  namespace  = var.namespace
  version    = var.chart_version

  # Helm release configuration
  timeout         = var.timeout
  wait            = var.wait
  wait_for_jobs   = var.wait_for_jobs
  cleanup_on_fail = var.cleanup_on_fail
  atomic          = var.atomic
  recreate_pods   = var.recreate_pods
  max_history     = var.max_history

  # Pass values to the chart
  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    kubernetes_namespace.this
  ]
}

# Health check for the deployment
resource "kubernetes_manifest" "health_check" {
  count = var.wait ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "Pod"
    metadata = {
      name      = "${var.chart_name}-health-check-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"       = "${var.chart_name}-health-check"
        "app.kubernetes.io/instance"   = var.chart_name
        "app.kubernetes.io/component"  = "health-check"
        "app.kubernetes.io/part-of"    = var.chart_name
        "app.kubernetes.io/managed-by" = "terraform"
        "environment"                  = var.environment
      }
    }
    spec = {
      restartPolicy = "Never"
      containers = [{
        name  = "health-check"
        image = "curlimages/curl:latest"
        command = [
          "sh", "-c",
          "curl -f http://${var.chart_name}.${var.namespace}.svc.cluster.local:${var.service.port}/health || exit 1"
        ]
      }]
    }
  }

  depends_on = [
    helm_release.this
  ]

  lifecycle {
    ignore_changes = [
      manifest.metadata.name
    ]
  }
}