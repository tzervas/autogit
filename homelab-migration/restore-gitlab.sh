#!/usr/bin/env bash
# GitLab Restore Script
#
# Restores GitLab from a complete backup created by backup-gitlab.sh
#
# Usage: ./restore-gitlab.sh <backup-name>
#
# Requirements:
# - Run as root
# - GitLab stopped
# - Backup exists in /var/opt/gitlab/backups/

set -euo pipefail

BACKUP_NAME="$1"
BACKUP_DIR="/var/opt/gitlab/backups"
CONFIG_DIR="${BACKUP_DIR}/config"

if [[ -z $BACKUP_NAME ]]; then
    echo "Usage: $0 <backup-name>" >&2
    exit 1
fi

echo "Restoring GitLab from backup: $BACKUP_NAME"

# Check if backup exists
BACKUPS_JSON="$BACKUP_DIR/backups.json"
if [[ ! -f $BACKUPS_JSON ]]; then
    echo "Error: No backups registry found" >&2
    exit 1
fi

BACKUP_INFO=$(jq -r ".[] | select(.name == \"$BACKUP_NAME\")" "$BACKUPS_JSON")
if [[ -z $BACKUP_INFO ]]; then
    echo "Error: Backup $BACKUP_NAME not found in registry" >&2
    exit 1
fi

BACKUP_FILE=$(echo "$BACKUP_INFO" | jq -r '.backup_file')
if [[ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
    echo "Error: Backup file $BACKUP_FILE not found" >&2
    exit 1
fi

echo "Found backup file: $BACKUP_FILE"

# Stop GitLab
echo "Stopping GitLab services..."
sudo gitlab-ctl stop

# Decompress backup if needed
if [[ $BACKUP_FILE == *.gz ]]; then
    echo "Decompressing backup..."
    sudo gunzip "$BACKUP_DIR/$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE%.gz}"
fi

# Extract backup name from filename (GitLab format: TIMESTAMP_BACKUPNAME_gitlab_backup.tar)
GITLAB_BACKUP_NAME=$(basename "$BACKUP_FILE" | sed 's/.*_\([^_]*\)_gitlab_backup\.tar/\1/')

# Restore GitLab data
echo "Restoring GitLab data..."
cd /var/opt/gitlab/backups
sudo gitlab-backup restore BACKUP="$GITLAB_BACKUP_NAME" --confirm

# Recompress backup
if [[ -f "$BACKUP_DIR/${BACKUP_FILE}.gz" ]]; then
    echo "Recompressing backup..."
    sudo gzip "$BACKUP_DIR/$BACKUP_FILE"
fi

# Start GitLab
echo "Starting GitLab services..."
sudo gitlab-ctl start

# Wait for services to be ready
echo "Waiting for GitLab to be ready..."
timeout=300
while [[ $timeout -gt 0 ]]; do
    if curl -s -f http://localhost/-/health >/dev/null 2>&1; then
        break
    fi
    sleep 5
    timeout=$((timeout - 5))
done

if [[ $timeout -le 0 ]]; then
    echo "Warning: GitLab may not be fully ready yet" >&2
fi

echo "GitLab restore from $BACKUP_NAME completed"
echo "You may need to reconfigure application settings from the config backup"
echo "Config files available in: $CONFIG_DIR/*-${BACKUP_NAME}.json"
