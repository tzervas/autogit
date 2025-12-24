#!/bin/bash
# End-to-End Dynamic Runner Test
# Tests the complete lifecycle: trigger -> spawn -> execute -> cleanup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Load configuration
if [ -f ".env.gitlab" ]; then
    source .env.gitlab
else
    echo "Error: .env.gitlab not found. Run: bash scripts/setup-gitlab-automation.sh"
    exit 1
fi

# Load helpers
source scripts/gitlab-helpers.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
step() { echo -e "${CYAN}▶${NC} $1"; }

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         AutoGit Dynamic Runner End-to-End Test                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Pre-flight checks
step "Pre-flight checks..."
echo ""

info "Checking services..."
if ! curl -sf "${COORDINATOR_URL}/health" >/dev/null 2>&1; then
    error "Runner Coordinator is not responding"
    exit 1
fi
success "Runner Coordinator: UP"

if ! curl -sf "${GITLAB_URL}/" >/dev/null 2>&1; then
    error "GitLab is not responding"
    exit 1
fi
success "GitLab: UP"

# Check current state
info "Current runner count:"
INITIAL_RUNNERS=$(curl -sf "${COORDINATOR_URL}/runners" | jq '. | length')
echo "  Active runners: ${INITIAL_RUNNERS}"

info "Current containers:"
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter 'name=autogit-runner' --format '{{.Names}}'" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        echo "  • ${name}"
    fi
done || echo "  (none)"

echo ""
step "Triggering pipeline..."
echo ""

# Trigger a new pipeline
TRIGGER_RESPONSE=$(curl -sf --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/pipeline?ref=main")

PIPELINE_ID=$(echo "$TRIGGER_RESPONSE" | jq -r '.id')
PIPELINE_STATUS=$(echo "$TRIGGER_RESPONSE" | jq -r '.status')

if [ -z "$PIPELINE_ID" ] || [ "$PIPELINE_ID" = "null" ]; then
    error "Failed to trigger pipeline"
    echo "$TRIGGER_RESPONSE" | jq .
    exit 1
fi

success "Pipeline triggered"
info "Pipeline ID: ${PIPELINE_ID}"
info "Initial status: ${PIPELINE_STATUS}"
info "View at: ${GITLAB_URL}/root/autogit/-/pipelines/${PIPELINE_ID}"
echo ""

# Monitor the pipeline and runners
step "Monitoring pipeline execution..."
echo ""

TIMEOUT=300 # 5 minutes
START_TIME=$(date +%s)
LAST_STATUS=""
MAX_RUNNERS=0
RUNNER_SPAWNED=false

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED -gt $TIMEOUT ]; then
        warning "Timeout reached (${TIMEOUT}s)"
        break
    fi

    # Get pipeline status
    PIPELINE_INFO=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${PIPELINE_ID}")

    STATUS=$(echo "$PIPELINE_INFO" | jq -r '.status')

    # Get runner count
    RUNNER_COUNT=$(curl -sf "${COORDINATOR_URL}/runners" | jq '. | length')

    if [ $RUNNER_COUNT -gt $MAX_RUNNERS ]; then
        MAX_RUNNERS=$RUNNER_COUNT
    fi

    if [ $RUNNER_COUNT -gt 0 ] && [ "$RUNNER_SPAWNED" = "false" ]; then
        RUNNER_SPAWNED=true
        success "Runner spawned! (${RUNNER_COUNT} active)"
    fi

    # Print status updates
    if [ "$STATUS" != "$LAST_STATUS" ]; then
        TIMESTAMP=$(date +"%H:%M:%S")
        case $STATUS in
        "created" | "waiting_for_resource" | "preparing")
            info "[${TIMESTAMP}] Pipeline: ${STATUS}"
            ;;
        "pending")
            info "[${TIMESTAMP}] Pipeline: ${STATUS} (waiting for runner)"
            ;;
        "running")
            success "[${TIMESTAMP}] Pipeline: ${STATUS}"
            ;;
        "success")
            success "[${TIMESTAMP}] Pipeline: ${STATUS}"
            break
            ;;
        "failed")
            error "[${TIMESTAMP}] Pipeline: ${STATUS}"
            break
            ;;
        "canceled")
            warning "[${TIMESTAMP}] Pipeline: ${STATUS}"
            break
            ;;
        esac
        LAST_STATUS=$STATUS
    fi

    # Print runner count if changed
    if [ $RUNNER_COUNT -gt 0 ]; then
        echo -ne "\r  Active runners: ${RUNNER_COUNT} | Elapsed: ${ELAPSED}s"
    fi

    sleep 2
