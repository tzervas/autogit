#!/bin/bash
# AutoGit First-Time Setup - Complete automated configuration
# This script sets up everything and provides all credentials securely

set -e

HOMELAB_IP="${HOMELAB_IP:-192.168.1.170}"
GITLAB_URL="${GITLAB_URL:-http://${HOMELAB_IP}:3000}"
COORDINATOR_URL="${COORDINATOR_URL:-http://${HOMELAB_IP}:8080}"
GITLAB_ROOT_PASSWORD="${GITLAB_ROOT_PASSWORD:-}"
PROJECT_NAME="${PROJECT_NAME:-autogit}"
SECRETS_FILE="${HOME}/.autogit_secrets"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
header() { echo -e "${BOLD}${CYAN}$1${NC}"; }

clear

cat <<"EOF"

╔════════════════════════════════════════════════════════╗
║                                                        ║
║       █████╗ ██╗   ██╗████████╗ ██████╗                ║
║      ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗               ║
║      ███████║██║   ██║   ██║   ██║   ██║               ║
║      ██╔══██║██║   ██║   ██║   ██║   ██║               ║
║      ██║  ██║╚██████╔╝   ██║   ╚██████╔╝               ║
║      ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝                ║
║                                                        ║
║        ██████╗ ██╗████████╗                            ║
║       ██╔════╝ ██║╚══██╔══╝                            ║
║       ██║  ███╗██║   ██║                               ║
║       ██║   ██║██║   ██║                               ║
║       ╚██████╔╝██║   ██║                               ║
║        ╚═════╝ ╚═╝   ╚═╝                               ║
║                                                        ║
║    Self-Hosted Git + Dynamic CI/CD Runners             ║
║                                                        ║
╚════════════════════════════════════════════════════════╝

EOF

header "    🚀 AutoGit First-Time Setup & Configuration"
echo ""
info "This script will:"
echo "  • Configure GitLab for first-time use"
echo "  • Create API tokens and credentials"
echo "  • Set up the autogit project with CI/CD"
echo "  • Configure dynamic runner management"
echo "  • Securely store and display all credentials"
echo ""
read -r -p "Press Enter to continue..."
echo ""

# Step 1: Check services
header "Step 1: Checking Services"
echo ""

info "Waiting for GitLab..."
RETRIES=0
until curl -sf "${GITLAB_URL}/" >/dev/null 2>&1; do
    RETRIES=$((RETRIES + 1))
    [ $RETRIES -ge 60 ] && {
        error "GitLab timeout"
        exit 1
    }
    echo -n "."
    sleep 5
done
echo ""
success "GitLab is ready"

if curl -sf "${COORDINATOR_URL}/health" >/dev/null 2>&1; then
    success "Runner Coordinator is ready"
else
    error "Runner Coordinator not responding"
    exit 1
fi

# Step 2: Get or generate root password
echo ""
header "Step 2: GitLab Root Password"
echo ""

PASSWORD_FILE="${HOME}/.autogit/gitlab_root_password"

if [ -f "$PASSWORD_FILE" ]; then
    GITLAB_ROOT_PASSWORD=$(cat "$PASSWORD_FILE")
    info "Using existing password from ${PASSWORD_FILE}"
else
    # Try to get from running container
    GITLAB_ROOT_PASSWORD=$(ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec autogit-git-server printenv GITLAB_ROOT_PASSWORD" 2>/dev/null || echo "")

    if [ -z "$GITLAB_ROOT_PASSWORD" ] || [ "$GITLAB_ROOT_PASSWORD" = "CHANGE_ME_SECURE_PASSWORD" ]; then # pragma: allowlist secret
        # Generate new secure password
        info "Generating secure random password..."
        GITLAB_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

        # Save it
        mkdir -p "$(dirname "$PASSWORD_FILE")"
        echo "$GITLAB_ROOT_PASSWORD" >"$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
        success "Generated and saved new password"
    else
        info "Retrieved password from container"
    fi
fi

# Step 3: Create API token
echo ""
header "Step 3: Creating GitLab API Token"
echo ""

TOKEN_SCRIPT="
user = User.find_by_username('root')
user.personal_access_tokens.where(name: 'AutoGit Automation Token').each(&:revoke!)
token = user.personal_access_tokens.create(
  scopes: [:api, :read_api, :write_repository, :read_repository],
  name: 'AutoGit Automation Token',
  expires_at: 365.days.from_now
)
puts token.token if token.persisted?
"

GITLAB_TOKEN=$(ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec autogit-git-server gitlab-rails runner \"$TOKEN_SCRIPT\"" 2>/dev/null | grep -E '^glpat-' | tail -1)

[ -z "$GITLAB_TOKEN" ] && {
    error "Token creation failed"
    exit 1
}
success "API token created"

# Step 4: Verify API
echo ""
header "Step 4: Verifying API Access"
echo ""

USER_INFO=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_URL}/api/v4/user")
USERNAME=$(echo "$USER_INFO" | jq -r '.username')

