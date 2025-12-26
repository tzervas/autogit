#!/bin/bash
# Simple log capture for debugging GitLab deployment
# Run this on the homelab server

set -euo pipefail

# Configuration
HOMELAB_USER="${HOMELAB_USER:-kang}"
HOMELAB_HOST="${HOMELAB_HOST:-192.168.1.170}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

# Set Docker socket for rootless
export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$(id -u)/docker.sock}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="gitlab-debug-${TIMESTAMP}.log"

echo "📋 Capturing GitLab Logs - $TIMESTAMP"
echo "==========================================" | tee "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Container status
echo "🔍 Container Status:" | tee -a "$LOG_FILE"
docker compose ps 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Health status
echo "💊 Health Check:" | tee -a "$LOG_FILE"
docker compose ps --format '{{.Name}}: {{.Status}}' 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Get last 500 lines of logs
echo "📝 GitLab Logs (last 500 lines):" | tee -a "$LOG_FILE"
echo "===================================" | tee -a "$LOG_FILE"
docker compose logs --tail=500 gitlab 2>&1 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "✅ Logs saved to: $LOG_FILE"
echo "📦 File size: $(du -h "$LOG_FILE" | cut -f1)"

if [[ "$NON_INTERACTIVE" != "true" ]]; then
    echo ""
    echo "To download to your local machine:"
    echo "scp ${HOMELAB_USER}@${HOMELAB_HOST}:$(pwd)/$LOG_FILE ."
fi
