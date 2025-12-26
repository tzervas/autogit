#!/usr/bin/env bash
# Local GitLab Restore Orchestrator
#
# Runs the GitLab restore process on the remote server
#
# Usage: ./run-gitlab-restore.sh <backup-name>
#
# Requirements:
# - SSH access to GitLab server as user with sudo
# - Scripts copied to server

set -euo pipefail

SERVER="${GITLAB_SERVER:-homelab}"
SSH_USER="${SSH_USER:-kang}" # Based on server directory ownership
BACKUP_NAME="$1"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"

if [[ -z $BACKUP_NAME ]]; then
    echo "Usage: $0 <backup-name>" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running GitLab restore on $SERVER..."

# Copy restore script to server
echo "Copying restore script to server..."
scp "$SCRIPT_DIR/restore-autogit-backup-simple.sh" "$SSH_USER@$SERVER:~/restore-autogit-backup-simple.sh"
ssh "$SSH_USER@$SERVER" "chmod +x ~/restore-autogit-backup-simple.sh"

# Run restore on server
RESTORE_CMD="./restore-autogit-backup-simple.sh '$BACKUP_NAME'"
if [[ -n $GPG_PASSPHRASE ]]; then
    RESTORE_CMD="GPG_PASSPHRASE='$GPG_PASSPHRASE' $RESTORE_CMD"
fi

echo "Executing restore on server..."
ssh "$SSH_USER@$SERVER" "sudo $RESTORE_CMD"

echo "GitLab restore completed successfully"
