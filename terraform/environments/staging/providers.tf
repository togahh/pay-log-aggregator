terraform {
  required_version = ">= 1.0"
  
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Backend configuration for state management
  # Uncomment and configure based on your backend setup
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "pay-log-aggregator/staging/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

# Configure Helm provider to use existing kubectl context
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Configure Kubernetes provider to use existing kubectl context
provider "kubernetes" {
  config_path = "~/.kube/config"
}