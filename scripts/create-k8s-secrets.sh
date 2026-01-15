#!/usr/bin/env bash
# =============================================================================
# AutoGit Kubernetes Secrets Setup Script
# =============================================================================
# This script creates Kubernetes secrets required for AutoGit deployment.
# It reads values from .env.k8s and creates secrets in the cluster.
#
# Prerequisites:
#   - kubectl configured with cluster access
#   - .env.k8s file with required values
#
# Usage:
#   ./scripts/create-k8s-secrets.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env.k8s"

# Function to print colored messages
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

# Check if .env.k8s exists
if [[ ! -f "${ENV_FILE}" ]]; then
    log_error ".env.k8s file not found!"
    log_info "Please copy .env.k8s.example to .env.k8s and fill in your values:"
    log_info "  cp .env.k8s.example .env.k8s"
    log_info "  nano .env.k8s  # Edit with your values"
    exit 1
fi

# Source the environment file
log_info "Loading configuration from ${ENV_FILE}..."
set -a
# shellcheck source=/dev/null
source "${ENV_FILE}"
set +a

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found! Please install kubectl first."
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster!"
    log_info "Please configure kubectl with cluster access."
    exit 1
fi

log_success "Connected to Kubernetes cluster"

# Function to create namespace if it doesn't exist
create_namespace_if_missing() {
    local namespace=$1
    if ! kubectl get namespace "${namespace}" &> /dev/null; then
        log_info "Creating namespace: ${namespace}"
        kubectl create namespace "${namespace}"
    else
        log_info "Namespace ${namespace} already exists"
    fi
}

# Function to create or update a secret
create_or_update_secret() {
    local name=$1
    local namespace=$2
    shift 2
    local args=("$@")
    
    if kubectl get secret "${name}" -n "${namespace}" &> /dev/null; then
        log_info "Updating secret: ${name} in namespace ${namespace}"
        kubectl delete secret "${name}" -n "${namespace}"
    else
        log_info "Creating secret: ${name} in namespace ${namespace}"
    fi
    
    kubectl create secret generic "${name}" \
        --namespace="${namespace}" \
        "${args[@]}"
}

# =============================================================================
# Create Namespaces
# =============================================================================
log_info "Creating namespaces..."
create_namespace_if_missing "autogit-system"
create_namespace_if_missing "autogit-gitlab"
create_namespace_if_missing "autogit-runners"
create_namespace_if_missing "autogit-observability"
create_namespace_if_missing "cert-manager"
create_namespace_if_missing "traefik"

# =============================================================================
# Create GitLab Secrets
# =============================================================================
log_info "Creating GitLab secrets..."

# Validate required GitLab variables
if [[ -z "${GITLAB_TOKEN:-}" ]]; then
    log_warning "GITLAB_TOKEN not set in .env.k8s"
    log_warning "You'll need to update this secret after GitLab is running"
    GITLAB_TOKEN="REPLACE_WITH_ACTUAL_TOKEN"
fi

if [[ -z "${GITLAB_RUNNER_REGISTRATION_TOKEN:-}" ]]; then
    log_warning "GITLAB_RUNNER_REGISTRATION_TOKEN not set in .env.k8s"
    log_warning "You'll need to update this secret after GitLab is running"
    GITLAB_RUNNER_REGISTRATION_TOKEN="REPLACE_WITH_ACTUAL_TOKEN"
fi

# Create GitLab tokens secret
create_or_update_secret "autogit-gitlab-tokens" "autogit-system" \
    --from-literal=GITLAB_TOKEN="${GITLAB_TOKEN}" \
    --from-literal=GITLAB_RUNNER_REGISTRATION_TOKEN="${GITLAB_RUNNER_REGISTRATION_TOKEN}"

log_success "GitLab tokens secret created"

# Create GitLab root password secret if provided
if [[ -n "${GITLAB_ROOT_PASSWORD:-}" ]] && [[ "${GITLAB_ROOT_PASSWORD}" != "changeme-generate-secure-password" ]]; then
    create_or_update_secret "gitlab-gitlab-initial-root-password" "autogit-gitlab" \
        --from-literal=password="${GITLAB_ROOT_PASSWORD}"
    log_success "GitLab root password secret created"
