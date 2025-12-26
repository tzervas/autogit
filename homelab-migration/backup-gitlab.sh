#!/usr/bin/env bash
# GitLab Full Backup Script
#
# Creates a complete backup of GitLab server including:
# - Configuration export (via API)
# - Full GitLab backup (database, repositories, etc.)
# - Named with timestamp for repeatability
#
# Usage: ./backup-gitlab.sh [backup-name]
# If backup-name not provided, uses timestamp
#
# Requirements:
# - Docker access to GitLab container
# - GitLab API token with admin access
# - jq for JSON processing
#
# Outputs:
# - Config files in /var/lib/autogit/data/backups/config/
# - Backup tar in /var/lib/autogit/data/backups/
# - Backup metadata in /var/lib/autogit/data/backups/backups.json

set -euo pipefail

# Configuration
GITLAB_CONTAINER="autogit-git-server"
DOCKER_SOCKET="${DOCKER_HOST:-unix:///run/user/1000/docker.sock}"
GITLAB_URL="${GITLAB_URL:-http://localhost:3000}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
BACKUP_DIR="/var/lib/autogit/data/backups"
CONFIG_DIR="${BACKUP_DIR}/config"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_NAME="${1:-${TIMESTAMP}}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"

# Validate environment
if [[ -z $GITLAB_TOKEN ]]; then
    echo "Error: GITLAB_TOKEN environment variable required" >&2
    exit 1
fi

# Ensure directories exist
sudo mkdir -p "$CONFIG_DIR"
sudo chown -R kang:kang "$BACKUP_DIR" 2> /dev/null || true

echo "Starting GitLab backup: $BACKUP_NAME"

# Export configuration via API
echo "Exporting GitLab configuration..."
export GITLAB_URL GITLAB_TOKEN CONFIG_DIR BACKUP_NAME GPG_PASSPHRASE
python3 - << 'EOF'
import json
import os
import sys
import requests
from datetime import datetime

gitlab_url = os.environ["GITLAB_URL"]
token = os.environ["GITLAB_TOKEN"]
backup_name = os.environ.get("BACKUP_NAME", "")
config_dir = os.environ["CONFIG_DIR"]

session = requests.Session()
session.headers.update({"Authorization": f"Bearer {token}"})

def api_call(endpoint):
    url = f"{gitlab_url}/api/v4{endpoint}"
    resp = session.get(url)
    resp.raise_for_status()
    return resp.json()

print("Exporting application settings...")
settings = api_call("/application/settings")
with open(f"{config_dir}/application-settings-{backup_name}.json", "w") as f:
    json.dump(settings, f, indent=2)

print("Exporting users...")
users = api_call("/users?per_page=100")
for user in users:
    user.pop("private_token", None)
with open(f"{config_dir}/users-{backup_name}.json", "w") as f:
    json.dump(users, f, indent=2)

print("Exporting groups...")
groups = api_call("/groups?per_page=100")
with open(f"{config_dir}/groups-{backup_name}.json", "w") as f:
    json.dump(groups, f, indent=2)

print("Exporting projects...")
projects = api_call("/projects?per_page=100")
for project in projects:
    project.pop("readme", None)
with open(f"{config_dir}/projects-{backup_name}.json", "w") as f:
    json.dump(projects, f, indent=2)

# Create backup metadata
metadata = {
    "backup_name": backup_name,
    "timestamp": datetime.now().isoformat(),
    "gitlab_version": settings.get("version", "unknown"),
    "user_count": len(users),
    "group_count": len(groups),
    "project_count": len(projects),
    "sensitive_files_encrypted": bool(os.environ.get("GPG_PASSPHRASE")),
}
with open(f"{config_dir}/backup-metadata-{backup_name}.json", "w") as f:
    json.dump(metadata, f, indent=2)

print("Configuration export complete")
EOF

