#!/bin/bash
# Comprehensive GitLab Deployment Diagnostics
# Captures all information needed to diagnose initialization vs. real issues
# shellcheck disable=SC2129  # Multiple heredocs to same file is intentional for report generation

# Configuration - can be overridden via environment variables
HOMELAB_USER="${HOMELAB_USER:-kang}"
HOMELAB_HOST="${HOMELAB_HOST:-192.168.1.170}"
DOCKER_SOCK="${DOCKER_SOCK:-unix:///run/user/1000/docker.sock}"
CONTAINER_NAME="${CONTAINER_NAME:-autogit-git-server}"
OUTPUT_DIR="./debug-$(date +%Y%m%d-%H%M%S)"

echo "🔍 GitLab Deployment Diagnostics"
echo "================================"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to run command and save output
run_diagnostic() {
    local name=$1
    local description=$2
    local command=$3

    echo "📊 $description..."
    ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && $command" > "$OUTPUT_DIR/$name.txt" 2>&1
    echo "   ✅ Saved to $name.txt"
}

echo "Collecting diagnostics from homelab..."
echo ""

# 1. Container status and uptime
run_diagnostic "01-container-status" "Container status & uptime" \
    "docker ps -a --filter name=${CONTAINER_NAME} --no-trunc"

# 2. Resource usage (current snapshot)
run_diagnostic "02-resource-usage" "Current CPU/Memory usage" \
    "docker stats --no-stream ${CONTAINER_NAME}"

# 3. Container inspect (full config)
run_diagnostic "03-container-config" "Container configuration" \
    "docker inspect ${CONTAINER_NAME}"

# 4. Process list inside container
run_diagnostic "04-process-list" "Running processes" \
    "docker exec ${CONTAINER_NAME} ps auxf"

# 5. PostgreSQL status
run_diagnostic "05-postgresql-status" "PostgreSQL processes & connections" \
    "docker exec ${CONTAINER_NAME} sh -c 'ps aux | grep postgres && echo \"\" && psql -U gitlab -d gitlabhq_production -c \"SELECT version();\" 2>&1 || echo \"PostgreSQL not ready yet\"'"

# 6. Puma/Rails status
run_diagnostic "06-puma-status" "Puma web server status" \
    "docker exec ${CONTAINER_NAME} sh -c 'ps aux | grep puma; ls -la /var/opt/gitlab/gitlab-rails/sockets/ 2>&1 || echo \"Socket directory not ready\"'"

# 7. Recent logs (last 500 lines)
run_diagnostic "07-recent-logs" "Recent container logs" \
    "docker logs --tail=500 ${CONTAINER_NAME}"

# 8. PostgreSQL logs
run_diagnostic "08-postgresql-logs" "PostgreSQL logs" \
    "docker exec ${CONTAINER_NAME} tail -100 /var/log/gitlab/postgresql/current"

# 9. Puma logs
run_diagnostic "09-puma-logs" "Puma web server logs" \
    "docker exec ${CONTAINER_NAME} tail -100 /var/log/gitlab/puma/current 2>&1 || echo 'Puma not started yet'"

# 10. Workhorse logs
run_diagnostic "10-workhorse-logs" "GitLab Workhorse logs" \
    "docker exec ${CONTAINER_NAME} tail -100 /var/log/gitlab/gitlab-workhorse/current 2>&1 || echo 'Workhorse not started yet'"

# 11. Sidekiq logs
run_diagnostic "11-sidekiq-logs" "Sidekiq background job logs" \
    "docker exec ${CONTAINER_NAME} tail -100 /var/log/gitlab/sidekiq/current 2>&1 || echo 'Sidekiq not started yet'"

# 12. Health check attempts
run_diagnostic "12-health-check" "Health endpoint test" \
    "curl -v -m 5 http://localhost:8080/-/health 2>&1"

# 13. Network connectivity
run_diagnostic "13-network-test" "Network connectivity test" \
    "docker exec ${CONTAINER_NAME} sh -c 'netstat -tlnp | grep -E \":80|:443|:8080\" || ss -tlnp | grep -E \":80|:443|:8080\"'"

# 14. Disk usage
run_diagnostic "14-disk-usage" "Disk usage in container" \
    "docker exec ${CONTAINER_NAME} df -h"

