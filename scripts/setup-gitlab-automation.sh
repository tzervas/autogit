#!/bin/bash
# AutoGit GitLab Automation Setup
# This script automatically sets up GitLab with a token and test project

set -e

HOMELAB_IP="${HOMELAB_IP:-192.168.1.170}"
GITLAB_URL="${GITLAB_URL:-http://${HOMELAB_IP}:3000}"
COORDINATOR_URL="${COORDINATOR_URL:-http://${HOMELAB_IP}:8080}"
GITLAB_ROOT_PASSWORD="${GITLAB_ROOT_PASSWORD:-CHANGE_ME_SECURE_PASSWORD}"
PROJECT_NAME="${PROJECT_NAME:-autogit}"
TOKEN_FILE="${HOME}/.autogit_gitlab_token"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          AutoGit GitLab Automation Setup                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Wait for GitLab to be ready
info "Waiting for GitLab to be ready..."
RETRIES=0
MAX_RETRIES=60
until curl -sf "${GITLAB_URL}/-/readiness" > /dev/null 2>&1 || curl -sf "${GITLAB_URL}/" > /dev/null 2>&1; do
    RETRIES=$((RETRIES + 1))
    if [ $RETRIES -ge $MAX_RETRIES ]; then
        error "GitLab did not become ready in time"
        exit 1
    fi
    echo -n "."
    sleep 5
done
echo ""
success "GitLab is ready"

# Step 2: Get or create GitLab personal access token
info "Setting up GitLab personal access token..."

# Check if we already have a saved token
if [ -f "$TOKEN_FILE" ]; then
    GITLAB_TOKEN=$(cat "$TOKEN_FILE")
    info "Found existing token in ${TOKEN_FILE}"

    # Verify token works
    if curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_URL}/api/v4/user" > /dev/null 2>&1; then
        success "Existing token is valid"
    else
        warning "Existing token is invalid, will create new one"
        rm -f "$TOKEN_FILE"
        GITLAB_TOKEN=""
    fi
fi

# Create new token if needed
if [ -z "$GITLAB_TOKEN" ]; then
    info "Creating new personal access token via GitLab Rails console..."

    # Generate token using GitLab Rails console
    TOKEN_SCRIPT="
user = User.find_by_username('root')
token = user.personal_access_tokens.create(
  scopes: [:api, :read_api, :write_repository, :read_repository],
  name: 'AutoGit Automation Token',
  expires_at: 365.days.from_now
)
puts token.token
"

    GITLAB_TOKEN=$(ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec autogit-git-server gitlab-rails runner \"$TOKEN_SCRIPT\"" 2> /dev/null | grep -v "^Loading" | tail -1)

    if [ -n "$GITLAB_TOKEN" ] && [ "$GITLAB_TOKEN" != "null" ]; then
        success "Created new personal access token"
        echo "$GITLAB_TOKEN" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        info "Token saved to ${TOKEN_FILE}"
    else
        error "Failed to create personal access token"
        exit 1
    fi
fi

export GITLAB_TOKEN

# Step 3: Verify API access
info "Verifying API access..."
USER_INFO=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_URL}/api/v4/user" 2> /dev/null || echo "{}")
USERNAME=$(echo "$USER_INFO" | jq -r '.username' 2> /dev/null || echo "")

if [ -n "$USERNAME" ] && [ "$USERNAME" != "null" ]; then
    success "Authenticated as: ${USERNAME}"
else
    error "Failed to authenticate with GitLab API"
    exit 1
fi

# Step 4: Create or update autogit project
info "Setting up project: ${PROJECT_NAME}..."

# Check if project exists
PROJECTS=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects?search=${PROJECT_NAME}" 2> /dev/null || echo "[]")
PROJECT_ID=$(echo "$PROJECTS" | jq -r '.[0].id' 2> /dev/null)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
    # Create new project
    info "Creating project '${PROJECT_NAME}'..."

    CREATE_RESPONSE=$(curl -sf --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"name\": \"${PROJECT_NAME}\",
            \"visibility\": \"private\",
            \"initialize_with_readme\": true,
            \"description\": \"AutoGit - Self-hosted Git server with dynamic CI/CD runners\"
        }" \
        "${GITLAB_URL}/api/v4/projects" 2> /dev/null || echo "{}")

    PROJECT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id' 2> /dev/null)

    if [ -n "$PROJECT_ID" ] && [ "$PROJECT_ID" != "null" ]; then
        success "Project created (ID: ${PROJECT_ID})"
    else
        error "Failed to create project"
        echo "$CREATE_RESPONSE" | jq . 2> /dev/null || echo "$CREATE_RESPONSE"
        exit 1
    fi
else
    success "Project already exists (ID: ${PROJECT_ID})"
fi

# Step 5: Add CI/CD configuration
info "Adding CI/CD configuration..."

if [ ! -f ".gitlab-ci.example.yml" ]; then
    error "CI configuration file not found: .gitlab-ci.example.yml"
    exit 1
fi

# Encode CI file content
CI_CONTENT=$(cat .gitlab-ci.example.yml | base64 -w 0)

# Prepare CI config data for API
CI_CONFIG_DATA="{
    \"branch\": \"main\",
    \"content\": \"${CI_CONTENT}\",
    \"commit_message\": \"Add CI/CD configuration\"
}"

# Check if .gitlab-ci.yml already exists
CI_CHECK=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/.gitlab-ci.yml?ref=main" 2> /dev/null || echo "{}")

if echo "$CI_CHECK" | jq -e '.content' > /dev/null 2>&1; then
    info "Updating existing .gitlab-ci.yml..."

    if curl -sf --request PUT \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "${CI_CONFIG_DATA}" \
        "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/.gitlab-ci.yml" > /dev/null 2>&1; then
        success "CI configuration updated"
    else
        warning "Failed to update CI configuration"
    fi
