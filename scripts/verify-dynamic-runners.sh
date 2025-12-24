#!/bin/bash
# AutoGit Dynamic Runner Verification Script
# This script helps verify that dynamic runners are working correctly

set -e

HOMELAB_IP="${HOMELAB_IP:-192.168.1.170}"
GITLAB_URL="${GITLAB_URL:-http://${HOMELAB_IP}:3000}"
COORDINATOR_URL="${COORDINATOR_URL:-http://${HOMELAB_IP}:8080}"
PROJECT_NAME="${PROJECT_NAME:-autogit}"
TOKEN_FILE="${HOME}/.autogit_gitlab_token"
UNATTENDED="${UNATTENDED:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

check_service() {
    local name=$1
    local url=$2
    local endpoint=${3:-/health}

    if curl -sf "${url}${endpoint}" >/dev/null 2>&1; then
        success "${name} is UP"
        return 0
    else
        error "${name} is DOWN"
        return 1
    fi
}

# Main script
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        AutoGit Dynamic Runner Verification Script            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if GITLAB_TOKEN is set or can be loaded
if [ -z "${GITLAB_TOKEN}" ]; then
    # Try to load from file
    if [ -f "$TOKEN_FILE" ]; then
        GITLAB_TOKEN=$(cat "$TOKEN_FILE")
        info "Loaded GitLab token from ${TOKEN_FILE}"
        export GITLAB_TOKEN
    elif [ -f ".env.gitlab" ]; then
        source .env.gitlab
        info "Loaded configuration from .env.gitlab"
    fi
fi

# If still no token, run automated setup
if [ -z "${GITLAB_TOKEN}" ]; then
    if [ "$UNATTENDED" = "true" ]; then
        warning "No GitLab token found, running automated setup..."
        bash scripts/setup-gitlab-automation.sh

        # Reload token
        if [ -f "$TOKEN_FILE" ]; then
            GITLAB_TOKEN=$(cat "$TOKEN_FILE")
            export GITLAB_TOKEN
        elif [ -f ".env.gitlab" ]; then
            source .env.gitlab
        fi

        if [ -z "${GITLAB_TOKEN}" ]; then
            error "Automated setup failed to create token"
            exit 1
        fi
    else
        warning "GITLAB_TOKEN not set"
        echo ""
        echo "You have two options:"
        echo ""
        echo "1. Run automated setup (recommended):"
        echo "   bash scripts/setup-gitlab-automation.sh"
        echo ""
        echo "2. Manual setup:"
        echo "   • Go to: ${GITLAB_URL}/-/user_settings/personal_access_tokens"
        echo "   • Create a token with 'api' and 'write_repository' scopes"
        echo "   • Export it: export GITLAB_TOKEN='your_token_here'"
        echo ""
        read -p "Run automated setup now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            bash scripts/setup-gitlab-automation.sh

            # Reload configuration
            if [ -f ".env.gitlab" ]; then
                source .env.gitlab
            fi
        else
            warning "Continuing with limited functionality..."
        fi
    fi
fi

# Step 1: Check services
echo ""
info "Step 1: Checking service health..."
echo "────────────────────────────────────────────────────────────────"

check_service "Runner Coordinator" "$COORDINATOR_URL" "/health"
COORDINATOR_UP=$?

if curl -sf "${GITLAB_URL}/" >/dev/null 2>&1; then
    success "GitLab is UP"
    GITLAB_UP=0
else
    error "GitLab is DOWN"
    GITLAB_UP=1
fi

if [ $COORDINATOR_UP -ne 0 ] || [ $GITLAB_UP -ne 0 ]; then
    error "Required services are not running!"
    echo ""
    info "Try running: bash scripts/check-homelab-status.sh"
    exit 1
fi

# Step 2: Check current runners
echo ""
info "Step 2: Checking active runners..."
echo "────────────────────────────────────────────────────────────────"

RUNNERS=$(curl -sf "${COORDINATOR_URL}/runners" 2>/dev/null || echo "[]")
RUNNER_COUNT=$(echo "$RUNNERS" | jq -r '. | length' 2>/dev/null || echo "0")

if [ "$RUNNER_COUNT" -eq 0 ]; then
    info "No active runners (expected when idle)"
else
    success "Found ${RUNNER_COUNT} active runner(s):"
    echo "$RUNNERS" | jq -r '.[] | "  • \(.name): \(.status) (\(.architecture))"'
fi

# Step 3: Check containers on homelab
echo ""
info "Step 3: Checking containers on homelab..."
echo "────────────────────────────────────────────────────────────────"

