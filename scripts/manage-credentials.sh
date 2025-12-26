#!/usr/bin/env bash
#
# manage-credentials.sh - Secure credential management for AutoGit
#
# This script manages GitHub and GitLab tokens securely using the system keyring.
# Tokens are stored with proper scoping and can be retrieved for specific use cases.
#
# Usage:
#   ./manage-credentials.sh store-ghcr-token    # Store GHCR PAT in keyring
#   ./manage-credentials.sh get-ghcr-token      # Retrieve GHCR PAT
#   ./manage-credentials.sh update-gitlab       # Push token to GitLab CI/CD
#   ./manage-credentials.sh test-ghcr           # Test GHCR authentication
#   ./manage-credentials.sh setup               # Full setup wizard
#
# Security:
#   - Tokens stored in GNOME Keyring (encrypted at rest)
#   - Minimal scope: only packages permissions for GHCR
#   - Protected branches only in GitLab
#

set -euo pipefail

# Configuration
KEYRING_SERVICE="autogit-credentials"
GHCR_REGISTRY="ghcr.io"
GHCR_OWNER="tzervas"
GITLAB_API_URL="http://192.168.1.170:3000/api/v4"
GITLAB_PROJECT_ID="1"
SECRETS_FILE=".env"

# Load secrets from file if it exists
if [[ -f $SECRETS_FILE ]]; then
    # shellcheck source=/dev/null
    source "$SECRETS_FILE"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Check dependencies
check_dependencies() {
    local missing=()
    command -v secret-tool &> /dev/null || missing+=("secret-tool (libsecret-tools)")
    command -v curl &> /dev/null || missing+=("curl")
    command -v jq &> /dev/null || missing+=("jq")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# Store GHCR token in keyring
store_ghcr_token() {
    log_info "Storing GHCR token in system keyring..."

    local token="${GH_TOKEN:-}"

    if [[ -z $token ]]; then
        echo ""
        echo "============================================================"
        echo "🔐 GitHub Classic PAT Setup (Required for GHCR)"
        echo "============================================================"
        echo ""
        echo "Note: Fine-grained tokens do not yet support GHCR for personal accounts."
        echo ""
        echo "1. Go to: https://github.com/settings/tokens/new"
        echo ""
        echo "2. Configure the token:"
        echo "   • Note: autogit-ghcr-push"
        echo "   • Expiration: 90 days (recommended)"
        echo ""
        echo "3. Select Scopes (Minimal):"
        echo "   • [X] write:packages -> (Allows uploading images to GHCR)"
        echo "   • [X] read:packages  -> (Allows pulling images)"
        echo "   • [ ] (No other scopes needed for registry access)"
        echo ""
        echo "4. Click 'Generate token' and copy the ghp_* token"
        echo ""
        echo "============================================================"
        echo ""

        # Read token securely (no echo)
        read -s -p "Paste your GitHub PAT (ghp_*): " token
        echo ""
    fi

    # Validate token format
    if [[ ! $token =~ ^ghp_ ]]; then
        log_error "Invalid token format. Expected ghp_*"
        return 1
    fi

    # Validate token works with GitHub API
    log_info "Validating token with GitHub API..."
    local response
    response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $token" \
        "https://api.github.com/user" 2> /dev/null)
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | head -n -1)

    if [[ $http_code != "200" ]]; then
        log_error "Token validation failed (HTTP $http_code)"
        echo "$body" | jq -r '.message // "Unknown error"' 2> /dev/null
        return 1
    fi

    local username=$(echo "$body" | jq -r '.login')
    log_success "Token valid for user: $username"

    # Store in keyring
    echo -n "$token" | secret-tool store --label="AutoGit GHCR Token" \
        service "$KEYRING_SERVICE" \
        type "ghcr-pat" \
        username "$username" \
        registry "$GHCR_REGISTRY"

    log_success "Token stored securely in system keyring"

    # Store username for reference
    echo -n "$username" | secret-tool store --label="AutoGit GHCR Username" \
        service "$KEYRING_SERVICE" \
        type "ghcr-username"

    return 0
}

# Retrieve GHCR token from keyring
get_ghcr_token() {
    local token
    token=$(secret-tool lookup service "$KEYRING_SERVICE" type "ghcr-pat" 2> /dev/null) || {
        log_error "GHCR token not found in keyring"
        log_info "Run: $0 store-ghcr-token"
        return 1
    }
    echo "$token"
}

# Get stored username
get_ghcr_username() {
    secret-tool lookup service "$KEYRING_SERVICE" type "ghcr-username" 2> /dev/null || echo "$GHCR_OWNER"
}

