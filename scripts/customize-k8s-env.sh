#!/usr/bin/env bash
# =============================================================================
# AutoGit Environment Configuration Helper
# =============================================================================
# This script helps customize Kubernetes environment files by substituting
# placeholder values with actual configuration from .env.k8s
#
# Prerequisites:
#   - .env.k8s file with required values
#
# Usage:
#   ./scripts/customize-k8s-env.sh [environment]
#
# Arguments:
#   environment - Target environment (homelab, staging, production)
#                 Default: homelab
#
# Examples:
#   ./scripts/customize-k8s-env.sh homelab
#   ./scripts/customize-k8s-env.sh production
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

# Get environment argument (default to homelab)
ENVIRONMENT="${1:-homelab}"
ENV_DIR="${PROJECT_ROOT}/environments/${ENVIRONMENT}"
ENV_BASE_FILE="${PROJECT_ROOT}/environments/${ENVIRONMENT}.yaml"

# Check if environment exists
if [[ ! -d "${ENV_DIR}" ]] && [[ ! -f "${ENV_BASE_FILE}" ]]; then
    log_error "Environment '${ENVIRONMENT}' not found!"
    log_info "Available environments:"
    find "${PROJECT_ROOT}/environments" -maxdepth 1 -type d -exec basename {} \; | grep -v "^environments$" | sed 's/^/  - /'
    exit 1
fi

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

# Validate required variables
REQUIRED_VARS=("DOMAIN" "LETSENCRYPT_EMAIL")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        MISSING_VARS+=("${var}")
    fi
done

if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
    log_error "Missing required variables in .env.k8s:"
    for var in "${MISSING_VARS[@]}"; do
        log_error "  - ${var}"
    done
    exit 1
fi

# Construct full URLs if not set
GITLAB_HOSTNAME="${GITLAB_HOSTNAME:-gitlab}"
GRAFANA_HOSTNAME="${GRAFANA_HOSTNAME:-grafana}"
TRAEFIK_HOSTNAME="${TRAEFIK_HOSTNAME:-traefik}"
RUNNER_API_HOSTNAME="${RUNNER_API_HOSTNAME:-runner}"
REGISTRY_HOSTNAME="${REGISTRY_HOSTNAME:-registry}"

GITLAB_FQDN="${GITLAB_HOSTNAME}.${DOMAIN}"
GRAFANA_FQDN="${GRAFANA_HOSTNAME}.${DOMAIN}"
TRAEFIK_FQDN="${TRAEFIK_HOSTNAME}.${DOMAIN}"
RUNNER_API_FQDN="${RUNNER_API_HOSTNAME}.${DOMAIN}"
REGISTRY_FQDN="${REGISTRY_HOSTNAME}.${DOMAIN}"

GITLAB_URL="${GITLAB_URL:-https://${GITLAB_FQDN}}"

log_success "Configuration loaded successfully"
log_info "Domain: ${DOMAIN}"
log_info "GitLab URL: ${GITLAB_URL}"
log_info "Grafana URL: https://${GRAFANA_FQDN}"

# =============================================================================
# Display Configuration Summary
# =============================================================================
echo ""
log_info "===================================================================="
log_info "Configuration Summary for '${ENVIRONMENT}' environment"
log_info "===================================================================="
echo ""
echo "Domain Configuration:"
echo "  Base Domain:      ${DOMAIN}"
echo "  GitLab:          ${GITLAB_FQDN}"
echo "  Grafana:         ${GRAFANA_FQDN}"
echo "  Traefik:         ${TRAEFIK_FQDN}"
echo "  Runner API:      ${RUNNER_API_FQDN}"
echo "  Registry:        ${REGISTRY_FQDN}"
echo ""
echo "TLS Configuration:"
echo "  Email:           ${LETSENCRYPT_EMAIL}"
echo "  Cluster Issuer:  ${CLUSTER_ISSUER:-letsencrypt-staging}"
echo ""
echo "Resource Profile:  ${RESOURCE_PROFILE:-standard}"
echo "Storage Class:     ${STORAGE_CLASS:-(default)}"
echo ""
echo "Feature Flags:"
echo "  Monitoring:      ${ENABLE_MONITORING:-true}"
echo "  Logging:         ${ENABLE_LOGGING:-true}"
echo "  Tracing:         ${ENABLE_TRACING:-false}"
echo "  GitLab Registry: ${ENABLE_GITLAB_REGISTRY:-false}"
echo ""