# Secure backup of sensitive configuration files
echo "Creating secure backup of sensitive configuration files..."
if [[ -n $GPG_PASSPHRASE ]]; then
    # Backup gitlab.rb
    if [[ -f "/var/lib/autogit/config/gitlab.rb" ]]; then
        echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
            --cipher-algo AES256 --symmetric \
            --output "${CONFIG_DIR}/gitlab.rb-${BACKUP_NAME}.gpg" \
            "/var/lib/autogit/config/gitlab.rb"
        echo "Encrypted gitlab.rb backup created"
    fi

    # Backup gitlab-secrets.json
    if [[ -f "/var/lib/autogit/config/gitlab-secrets.json" ]]; then
        echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
            --cipher-algo AES256 --symmetric \
            --output "${CONFIG_DIR}/gitlab-secrets.json-${BACKUP_NAME}.gpg" \
            "/var/lib/autogit/config/gitlab-secrets.json"
        echo "Encrypted gitlab-secrets.json backup created"
    fi
else
    echo "Warning: GPG_PASSPHRASE not set - sensitive files will not be backed up"
    echo "Set GPG_PASSPHRASE environment variable to enable secure backup of sensitive files"
fi

# Create full GitLab backup via Docker
echo "Creating GitLab data backup..."
DOCKER_HOST="$DOCKER_SOCKET" docker exec "$GITLAB_CONTAINER" gitlab-backup create BACKUP="$BACKUP_NAME"

# Find the created backup file
BACKUP_FILE=$(ls -t *_${BACKUP_NAME}_*.tar 2> /dev/null | head -1)
if [[ -z $BACKUP_FILE ]]; then
    echo "Error: Backup file not found" >&2
    exit 1
fi

# Compress the backup for efficiency
echo "Compressing backup..."
sudo gzip "$BACKUP_FILE"
COMPRESSED_FILE="${BACKUP_FILE}.gz"

# Update backups registry
BACKUP_INFO=$(
    cat << EOF
{
    "name": "$BACKUP_NAME",
    "timestamp": "$TIMESTAMP",
    "config_dir": "$CONFIG_DIR",
    "backup_file": "$COMPRESSED_FILE",
    "size_bytes": $(stat -c%s "$COMPRESSED_FILE" 2> /dev/null || echo 0)
}
EOF
)

# Append to backups.json
BACKUPS_JSON="$BACKUP_DIR/backups.json"
if [[ ! -f $BACKUPS_JSON ]]; then
    echo "[]" > "$BACKUPS_JSON"
fi

# Add new backup to array
jq ". += [$BACKUP_INFO]" "$BACKUPS_JSON" > "${BACKUPS_JSON}.tmp"
sudo mv "${BACKUPS_JSON}.tmp" "$BACKUPS_JSON"

echo "Backup complete!"
echo "Config files: $CONFIG_DIR/*-${BACKUP_NAME}.json"
echo "Backup file: $COMPRESSED_FILE"
echo "Size: $(du -h "$COMPRESSED_FILE" | cut -f1)"

# Optional: Clean old backups (keep last 5)
echo "Cleaning old backups..."
BACKUP_COUNT=$(jq length "$BACKUPS_JSON")
if [[ $BACKUP_COUNT -gt 5 ]]; then
    echo "Keeping only last 5 backups"
    jq '.[-5:]' "$BACKUPS_JSON" > "${BACKUPS_JSON}.tmp"
    sudo mv "${BACKUPS_JSON}.tmp" "$BACKUPS_JSON"

    # Remove old files
    jq -r '.[].name' "${BACKUPS_JSON}.old" 2> /dev/null | while read -r old_name; do
        if ! jq -e ".[] | select(.name == \"$old_name\")" "$BACKUPS_JSON" > /dev/null; then
            echo "Removing old backup: $old_name"
            sudo rm -f "${BACKUP_DIR}"/*"${old_name}"* 2> /dev/null || true
            sudo rm -f "${CONFIG_DIR}"/*"${old_name}"* 2> /dev/null || true
        fi
    done
fi

echo "GitLab backup $BACKUP_NAME completed successfully"