CONTAINERS=$(ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter 'name=autogit' --format '{{.Names}}\t{{.Status}}'" 2>/dev/null || echo "")

if [ -n "$CONTAINERS" ]; then
    echo "$CONTAINERS" | while IFS=$'\t' read -r name status; do
        if [[ $name == *"coordinator"* ]] || [[ $name == *"git-server"* ]]; then
            success "${name}: ${status}"
        else
            info "${name}: ${status}"
        fi
    done
else
    warning "Could not retrieve container information"
fi

# Step 4: Check GitLab project (if token available)
echo ""
info "Step 4: Checking GitLab project..."
echo "────────────────────────────────────────────────────────────────"

if [ -n "${GITLAB_TOKEN}" ]; then
    # Try to find the autogit project
    PROJECTS=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects?search=${PROJECT_NAME}" 2>/dev/null || echo "[]")

    PROJECT_COUNT=$(echo "$PROJECTS" | jq -r '. | length' 2>/dev/null || echo "0")

    if [ "$PROJECT_COUNT" -eq 0 ]; then
        warning "Project '${PROJECT_NAME}' not found in GitLab"
        echo ""
        read -p "Would you like to create it? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Creating project '${PROJECT_NAME}'..."

            CREATE_RESPONSE=$(curl -sf --request POST \
                --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
                --header "Content-Type: application/json" \
                --data "{
                    \"name\": \"${PROJECT_NAME}\",
                    \"visibility\": \"private\",
                    \"initialize_with_readme\": true
                }" \
                "${GITLAB_URL}/api/v4/projects" 2>/dev/null || echo "{}")

            PROJECT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id' 2>/dev/null)

            if [ -n "$PROJECT_ID" ] && [ "$PROJECT_ID" != "null" ]; then
                success "Project created successfully (ID: ${PROJECT_ID})"

                # Add the example CI file
                info "Adding .gitlab-ci.yml..."

                if curl -sf --request POST \
                    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
                    --header "Content-Type: application/json" \
                    --data "{
                        \"branch\": \"main\",
                        \"content\": \"${ENCODED_CONTENT}\",
                        \"commit_message\": \"Add CI/CD configuration\",
                        \"encoding\": \"base64\"
                    }" \
                    "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/.gitlab-ci.yml" >/dev/null 2>&1; then
                    success "CI configuration added"
                else
                    warning "Could not add CI configuration automatically"
                    info "You can manually add it from .gitlab-ci.example.yml"
                fi
            else
                error "Failed to create project"
            fi
        fi
    else
        PROJECT_ID=$(echo "$PROJECTS" | jq -r '.[0].id')
        PROJECT_PATH=$(echo "$PROJECTS" | jq -r '.[0].path_with_namespace')
        success "Found project: ${PROJECT_PATH} (ID: ${PROJECT_ID})"

        # Check if CI file exists
        CI_CHECK=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
            "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/.gitlab-ci.yml?ref=main" 2>/dev/null || echo "{}")

        if echo "$CI_CHECK" | jq -e '.content' >/dev/null 2>&1; then
            success "CI configuration found"
        else
            warning "No .gitlab-ci.yml found in project"
            info "Consider adding the example from .gitlab-ci.example.yml"
        fi
    fi
else
    warning "Skipping project check (no GitLab token)"
    info "Set GITLAB_TOKEN to enable project operations"
fi

# Step 5: Test runner spawn capability
echo ""
info "Step 5: Testing runner spawn capability..."
echo "────────────────────────────────────────────────────────────────"

info "Dynamic runners spawn automatically when:"
echo "  1. A CI/CD pipeline is triggered in GitLab"
echo "  2. A job requires execution"
echo "  3. No suitable idle runner is available"
echo ""
info "Runners cleanup automatically after:"
echo "  • Job completion"
echo "  • Cooldown period (default: 5 minutes)"
echo "  • No new jobs assigned"

# Step 6: Provide next actions
echo ""
info "Step 6: Next actions to verify dynamic runners..."
echo "────────────────────────────────────────────────────────────────"

if [ -n "${GITLAB_TOKEN}" ] && [ -n "${PROJECT_ID}" ]; then
    echo ""
    success "Your environment is ready to test!"
    echo ""
    info "Test dynamic runner behavior:"
    echo ""
    echo "  1. Trigger a pipeline:"
    echo '     curl --request POST \'
    echo '       --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \'
    echo "       \"${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/ref/main/trigger/pipeline\""
    echo ""
    echo "  2. Or push a commit to the project"
    echo ""
    echo "  3. Monitor runners in real-time:"
    echo "     watch -n 2 'curl -s ${COORDINATOR_URL}/runners | jq'"
    echo ""
    echo "  4. Watch containers being created/destroyed:"
    echo "     watch -n 2 'ssh homelab \"DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter name=autogit-runner\"'"
    echo ""
    echo "  5. View coordinator logs:"
    echo '     ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker logs -f autogit-runner-coordinator"'
    echo ""
else
    echo ""
    warning "Manual setup required"
    echo ""
    info "Complete these steps:"
    echo ""
    echo "  1. Login to GitLab: ${GITLAB_URL}"
    echo "     Username: root"
    echo "     Password: (from GITLAB_ROOT_PASSWORD env var)"
    echo ""
    echo "  2. Create a personal access token"
    echo "     Settings → Access Tokens → Create with 'api' scope"
    echo ""
    echo "  3. Export the token:"
    echo "     export GITLAB_TOKEN='your_token_here'"
    echo ""
    echo "  4. Run this script again:"
    echo "     bash scripts/verify-dynamic-runners.sh"
    echo ""
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                          Summary                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

if [ $COORDINATOR_UP -eq 0 ] && [ $GITLAB_UP -eq 0 ]; then
    success "All services are operational"
else
    error "Some services need attention"
fi

if [ "$RUNNER_COUNT" -gt 0 ]; then
    info "${RUNNER_COUNT} runner(s) currently active"
else
    info "No active runners (will spawn on-demand)"
fi

echo ""
info "Documentation:"
echo "  • Dynamic Runner Testing: docs/runners/dynamic-runner-testing.md"
echo "  • Example CI Config: .gitlab-ci.example.yml"
echo ""

success "Verification complete!"
