#!/bin/bash

# Deploy Pay Log Aggregator to Kubernetes using Terraform
# Usage: ./deploy.sh <environment> [image_tag] [options]

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 <environment> [image_tag] [options]

Arguments:
  environment     Target environment (dev, staging, prod)
  image_tag      Docker image tag to deploy (optional, defaults per environment)

Options:
  -p, --plan-only          Only run terraform plan, don't apply
  -d, --destroy           Destroy the deployment
  -f, --force             Auto-approve terraform apply
  -v, --verbose           Enable verbose output
  -h, --help              Show this help message
  --var-file=FILE         Use specific terraform vars file
  --backend-config=FILE   Use specific backend configuration

Examples:
  $0 dev                           # Deploy latest to dev
  $0 staging v1.2.3               # Deploy v1.2.3 to staging
  $0 prod v1.2.3 --plan-only     # Plan prod deployment
  $0 dev --destroy                # Destroy dev deployment

EOF
}

# Validate environment
validate_environment() {
    local env=$1
    if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: $env"
        log_error "Valid environments: dev, staging, prod"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if kubectl context is configured
    if ! kubectl config current-context &> /dev/null; then
        log_error "kubectl is not configured or no context is set"
        exit 1
    fi
    
    # Check if helm is installed (optional but recommended)
    if ! command -v helm &> /dev/null; then
        log_warning "Helm is not installed. Consider installing it for debugging."
    fi
    
    log_success "Prerequisites check passed"
}

# Initialize terraform
terraform_init() {
    local env_dir=$1
    log_info "Initializing Terraform in $env_dir..."
    
    cd "$env_dir"
    
    if [[ -n "$BACKEND_CONFIG" ]]; then
        terraform init -backend-config="$BACKEND_CONFIG"
    else
        terraform init
    fi
    
    log_success "Terraform initialized"
}

# Validate terraform configuration
terraform_validate() {
    log_info "Validating Terraform configuration..."
    terraform validate
    terraform fmt -check=true
    log_success "Terraform configuration is valid"
}

# Run terraform plan
terraform_plan() {
    local env=$1
    local image_tag=$2
    
    log_info "Running Terraform plan for $env environment..."
    
    local plan_args=()
    
    if [[ -n "$image_tag" ]]; then
        plan_args+=("-var=image_tag=$image_tag")
    fi
    
    if [[ -n "$VAR_FILE" ]]; then
        plan_args+=("-var-file=$VAR_FILE")
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        plan_args+=("-detailed-exitcode")
    fi
    
    terraform plan "${plan_args[@]}" -out=tfplan
    
    log_success "Terraform plan completed"
}

# Apply terraform changes
terraform_apply() {
    log_info "Applying Terraform changes..."
    
    local apply_args=("tfplan")
    
    if [[ "$FORCE" == "true" ]]; then
        apply_args=("-auto-approve")
        
        # Re-add variables if not using plan file
        if [[ -n "$IMAGE_TAG" ]]; then
            apply_args+=("-var=image_tag=$IMAGE_TAG")
        fi
        
        if [[ -n "$VAR_FILE" ]]; then
            apply_args+=("-var-file=$VAR_FILE")
        fi
    fi
    
    terraform apply "${apply_args[@]}"
    
    log_success "Terraform apply completed"
}

# Destroy terraform resources
terraform_destroy() {
    local env=$1
    local image_tag=$2
    
    log_warning "This will destroy all resources in $env environment!"
    
    if [[ "$FORCE" != "true" ]]; then
        read -p "Are you sure you want to continue? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Destroy cancelled"
            exit 0
        fi
    fi
    
    local destroy_args=()
    
    if [[ -n "$image_tag" ]]; then
        destroy_args+=("-var=image_tag=$image_tag")
    fi
    
    if [[ -n "$VAR_FILE" ]]; then
        destroy_args+=("-var-file=$VAR_FILE")
    fi
    
    if [[ "$FORCE" == "true" ]]; then
        destroy_args+=("-auto-approve")
    fi
    
    terraform destroy "${destroy_args[@]}"
    
    log_success "Resources destroyed"
}

# Show deployment information
show_deployment_info() {
    local env=$1
    
    log_info "Deployment information for $env:"
    echo
    
    # Get terraform outputs
    if terraform output &> /dev/null; then
        echo "Terraform Outputs:"
        terraform output
        echo
    fi
    
    # Get Kubernetes resources
    local namespace
    namespace=$(terraform output -raw namespace 2>/dev/null || echo "pay-log-aggregator-$env")
    
    echo "Kubernetes Resources:"
    kubectl get all -n "$namespace" 2>/dev/null || log_warning "Namespace $namespace not found"
    echo
    
    # Check pod status
    echo "Pod Status:"
    kubectl get pods -n "$namespace" -o wide 2>/dev/null || log_warning "No pods found in namespace $namespace"
}

# Main execution
main() {
    # Parse command line arguments
    ENVIRONMENT=""
    IMAGE_TAG=""
    PLAN_ONLY=false
    DESTROY=false
    FORCE=false
    VERBOSE=false
    VAR_FILE=""
    BACKEND_CONFIG=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--plan-only)
                PLAN_ONLY=true
                shift
                ;;
            -d|--destroy)
                DESTROY=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --var-file=*)
                VAR_FILE="${1#*=}"
                shift
                ;;
            --backend-config=*)
                BACKEND_CONFIG="${1#*=}"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$ENVIRONMENT" ]]; then
                    ENVIRONMENT=$1
                elif [[ -z "$IMAGE_TAG" ]]; then
                    IMAGE_TAG=$1
                else
                    log_error "Unknown argument: $1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$ENVIRONMENT" ]]; then
        log_error "Environment is required"
        show_usage
        exit 1
    fi
    
    validate_environment "$ENVIRONMENT"
    
    # Set default image tags per environment if not provided
    if [[ -z "$IMAGE_TAG" ]]; then
        case $ENVIRONMENT in
            dev)
                IMAGE_TAG="latest"
                ;;
            staging)
                IMAGE_TAG="stable"
                ;;
            prod)
                log_error "Production deployments require an explicit image tag (not 'latest')"
                exit 1
                ;;
        esac
    fi
    
    # Production safety check
    if [[ "$ENVIRONMENT" == "prod" && "$IMAGE_TAG" == "latest" ]]; then
        log_error "Cannot deploy 'latest' tag to production environment"
        exit 1
    fi
    
    log_info "Starting deployment to $ENVIRONMENT environment"
    log_info "Image tag: $IMAGE_TAG"
    
    if [[ "$VERBOSE" == "true" ]]; then
        export TF_LOG=DEBUG
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Change to environment directory
    local env_dir="$TERRAFORM_DIR/environments/$ENVIRONMENT"
    if [[ ! -d "$env_dir" ]]; then
        log_error "Environment directory not found: $env_dir"
        exit 1
    fi
    
    # Execute terraform operations
    terraform_init "$env_dir"
    terraform_validate
    
    if [[ "$DESTROY" == "true" ]]; then
        terraform_destroy "$ENVIRONMENT" "$IMAGE_TAG"
    else
        terraform_plan "$ENVIRONMENT" "$IMAGE_TAG"
        
        if [[ "$PLAN_ONLY" == "false" ]]; then
            terraform_apply
            show_deployment_info "$ENVIRONMENT"
        fi
    fi
    
    log_success "Operation completed successfully!"
}

# Execute main function
main "$@"