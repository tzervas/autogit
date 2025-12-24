#!/bin/bash
# Wrapper script to run Terraform deployment and monitor it live
# Usage: ./scripts/deploy-and-monitor.sh

set -e

# Load environment variables if .env.homelab exists
if [ -f ".env.homelab" ]; then
    set -a
    source .env.homelab
    set +a
fi

USER=${HOMELAB_SSH_USER:-"kang"}
KEY_PATH=${HOMELAB_SSH_KEY_PATH:-"~/.ssh/id_ed25519"}

echo "Starting AutoGit Homelab Deployment..."

# 1. Run Terraform Apply in the background
# We redirect output to a file so it doesn't mess with the monitor UI
echo "Initializing Terraform Apply (background)..."
# Ensure DOCKER_HOST is set for local rootless use if not already
export DOCKER_HOST=${DOCKER_HOST:-"unix:///run/user/1000/docker.sock"}

cd infrastructure/homelab
terraform apply -auto-approve \
    -var="ssh_user=$USER" \
    -var="ssh_key_path=$KEY_PATH" >terraform_apply.log 2>&1 &

TF_PID=$!

echo "Terraform PID: $TF_PID"
echo "Starting monitor in 2 seconds..."
sleep 2

# 2. Start the monitor script
cd ../..
./scripts/monitor-deployment.sh
