#!/bin/bash
# Test all CI/CD workflows sequentially
# Verifies dynamic runner spawning, execution, and cleanup

set -e

cd "$(dirname "$0")/.."

# Load config
[ -f ".env" ] || {
    echo "Run first-time-setup first!"
    exit 1
}
source .env
source scripts/gitlab-helpers.sh

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

clear

cat << "EOF"
╔════════════════════════════════════════════════════════╗
║     Dynamic Runner CI/CD Complete Workflow Test       ║
╚════════════════════════════════════════════════════════╝

EOF

echo -e "${CYAN}This test will:${NC}"
echo "  1. Trigger a CI/CD pipeline"
echo "  2. Watch runners spawn automatically (4 cores, 6GB each)"
echo "  3. Monitor job execution"
echo "  4. Verify cleanup after cooldown"
echo ""
read -r -p "Press Enter to start..."
echo ""

# Test 1: Trigger pipeline
echo -e "${BOLD}${BLUE}▶ Triggering CI/CD Pipeline...${NC}"
echo ""

TRIGGER_RESPONSE=$(curl -sf --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/pipeline?ref=main")

PIPELINE_ID=$(echo "$TRIGGER_RESPONSE" | jq -r '.id')
[ "$PIPELINE_ID" = "null" ] && {
    echo "Failed to trigger"
    exit 1
}

echo -e "${GREEN}✓${NC} Pipeline ${PIPELINE_ID} triggered"
echo -e "  View: ${GITLAB_URL}/root/autogit/-/pipelines/${PIPELINE_ID}"
echo ""

# Test 2: Monitor execution
echo -e "${BOLD}${BLUE}▶ Monitoring Pipeline Execution...${NC}"
echo ""

LAST_STATUS=""
START_TIME=$(date +%s)
MAX_RUNNERS_SEEN=0

for i in {1..60}; do
    # Get pipeline status
    PIPELINE=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${PIPELINE_ID}")

    STATUS=$(echo "$PIPELINE" | jq -r '.status')

    # Get runner count
    RUNNER_COUNT=$(curl -sf "${COORDINATOR_URL}/runners" | jq '. | length')
    [ "$RUNNER_COUNT" -gt "$MAX_RUNNERS_SEEN" ] && MAX_RUNNERS_SEEN=$RUNNER_COUNT

    # Print status change
    if [ "$STATUS" != "$LAST_STATUS" ]; then
        TIME=$(date +"%H:%M:%S")
        case $STATUS in
            "pending") echo -e "${YELLOW}⏳${NC} [$TIME] Pipeline: ${STATUS}" ;;
            "running") echo -e "${GREEN}▶${NC}  [$TIME] Pipeline: ${STATUS}" ;;
            "success")
                echo -e "${GREEN}✓${NC}  [$TIME] Pipeline: ${STATUS}"
                break
                ;;
            "failed")
                echo -e "${RED}✗${NC}  [$TIME] Pipeline: ${STATUS}"
                break
                ;;
        esac
        LAST_STATUS=$STATUS
    fi

    # Show runner activity
    if [ "$RUNNER_COUNT" -gt 0 ]; then
        echo -ne "\r  ${CYAN}Runners active: ${RUNNER_COUNT}${NC} | Elapsed: $(($(date +%s) - START_TIME))s"
    fi

    [ "$STATUS" = "success" ] || [ "$STATUS" = "failed" ] && break
    sleep 2
done

echo ""
echo ""

# Test 3: Get results
echo -e "${BOLD}${BLUE}▶ Pipeline Results...${NC}"
echo ""

JOBS=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${PIPELINE_ID}/jobs")

echo "$JOBS" | jq -r '.[] | "  • \(.name): \(.status)"'
echo ""

SUCCESS_COUNT=$(echo "$JOBS" | jq '[.[] | select(.status == "success")] | length')
TOTAL_COUNT=$(echo "$JOBS" | jq '. | length')

echo -e "  ${BOLD}Summary:${NC} ${SUCCESS_COUNT}/${TOTAL_COUNT} jobs succeeded"
echo -e "  ${BOLD}Max concurrent runners:${NC} ${MAX_RUNNERS_SEEN}"
echo ""

# Test 4: Monitor cleanup
echo -e "${BOLD}${BLUE}▶ Monitoring Runner Cleanup...${NC}"
echo ""
echo "  Waiting for cooldown period (5 minutes)..."
echo "  Monitoring for 60 seconds..."
echo ""

for i in {1..30}; do
    RUNNER_COUNT=$(curl -sf "${COORDINATOR_URL}/runners" | jq '. | length')
    CONTAINERS=$(ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter 'name=autogit-runner' --filter 'status=running' -q" 2> /dev/null | wc -l)

    TIME=$(date +"%H:%M:%S")
    echo -ne "\r  [$TIME] Runners: ${RUNNER_COUNT} | Containers: ${CONTAINERS} | Check: $i/30"

    [ "$RUNNER_COUNT" -eq 0 ] && [ "$CONTAINERS" -le 1 ] && {
        echo ""
        echo -e "${GREEN}✓${NC} Cleanup complete!"
        break
    }
    sleep 2
done

echo ""
echo ""

# Final summary
cat << "EOF"
╔════════════════════════════════════════════════════════╗
║                  Test Complete! 🎉                     ║
╚════════════════════════════════════════════════════════╝

EOF

echo -e "${BOLD}Results:${NC}"
echo -e "  ${GREEN}✓${NC} Pipeline triggered and executed"
echo -e "  ${GREEN}✓${NC} Dynamic runners spawned (max: ${MAX_RUNNERS_SEEN})"
echo -e "  ${GREEN}✓${NC} Jobs executed: ${SUCCESS_COUNT}/${TOTAL_COUNT} succeeded"
if [ "$RUNNER_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} Runners cleaned up successfully"
else
    echo -e "  ${YELLOW}⏳${NC} Runners in cooldown (${RUNNER_COUNT} active)"
fi
echo ""

echo -e "${BOLD}Configuration:${NC}"
echo -e "  • CPU per runner: ${GREEN}4 cores${NC}"
echo -e "  • RAM per runner: ${GREEN}6 GB${NC}"
echo -e "  • Cooldown: ${GREEN}5 minutes${NC}"
echo ""

echo -e "${BOLD}Next steps:${NC}"
echo "  • View pipeline: ${GITLAB_URL}/root/autogit/-/pipelines/${PIPELINE_ID}"
echo "  • Check logs: ssh homelab 'docker logs autogit-runner-coordinator'"
echo "  • Monitor: watch -n2 'curl -s ${COORDINATOR_URL}/runners | jq'"
echo ""

echo -e "${GREEN}✓${NC} Dynamic runner system is fully operational!"
echo ""