else
    log_warning "GITLAB_ROOT_PASSWORD not set or is default value - skipping"
    log_info "GitLab will generate a random root password on first start"
fi

# =============================================================================
# Create Grafana Secrets
# =============================================================================
log_info "Creating Grafana secrets..."

if [[ -n "${GRAFANA_ADMIN_PASSWORD:-}" ]] && [[ "${GRAFANA_ADMIN_PASSWORD}" != "changeme-generate-secure-password" ]]; then
    create_or_update_secret "grafana-admin" "autogit-observability" \
        --from-literal=admin-password="${GRAFANA_ADMIN_PASSWORD}"
    log_success "Grafana admin password secret created"
else
    log_warning "GRAFANA_ADMIN_PASSWORD not set or is default value - skipping"
    log_info "Grafana will generate a random admin password on first start"
fi

# =============================================================================
# Create SMTP Secrets (if enabled)
# =============================================================================
if [[ "${SMTP_ENABLED:-false}" == "true" ]]; then
    log_info "Creating SMTP secrets..."
    
    if [[ -n "${SMTP_PASSWORD:-}" ]]; then
        create_or_update_secret "gitlab-smtp" "autogit-gitlab" \
            --from-literal=password="${SMTP_PASSWORD}"
        log_success "SMTP password secret created"
    else
        log_warning "SMTP_ENABLED is true but SMTP_PASSWORD not set"
    fi
fi

# =============================================================================
# Create External Database Secrets (if configured)
# =============================================================================
if [[ -n "${EXTERNAL_POSTGRES_PASSWORD:-}" ]]; then
    log_info "Creating external PostgreSQL secret..."
    create_or_update_secret "gitlab-postgres-external" "autogit-gitlab" \
        --from-literal=password="${EXTERNAL_POSTGRES_PASSWORD}"
    log_success "External PostgreSQL secret created"
fi

if [[ -n "${EXTERNAL_REDIS_PASSWORD:-}" ]]; then
    log_info "Creating external Redis secret..."
    create_or_update_secret "gitlab-redis-external" "autogit-gitlab" \
        --from-literal=password="${EXTERNAL_REDIS_PASSWORD}"
    log_success "External Redis secret created"
fi

# =============================================================================
# Create S3 Backup Secrets (if configured)
# =============================================================================
if [[ "${ENABLE_BACKUPS:-false}" == "true" ]] && [[ -n "${BACKUP_S3_ACCESS_KEY:-}" ]]; then
    log_info "Creating S3 backup credentials..."
    create_or_update_secret "backup-s3-credentials" "autogit-system" \
        --from-literal=access-key="${BACKUP_S3_ACCESS_KEY}" \
        --from-literal=secret-key="${BACKUP_S3_SECRET_KEY}"
    log_success "S3 backup credentials created"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
log_success "===================================================================="
log_success "Secrets created successfully!"
log_success "===================================================================="
echo ""
log_info "Next steps:"
echo ""
echo "  1. Deploy AutoGit using ArgoCD:"
echo "     kubectl apply -f argocd/apps/root.yaml"
echo ""
echo "  2. Or deploy using Helmfile:"
echo "     helmfile -e homelab sync"
echo ""
echo "  3. Monitor deployment:"
echo "     kubectl get pods -A | grep autogit"
echo ""
echo "  4. After GitLab starts, get the initial root password:"
echo "     kubectl get secret -n autogit-gitlab gitlab-gitlab-initial-root-password \\"
echo "       -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "  5. Create API token and runner registration token in GitLab"
echo ""
echo "  6. Update secrets with actual tokens:"
echo "     kubectl patch secret autogit-gitlab-tokens -n autogit-system \\"
echo "       --type='json' \\"
echo "       -p='[{\"op\": \"replace\", \"path\": \"/data/GITLAB_TOKEN\", \"value\":\"'\$(echo -n \"YOUR_TOKEN\" | base64)'\"}]'"
echo ""
log_info "For detailed documentation, see:"
echo "  - docs/installation/kubernetes.md"
echo "  - docs/installation/argocd.md"
echo ""
