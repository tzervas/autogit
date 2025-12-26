#!/bin/bash
# GitLab Debug Log Capture and Analysis
# Captures detailed logs and performs automated analysis

set -euo pipefail

# Configuration
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

# Set Docker socket for rootless if needed
export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$(id -u)/docker.sock}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="debug-logs-${TIMESTAMP}"

echo "🐛 GitLab Debug Log Capture"
echo "============================"
echo ""
echo "Docker Host: $DOCKER_HOST"
echo ""

# Create log directory
mkdir -p "$LOG_DIR"

echo "📁 Log directory: $LOG_DIR"
echo ""

# Check if containers are running
echo "1️⃣ Checking container status..."
docker compose ps > "$LOG_DIR/container-status.txt" 2>&1
cat "$LOG_DIR/container-status.txt"
echo ""

# Capture full GitLab logs
echo "2️⃣ Capturing GitLab container logs..."
docker compose logs gitlab > "$LOG_DIR/gitlab-full.log" 2>&1
echo "   Saved to: $LOG_DIR/gitlab-full.log"
echo "   Lines: $(wc -l < "$LOG_DIR/gitlab-full.log")"
echo ""

# Capture runner logs
echo "3️⃣ Capturing runner logs..."
docker compose logs gitlab-runner > "$LOG_DIR/gitlab-runner.log" 2>&1 || echo "   (Runner may not be started)"
echo ""

# Extract critical sections
echo "4️⃣ Analyzing logs..."
echo ""

# PostgreSQL initialization
echo "   📊 PostgreSQL Analysis:"
grep -i "postgres\|database" "$LOG_DIR/gitlab-full.log" > "$LOG_DIR/postgres-events.log" 2>&1 || echo "      No PostgreSQL events found"
if [ -s "$LOG_DIR/postgres-events.log" ]; then
    echo "      Events found: $(wc -l < "$LOG_DIR/postgres-events.log")"
    echo "      First event: $(head -1 "$LOG_DIR/postgres-events.log")"
    echo "      Last event: $(tail -1 "$LOG_DIR/postgres-events.log")"
fi
echo ""

# Errors
echo "   ❌ Error Analysis:"
grep -i "error\|fail\|fatal\|exception" "$LOG_DIR/gitlab-full.log" > "$LOG_DIR/errors.log" 2>&1 || echo "      No errors found"
if [ -s "$LOG_DIR/errors.log" ]; then
    ERROR_COUNT=$(wc -l < "$LOG_DIR/errors.log")
    echo "      Total errors: $ERROR_COUNT"
    echo "      First 10 errors:"
    head -10 "$LOG_DIR/errors.log" | sed 's/^/         /'
fi
echo ""

# Warnings
echo "   ⚠️  Warning Analysis:"
grep -i "warn" "$LOG_DIR/gitlab-full.log" > "$LOG_DIR/warnings.log" 2>&1 || echo "      No warnings found"
if [ -s "$LOG_DIR/warnings.log" ]; then
    WARN_COUNT=$(wc -l < "$LOG_DIR/warnings.log")
    echo "      Total warnings: $WARN_COUNT"
fi
echo ""

# Configuration checks
echo "   ⚙️  Configuration Analysis:"
grep -i "shared_buffers\|effective_cache\|work_mem" "$LOG_DIR/gitlab-full.log" > "$LOG_DIR/postgres-config.log" 2>&1 || echo "      No PostgreSQL config found in logs"
if [ -s "$LOG_DIR/postgres-config.log" ]; then
    echo "      PostgreSQL tuning applied:"
    cat "$LOG_DIR/postgres-config.log" | sed 's/^/         /'
fi
echo ""

# Service readiness
echo "   ✅ Service Readiness:"
grep -i "workhorse\|ready\|listening\|started" "$LOG_DIR/gitlab-full.log" > "$LOG_DIR/service-events.log" 2>&1 || echo "      No service events found"
if [ -s "$LOG_DIR/service-events.log" ]; then
    echo "      Events: $(wc -l < "$LOG_DIR/service-events.log")"
    echo "      Last 5 events:"
    tail -5 "$LOG_DIR/service-events.log" | sed 's/^/         /'
fi
echo ""

# Port binding issues
echo "   🔌 Port Binding Analysis:"
grep -i "port\|bind\|address already in use\|permission denied" "$LOG_DIR/gitlab-full.log" > "$LOG_DIR/port-issues.log" 2>&1 || echo "      No port issues found"
if [ -s "$LOG_DIR/port-issues.log" ]; then
    echo "      Issues found:"
    cat "$LOG_DIR/port-issues.log" | sed 's/^/         /'
fi
echo ""

