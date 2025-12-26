#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# GitLab Homelab Deployment Script
# IDEMPOTENT: Safe to run multiple times - detects state and acts accordingly
#
# Usage:
#   ./deploy.sh                    # Deploy/update GitLab
#   ./deploy.sh --status           # Check status only
#   ./deploy.sh --bootstrap        # Deploy + create users
#   ./deploy.sh --full             # Deploy + users + mirroring
#   ./deploy.sh --teardown         # Remove deployment
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment (local .env or defaults)
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/.env"
fi

# Remote host settings
HOMELAB_USER="${HOMELAB_USER:-kang}"
HOMELAB_HOST="${HOMELAB_HOST:-192.168.1.170}"
HOMELAB_DIR="${HOMELAB_DIR:-/home/${HOMELAB_USER}/homelab-gitlab}"
DOCKER_SOCK="${DOCKER_SOCK:-unix:///run/user/1000/docker.sock}"
CONTAINER_NAME="${CONTAINER_NAME:-autogit-git-server}"

# Compose file to deploy
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.gitlab.yml}"

# Timeouts
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-300}"   # 5 minutes for initial health
HEALTH_INTERVAL="${HEALTH_INTERVAL:-10}"  # Check every 10 seconds

#───────────────────────────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────
log()      { echo "[$(date '+%H:%M:%S')] $*"; }
log_ok()   { echo "[$(date '+%H:%M:%S')] ✅ $*"; }
log_warn() { echo "[$(date '+%H:%M:%S')] ⚠️  $*"; }
log_err()  { echo "[$(date '+%H:%M:%S')] ❌ $*" >&2; }
log_skip() { echo "[$(date '+%H:%M:%S')] ⏭️  $*"; }

# Execute command on remote host with correct Docker context
remote() {
    ssh "${HOMELAB_USER}@${HOMELAB_HOST}" \
        "cd ${HOMELAB_DIR} && export DOCKER_HOST=${DOCKER_SOCK} && $*"
}

# Check if container exists
container_exists() {
    remote "docker ps -a --format '{{.Names}}' | grep -q '^${CONTAINER_NAME}$'" 2>/dev/null
}

# Check if container is running
container_running() {
    remote "docker ps --format '{{.Names}}' | grep -q '^${CONTAINER_NAME}$'" 2>/dev/null
}

# Check if container is healthy
container_healthy() {
    local health
    health=$(remote "docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null" || echo "none")
    [[ "$health" == "healthy" ]]
}

# Get container status summary
get_status() {
    if ! container_exists; then
        echo "ABSENT"
    elif ! container_running; then
        echo "STOPPED"
    elif container_healthy; then
        echo "HEALTHY"
    else
        echo "STARTING"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# ACTIONS
#───────────────────────────────────────────────────────────────────────────────

action_status() {
    log "📊 GitLab Deployment Status"
    echo "─────────────────────────────────────────"
    
    local status
    status=$(get_status)
    
    case "$status" in
        ABSENT)
            log_warn "GitLab is not deployed"
            echo "   Run: ./deploy.sh to deploy"
            return 1
            ;;
        STOPPED)
            log_warn "GitLab container exists but is stopped"
            remote "docker ps -a --filter name=${CONTAINER_NAME} --format 'table {{.Status}}\t{{.Ports}}'"
            echo "   Run: ./deploy.sh to start"
            return 1
            ;;
        STARTING)
            log_warn "GitLab is starting (not yet healthy)"
            remote "docker stats --no-stream ${CONTAINER_NAME} --format 'CPU: {{.CPUPerc}} | Memory: {{.MemUsage}}'" 2>/dev/null || true
            echo "   Wait for health check or check logs: docker logs ${CONTAINER_NAME}"
            return 0
            ;;
        HEALTHY)
            log_ok "GitLab is healthy and running"
            remote "docker stats --no-stream ${CONTAINER_NAME} --format 'CPU: {{.CPUPerc}} | Memory: {{.MemUsage}}'" 2>/dev/null || true
            
            # Show version
            local version
            version=$(remote "docker exec ${CONTAINER_NAME} cat /opt/gitlab/version-manifest.txt 2>/dev/null | head -1" || echo "unknown")
            echo "   Version: ${version}"
            echo "   URL: http://${HOMELAB_HOST}:${HTTP_PORT:-8080}"
            return 0
            ;;
    esac
}

action_deploy() {
    log "🚀 GitLab Deployment"
    echo "─────────────────────────────────────────"
    
    local status
    status=$(get_status)
    
    # Check current state
    case "$status" in
        HEALTHY)
            log_skip "GitLab is already running and healthy"
            log "   Use --force to redeploy anyway"
            return 0
            ;;
        STARTING)
            log_skip "GitLab is currently starting"
            log "   Waiting for health check..."
            wait_for_health
            return $?
            ;;
    esac
    
    # Ensure remote directory exists
    log "📁 Ensuring remote directory..."
    ssh "${HOMELAB_USER}@${HOMELAB_HOST}" "mkdir -p ${HOMELAB_DIR}"
    
    # Copy configuration files
    log "📤 Deploying configuration..."
    scp -q "${SCRIPT_DIR}/${COMPOSE_FILE}" "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DIR}/docker-compose.yml"
    
    if [[ -f "${SCRIPT_DIR}/.env" ]]; then
        scp -q "${SCRIPT_DIR}/.env" "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DIR}/.env"
    fi
    
    # Stop existing if present
    if container_exists; then
        log "🛑 Stopping existing container..."
        remote "docker compose down" 2>&1 | grep -E 'Stopping|Stopped|Removing|Removed' || true
    fi
    
    # Start fresh
    log "🚀 Starting GitLab..."
    remote "docker compose up -d" 2>&1
    
    # Wait for health
    log "⏳ Waiting for GitLab to become healthy..."
    wait_for_health
}

