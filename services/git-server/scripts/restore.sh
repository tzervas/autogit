#!/bin/bash
# Restore Script for GitLab
# Restores GitLab from a specified backup file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    print_error "Usage: $0 <backup_timestamp_name>"
    print_info "Example: $0 1703325600_2025_12_23_16.11.0"
    exit 1
fi

# Determine script directory to anchor paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/../../../docker-compose.yml"

# Check if GitLab is running
if ! docker compose -f "$COMPOSE_FILE" ps git-server --status running --format json | grep -q '"State":"running"'; then
    print_error "GitLab container is not running"
    exit 1
fi

print_info "Stopping services that connect to the database..."
docker compose -f "$COMPOSE_FILE" exec -T git-server gitlab-ctl stop puma
docker compose -f "$COMPOSE_FILE" exec -T git-server gitlab-ctl stop sidekiq

print_info "Restoring from backup: $BACKUP_FILE..."
docker compose -f "$COMPOSE_FILE" exec -T git-server gitlab-backup restore BACKUP="$BACKUP_FILE" force=yes

print_info "Restarting GitLab services..."
docker compose -f "$COMPOSE_FILE" exec -T git-server gitlab-ctl reconfigure
docker compose -f "$COMPOSE_FILE" exec -T git-server gitlab-ctl restart

print_info "✅ Restore completed successfully."
