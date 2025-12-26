#!/bin/bash
# Monitor GitLab startup with milestones
# Run on homelab server

set -euo pipefail

export DOCKER_HOST=unix:///run/user/1000/docker.sock

echo "🚀 GitLab Startup Monitor"
echo "========================="
echo ""
echo "Monitoring container: autogit-git-server"
echo "Expected milestones:"
echo "  ~2 min: PostgreSQL ready"
echo "  ~5 min: Database migrations"
echo "  ~8 min: Puma starts"
echo "  ~10 min: Health check passes"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""
sleep 2

START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    MINUTES=$((ELAPSED / 60))
    SECONDS=$((ELAPSED % 60))
    
    echo "⏱️  $(printf '%02d:%02d' $MINUTES $SECONDS) - Checking status..."
    
    # Check container health
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' autogit-git-server 2>/dev/null || echo "no-healthcheck")
    echo "   Health: $HEALTH"
    
    # Check for key milestones in logs
    RECENT_LOGS=$(docker logs --tail=50 autogit-git-server 2>&1)
    
    if echo "$RECENT_LOGS" | grep -q "database system is ready to accept connections"; then
        echo "   ✅ PostgreSQL is ready!"
    fi
    
    if echo "$RECENT_LOGS" | grep -q "postgresql\['shared_buffers'\]"; then
        echo "   ✅ PostgreSQL tuning applied!"
    fi
    
    if echo "$RECENT_LOGS" | grep -q "Database Migration"; then
        echo "   ✅ Database migrations running..."
    fi
    
    if echo "$RECENT_LOGS" | grep -q "Puma starting\|puma.*Listening"; then
        echo "   ✅ Puma started!"
    fi
    
    if echo "$RECENT_LOGS" | grep -q "Workhorse.*started"; then
        echo "   ✅ Workhorse connected!"
    fi
    
    if [ "$HEALTH" = "healthy" ]; then
        echo ""
        echo "🎉 GitLab is HEALTHY!"
        echo ""
        echo "Test with:"
        echo "  curl http://localhost:8080/-/health"
        echo "  curl http://192.168.1.170:8080/-/health"
        break
    fi
    
    echo ""
    sleep 15
done
