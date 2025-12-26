#!/bin/bash
# Clean deployment script with smart error filtering
# Hardware: 28 cores / 56 threads / 120GB RAM

set -e

HOMELAB_USER="kang"
HOMELAB_HOST="192.168.1.170"
HOMELAB_DIR="/home/kang/homelab-gitlab"
DOCKER_SOCK="unix:///run/user/1000/docker.sock"
CONTAINER_NAME="autogit-git-server"

echo "🚀 ULTRA BEAST MODE DEPLOYMENT"
echo "================================"
echo "Config: 12 cores | 12GB RAM | 2GB PostgreSQL cache | 1GB maintenance memory"
echo ""

# Deploy config
echo "📤 Deploying configuration..."
scp -q docker-compose.rootless.yml ${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DIR}/docker-compose.yml

# Restart container
echo "🔄 Restarting GitLab container..."
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "cd ${HOMELAB_DIR} && export DOCKER_HOST=${DOCKER_SOCK} && docker compose down 2>&1 | grep -E 'Stopping|Stopped|Removing|Removed' || true"
echo ""
echo "🚀 Starting container..."
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "cd ${HOMELAB_DIR} && export DOCKER_HOST=${DOCKER_SOCK} && docker compose up -d 2>&1"

echo ""
echo "✅ Deployment complete! Monitoring initialization..."
echo ""
sleep 3

# Show initial stats
echo "📊 Resource allocation:"
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "cd ${HOMELAB_DIR} && export DOCKER_HOST=${DOCKER_SOCK} && docker stats --no-stream ${CONTAINER_NAME} --format 'CPU: {{.CPUPerc}} | Memory: {{.MemUsage}}'"

echo ""
echo "⏱️  Initialization timeline (expected: 2-3 minutes with BEAST MODE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
START_TIME=$(date +%s)

# Function to show elapsed time
show_elapsed() {
    CURRENT=$(date +%s)
    ELAPSED=$((CURRENT - START_TIME))
    MINUTES=$((ELAPSED / 60))
    SECONDS=$((ELAPSED % 60))
    printf "[%02d:%02d]" $MINUTES $SECONDS
}

# Track milestones
POSTGRES_READY=false
MIGRATIONS_STARTED=false
PUMA_STARTING=false
HEALTH_PASSED=false

echo ""
echo "$(show_elapsed) 🎯 Watching for key milestones..."
echo ""

# Stream logs with SMART filtering
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "cd ${HOMELAB_DIR} && export DOCKER_HOST=${DOCKER_SOCK} && docker logs -f --tail=100 ${CONTAINER_NAME} 2>&1" | while IFS= read -r line; do
    TIMESTAMP=$(show_elapsed)
    ELAPSED_SECONDS=$(( $(date +%s) - START_TIME ))
    
    # Skip Chef cookbook caching messages (not useful for monitoring)
    if echo "$line" | grep -qi "storing updated cookbooks"; then
        continue
    fi
    
    # Skip generic warning message (not a real error)
    if echo "$line" | grep -qi "if this container fails to start due to permission"; then
        continue
    fi
    
    # Skip "connection refused" errors in first 90 seconds (normal during startup)
    if [ $ELAPSED_SECONDS -lt 90 ] && echo "$line" | grep -qi "connection refused\|badgateway"; then
        continue
    fi
    
    # Highlight PostgreSQL readiness
    if echo "$line" | grep -qi "database system is ready to accept connections"; then
        if [ "$POSTGRES_READY" = false ]; then
            echo "$TIMESTAMP ✅ MILESTONE 1/4: PostgreSQL ready!"
            POSTGRES_READY=true
        fi
        continue
    fi
    
    # Show PostgreSQL config (one time only)
    if echo "$line" | grep -qiE "shared_buffers.*=.*[0-9]"; then
        echo "$TIMESTAMP 🎯 PostgreSQL: $line"
        continue
    fi
    
    if echo "$line" | grep -qiE "maintenance_work_mem.*=.*[0-9]"; then
        echo "$TIMESTAMP 🎯 PostgreSQL: $line"
        continue
    fi
    
    if echo "$line" | grep -qiE "max_parallel.*=.*[0-9]"; then
        echo "$TIMESTAMP 🎯 PostgreSQL: $line"
        continue
    fi
    
    # Track migrations (show summary, not every file)
    if echo "$line" | grep -qiE "== [0-9]+ .* migrating"; then
        if [ "$MIGRATIONS_STARTED" = false ]; then
            echo "$TIMESTAMP ✅ MILESTONE 2/4: Database migrations started"
            MIGRATIONS_STARTED=true
        fi
        echo "$TIMESTAMP 🔄 Migration: $(echo "$line" | grep -oE '== [0-9]+ .*')"
        continue
    fi
    
    # Track Puma startup
    if echo "$line" | grep -qi "puma starting in cluster mode"; then
        if [ "$PUMA_STARTING" = false ]; then
            echo "$TIMESTAMP ✅ MILESTONE 3/4: Puma web server starting"
            PUMA_STARTING=true
        fi
        continue
    fi
    
    if echo "$line" | grep -qiE "workers.*:.*[0-9]" && echo "$line" | grep -qi "puma"; then
        echo "$TIMESTAMP 👷 Puma: $(echo "$line" | grep -oE 'Workers.*')"
        continue
    fi
    
    # Track Workhorse
    if echo "$line" | grep -qi "workhorse.*listening"; then
        echo "$TIMESTAMP 🌐 Workhorse: Ready"
        continue
    fi
    
    # Track Sidekiq
    if echo "$line" | grep -qiE "sidekiq.*starting|sidekiq.*ready"; then
        echo "$TIMESTAMP 🔧 Sidekiq: Background workers ready"
        continue
    fi
    
    # Track health check passing
    if echo "$line" | grep -qi "health check.*passed\|health.*ok"; then
        if [ "$HEALTH_PASSED" = false ]; then
            echo "$TIMESTAMP ✅ MILESTONE 4/4: Health check PASSED!"
            echo ""
            echo "🎉 GitLab is ready!"
            echo ""
            HEALTH_PASSED=true
        fi
        continue
    fi
    
    # Show REAL errors (not filenames, not during initial startup)
    if [ $ELAPSED_SECONDS -gt 90 ]; then
        if echo "$line" | grep -qiE "fatal|exception|backtrace|errno"; then
            # Make sure it's not a filename
            if ! echo "$line" | grep -qiE "\.rb|\.erb|\.js|cookbook"; then
                echo "$TIMESTAMP ⚠️  Warning: $line"
            fi
        fi
    fi
done
