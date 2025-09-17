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
  # Configure based on your backend setup
  backend "local" {
    # For local development - replace with remote backend for production
    path = "terraform-${terraform.workspace}.tfstate"
  }
  
  # Example S3 backend configuration:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "pay-log-aggregator/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  #   workspace_key_prefix = "workspaces"
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