# Test GHCR authentication
test_ghcr_auth() {
    log_info "Testing GHCR authentication..."

    local token username
    token=$(get_ghcr_token) || return 1
    username=$(get_ghcr_username)

    # Test Docker login
    if echo "$token" | docker login "$GHCR_REGISTRY" -u "$username" --password-stdin 2>&1 | grep -q "Login Succeeded"; then
        log_success "GHCR authentication successful!"
        docker logout "$GHCR_REGISTRY" &> /dev/null
        return 0
    else
        log_error "GHCR authentication failed"
        return 1
    fi
}

# Store GitLab API token
store_gitlab_token() {
    log_info "Storing GitLab API token in keyring..."

    local token="${GL_TOKEN:-}"

    if [[ -z $token ]]; then
        echo ""
        echo "============================================================"
        echo "🔐 GitLab Personal Access Token (PAT) Setup"
        echo "============================================================"
        echo ""
        echo "1. Go to your GitLab instance: http://192.168.1.170:3000/-/profile/personal_access_tokens"
        echo ""
        echo "2. Configure the token:"
        echo "   • Token name: autogit-credential-manager"
        echo "   • Expiration: 90 days (recommended)"
        echo ""
        echo "3. Select Scopes:"
        echo "   • [X] api (Required to manage CI/CD variables)"
        echo ""
        echo "4. Click 'Create personal access token' and copy the glpat-* token"
        echo ""
        echo "============================================================"
        echo ""

        read -s -p "Enter GitLab API token (glpat-*): " token
        echo ""
    fi

    # Validate token format
    if [[ ! $token =~ ^glpat- ]]; then
        log_error "Invalid token format. Expected glpat-*"
        return 1
    fi

    echo -n "$token" | secret-tool store --label="AutoGit GitLab API Token" \
        service "$KEYRING_SERVICE" \
        type "gitlab-api" \
        url "$GITLAB_API_URL"

    log_success "GitLab token stored in keyring"
}

# Update GitLab CI/CD variable
update_gitlab_variable() {
    log_info "Updating GitLab CI/CD variable..."

    local token username
    token=$(get_ghcr_token) || return 1
    username=$(get_ghcr_username)

    # Check for GitLab API token
    local gitlab_token
    gitlab_token=$(secret-tool lookup service "$KEYRING_SERVICE" type "gitlab-api" 2> /dev/null) || {
        log_error "GitLab API token not found in keyring"
        log_info "Run: $0 store-gitlab-token"
        return 1
    }

    # Update GHCR_TOKEN variable
    local response
    response=$(curl -s -w "\n%{http_code}" --request PUT \
        --header "PRIVATE-TOKEN: $gitlab_token" \
        "$GITLAB_API_URL/projects/$GITLAB_PROJECT_ID/variables/GHCR_TOKEN" \
        --form "value=$token" \
        --form "protected=true" \
        --form "masked=true")

    local http_code=$(echo "$response" | tail -1)

    if [[ $http_code == "200" ]]; then
        log_success "GHCR_TOKEN updated in GitLab"
    else
        log_error "Failed to update GitLab variable (HTTP $http_code)"
        return 1
    fi

    # Update GHCR_USER variable
    response=$(curl -s -w "\n%{http_code}" --request PUT \
        --header "PRIVATE-TOKEN: $gitlab_token" \
        "$GITLAB_API_URL/projects/$GITLAB_PROJECT_ID/variables/GHCR_USER" \
        --form "value=$username" \
        --form "protected=true" \
        --form "masked=false")

    http_code=$(echo "$response" | tail -1)

    if [[ $http_code == "200" ]]; then
        log_success "GHCR_USER updated in GitLab"
    else
        log_warn "Failed to update GHCR_USER (HTTP $http_code) - may already be correct"
    fi

    return 0
}

# List stored credentials
list_credentials() {
    log_info "Stored credentials in keyring:"
    echo ""

    # Check GHCR token
    if secret-tool lookup service "$KEYRING_SERVICE" type "ghcr-pat" &> /dev/null; then
        local username=$(get_ghcr_username)
        echo "  ✅ GHCR PAT (user: $username)"
    else
        echo "  ❌ GHCR PAT (not stored)"
    fi

    # Check GitLab token
    if secret-tool lookup service "$KEYRING_SERVICE" type "gitlab-api" &> /dev/null; then
        echo "  ✅ GitLab API token"
    else
        echo "  ❌ GitLab API token (not stored)"
    fi

    echo ""
}

