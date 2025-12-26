#!/usr/bin/env bash
# GitLab Restore Script for AutoGit Backups
#
# Restores GitLab from an AutoGit backup created by backup-gitlab.sh
#
# Usage: ./restore-autogit-backup.sh <backup-name>
#
# Requirements:
# - Run as root
# - GitLab stopped
# - Backup exists in /var/lib/autogit/data/backups/

set -euo pipefail

BACKUP_NAME="$1"
BACKUP_DIR="/var/lib/autogit/data/backups"
CONFIG_DIR="${BACKUP_DIR}/config"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"

if [[ -z $BACKUP_NAME ]]; then
    echo "Usage: $0 <backup-name>" >&2
    exit 1
fi

echo "Restoring GitLab from AutoGit backup: $BACKUP_NAME"

# Check if backup exists
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}_gitlab_backup.tar"
if [[ ! -f $BACKUP_FILE ]]; then
    echo "Error: Backup file $BACKUP_FILE not found" >&2
    exit 1
fi

echo "Found backup file: $BACKUP_FILE"

# Check if config files exist
CONFIG_FILES=(
    "${CONFIG_DIR}/application-settings-${BACKUP_NAME}.json"
    "${CONFIG_DIR}/users-${BACKUP_NAME}.json"
    "${CONFIG_DIR}/groups-${BACKUP_NAME}.json"
    "${CONFIG_DIR}/projects-${BACKUP_NAME}.json"
)

for config_file in "${CONFIG_FILES[@]}"; do
    if [[ ! -f $config_file ]]; then
        echo "Error: Config file $config_file not found" >&2
        exit 1
    fi
done

# Check for encrypted sensitive files
GITLAB_RB_ENCRYPTED="${CONFIG_DIR}/gitlab.rb-${BACKUP_NAME}.gpg"
GITLAB_SECRETS_ENCRYPTED="${CONFIG_DIR}/gitlab-secrets.json-${BACKUP_NAME}.gpg"

# Stop GitLab
echo "Stopping GitLab services..."
docker stop autogit-git-server

# Restore configuration files first
if [[ -f $GITLAB_RB_ENCRYPTED && -f $GITLAB_SECRETS_ENCRYPTED ]]; then
    echo "Found encrypted sensitive files"
    if [[ -z $GPG_PASSPHRASE ]]; then
        echo "Error: GPG_PASSPHRASE required for encrypted backup" >&2
        exit 1
    fi

    # Decrypt sensitive files
    echo "Decrypting sensitive files..."
    echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 --decrypt "$GITLAB_RB_ENCRYPTED" > "/var/lib/autogit/config/gitlab.rb"
    echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 --decrypt "$GITLAB_SECRETS_ENCRYPTED" > "/var/lib/autogit/config/gitlab-secrets.json"

    echo "Reconfigured GitLab with decrypted settings"
fi

# Start GitLab temporarily for reconfigure
echo "Starting GitLab for reconfiguration..."
docker start autogit-git-server

# Wait for container to be ready
echo "Waiting for GitLab container to be ready..."
sleep 15

# Try a quick reconfigure to generate required files
echo "Running quick reconfigure to generate required files..."
if docker exec autogit-git-server timeout 60 gitlab-ctl reconfigure; then
    echo "Reconfigure completed successfully"
else
    echo "Reconfigure failed or timed out, but continuing with restore..."
fi

# Stop GitLab again for data restore
echo "Stopping GitLab for data restore..."
docker stop autogit-git-server

# Stop GitLab
echo "Stopping GitLab services..."
docker stop autogit-git-server

# Restore GitLab data while running
echo "Restoring GitLab data..."
cd /var/lib/autogit/data/backups
docker exec autogit-git-server gitlab-backup restore BACKUP="$BACKUP_NAME" --confirm

# Start GitLab
echo "Starting GitLab services..."
docker start autogit-git-server

# Wait for services to be ready
echo "Waiting for GitLab to be ready..."
timeout=300
while [[ $timeout -gt 0 ]]; do
    if curl -s -f http://localhost/-/health > /dev/null 2>&1; then
        break
    fi
    sleep 5
    timeout=$((timeout - 5))
done

if [[ $timeout -le 0 ]]; then
    echo "Warning: GitLab may not be fully ready yet" >&2
fi

echo "GitLab restore from $BACKUP_NAME completed"
echo "Config files available in: $CONFIG_DIR/*-${BACKUP_NAME}.*"
