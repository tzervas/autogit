#!/bin/bash
# Script to fetch logs from the homelab server
# Usage: ./scripts/fetch-homelab-logs.sh [service_name] [--follow]

set -e

# Load environment variables if .env.homelab exists
if [ -f ".env.homelab" ]; then
    set -a
    source .env.homelab
    set +a
fi

USER=${HOMELAB_SSH_USER:-"kang"}
HOST=${HOMELAB_SSH_HOST:-"192.168.1.170"}
TARGET_PATH=${HOMELAB_TARGET_PATH:-"/home/$USER/autogit"}
DOCKER_SOCKET="unix:///run/user/1000/docker.sock"

SERVICE=$1
FOLLOW=$2

if [ "$SERVICE" == "--follow" ]; then
    FOLLOW="--follow"
    SERVICE=""
fi

echo "Fetching logs from $USER@$HOST:$TARGET_PATH..."

if [ -n "$SERVICE" ]; then
    ssh -t "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && cd $TARGET_PATH && docker compose logs $FOLLOW $SERVICE"
else
    ssh -t "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && cd $TARGET_PATH && docker compose logs $FOLLOW"
fi