# 15. GitLab service status
run_diagnostic "15-gitlab-services" "GitLab service status" \
    "docker exec ${CONTAINER_NAME} gitlab-ctl status 2>&1 || echo 'gitlab-ctl not available yet'"

# 16. Recent errors only
run_diagnostic "16-errors-only" "Error messages only" \
    "docker logs --tail=1000 ${CONTAINER_NAME} 2>&1 | grep -iE 'error|fatal|exception|fail' | grep -v 'error.html\|failover_helper\|\.erb\|\.rb' | tail -50"

# 17. PostgreSQL configuration
run_diagnostic "17-postgresql-config" "PostgreSQL tuning verification" \
    "docker logs ${CONTAINER_NAME} 2>&1 | grep -E 'shared_buffers|maintenance_work_mem|max_parallel|effective_cache' | head -20"

# 18. Migration status
run_diagnostic "18-migration-status" "Database migration status" \
    "docker logs --tail=2000 ${CONTAINER_NAME} 2>&1 | grep -E 'migrat|schema' | grep -v 'migrations.rb\|migration_helper' | tail -30"

# 19. Container restart count
run_diagnostic "19-restart-count" "Container restart history" \
    "docker inspect ${CONTAINER_NAME} --format='{{.RestartCount}}' && docker inspect ${CONTAINER_NAME} --format='{{.State.Status}}'"

# 20. Resource limit verification
run_diagnostic "20-resource-limits" "Configured resource limits" \
    "docker inspect ${CONTAINER_NAME} --format='CPU NanoCPUs: {{.HostConfig.NanoCpus}} | Memory: {{.HostConfig.Memory}} | SHM: {{.HostConfig.ShmSize}}'"

echo ""
echo "✅ Diagnostic collection complete!"
echo ""

# Analyze and generate summary
echo "📋 Generating analysis summary..."
echo ""

SUMMARY_FILE="$OUTPUT_DIR/00-ANALYSIS-SUMMARY.md"

cat > "$SUMMARY_FILE" << EOF
# GitLab Deployment Diagnostic Analysis

**Date:** $(date)
**Status:** Analyzing...

---

## Quick Status Check

### Container Status
EOF

# Extract key info
UPTIME=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker ps --filter name=${CONTAINER_NAME} --format '{{.Status}}'")
CPU_MEM=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker stats --no-stream ${CONTAINER_NAME} --format 'CPU: {{.CPUPerc}} | Memory: {{.MemUsage}}'")
RESTART_COUNT=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker inspect ${CONTAINER_NAME} --format='{{.RestartCount}}'")

cat >> "$SUMMARY_FILE" << EOF
- **Uptime:** $UPTIME
- **Resources:** $CPU_MEM
- **Restart Count:** $RESTART_COUNT

### Key Indicators

EOF

# Check for PostgreSQL ready
if ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker logs ${CONTAINER_NAME} 2>&1 | grep -q 'database system is ready to accept connections'"; then
    echo "- ✅ PostgreSQL is ready" >> "$SUMMARY_FILE"
else
    echo "- ⏳ PostgreSQL is initializing" >> "$SUMMARY_FILE"
fi

# Check for Puma
if ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker exec ${CONTAINER_NAME} test -S /var/opt/gitlab/gitlab-rails/sockets/gitlab.socket 2>/dev/null"; then
    echo "- ✅ Puma socket exists" >> "$SUMMARY_FILE"
else
    echo "- ⏳ Puma socket not created yet (Rails app still loading)" >> "$SUMMARY_FILE"
fi

# Check for errors
ERROR_COUNT=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker logs --tail=500 ${CONTAINER_NAME} 2>&1 | grep -iE 'fatal|exception' | grep -v 'error.html\|\.erb\|\.rb' | wc -l")
echo "- **Error Count (last 500 lines):** $ERROR_COUNT" >> "$SUMMARY_FILE"

# Check health endpoint
if ssh ${HOMELAB_USER}@${HOMELAB_HOST} "curl -s -m 2 http://localhost:8080/-/health 2>&1 | grep -q 'ok'"; then
    echo "- ✅ Health endpoint is responding" >> "$SUMMARY_FILE"
else
    echo "- ⏳ Health endpoint not ready (expected during initialization)" >> "$SUMMARY_FILE"
fi

cat >> "$SUMMARY_FILE" << 'EOF'

---

## Diagnosis

EOF