# Health checks
echo "5️⃣ Health Check Status..."
docker compose ps --format json > "$LOG_DIR/container-health.json" 2>&1
if command -v jq > /dev/null 2>&1; then
    echo "   Health status:"
    jq -r '.[] | "      \(.Name): \(.Health)"' "$LOG_DIR/container-health.json" 2> /dev/null || echo "      (Unable to parse health status)"
fi
echo ""

# System resources
echo "6️⃣ System Resources..."
{
    echo "   Memory usage:"
    free -h 2>&1
    echo ""
    echo "   Disk usage:"
    df -h . 2>&1
} > "$LOG_DIR/system-resources.txt"
cat "$LOG_DIR/system-resources.txt" | sed 's/^/   /'
echo ""

# Docker inspect
echo "7️⃣ Container Inspection..."
docker compose ps -q gitlab | xargs -r docker inspect > "$LOG_DIR/gitlab-inspect.json" 2>&1 || echo "   Container not running"
echo ""

# Generate summary report
echo "8️⃣ Generating Summary Report..."
cat > "$LOG_DIR/ANALYSIS_SUMMARY.md" << EOF
# GitLab Debug Analysis Summary

**Timestamp:** $TIMESTAMP
**Directory:** $LOG_DIR

## Container Status

\`\`\`
$(cat "$LOG_DIR/container-status.txt")
\`\`\`

## Error Summary

**Total Errors:** $(wc -l < "$LOG_DIR/errors.log" 2> /dev/null || echo 0)

### Top 10 Errors:
\`\`\`
$(head -10 "$LOG_DIR/errors.log" 2> /dev/null || echo "No errors found")
\`\`\`

## PostgreSQL Status

**Events:** $(wc -l < "$LOG_DIR/postgres-events.log" 2> /dev/null || echo 0)

### Key Events:
\`\`\`
$(head -20 "$LOG_DIR/postgres-events.log" 2> /dev/null || echo "No PostgreSQL events")
\`\`\`

## Configuration Verification

\`\`\`
$(cat "$LOG_DIR/postgres-config.log" 2> /dev/null || echo "No configuration found in logs")
\`\`\`

## Port Binding Issues

\`\`\`
$(cat "$LOG_DIR/port-issues.log" 2> /dev/null || echo "No port issues")
\`\`\`

## Service Readiness

\`\`\`
$(tail -20 "$LOG_DIR/service-events.log" 2> /dev/null || echo "No service events")
\`\`\`

## System Resources

\`\`\`
$(cat "$LOG_DIR/system-resources.txt")
\`\`\`

## Recommendations

### If Errors Found:
1. Check error patterns in \`errors.log\`
2. Verify PostgreSQL tuning in \`postgres-config.log\`
3. Check port conflicts in \`port-issues.log\`
4. Review full logs in \`gitlab-full.log\`

### If Container Not Starting:
1. Check \`container-status.txt\` for exit codes
2. Review \`gitlab-inspect.json\` for configuration issues
3. Verify resources in \`system-resources.txt\`

### If PostgreSQL Hanging:
1. Check if tuning is applied: \`postgres-config.log\`
2. Monitor timing in \`postgres-events.log\`
3. Increase resources or adjust tuning parameters

## Next Steps

1. Review this summary
2. Examine specific log files for details
3. Apply fixes based on findings
4. Re-test deployment

EOF

echo "   Saved to: $LOG_DIR/ANALYSIS_SUMMARY.md"
echo ""

echo "================================"
echo "✅ Debug capture complete!"
echo ""
echo "📂 All logs saved to: $LOG_DIR/"
echo ""
echo "📄 Key files:"
echo "   - ANALYSIS_SUMMARY.md    (Start here)"
echo "   - gitlab-full.log        (Complete logs)"
echo "   - errors.log             (All errors)"
echo "   - postgres-events.log    (Database events)"
echo "   - container-status.txt   (Container state)"
echo ""
echo "📖 Quick view:"
echo "   cat $LOG_DIR/ANALYSIS_SUMMARY.md"
echo ""
echo "🔍 Search logs:"
echo "   grep 'pattern' $LOG_DIR/gitlab-full.log"
echo ""

# Offer to view summary
if [[ "$NON_INTERACTIVE" != "true" ]] && [[ -t 0 ]]; then
    read -p "View ANALYSIS_SUMMARY.md now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cat "$LOG_DIR/ANALYSIS_SUMMARY.md"
    fi
else
    echo "📄 Summary saved to: $LOG_DIR/ANALYSIS_SUMMARY.md"
    echo "   Run 'cat $LOG_DIR/ANALYSIS_SUMMARY.md' to view"
fi
