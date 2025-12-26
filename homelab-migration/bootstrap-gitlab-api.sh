#!/bin/bash
# GitLab User Bootstrap via REST API
# FAST: Uses HTTP API (50-200ms/call) instead of Rails runner (3-5s/call)
#
# Strategy:
# 1. Single Rails call to create root admin token (unavoidable bootstrap)
# 2. All subsequent operations via REST API
#
# Threat Model:
# - Root token created with 24h expiry for bootstrap only
# - Service tokens scoped to minimal required permissions
# - Credentials written to chmod 600 file, never echoed
# - API approach properly validates + creates namespaces automatically

set -euo pipefail

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

HOMELAB_USER="${HOMELAB_USER:-kang}"
HOMELAB_HOST="${HOMELAB_HOST:-192.168.1.170}"
DOCKER_SOCK="${DOCKER_SOCK:-unix:///run/user/1000/docker.sock}"
CONTAINER_NAME="${CONTAINER_NAME:-autogit-git-server}"
GITLAB_URL="${GITLAB_URL:-https://192.168.1.170}"

CREDS_FILE="${CREDS_FILE:-gitlab-credentials.env}"
TOKEN_EXPIRY_DAYS="${TOKEN_EXPIRY_DAYS:-365}"

# User definitions: USERNAME="email|name|is_admin"
declare -A USERS=(
    ["admin"]="admin@vectorweight.com|Admin User|true"
    ["kang"]="kang@vectorweight.com|Kang|false"
    ["dev"]="dev@vectorweight.com|Developer|false"
    ["autogit-ci"]="ci@vectorweight.com|CI Service|false"
    ["autogit-api"]="api@vectorweight.com|API Service|false"
    ["autogit-backup"]="backup@vectorweight.com|Backup Service|true"
)

# Service account token scopes
declare -A SERVICE_SCOPES=(
    ["autogit-ci"]="api read_repository write_repository"
    ["autogit-api"]="api read_api"
    ["autogit-backup"]="api read_repository sudo"
)

#═══════════════════════════════════════════════════════════════════════════════
# FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

log() { echo "[$(date '+%H:%M:%S')] $*"; }
log_ok() { echo "[$(date '+%H:%M:%S')] ✅ $*"; }
log_skip() { echo "[$(date '+%H:%M:%S')] ⏭️  $*"; }
log_err() { echo "[$(date '+%H:%M:%S')] ❌ $*" >&2; }

# Generate secure password (GitLab-compliant: 12+ chars, mixed)
generate_password() {
    local base
    base=$(openssl rand -base64 32 | tr -d '/+=' | head -c 20)
    echo "${base}#Ag$(date +%s | tail -c 5)"
}

# Single Rails call - only used for initial token bootstrap
rails_runner() {
    ssh "${HOMELAB_USER}@${HOMELAB_HOST}" \
        "export DOCKER_HOST=${DOCKER_SOCK} && docker exec ${CONTAINER_NAME} gitlab-rails runner '$1'" 2>&1
}

# GitLab API call (fast!)
gitlab_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local args=(-s -w "\n%{http_code}" -X "$method")
    args+=(-H "PRIVATE-TOKEN: ${ROOT_TOKEN}")
    args+=(-H "Content-Type: application/json")

    if [[ -n $data ]]; then
        args+=(--data "$data")
    fi

    curl "${args[@]}" "${GITLAB_URL}/api/v4${endpoint}"
}

# Parse API response - returns body and sets HTTP_CODE global
parse_response() {
    local response="$1"
    HTTP_CODE=$(echo "$response" | tail -1)
    echo "$response" | head -n -1
}

# Check if user exists via API
user_exists_api() {
    local username="$1"
    local response body
    response=$(gitlab_api GET "/users?username=${username}")
    body=$(parse_response "$response")

    # Check for API errors first
    if [[ $body == *"error"* ]]; then
        log_err "API error checking user: ${body}"
        return 1
    fi

    # Returns array - empty [] means not found
    [[ $body != "[]" ]]
}

# Create user via API
create_user_api() {
    local username="$1"
    local email="$2"
    local name="$3"
    local password="$4"
    local is_admin="$5"

    local data
    data=$(
        cat << EOF
{
    "username": "${username}",
    "email": "${email}",
    "name": "${name}",
    "password": "${password}",
    "skip_confirmation": true,
    "admin": ${is_admin}
}
EOF
    )

    local response body
    response=$(gitlab_api POST "/users" "$data")
    body=$(parse_response "$response")

    if [[ $HTTP_CODE == "201" ]]; then
        echo "$body" | jq -r '.id'
        return 0
    else
        echo "error: $(echo "$body" | jq -r '.message // .error // "unknown"')"
        return 1
    fi
}