# Determine status
if [ "$RESTART_COUNT" -gt 0 ]; then
    cat >> "$SUMMARY_FILE" << 'EOF'
### ⚠️  Container Has Restarted

The container has restarted, which indicates a potential issue.

**Action Required:**
1. Check `07-recent-logs.txt` for crash/exit messages
2. Check `16-errors-only.txt` for fatal errors
3. Review `05-postgresql-status.txt` for database issues

EOF
else
    # Check uptime
    if echo "$UPTIME" | grep -qE "seconds|minute"; then
        cat >> "$SUMMARY_FILE" << 'EOF'
### ⏳ Early Initialization (< 2 minutes)

Container is in early initialization phase.

**Expected Behavior:**
- PostgreSQL starting up
- Services initializing
- Connection refused errors are NORMAL

**Wait Time:** 2-3 minutes for ULTRA BEAST MODE

EOF
    elif echo "$UPTIME" | grep -qE "2.*minute|3.*minute"; then
        cat >> "$SUMMARY_FILE" << 'EOF'
### ⏳ Mid Initialization (2-3 minutes)

Container is in mid-initialization phase.

**Expected Activity:**
- PostgreSQL ready ✅
- Database migrations running
- Puma loading Rails application
- Connection refused still possible

**Wait Time:** 1-2 more minutes

EOF
    elif echo "$UPTIME" | grep -qE "[4-9].*minute"; then
        cat >> "$SUMMARY_FILE" << 'EOF'
### ⏳ Late Initialization (4+ minutes)

Container should be nearly ready or experiencing issues.

**Check:**
1. If Puma socket exists → Almost ready!
2. If no socket → Check Puma logs (09-puma-logs.txt)
3. If errors present → Review error logs

EOF
    fi
fi

cat >> "$SUMMARY_FILE" << 'EOF'

---

## Resource Usage Analysis

Check `02-resource-usage.txt` for current resource consumption.

**Expected Resource Usage:**

| Phase | CPU | Memory | Duration |
|-------|-----|--------|----------|
| PostgreSQL Init | 100-200% | 2-3GB | 0-1 min |
| Migrations | 400-800% | 4-6GB | 1-2 min |
| Puma Loading | 200-400% | 6-8GB | 2-3 min |
| Steady State | 50-150% | 4-6GB | After ready |

**ULTRA BEAST MODE Config:**
- CPU Limit: 24 cores (24000000000 nanocpus)
- Memory Limit: 32GB
- SHM: 8GB

EOF

echo "- **Current:** $CPU_MEM" >> "$SUMMARY_FILE"

cat >> "$SUMMARY_FILE" << 'EOF'

---

## Next Steps

### If Still Initializing (< 5 minutes uptime)
✅ **Wait 2-3 more minutes** - This is normal!

### If Taking Too Long (> 5 minutes)
1. Check `09-puma-logs.txt` for Rails loading progress
2. Check `18-migration-status.txt` for stuck migrations
3. Check `16-errors-only.txt` for real errors

### If Container Restarting
1. Review `07-recent-logs.txt` for exit reason
2. Check `05-postgresql-status.txt` for DB corruption
3. Review `16-errors-only.txt` for fatal errors

---

## Files to Review

**Must Review:**
- `00-ANALYSIS-SUMMARY.md` - This file
- `01-container-status.txt` - Container state
- `02-resource-usage.txt` - Resource consumption

**If Issues Found:**
- `07-recent-logs.txt` - Full recent logs
- `09-puma-logs.txt` - Web server logs
- `16-errors-only.txt` - Error messages only

**For Deep Dive:**
- All other numbered files contain detailed diagnostics

EOF

echo ""
cat "$SUMMARY_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 All diagnostics saved to: $OUTPUT_DIR"
echo ""
echo "🔍 Key files to review:"
echo "   1. $OUTPUT_DIR/00-ANALYSIS-SUMMARY.md    <- START HERE"
echo "   2. $OUTPUT_DIR/02-resource-usage.txt     <- Resource consumption"
echo "   3. $OUTPUT_DIR/09-puma-logs.txt          <- Puma/Rails status"
echo "   4. $OUTPUT_DIR/16-errors-only.txt        <- Real errors only"
echo ""
echo "💡 To review: cat $OUTPUT_DIR/00-ANALYSIS-SUMMARY.md"
echo ""