done

echo ""
echo ""

# Get final statistics
step "Pipeline complete - gathering statistics..."
echo ""

# Get jobs
JOBS=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${PIPELINE_ID}/jobs")

JOB_COUNT=$(echo "$JOBS" | jq '. | length')
SUCCESS_COUNT=$(echo "$JOBS" | jq '[.[] | select(.status == "success")] | length')
FAILED_COUNT=$(echo "$JOBS" | jq '[.[] | select(.status == "failed")] | length')

info "Pipeline Summary:"
echo "  • Total jobs: ${JOB_COUNT}"
echo "  • Successful: ${SUCCESS_COUNT}"
echo "  • Failed: ${FAILED_COUNT}"
echo "  • Max concurrent runners: ${MAX_RUNNERS}"
echo "  • Total duration: ${ELAPSED}s"
echo ""

if [ $JOB_COUNT -gt 0 ]; then
    info "Job Details:"
    echo "$JOBS" | jq -r '.[] | "  • \(.name): \(.status) (\(.stage))"'
    echo ""
fi

# Monitor cleanup phase
if [ "$RUNNER_SPAWNED" = "true" ]; then
    echo ""
    step "Monitoring runner cleanup..."
    echo ""

    info "Runners enter cooldown after job completion"
    info "Default cooldown period: 5 minutes"
    info "Monitoring for 60 seconds..."
    echo ""

    for i in {1..30}; do
        RUNNER_COUNT=$(curl -sf "${COORDINATOR_URL}/runners" | jq '. | length')
        CONTAINER_COUNT=$(ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter 'name=autogit-runner' --filter 'status=running' -q" 2>/dev/null | wc -l)

        TIMESTAMP=$(date +"%H:%M:%S")
        echo -ne "\r[${TIMESTAMP}] Active runners: ${RUNNER_COUNT} | Containers: ${CONTAINER_COUNT} | Waiting: ${i}x2s"

        if [ $RUNNER_COUNT -eq 0 ] && [ $CONTAINER_COUNT -eq 0 ]; then
            echo ""
            success "All runners cleaned up!"
            break
        fi

        sleep 2
    done
    echo ""
fi

# Final status
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      Test Results                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

FINAL_RUNNERS=$(curl -sf "${COORDINATOR_URL}/runners" | jq '. | length')

if [ "$RUNNER_SPAWNED" = "true" ]; then
    success "✓ Dynamic runner spawning: WORKING"
else
    error "✗ Dynamic runner spawning: FAILED"
fi

if [ "$SUCCESS_COUNT" -gt 0 ]; then
    success "✓ Job execution: WORKING (${SUCCESS_COUNT} jobs succeeded)"
else
    warning "⚠ Job execution: No successful jobs"
fi

if [ $FINAL_RUNNERS -eq 0 ]; then
    success "✓ Runner cleanup: WORKING"
else
    warning "⚠ Runner cleanup: ${FINAL_RUNNERS} runner(s) still active (cooldown period)"
fi

echo ""
info "Additional verification:"
echo ""
echo "  • View pipeline: ${GITLAB_URL}/root/autogit/-/pipelines/${PIPELINE_ID}"
echo "  • Check coordinator logs:"
echo "    ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker logs autogit-runner-coordinator --tail 50'"
echo ""
echo "  • Monitor runners in real-time:"
echo "    watch -n 2 'curl -s ${COORDINATOR_URL}/runners | jq'"
echo ""
echo "  • Watch container lifecycle:"
echo "    watch -n 2 'ssh homelab \"DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter name=autogit-runner\"'"
echo ""

success "End-to-end test complete!"
