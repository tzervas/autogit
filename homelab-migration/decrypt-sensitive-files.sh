#!/usr/bin/env bash
# Decrypt GitLab sensitive configuration files from backup
#
# Usage: ./decrypt-sensitive-files.sh <backup-name> <output-dir>
#
# Requirements:
# - GPG installed
# - GPG_PASSPHRASE environment variable set
#
# Example:
# export GPG_PASSPHRASE="my-secret-passphrase"
# ./decrypt-sensitive-files.sh 20231225_143022 /tmp/gitlab-restore

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <backup-name> <output-dir>" >&2
    echo "Example: $0 20231225_143022 /tmp/gitlab-restore" >&2
    exit 1
fi

BACKUP_NAME="$1"
OUTPUT_DIR="$2"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"

if [[ -z $GPG_PASSPHRASE ]]; then
    echo "Error: GPG_PASSPHRASE environment variable required" >&2
    exit 1
fi

BACKUP_DIR="/var/lib/autogit/data/backups"
CONFIG_DIR="${BACKUP_DIR}/config"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Decrypting sensitive files for backup: $BACKUP_NAME"

# Decrypt gitlab.rb
GPG_FILE="${CONFIG_DIR}/gitlab.rb-${BACKUP_NAME}.gpg"
if [[ -f $GPG_FILE ]]; then
    echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
        --decrypt --output "${OUTPUT_DIR}/gitlab.rb" "$GPG_FILE"
    echo "Decrypted gitlab.rb to ${OUTPUT_DIR}/gitlab.rb"
else
    echo "Warning: Encrypted gitlab.rb not found: $GPG_FILE" >&2
fi

# Decrypt gitlab-secrets.json
GPG_FILE="${CONFIG_DIR}/gitlab-secrets.json-${BACKUP_NAME}.gpg"
if [[ -f $GPG_FILE ]]; then
    echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
        --decrypt --output "${OUTPUT_DIR}/gitlab-secrets.json" "$GPG_FILE"
    echo "Decrypted gitlab-secrets.json to ${OUTPUT_DIR}/gitlab-secrets.json"
else
    echo "Warning: Encrypted gitlab-secrets.json not found: $GPG_FILE" >&2
fi

# Set secure permissions on decrypted files
if [[ -f "${OUTPUT_DIR}/gitlab.rb" ]]; then
    chmod 600 "${OUTPUT_DIR}/gitlab.rb"
fi
if [[ -f "${OUTPUT_DIR}/gitlab-secrets.json" ]]; then
    chmod 600 "${OUTPUT_DIR}/gitlab-secrets.json"
fi

echo "Decryption complete. Files are in: $OUTPUT_DIR"
echo "Remember to securely delete these files after use!"
