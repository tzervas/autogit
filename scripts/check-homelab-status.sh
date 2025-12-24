#!/bin/bash
# Script to check the status of the homelab deployment
# Provides a summary of system resources and container health

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

echo "--- Homelab Status Report: $HOST ---"
echo "Time: $(date)"
echo ""

# 1. System Resources
echo "--- System Resources ---"
ssh "$USER@$HOST" "uptime && free -h && df -h /"
echo ""

# 2. Docker Container Status
echo "--- Docker Containers ---"
ssh "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
echo ""

# 3. Recent Deployment Logs
echo "--- Recent Deployment Activity (Last 5 lines) ---"
ssh "$USER@$HOST" "tail -n 5 $TARGET_PATH/deploy.log 2>/dev/null || echo 'No deployment log found.'"
echo ""

# 4. Service Health Checks
echo "--- Service Health ---"
# Use rootless DOCKER_HOST for remote checks
export DOCKER_HOST="unix:///run/user/1000/docker.sock"

# Check GitLab (if port 3000 is used)
if ssh "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/-/health" | grep -q "200"; then
    echo "GitLab: UP (200 OK)"
else
    echo "GitLab: DOWN or Starting..."
fi

# Check Runner Coordinator (if port 8080 is used)
if ssh "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/health" | grep -q "200"; then
    echo "Runner Coordinator: UP (200 OK)"
else
    echo "Runner Coordinator: DOWN or Starting..."
fi

# Check GitLab container health
GITLAB_STATUS=$(ssh "$USER@$HOST" "export DOCKER_HOST=$DOCKER_HOST && docker inspect -f '{{.State.Health.Status}}' autogit-git-server 2>/dev/null || echo 'not found'")

if [ "$GITLAB_STATUS" == "running" ]; then
    echo "GitLab Container: Healthy"
else
    echo "GitLab Container: Unhealthy or Not Running"
fi
