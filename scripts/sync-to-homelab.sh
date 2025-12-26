#!/bin/bash
# Script to sync local project files to homelab server
# Usage: ./scripts/sync-to-homelab.sh <user> <host> [path]

set -e

# Load environment variables if .env exists
if [ -f ".env" ]; then
    # Use a more robust way to load env vars
    set -a
    source .env
    set +a
fi

USER=${1:-$HOMELAB_SSH_USER}
HOST=${2:-$HOMELAB_SSH_HOST}
# Default to /home/<user>/autogit if no path is provided
TARGET_PATH=${3:-${HOMELAB_TARGET_PATH:-"/home/$USER/autogit"}}

# Use a specific key name for AutoGit to avoid conflicts
DEFAULT_KEY_PATH="$HOME/.ssh/id_ed25519_autogit"
KEY_PATH=$(eval echo "${HOMELAB_SSH_KEY_PATH:-$DEFAULT_KEY_PATH}")
PUB_KEY="${KEY_PATH}.pub"

if [ -z "$USER" ] || [ -z "$HOST" ]; then
    echo "Usage: $0 <user> <host> [path]"
    echo "Or set HOMELAB_SSH_USER and HOMELAB_SSH_HOST in .env"
    exit 1
fi

# Function to setup SSH key on remote host
setup_ssh_key() {
    local user=$1
    local host=$2
    local pub_key=$3
    local priv_key="${pub_key%.pub}"

    if [ ! -f "$pub_key" ]; then
        echo "Public key not found at $pub_key. Generating a dedicated AutoGit key..."
        ssh-keygen -t ed25519 -C "autogit-homelab" -f "$priv_key" -N ""
    else
        echo "Using existing key found at $priv_key"
    fi

    echo "Copying SSH key to $user@$host..."
    ssh-copy-id -i "$pub_key" "$user@$host"
}

# Check if SSH key is already authorized
# We specify the identity file to ensure we're testing the right key
if ! ssh -i "$KEY_PATH" -o BatchMode=yes -o ConnectTimeout=5 "$USER@$HOST" exit 2> /dev/null; then
    echo "SSH key-based auth not working with $KEY_PATH. Attempting to set up..."
    setup_ssh_key "$USER" "$HOST" "$PUB_KEY"
else
    echo "SSH key-based auth already configured with $KEY_PATH."
fi

echo "Syncing files to $USER@$HOST:$TARGET_PATH..."

# Sync core files and services
# Use the specific identity file for rsync as well
rsync -avz --progress -e "ssh -i $KEY_PATH" \
    --exclude '.git/' \
    --exclude '.venv/' \
    --exclude '__pycache__/' \
    --exclude '*.db' \
    --exclude '.env' \
    ./ "$USER@$HOST:$TARGET_PATH/"

echo "Sync complete!"