# =============================================================================
# Customization Instructions
# =============================================================================
log_info "===================================================================="
log_info "Manual Customization Required"
log_info "===================================================================="
echo ""
log_warning "This script displays your configuration but does NOT modify files."
log_warning "You need to manually update the following files with your values:"
echo ""

if [[ -f "${ENV_BASE_FILE}" ]]; then
    echo "Base environment file:"
    echo "  - ${ENV_BASE_FILE}"
fi

if [[ -d "${ENV_DIR}" ]]; then
    echo ""
    echo "Environment-specific files:"
    find "${ENV_DIR}" -type f -name "*.yaml" | sed 's/^/  - /'
fi

echo ""
log_info "Search and replace the following values:"
echo ""
echo "  example.com              → ${DOMAIN}"
echo "  gitlab.example.com       → ${GITLAB_FQDN}"
echo "  grafana.example.com      → ${GRAFANA_FQDN}"
echo "  traefik.example.com      → ${TRAEFIK_FQDN}"
echo "  runner.example.com       → ${RUNNER_API_FQDN}"
echo "  registry.example.com     → ${REGISTRY_FQDN}"
echo "  admin@example.com        → ${LETSENCRYPT_EMAIL}"
echo "  letsencrypt-staging      → ${CLUSTER_ISSUER:-letsencrypt-staging}"
echo ""

# =============================================================================
# Automated Replacement Offer
# =============================================================================
echo ""
read -p "Would you like to automatically update these files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Creating backup of original files..."
    BACKUP_DIR="${PROJECT_ROOT}/environments/.backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${BACKUP_DIR}"
    
    # Backup base file
    if [[ -f "${ENV_BASE_FILE}" ]]; then
        cp "${ENV_BASE_FILE}" "${BACKUP_DIR}/"
    fi
    
    # Backup environment files
    if [[ -d "${ENV_DIR}" ]]; then
        cp -r "${ENV_DIR}" "${BACKUP_DIR}/"
    fi
    
    log_success "Backup created at: ${BACKUP_DIR}"
    
    log_info "Updating files..."
    
    # Function to update a file
    update_file() {
        local file=$1
        log_info "  Updating $(basename "${file}")..."
        
        sed -i "s/example\.com/${DOMAIN}/g" "${file}"
        sed -i "s/gitlab\.example\.com/${GITLAB_FQDN}/g" "${file}"
        sed -i "s/grafana\.example\.com/${GRAFANA_FQDN}/g" "${file}"
        sed -i "s/traefik\.example\.com/${TRAEFIK_FQDN}/g" "${file}"
        sed -i "s/runner\.example\.com/${RUNNER_API_FQDN}/g" "${file}"
        sed -i "s/registry\.example\.com/${REGISTRY_FQDN}/g" "${file}"
        sed -i "s/admin@example\.com/${LETSENCRYPT_EMAIL}/g" "${file}"
        
        # Update cluster issuer if not default
        if [[ -n "${CLUSTER_ISSUER:-}" ]] && [[ "${CLUSTER_ISSUER}" != "letsencrypt-staging" ]]; then
            sed -i "s/letsencrypt-staging/${CLUSTER_ISSUER}/g" "${file}"
        fi
    }
    
    # Update base file
    if [[ -f "${ENV_BASE_FILE}" ]]; then
        update_file "${ENV_BASE_FILE}"
    fi
    
    # Update environment files
    if [[ -d "${ENV_DIR}" ]]; then
        find "${ENV_DIR}" -type f -name "*.yaml" -exec bash -c 'update_file "$0"' {} \;
    fi
    
    log_success "Files updated successfully!"
    log_info "Original files backed up to: ${BACKUP_DIR}"
    echo ""
    log_info "Next steps:"
    echo "  1. Review the updated files"
    echo "  2. Create secrets: ./scripts/create-k8s-secrets.sh"
    echo "  3. Deploy: kubectl apply -f argocd/apps/root.yaml"
else
    log_info "Skipping automatic update"
    log_info "You can manually update the files using the values shown above"
fi

echo ""