# Create personal access token for user via API
create_user_token_api() {
    local user_id="$1"
    local token_name="$2"
    local scopes="$3"
    local expires_at="$4"

    # Convert space-separated scopes to JSON array
    local scopes_json
    scopes_json=$(echo "$scopes" | tr ' ' '\n' | jq -R . | jq -s .)

    local data
    data=$(
        cat << EOF
{
    "name": "${token_name}",
    "scopes": ${scopes_json},
    "expires_at": "${expires_at}"
}
EOF
    )

    local response body
    response=$(gitlab_api POST "/users/${user_id}/personal_access_tokens" "$data")
    body=$(parse_response "$response")

    if [[ $HTTP_CODE == "201" ]]; then
        echo "$body" | jq -r '.token'
        return 0
    else
        echo "error: $(echo "$body" | jq -r '.message // .error // "unknown"')"
        return 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
# MAIN
#═══════════════════════════════════════════════════════════════════════════════

main() {
    log "🔐 GitLab User Bootstrap (API Mode)"
    log "===================================="
    log "Using REST API for fast operations (~100ms vs ~4s per call)"
    echo ""

    # Check dependencies
    if ! command -v jq &> /dev/null; then
        log_err "jq required but not installed. Run: sudo apt install jq"
        exit 1
    fi

    # Initialize credentials file
    if [[ -f $CREDS_FILE ]]; then
        log "Backing up existing credentials to ${CREDS_FILE}.bak"
        cp "$CREDS_FILE" "${CREDS_FILE}.bak"
    fi

    cat > "$CREDS_FILE" << 'HEADER'
# GitLab Credentials
# Generated by bootstrap-gitlab-api.sh
# KEEP THIS FILE SECURE - chmod 600
HEADER
    chmod 600 "$CREDS_FILE"

    # ─────────────────────────────────────────────────────────────────────────
    # Step 1: Capture root password (from initial file)
    # ─────────────────────────────────────────────────────────────────────────
    log "📝 Capturing root credentials..."

    ROOT_PASSWORD=$(ssh "${HOMELAB_USER}@${HOMELAB_HOST}" \
        "export DOCKER_HOST=${DOCKER_SOCK} && docker exec ${CONTAINER_NAME} cat /etc/gitlab/initial_root_password 2>/dev/null" \
        | grep -E '^Password:' | awk '{print $2}' || echo "")

    if [[ -n $ROOT_PASSWORD ]]; then
        echo "GITLAB_PASSWORD_root='${ROOT_PASSWORD}'" >> "$CREDS_FILE"
        log_ok "Root password captured"
    else
        log_err "No initial_root_password - cannot proceed without root access"
        log "    Reset with: gitlab-rake 'gitlab:password:reset[root]'"
        exit 1
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Step 2: Create bootstrap admin token (single Rails call - unavoidable)
    # ─────────────────────────────────────────────────────────────────────────
    log ""
    log "🎫 Creating bootstrap admin token (single Rails call)..."

    BOOTSTRAP_EXPIRY=$(date -d "+1 day" '+%Y-%m-%d')
    local token_name
    token_name="bootstrap-$(date +%s)"

    ROOT_TOKEN=$(ssh "${HOMELAB_USER}@${HOMELAB_HOST}" \
        "export DOCKER_HOST=${DOCKER_SOCK} && docker exec ${CONTAINER_NAME} gitlab-rails runner \"token = User.find_by(username: 'root').personal_access_tokens.create!(name: '${token_name}', scopes: ['api', 'read_user', 'sudo'], expires_at: '${BOOTSTRAP_EXPIRY}'); puts token.token\"" 2>&1)

    if [[ -z $ROOT_TOKEN || $ROOT_TOKEN == *"error"* || $ROOT_TOKEN == *"Error"* ]]; then
        log_err "Failed to create bootstrap token: ${ROOT_TOKEN}"
        exit 1
    fi

    echo "GITLAB_TOKEN_root_bootstrap='${ROOT_TOKEN}'" >> "$CREDS_FILE"
    log_ok "Bootstrap token created (expires: ${BOOTSTRAP_EXPIRY})"

    # ─────────────────────────────────────────────────────────────────────────
    # Step 3: Create users via API (fast!)
    # ─────────────────────────────────────────────────────────────────────────
    log ""
    log "👥 Creating user accounts via API..."

    EXPIRY_DATE=$(date -d "+${TOKEN_EXPIRY_DAYS} days" '+%Y-%m-%d')
    echo "" >> "$CREDS_FILE"
    echo "# User Accounts" >> "$CREDS_FILE"

    for username in "${!USERS[@]}"; do
        IFS='|' read -r email name is_admin <<< "${USERS[$username]}"

        if user_exists_api "$username"; then
            log_skip "User '$username' exists"
            continue
        fi

        password=$(generate_password)

        log "  Creating ${username}..."
        result=$(create_user_api "$username" "$email" "$name" "$password" "$is_admin")

        if [[ $result == error:* ]]; then
            log_err "Failed: ${username} - ${result#error: }"
        else
            user_id="$result"
            echo "GITLAB_PASSWORD_${username//-/_}='${password}'" >> "$CREDS_FILE"
            log_ok "Created ${username} (id=${user_id}, admin=${is_admin})"

            # Create token for service accounts
            if [[ -n ${SERVICE_SCOPES[$username]:-} ]]; then
                scopes="${SERVICE_SCOPES[$username]}"
                token=$(create_user_token_api "$user_id" "autogit-token" "$scopes" "$EXPIRY_DATE")

                if [[ $token == error:* ]]; then
                    log_err "  Token failed: ${token#error: }"
                else
                    echo "GITLAB_TOKEN_${username//-/_}='${token}'" >> "$CREDS_FILE"
                    log_ok "  Token created (expires: ${EXPIRY_DATE})"
                fi
            fi
        fi
    done

    # ─────────────────────────────────────────────────────────────────────────
    # Summary
    # ─────────────────────────────────────────────────────────────────────────
    echo "" >> "$CREDS_FILE"
    echo "# Generated: $(date -Iseconds)" >> "$CREDS_FILE"

    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_ok "Bootstrap complete!"
    log ""
    log "📁 Credentials: ${CREDS_FILE}"
    log "🔒 Permissions: $(stat -c '%a' "$CREDS_FILE")"
    log ""
    log "⚠️  Next steps:"
    log "   1. Move credentials to password manager"
    log "   2. Delete bootstrap token after setup (expires ${BOOTSTRAP_EXPIRY})"
    log "   3. Consider changing root password via web UI"
}

main "$@"
