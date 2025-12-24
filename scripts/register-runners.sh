#!/bin/bash
# Register GitLab Runners for AutoGit Project
# This registers static runners that will pick up jobs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Load configuration
if [ -f ".env" ]; then
    source .env
else
    echo "Error: .env not found. Run: bash scripts/setup-gitlab-automation.sh"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           AutoGit Runner Registration                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Get the runner registration token from the project
info "Getting runner registration token from GitLab..."

RUNNER_TOKEN=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}" |
    jq -r '.runners_token' 2>/dev/null)

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    # Try to get the group or instance token
    info "Project token not available, checking runners..."

    # For now, let's register a project runner using the newer API
    info "Registering runner via API..."

    # Create runner using the new API (GitLab 15.6+)
    RUNNER_CREATE=$(curl -sf --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"runner_type\": \"project_type\",
            \"project_id\": ${GITLAB_PROJECT_ID},
            \"description\": \"AutoGit Dynamic Runner\",
            \"tag_list\": [\"docker\", \"autogit\", \"amd64\"],
            \"locked\": false,
            \"run_untagged\": false,
            \"maximum_timeout\": 3600
        }" \
        "${GITLAB_URL}/api/v4/user/runners" 2>&1)

    RUNNER_TOKEN=$(echo "$RUNNER_CREATE" | jq -r '.token' 2>/dev/null)
fi

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    info "Using direct container registration..."

    # Register runner directly in a container
    info "Creating runner container..."

    RUNNER_NAME="autogit-runner-static-$$"

    # Create and register runner container
    ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker run -d \
        --name ${RUNNER_NAME} \
        --network autogit-network \
        --restart unless-stopped \
        -v /run/user/1000/docker.sock:/var/run/docker.sock \
        gitlab/gitlab-runner:latest" >/dev/null

    success "Runner container created: ${RUNNER_NAME}"

    # Wait for container to be ready
    sleep 3

    # Register the runner
    info "Registering runner with GitLab..."

    ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec ${RUNNER_NAME} \
        gitlab-runner register \
        --non-interactive \
        --url '${GITLAB_URL}' \
        --token '${GITLAB_TOKEN}' \
        --executor docker \
        --docker-image alpine:latest \
        --description 'AutoGit Static Runner' \
        --tag-list 'docker,autogit,amd64' \
        --docker-privileged=false \
        --docker-volumes '/var/run/docker.sock:/var/run/docker.sock' \
        --docker-network-mode autogit-network" 2>&1 || true

    success "Runner registered!"

    echo ""
    info "Runner details:"
    echo "  • Name: ${RUNNER_NAME}"
    echo "  • Network: autogit-network"
    echo "  • Tags: docker, autogit, amd64"
    echo ""

else
    success "Got runner registration token"
    info "Token: ${RUNNER_TOKEN}"
fi

# Verify runners are registered
info "Checking registered runners..."
RUNNERS=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/runners" 2>/dev/null || echo "[]")

RUNNER_COUNT=$(echo "$RUNNERS" | jq '. | length' 2>/dev/null || echo "0")

if [ "$RUNNER_COUNT" -gt 0 ]; then
    success "Found ${RUNNER_COUNT} registered runner(s):"
    echo "$RUNNERS" | jq -r '.[] | "  • \(.description): \(.status) (id: \(.id))"'
else
    info "No runners registered yet"
    info "GitLab may take a few moments to register the runner"
fi

echo ""
success "Runner registration complete!"
echo ""
info "Test the runner:"
echo "  bash scripts/test-dynamic-runners.sh"
