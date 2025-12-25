#!/usr/bin/env bash
# Local GitLab Backup Orchestrator
#
# Runs the full GitLab backup process on the remote server
#
# Usage: ./run-gitlab-backup.sh [backup-name]
#
# Requirements:
# - SSH access to GitLab server as user with sudo
# - GITLAB_TOKEN environment variable
# - Scripts copied to server

set -euo pipefail

SERVER="${GITLAB_SERVER:-homelab}"
SSH_USER="${SSH_USER:-kang}" # Based on server directory ownership
BACKUP_NAME="${1:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"

if [[ -z $GITLAB_TOKEN ]]; then
    echo "Error: GITLAB_TOKEN environment variable required" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Running GitLab backup on $SERVER..."

# Copy scripts to server if needed
echo "Ensuring backup script is on server..."
scp "$SCRIPT_DIR/backup-gitlab.sh" "$SSH_USER@$SERVER:~/backup-gitlab.sh"
ssh "$SSH_USER@$SERVER" "chmod +x ~/backup-gitlab.sh"

# Run backup on server
BACKUP_CMD="GITLAB_TOKEN='$GITLAB_TOKEN'"
if [[ -n $GPG_PASSPHRASE ]]; then
    BACKUP_CMD="$BACKUP_CMD GPG_PASSPHRASE='$GPG_PASSPHRASE'"
fi
BACKUP_CMD="$BACKUP_CMD ./backup-gitlab.sh"
if [[ -n $BACKUP_NAME ]]; then
    BACKUP_CMD="$BACKUP_CMD '$BACKUP_NAME'"
fi

echo "Executing backup on server..."
ssh "$SSH_USER@$SERVER" "$BACKUP_CMD"

# Optionally copy backup files locally
read -p "Copy backup files locally? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    LOCAL_BACKUP_DIR="$REPO_ROOT/backups"
    mkdir -p "$LOCAL_BACKUP_DIR"

    echo "Copying backup files from server..."
    scp -r "$SSH_USER@$SERVER:/var/opt/gitlab/backups/*" "$LOCAL_BACKUP_DIR/"

    echo "Backup files copied to: $LOCAL_BACKUP_DIR"
fi

echo "GitLab backup completed successfully"
