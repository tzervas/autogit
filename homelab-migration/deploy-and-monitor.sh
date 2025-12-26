#!/bin/bash
# Deploy and Monitor GitLab with ULTRA BEAST MODE
# Hardware: 28 cores / 56 threads / 120GB RAM

set -e

HOMELAB_USER="kang"
HOMELAB_HOST="192.168.1.170"
HOMELAB_DIR="/home/kang/homelab-gitlab"
DOCKER_SOCK="unix:///run/user/1000/docker.sock"
CONTAINER_NAME="autogit-git-server"

echo "🚀 ULTRA BEAST MODE DEPLOYMENT"
echo "================================"
echo "Config: 24 cores | 32GB RAM | 8GB PostgreSQL cache | 2GB maintenance memory"
echo ""

# Deploy config
echo "📤 Deploying configuration..."
scp docker-compose.rootless.yml ${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DIR}/docker-compose.yml

# Restart container
echo "🔄 Restarting GitLab container..."
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && cd ${HOMELAB_DIR} && docker compose down && docker compose up -d"

echo ""
echo "✅ Deployment complete! Starting monitoring..."
echo ""
sleep 2

# Show initial stats
echo "📊 Initial resource allocation:"
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker stats --no-stream ${CONTAINER_NAME} --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'"

echo ""
echo "⏱️  Starting initialization timer..."
START_TIME=$(date +%s)

echo ""
echo "🔍 Monitoring GitLab initialization (Ctrl+C to stop, container continues)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to show elapsed time
show_elapsed() {
    CURRENT=$(date +%s)
    ELAPSED=$((CURRENT - START_TIME))
    MINUTES=$((ELAPSED / 60))
    SECONDS=$((ELAPSED % 60))
    printf "[%02d:%02d]" $MINUTES $SECONDS
}

# Monitor key milestones
echo "$(show_elapsed) 🎯 Watching for key milestones..."
echo ""

# Stream logs with timestamps and filtering
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker logs -f --tail=50 ${CONTAINER_NAME} 2>&1" | while IFS= read -r line; do
    TIMESTAMP=$(show_elapsed)

    # Highlight key events (skip false positives like error.html.erb)
    if echo "$line" | grep -qi "shared_buffers"; then
        echo "$TIMESTAMP 🎯 PostgreSQL Config: $line"
    elif echo "$line" | grep -qi "database system is ready"; then
        echo "$TIMESTAMP ✅ MILESTONE: PostgreSQL ready!"
    elif echo "$line" | grep -qi "max_parallel"; then
        echo "$TIMESTAMP 🎯 Parallel Workers: $line"
    elif echo "$line" | grep -qi "maintenance_work_mem"; then
        echo "$TIMESTAMP 🎯 Maintenance Memory: $line"
    elif echo "$line" | grep -qi "migrat" | grep -qv "migrations.rb"; then
        echo "$TIMESTAMP 🔄 Migration: $line"
    elif echo "$line" | grep -qi "puma.*start\|workhorse.*start"; then
        echo "$TIMESTAMP ✅ MILESTONE: Application starting"
    elif echo "$line" | grep -qi "listening on\|successfully started"; then
        echo "$TIMESTAMP ✅ MILESTONE: Service ready"
    elif echo "$line" | grep -qiE "error|fatal|fail" | grep -qv "error\.html\|failover_helper\|error_messages"; then
        # Only show real errors, not filenames
        if ! echo "$line" | grep -qi "\.rb\|\.erb\|\.js"; then
            echo "$TIMESTAMP ❌ ERROR: $line"
        fi
    elif echo "$line" | grep -qi "worker.*processes\|puma.*worker"; then
        echo "$TIMESTAMP 👷 Workers: $line"
    fi
done