# Full setup wizard
setup_wizard() {
    echo ""
    echo "============================================================"
    echo "🔧 AutoGit Credential Setup Wizard"
    echo "============================================================"
    echo ""

    check_dependencies

    # Step 1: GHCR Token
    log_info "Step 1: GitHub Container Registry (GHCR) Token"
    if secret-tool lookup service "$KEYRING_SERVICE" type "ghcr-pat" &> /dev/null; then
        read -p "GHCR token already exists. Replace? [y/N]: " replace
        if [[ $replace =~ ^[Yy]$ ]]; then
            store_ghcr_token || return 1
        fi
    else
        store_ghcr_token || return 1
    fi

    echo ""

    # Step 2: Test GHCR
    log_info "Step 2: Testing GHCR Authentication"
    test_ghcr_auth || log_warn "GHCR test failed - continuing anyway"

    echo ""

    # Step 3: GitLab Token
    log_info "Step 3: GitLab API Token"
    if ! secret-tool lookup service "$KEYRING_SERVICE" type "gitlab-api" &> /dev/null; then
        read -p "Store GitLab API token? [Y/n]: " store_gl
        if [[ ! $store_gl =~ ^[Nn]$ ]]; then
            store_gitlab_token
        fi
    else
        log_success "GitLab API token already stored"
    fi

    echo ""

    # Step 4: Update GitLab
    log_info "Step 4: Update GitLab CI/CD Variables"
    read -p "Push GHCR token to GitLab CI/CD? [Y/n]: " push_gl
    if [[ ! $push_gl =~ ^[Nn]$ ]]; then
        update_gitlab_variable || return 1
    fi

    echo ""
    log_success "Setup complete!"
    echo ""
    list_credentials
}

# Delete stored credentials
delete_credentials() {
    log_warn "This will delete all AutoGit credentials from the keyring"
    read -p "Are you sure? [y/N]: " confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        secret-tool clear service "$KEYRING_SERVICE" type "ghcr-pat" 2> /dev/null || true
        secret-tool clear service "$KEYRING_SERVICE" type "ghcr-username" 2> /dev/null || true
        secret-tool clear service "$KEYRING_SERVICE" type "gitlab-api" 2> /dev/null || true
        log_success "Credentials deleted"
    else
        log_info "Cancelled"
    fi
}

# Export keyring to .env file
export_to_file() {
    log_info "Exporting credentials from keyring to .env..."

    local gh_token gl_token
    gh_token=$(get_ghcr_token) || return 1
    gl_token=$(secret-tool lookup service "$KEYRING_SERVICE" type "gitlab-api" 2> /dev/null) || {
        log_error "GitLab token not found in keyring"
        return 1
    }

    cat >> "$SECRETS_FILE" << EOF

# AutoGit Secrets - DO NOT COMMIT
export GH_TOKEN="$gh_token"
export GL_TOKEN="$gl_token"
EOF

    chmod 600 "$SECRETS_FILE"
    log_success "Credentials exported to $SECRETS_FILE (permissions set to 600)"
}

# Main
main() {
    local cmd="${1:-help}"

    case "$cmd" in
        store-ghcr-token)
            check_dependencies
            store_ghcr_token
            ;;
        get-ghcr-token)
            get_ghcr_token
            ;;
        test-ghcr)
            check_dependencies
            test_ghcr_auth
            ;;
        update-gitlab)
            check_dependencies
            update_gitlab_variable
            ;;
        store-gitlab-token)
            check_dependencies
            store_gitlab_token
            ;;
        export)
            export_to_file
            ;;
        list)
            list_credentials
            ;;
        setup)
            setup_wizard
            ;;
        delete)
            delete_credentials
            ;;
        help | --help | -h)
            echo "AutoGit Credential Manager"
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  setup              Full setup wizard (recommended)"
            echo "  store-ghcr-token   Store GHCR PAT in keyring"
            echo "  get-ghcr-token     Retrieve GHCR PAT (for scripts)"
            echo "  test-ghcr          Test GHCR authentication"
            echo "  store-gitlab-token Store GitLab API token"
            echo "  update-gitlab      Push GHCR token to GitLab CI/CD"
            echo "  export             Export keyring to .env"
            echo "  list               List stored credentials"
            echo "  delete             Delete all stored credentials"
            echo ""
            echo "Security:"
            echo "  - Tokens stored in GNOME Keyring (encrypted)"
            echo "  - Fine-grained PATs with minimal scope"
            echo "  - Protected branch access only in GitLab"
            ;;
        *)
            log_error "Unknown command: $cmd"
            echo "Run '$0 help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