[ "$USERNAME" != "root" ] && {
    error "API verification failed"
    exit 1
}
success "API verified: ${USERNAME}"

# Step 5: Setup project
echo ""
header "Step 5: Setting Up Project"
echo ""

PROJECTS=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_URL}/api/v4/projects?search=${PROJECT_NAME}")
PROJECT_ID=$(echo "$PROJECTS" | jq -r '.[0].id')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
    CREATE_RESPONSE=$(curl -sf --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --header "Content-Type: application/json" --data '{"name": "'"${PROJECT_NAME}"'", "visibility": "private", "initialize_with_readme": true}' "${GITLAB_URL}/api/v4/projects")
    PROJECT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id')
    success "Project created (ID: ${PROJECT_ID})"
else
    success "Project found (ID: ${PROJECT_ID})"
fi

PROJECT_URL="${GITLAB_URL}/root/${PROJECT_NAME}"

# Step 6: Add CI configuration
echo ""
header "Step 6: Configuring CI/CD"
echo ""

CI_CONTENT=$(cat .gitlab-ci-simple.yml | base64 -w 0)
curl -sf --request PUT --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --header "Content-Type: application/json" --data '{"branch": "main", "content": "'"${CI_CONTENT}"'", "commit_message": "Add CI/CD", "encoding": "base64"}' "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/.gitlab-ci.yml" >/dev/null 2>&1 ||
    curl -sf --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --header "Content-Type: application/json" --data '{"branch": "main", "content": "'"${CI_CONTENT}"'", "commit_message": "Add CI/CD", "encoding": "base64"}' "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/.gitlab-ci.yml" >/dev/null 2>&1

success "CI/CD configured"

# Step 7: Save configuration
echo ""
header "Step 7: Saving Configuration"
echo ""

cat >.env.gitlab <<EOF
GITLAB_URL=${GITLAB_URL}
GITLAB_TOKEN=${GITLAB_TOKEN}
GITLAB_PROJECT_ID=${PROJECT_ID}
COORDINATOR_URL=${COORDINATOR_URL}
RUNNER_CPU_LIMIT=4.0
RUNNER_MEM_LIMIT=6g
EOF
chmod 600 .env.gitlab

cat >"$SECRETS_FILE" <<EOF
GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD}
GITLAB_TOKEN=${GITLAB_TOKEN}
GITLAB_URL=${GITLAB_URL}
PROJECT_URL=${PROJECT_URL}
EOF
chmod 600 "$SECRETS_FILE"

success "Configuration saved"

# Display credentials
echo ""
echo ""
cat <<"EOF"
╔════════════════════════════════════════════════════════╗
║              🎉 Setup Complete! 🎉                     ║
╚════════════════════════════════════════════════════════╝

EOF

header "📋 Your AutoGit Credentials"
echo ""
echo -e "${BOLD}GitLab Web Interface${NC}"
echo -e "  URL:      ${MAGENTA}${GITLAB_URL}${NC}"
echo -e "  Username: ${GREEN}root${NC}"
echo -e "  Password: ${YELLOW}${GITLAB_ROOT_PASSWORD}${NC}"
echo ""
echo -e "${BOLD}API Token${NC}"
echo -e "  ${YELLOW}${GITLAB_TOKEN}${NC}"
echo ""
echo -e "${BOLD}Project${NC}"
echo -e "  ${MAGENTA}${PROJECT_URL}${NC}"
echo ""
echo -e "${BOLD}Runner Config${NC}"
echo -e "  CPU: ${GREEN}4 cores${NC} | RAM: ${GREEN}6GB${NC} | Cooldown: ${GREEN}5min${NC}"
echo ""

warning "Credentials saved to: ${SECRETS_FILE}"
echo ""

header "🚀 Quick Start"
echo ""
echo "  source scripts/gitlab-helpers.sh    # Load helpers"
echo "  gitlab-trigger                       # Trigger pipeline"
echo "  watch-runners                        # Watch runners"
echo ""

success "Ready to test! Run: bash scripts/test-dynamic-runners.sh"
echo ""
