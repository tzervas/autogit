#!/usr/bin/env bash
#
# deploy-homelab.sh - Idempotent deployment script for AutoGit homelab
#
# This script can be run repeatedly to sync/align the deployment.
# It handles:
#   - File synchronization
#   - Image rebuilding (only if sources changed)
#   - Container recreation (only if needed)
#   - Network compatibility (existing or new)
#
# Usage: ./scripts/deploy-homelab.sh [OPTIONS]
#   --full      Force full rebuild of all images
#   --sync-only Only sync files, don't rebuild/restart
#   --dry-run   Show what would be done without doing it

set -euo pipefail

# Configuration
HOMELAB_HOST="${HOMELAB_HOST:-homelab}"
HOMELAB_PATH="${HOMELAB_PATH:-/home/kang/autogit}"
DOCKER_HOST_SOCK="unix:///run/user/1000/docker.sock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
FULL_REBUILD=false
SYNC_ONLY=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --full)
        FULL_REBUILD=true
        shift
        ;;
    --sync-only)
        SYNC_ONLY=true
        shift
        ;;
    --dry-run)
        DRY_RUN=true
        shift
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

run_cmd() {
    if [[ $DRY_RUN == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

ssh_cmd() {
    # shellcheck disable=SC2029 # Intentional client-side expansion
    ssh "$HOMELAB_HOST" "DOCKER_HOST=$DOCKER_HOST_SOCK $*"
}

# Check connectivity
check_homelab() {
    log_info "Checking homelab connectivity..."
    if ! ssh -q "$HOMELAB_HOST" exit; then
        log_error "Cannot connect to homelab at $HOMELAB_HOST"
        exit 1
    fi
    log_success "Connected to $HOMELAB_HOST"
}

# Sync files to homelab
sync_files() {
    log_info "Syncing files to homelab..."

    # Files to sync
    local files=(
        "docker-compose.yml"
        "pyproject.toml"
        "config/config.yml"
    )

    # Directories to sync
    local dirs=(
        "services/runner-coordinator"
        "services/git-server"
        "scripts"
    )

    # Create target directory if needed
    run_cmd ssh "$HOMELAB_HOST" "mkdir -p $HOMELAB_PATH"

    # Sync individual files
    for file in "${files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local target_dir
            target_dir=$(dirname "$HOMELAB_PATH/$file")
            run_cmd ssh "$HOMELAB_HOST" "mkdir -p $target_dir"
            run_cmd scp "$PROJECT_ROOT/$file" "$HOMELAB_HOST:$HOMELAB_PATH/$file"
            log_success "Synced $file"
        fi
    done

    # Sync directories
    for dir in "${dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            run_cmd ssh "$HOMELAB_HOST" "mkdir -p $HOMELAB_PATH/$dir"
            run_cmd rsync -avz --delete \
                --exclude '__pycache__' \
                --exclude '*.pyc' \
                --exclude '.git' \
                --exclude 'node_modules' \
                "$PROJECT_ROOT/$dir/" "$HOMELAB_HOST:$HOMELAB_PATH/$dir/"
            log_success "Synced $dir/"
        fi
    done
}

# Check if image needs rebuild
check_image_needs_rebuild() {
    local service=$1
    local image_name="autogit-${service}:latest"

    # Get local source hash
    local local_hash
    if [[ -d "$PROJECT_ROOT/services/$service" ]]; then
        local_hash=$(find "$PROJECT_ROOT/services/$service" -type f \( -name "*.py" -o -name "Dockerfile" -o -name "requirements.txt" \) -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1)
    else
        return 0 # Rebuild if we can't hash
    fi

    # Get remote source hash
    local remote_hash
    # shellcheck disable=SC2029 # Intentional client-side expansion for HOMELAB_PATH
    remote_hash=$(ssh "$HOMELAB_HOST" "find $HOMELAB_PATH/services/$service -type f \( -name '*.py' -o -name 'Dockerfile' -o -name 'requirements.txt' \) -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1" 2>/dev/null || echo "")

    if [[ $local_hash != "$remote_hash" ]]; then
        log_info "Source changes detected for $service"
        return 0 # Needs rebuild
    fi

    # Check if image exists
    if ! ssh_cmd "docker image inspect $image_name" &>/dev/null; then
        log_info "Image $image_name does not exist"
        return 0 # Needs rebuild
    fi

    return 1 # No rebuild needed
}

# Build images
build_images() {
    log_info "Checking images..."

    local services=("runner-coordinator")
    local rebuild_needed=false

    for service in "${services[@]}"; do
        if [[ $FULL_REBUILD == "true" ]] || check_image_needs_rebuild "$service"; then
            log_info "Building $service image..."
            run_cmd ssh "$HOMELAB_HOST" "cd $HOMELAB_PATH && DOCKER_HOST=$DOCKER_HOST_SOCK docker build -t autogit-${service}:latest ./services/${service}/"
            log_success "Built autogit-${service}:latest"
            rebuild_needed=true
        else
            log_success "$service image is up to date"
        fi
    done

    echo "$rebuild_needed"
}

# Deploy/update containers
deploy_containers() {
    local force_recreate=$1

    log_info "Deploying containers..."

    cd "$PROJECT_ROOT"

    # Check current state
    local running_containers
    running_containers=$(ssh_cmd "docker ps --filter 'name=autogit' --format '{{.Names}}'" 2>/dev/null || echo "")

    if [[ -n $running_containers ]]; then
        log_info "Running AutoGit containers: $running_containers"
    fi

    # Deploy with docker-compose
    local compose_cmd="cd $HOMELAB_PATH && DOCKER_HOST=$DOCKER_HOST_SOCK docker compose up -d"

    if [[ $force_recreate == "true" ]]; then
        compose_cmd="$compose_cmd --force-recreate"
    fi

    run_cmd ssh "$HOMELAB_HOST" "$compose_cmd"

    log_success "Containers deployed"
}

# Health check
health_check() {
    log_info "Running health checks..."

    # Wait for services to start
    sleep 5

    # Check GitLab
    local gitlab_health
    gitlab_health=$(ssh_cmd "docker inspect --format='{{.State.Health.Status}}' autogit-git-server 2>/dev/null" || echo "unknown")
    if [[ $gitlab_health == "healthy" ]]; then
        log_success "GitLab CE: healthy"
    else
        log_warning "GitLab CE: $gitlab_health (may still be starting)"
    fi

    # Check Coordinator
    local coord_health
    coord_health=$(ssh_cmd "docker inspect --format='{{.State.Health.Status}}' autogit-runner-coordinator 2>/dev/null" || echo "unknown")
    if [[ $coord_health == "healthy" ]]; then
        log_success "Runner Coordinator: healthy"
    else
        log_warning "Runner Coordinator: $coord_health"
    fi

    # Check coordinator API
    if ssh "$HOMELAB_HOST" "curl -sf http://localhost:8080/health" &>/dev/null; then
        log_success "Coordinator API responding"
    else
        log_warning "Coordinator API not responding yet"
    fi
}

# Show status
show_status() {
    log_info "Current deployment status:"
    echo ""

    # Container status
    echo "=== Containers ==="
    ssh_cmd "docker ps -a --filter 'name=autogit' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null || echo "Unable to get container status"
    echo ""

    # Network status
    echo "=== Network ==="
    ssh_cmd "docker network ls --filter 'name=autogit'" 2>/dev/null || echo "Unable to get network status"
    echo ""

    # Recent coordinator logs
    echo "=== Recent Coordinator Logs ==="
    ssh_cmd "docker logs autogit-runner-coordinator 2>&1 | tail -10" 2>/dev/null || echo "Unable to get logs"
}

# Main
main() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     AutoGit Homelab Deployment Script    ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    if [[ $DRY_RUN == "true" ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    check_homelab
    sync_files

    if [[ $SYNC_ONLY == "true" ]]; then
        log_success "Sync complete (--sync-only mode)"
        exit 0
    fi

    local rebuild_result
    rebuild_result=$(build_images)

    # Deploy (force recreate if images were rebuilt)
    deploy_containers "$rebuild_result"

    # Health check
    health_check

    echo ""
    show_status

    echo ""
    log_success "Deployment complete!"
}

main "$@"
