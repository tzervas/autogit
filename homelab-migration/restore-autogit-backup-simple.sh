#!/usr/bin/env bash
# Simplified GitLab Restore Script for AutoGit Backups
#
# Restores GitLab from an AutoGit backup created by backup-gitlab.sh
#
# Usage: ./restore-autogit-backup-simple.sh <backup-name>
#
# Requirements:
# - GitLab container should be running
# - Backup exists in /var/lib/autogit/data/backups/

set -euo pipefail

BACKUP_NAME="$1"
BACKUP_DIR="/var/opt/gitlab/backups"
CONFIG_DIR="${BACKUP_DIR}/config"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"

if [[ -z $BACKUP_NAME ]]; then
    echo "Usage: $0 <backup-name>" >&2
    exit 1
fi

echo "Restoring GitLab from AutoGit backup: $BACKUP_NAME"

# Check if backup exists
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}_gitlab_backup.tar"
if ! docker exec autogit-git-server test -f "$BACKUP_FILE"; then
    echo "Error: Backup file $BACKUP_FILE not found in container" >&2
    exit 1
fi

echo "Found backup file: $BACKUP_FILE"

# Check for encrypted sensitive files
GITLAB_RB_ENCRYPTED="${CONFIG_DIR}/gitlab.rb-${BACKUP_NAME}.gpg"
GITLAB_SECRETS_ENCRYPTED="${CONFIG_DIR}/gitlab-secrets.json-${BACKUP_NAME}.gpg"

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

# Start GitLab if not running
if ! docker ps | grep -q autogit-git-server; then
    echo "Starting GitLab services..."
    docker start autogit-git-server

    # Wait for GitLab to be ready
    echo "Waiting for GitLab to be ready..."
    sleep 30
fi

# Restore GitLab data while running
echo "Restoring GitLab data..."
echo "yes" | docker exec -i autogit-git-server su - git -c "gitlab-backup restore BACKUP=\"$BACKUP_NAME\""

echo "GitLab restore from $BACKUP_NAME completed"
