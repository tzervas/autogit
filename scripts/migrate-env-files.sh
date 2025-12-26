#!/usr/bin/env bash
#
# migrate-env-files.sh - Migrate existing .env.* files to single .env
#
# This script consolidates all environment configuration files into a single .env file.
# It preserves existing configurations while removing duplicate entries.
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Backup existing .env if it exists
backup_existing_env() {
    if [[ -f ".env" ]]; then
        local backup
        backup=".env.backup.$(date +%Y%m%d_%H%M%S)"
        cp .env "$backup"
        log_info "Backed up existing .env to $backup"
    fi
}

# Migrate a specific env file
migrate_file() {
    local file="$1"
    local description="$2"

    if [[ -f $file ]]; then
        log_info "Migrating $file ($description)..."

        # Skip comment lines and empty lines, append to .env
        grep -v '^#' "$file" | grep -v '^$' >>.env || true

        # Remove the old file
        rm "$file"
        log_info "Removed $file (migrated to .env)"
    else
        log_info "$file not found, skipping"
    fi
}

# Remove duplicate entries from .env
deduplicate_env() {
    if [[ -f ".env" ]]; then
        log_info "Removing duplicate entries from .env..."

        # Create a temporary file with unique entries
        local temp_file=".env.temp"
        awk -F'=' '!seen[$1]++' .env >"$temp_file"
        mv "$temp_file" .env

        log_info "Deduplication complete"
    fi
}

# Set proper permissions
set_permissions() {
    if [[ -f ".env" ]]; then
        chmod 600 .env
        log_info "Set .env permissions to 600 (owner read/write only)"
    fi
}

# Main migration
main() {
    echo ""
    echo "========================================"
    echo "🔄 AutoGit Environment File Migration"
    echo "========================================"
    echo ""

    backup_existing_env

    # Create .env if it doesn't exist
    touch .env

    # Migrate each file type
    migrate_file ".env.gitlab" "GitLab configuration"
    migrate_file ".env.homelab" "Homelab configuration"
    migrate_file ".env.runner" "Runner configuration"

    # Clean up duplicates
    deduplicate_env

    # Set permissions
    set_permissions

    echo ""
    log_info "Migration complete!"
    echo ""
    echo "📋 Summary:"
    echo "  • All .env.* files consolidated into .env"
    echo "  • Duplicate entries removed"
    echo "  • File permissions set to 600"
    echo "  • Original .env backed up (if it existed)"
    echo ""
    echo "🔧 Next steps:"
    echo "  • Review .env contents: cat .env"
    echo "  • Test your scripts still work"
    echo "  • Update any manual references to .env.* files"
    echo ""
}

main "$@"
