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

locals {
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

    labels = {
      environment = var.environment
    }

    annotations = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform.io/environment"     = var.environment
    }
  }

  chart_values = merge(local.base_values, var.extra_values)
}

resource "helm_release" "this" {
  name       = var.chart_name
  chart      = var.chart_path
  namespace  = var.namespace
  version    = var.chart_version

  timeout         = var.timeout
  wait            = var.wait
  wait_for_jobs   = var.wait_for_jobs
  cleanup_on_fail = var.cleanup_on_fail
  atomic          = var.atomic
  recreate_pods   = var.recreate_pods
  max_history     = var.max_history

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    kubernetes_namespace.this
  ]
}