else
    info "Creating .gitlab-ci.yml..."

    if curl -sf --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "${CI_CONFIG_DATA}" \
        "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/.gitlab-ci.yml" > /dev/null 2>&1; then
        success "CI configuration added"
    else
        warning "Failed to add CI configuration"
    fi
fi

# Step 6: Register a GitLab runner with the coordinator
info "Registering GitLab runner..."

# Get runner registration token from project
RUNNER_TOKEN=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}" 2> /dev/null | jq -r '.runners_token' 2> /dev/null)

if [ -n "$RUNNER_TOKEN" ] && [ "$RUNNER_TOKEN" != "null" ]; then
    info "Got runner registration token"

    # Register runner via coordinator (if endpoint exists)
    # For now, we'll register directly with GitLab
    info "Runner will be registered dynamically when jobs are triggered"
else
    warning "Could not get runner registration token"
fi

# Step 7: Export environment configuration
info "Creating environment configuration..."

cat >> .env << EOF
# AutoGit GitLab Configuration
# Generated on $(date)

GITLAB_URL=${GITLAB_URL}
GITLAB_TOKEN=${GITLAB_TOKEN}
GITLAB_PROJECT_ID=${PROJECT_ID}
COORDINATOR_URL=${COORDINATOR_URL}
EOF

chmod 600 .env
success "Configuration saved to .env"

# Step 8: Create helper aliases
info "Creating helper scripts..."

cat > scripts/gitlab-helpers.sh << 'EOFHELPER'
#!/bin/bash
# GitLab Helper Functions

# Source the environment
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

# List projects
gitlab-projects() {
    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects" | jq -r '.[] | "\(.id)\t\(.name)\t\(.web_url)"'
}

# Trigger pipeline
gitlab-trigger() {
    local project_id=${1:-$GITLAB_PROJECT_ID}
    local ref=${2:-main}

    echo "Triggering pipeline for project ${project_id} on ${ref}..."
    curl -sf --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/pipeline?ref=${ref}" | jq .
}

# List pipelines
gitlab-pipelines() {
    local project_id=${1:-$GITLAB_PROJECT_ID}

    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/pipelines" | \
        jq -r '.[] | "\(.id)\t\(.status)\t\(.ref)\t\(.created_at)"'
}

# Get pipeline jobs
gitlab-jobs() {
    local project_id=${1:-$GITLAB_PROJECT_ID}
    local pipeline_id=$2

    if [ -z "$pipeline_id" ]; then
        # Get latest pipeline
        pipeline_id=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
            "${GITLAB_URL}/api/v4/projects/${project_id}/pipelines" | jq -r '.[0].id')
    fi

    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/pipelines/${pipeline_id}/jobs" | \
        jq -r '.[] | "\(.id)\t\(.name)\t\(.status)\t\(.stage)"'
}

# Watch runners
watch-runners() {
    watch -n 2 "curl -s ${COORDINATOR_URL}/runners | jq '.'"
}

# Watch containers
watch-containers() {
    watch -n 2 "ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter name=autogit-runner'"
}

# Get job log
gitlab-job-log() {
    local project_id=${1:-$GITLAB_PROJECT_ID}
    local job_id=$2

    if [ -z "$job_id" ]; then
        echo "Usage: gitlab-job-log [project_id] <job_id>"
        return 1
    fi

    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/jobs/${job_id}/trace"
}

# Show help
gitlab-help() {
    cat << 'EOF'
GitLab Helper Commands:

  gitlab-projects          - List all projects
  gitlab-trigger [id] [ref]- Trigger pipeline (default: autogit, main)
  gitlab-pipelines [id]    - List pipelines for project
  gitlab-jobs [id] [pid]   - List jobs for pipeline
  gitlab-job-log [id] <jid>- Get job log
  watch-runners            - Watch active runners in real-time
  watch-containers         - Watch runner containers on homelab

Environment:
  GITLAB_URL:       ${GITLAB_URL}
  GITLAB_PROJECT_ID:${GITLAB_PROJECT_ID}
  COORDINATOR_URL:  ${COORDINATOR_URL}

EOF
}

# Export functions if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f gitlab-projects gitlab-trigger gitlab-pipelines gitlab-jobs
    export -f gitlab-job-log watch-runners watch-containers gitlab-help
    echo "GitLab helper functions loaded. Run 'gitlab-help' for usage."
fi
EOFHELPER

chmod +x scripts/gitlab-helpers.sh
success "Helper scripts created"

# Step 9: Summary and next steps
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

success "GitLab automation is configured"
echo ""
info "Configuration:"
echo "  • GitLab URL:     ${GITLAB_URL}"
echo "  • Project:        ${PROJECT_NAME} (ID: ${PROJECT_ID})"
echo "  • Token saved:    ${TOKEN_FILE}"
echo "  • Environment:    .env"
echo ""

info "Quick start:"
echo ""
echo "  1. Load helper functions:"
echo "     source scripts/gitlab-helpers.sh"
echo ""
echo "  2. Trigger a test pipeline:"
echo "     gitlab-trigger"
echo ""
echo "  3. Watch runners spawn and cleanup:"
echo "     watch-runners"
echo ""
echo "  4. Monitor in another terminal:"
echo "     watch-containers"
echo ""

info "Web interface:"
echo "  • GitLab:  ${GITLAB_URL}"
echo "  • Project: ${GITLAB_URL}/${USERNAME}/${PROJECT_NAME}"
echo ""

success "You can now test dynamic runners!"
echo ""
