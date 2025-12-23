#!/bin/bash
# Backup Script for GitLab
# Creates a full backup of GitLab configuration and data

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Determine script directory to anchor backup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$SCRIPT_DIR/../backups"
COMPOSE_FILE="$SCRIPT_DIR/../../../docker-compose.yml"

# Check if GitLab is running
check_gitlab_running() {
    if ! docker compose -f "$COMPOSE_FILE" ps git-server --status running --format json | grep -q '"State":"running"'; then
        print_error "GitLab container is not running"
        exit 1
    fi
}

# Create application backup
create_backup() {
    print_info "Starting GitLab application backup..."
    # Use -T to avoid pseudo-terminal issues in non-interactive shells
    docker compose -f "$COMPOSE_FILE" exec -T git-server gitlab-backup create
    print_info "✅ Application backup completed."
}

# Backup configuration files
backup_config() {
    print_info "Backing up GitLab configuration..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$BACKUP_ROOT/config_$TIMESTAMP"
    # Create parent directory if it doesn't exist
    mkdir -p "$BACKUP_ROOT"
    # Create backup directory with secure permissions
    mkdir -m 700 "$BACKUP_DIR"

    # Copy config from volume/container
    # Note: /etc/gitlab contains sensitive secrets (gitlab-secrets.json)
    docker compose -f "$COMPOSE_FILE" cp git-server:/etc/gitlab "$BACKUP_DIR"

    # Ensure restrictive permissions on sensitive secret file
    chmod 600 "$BACKUP_DIR/gitlab/gitlab-secrets.json" 2>/dev/null || true

    print_info "✅ Configuration backed up to $BACKUP_DIR"
    print_warn "Ensure $BACKUP_DIR is stored securely as it contains sensitive secrets."
}

# Main execution
mkdir -p "$BACKUP_ROOT"
check_gitlab_running
create_backup
backup_config

print_info "--- Backup Summary ---"
print_info "Application backups are stored in the 'git-data' volume (/var/opt/gitlab/backups)"
print_info "Configuration backups are stored in $BACKUP_ROOT"
