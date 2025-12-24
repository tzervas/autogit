#!/bin/bash
# Script to monitor the homelab deployment live
# Usage: ./scripts/monitor-deployment.sh

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

echo "Starting live monitor for $HOST..."
echo "Press Ctrl+C to stop."

# Function to cleanup background processes
cleanup() {
    echo "Stopping monitor..."
    kill "$(jobs -p)" 2>/dev/null || true
    exit
}

trap cleanup SIGINT SIGTERM

# 0. Trigger Deployment in the background
echo "--- Triggering Deployment (Terraform) ---"
(
    cd infrastructure/homelab
    terraform apply -auto-approve \
        -var="ssh_user=$USER" \
        -var="ssh_key_path=$HOMELAB_SSH_KEY_PATH" \
        >>terraform.log 2>&1
    echo "[$(date)] Terraform apply finished." >>../../deploy.log
) &

# 1. Tail the deployment log in the background
echo "--- Tailing Deployment Log ---"
ssh "$USER@$HOST" "touch $TARGET_PATH/deploy.log && tail -f $TARGET_PATH/deploy.log" &

# 2. Periodically show container status and health
while true; do
    # We use a temporary file to avoid flickering
    STATUS_TMP=$(mktemp)

    {
        echo "========================================================================"
        echo " HOMELAB DEPLOYMENT DASHBOARD | $(date)"
        echo "========================================================================"
        echo ""
        echo "--- System Status ---"
        ssh "$USER@$HOST" "uptime && free -h | grep Mem"
        echo ""
        echo "--- Container Status ---"
        ssh "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
        echo ""
        echo "--- Service Health ---"
        GITLAB_HEALTH=$(ssh "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/-/health || echo 'FAIL'")
        RUNNER_HEALTH=$(ssh "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/health || echo 'FAIL'")

        echo "GitLab: $([ "$GITLAB_HEALTH" == "200" ] && echo "UP (200)" || echo "DOWN ($GITLAB_HEALTH)")"
        echo "Runner Coordinator: $([ "$RUNNER_HEALTH" == "200" ] && echo "UP (200)" || echo "DOWN ($RUNNER_HEALTH)")"
        echo ""
        echo "========================================================================"
        echo " (Log output continues below...)"
    } >"$STATUS_TMP"

    # Clear screen and show status
    clear
    cat "$STATUS_TMP"
    rm "$STATUS_TMP"

    sleep 10
done