action_teardown() {
    log "🗑️  Tearing down GitLab"
    echo "─────────────────────────────────────────"
    
    if ! container_exists; then
        log_skip "GitLab is not deployed"
        return 0
    fi
    
    read -p "⚠️  This will stop GitLab. Data volumes preserved. Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Cancelled."
        return 1
    fi
    
    log "🛑 Stopping GitLab..."
    remote "docker compose down"
    log_ok "GitLab stopped. Data volumes preserved."
    log "   To remove data: ssh ${HOMELAB_USER}@${HOMELAB_HOST} 'docker volume rm gitlab-config gitlab-logs gitlab-data'"
}

action_bootstrap() {
    action_deploy || return 1
    
    log ""
    log "👥 Running user bootstrap..."
    echo "─────────────────────────────────────────"
    
    if [[ -x "${SCRIPT_DIR}/bootstrap-gitlab-users.sh" ]]; then
        "${SCRIPT_DIR}/bootstrap-gitlab-users.sh"
    else
        log_err "bootstrap-gitlab-users.sh not found or not executable"
        return 1
    fi
}

action_full() {
    action_bootstrap || return 1
    
    log ""
    log "🔗 Setting up repository mirroring..."
    echo "─────────────────────────────────────────"
    
    # Check for required tokens
    if [[ -z "${GITHUB_PAT_MIRROR:-}" ]] || [[ -z "${GITLAB_PAT_MIRROR:-}" ]]; then
        log_warn "Mirror tokens not set. Set GITHUB_PAT_MIRROR and GITLAB_PAT_MIRROR"
        log "   Skipping mirroring setup"
        return 0
    fi
    
    if [[ -f "${SCRIPT_DIR}/setup-mirroring.py" ]]; then
        cd "${SCRIPT_DIR}"
        python3 setup-mirroring.py
    else
        log_err "setup-mirroring.py not found"
        return 1
    fi
}

wait_for_health() {
    local elapsed=0
    local status
    
    while [[ $elapsed -lt $HEALTH_TIMEOUT ]]; do
        status=$(get_status)
        
        case "$status" in
            HEALTHY)
                log_ok "GitLab is healthy! (${elapsed}s)"
                echo ""
                echo "🎉 Deployment complete!"
                echo "   URL: http://${HOMELAB_HOST}:${HTTP_PORT:-8080}"
                echo "   SSH: ssh://git@${HOMELAB_HOST}:${SSH_PORT:-2222}"
                return 0
                ;;
            ABSENT|STOPPED)
                log_err "Container stopped unexpectedly"
                return 1
                ;;
            STARTING)
                # Show progress
                local mem cpu
                read -r cpu mem <<< "$(remote "docker stats --no-stream ${CONTAINER_NAME} --format '{{.CPUPerc}} {{.MemUsage}}'" 2>/dev/null || echo "- -")"
                printf "\r[%3ds] Initializing... CPU: %s | Memory: %s    " "$elapsed" "$cpu" "$mem"
                ;;
        esac
        
        sleep "$HEALTH_INTERVAL"
        elapsed=$((elapsed + HEALTH_INTERVAL))
    done
    
    echo ""
    log_err "Health check timeout after ${HEALTH_TIMEOUT}s"
    log "   Check logs: ssh ${HOMELAB_USER}@${HOMELAB_HOST} 'docker logs ${CONTAINER_NAME}'"
    return 1
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << EOF
GitLab Homelab Deployment

Usage: ./deploy.sh [OPTIONS]

Options:
  (none)        Deploy/update GitLab (idempotent)
  --status      Show current deployment status
  --bootstrap   Deploy + create user accounts
  --full        Deploy + users + repository mirroring
  --teardown    Stop GitLab (preserves data)
  --force       Force redeploy even if healthy
  --help        Show this help

Environment Variables (or set in .env):
  HOMELAB_USER      SSH username (default: kang)
  HOMELAB_HOST      Remote host IP (default: 192.168.1.170)
  HOMELAB_DIR       Remote directory (default: /home/\$USER/homelab-gitlab)
  HTTP_PORT         HTTP port (default: 8080)
  HTTPS_PORT        HTTPS port (default: 8443)
  SSH_PORT          SSH port (default: 2222)

Resource Presets (set in .env):
  CPU_LIMIT/MEMORY_LIMIT to customize allocation
  See gitlab.env.example for full options

EOF
}

main() {
    local action="deploy"
    local force=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status)   action="status" ;;
            --bootstrap) action="bootstrap" ;;
            --full)     action="full" ;;
            --teardown) action="teardown" ;;
            --force)    force=true ;;
            --help|-h)  show_help; exit 0 ;;
            *)          log_err "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done
    
    # Execute action
    case "$action" in
        status)    action_status ;;
        deploy)    action_deploy ;;
        bootstrap) action_bootstrap ;;
        full)      action_full ;;
        teardown)  action_teardown ;;
    esac
}

main "$@"
