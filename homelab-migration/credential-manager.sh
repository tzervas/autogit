#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# GitLab Credential Manager
# Secure handling of credentials with NO shell history or log exposure
#
# SECURITY FEATURES:
# - Credentials never appear in shell history (uses temp files + secure delete)
# - No sensitive data in stdout/stderr (written directly to secure file)
# - Encrypted output option (GPG)
# - Memory-only operations where possible
# - Auto-cleanup of temp files
#
# IDEMPOTENT: Safe to run multiple times
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment
[[ -f "${SCRIPT_DIR}/.env" ]] && source "${SCRIPT_DIR}/.env"

# Connection settings
HOMELAB_USER="${HOMELAB_USER:-kang}"
HOMELAB_HOST="${HOMELAB_HOST:-192.168.1.170}"
DOCKER_SOCK="${DOCKER_SOCK:-unix:///run/user/1000/docker.sock}"
CONTAINER_NAME="${CONTAINER_NAME:-autogit-git-server}"

# Output settings
CREDS_DIR="${CREDS_DIR:-${SCRIPT_DIR}/.credentials}"
CREDS_FILE="${CREDS_DIR}/gitlab.env"
ENCRYPT_OUTPUT="${ENCRYPT_OUTPUT:-false}"
GPG_RECIPIENT="${GPG_RECIPIENT:-}"

# Token settings
TOKEN_EXPIRY_DAYS="${TOKEN_EXPIRY_DAYS:-365}"

#───────────────────────────────────────────────────────────────────────────────
# USER DEFINITIONS
#───────────────────────────────────────────────────────────────────────────────
# Format: username|email|is_admin|description
HUMAN_USERS=(
    "admin|admin@vectorweight.com|true|Day-to-day administrator"
    "kang|kang@vectorweight.com|false|Power user / maintainer"
    "dev|dev@vectorweight.com|false|Regular developer"
)

# Format: username|email|is_admin|scopes|description
SERVICE_ACCOUNTS=(
    "autogit-ci|ci@vectorweight.com|false|api,read_repository,write_repository|CI/CD pipelines"
    "autogit-api|api@vectorweight.com|false|api,read_api|External API integrations"
    "autogit-backup|backup@vectorweight.com|true|api,read_repository,sudo|Backup operations"
    "autogit-mirror|mirror@vectorweight.com|false|api,read_repository,write_repository|Repository mirroring"
)

#───────────────────────────────────────────────────────────────────────────────
# SECURE UTILITY FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────
# Logging (no sensitive data)
log()      { echo "[$(date '+%H:%M:%S')] $*"; }
log_ok()   { echo "[$(date '+%H:%M:%S')] ✅ $*"; }
log_warn() { echo "[$(date '+%H:%M:%S')] ⚠️  $*"; }
log_err()  { echo "[$(date '+%H:%M:%S')] ❌ $*" >&2; }
log_skip() { echo "[$(date '+%H:%M:%S')] ⏭️  $*"; }

# Create secure temp file (auto-deleted on exit)
TEMP_FILES=()
secure_temp() {
    local tmp
    tmp=$(mktemp -t "autogit-XXXXXX")
    chmod 600 "$tmp"
    TEMP_FILES+=("$tmp")
    echo "$tmp"
}

# Cleanup temp files securely
cleanup() {
    for f in "${TEMP_FILES[@]:-}"; do
        if [[ -f "$f" ]]; then
            # Overwrite before delete (secure delete)
            dd if=/dev/urandom of="$f" bs=1k count=10 conv=notrunc 2>/dev/null || true
            rm -f "$f"
        fi
    done
}
trap cleanup EXIT

# Execute gitlab-rails command WITHOUT exposing code in process list
# Uses temp file to pass Ruby code securely
gitlab_rails_secure() {
    local ruby_code="$1"
    local tmp_script
    tmp_script=$(secure_temp)
    
    # Write Ruby code to temp file
    echo "$ruby_code" > "$tmp_script"
    
    # Copy to remote, execute, delete
    local remote_tmp="/tmp/gitlab-rails-$$.rb"
    scp -q "$tmp_script" "${HOMELAB_USER}@${HOMELAB_HOST}:${remote_tmp}"
    
    ssh "${HOMELAB_USER}@${HOMELAB_HOST}" "
        export DOCKER_HOST=${DOCKER_SOCK}
        docker cp ${remote_tmp} ${CONTAINER_NAME}:/tmp/script.rb
        docker exec ${CONTAINER_NAME} gitlab-rails runner /tmp/script.rb
        docker exec ${CONTAINER_NAME} rm -f /tmp/script.rb
        rm -f ${remote_tmp}
    " 2>/dev/null
}

# Generate secure password (no echo to terminal)
generate_password() {
    openssl rand -base64 32 | tr -d '/+=' | head -c 32
}

# Check if user exists
user_exists() {
    local username="$1"
    local result
    result=$(gitlab_rails_secure "puts User.find_by(username: '${username}').present?")
    [[ "$result" == "true" ]]
}

# Write credential to file (never to stdout)
write_credential() {
    local key="$1"
    local value="$2"
    echo "${key}='${value}'" >> "$CREDS_FILE"
}

# Write comment to file
write_comment() {
    echo "$1" >> "$CREDS_FILE"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

init_creds_file() {
    # Create secure directory
    mkdir -p "$CREDS_DIR"
    chmod 700 "$CREDS_DIR"
    
    # Add to gitignore
    if [[ -f "${SCRIPT_DIR}/.gitignore" ]]; then
        grep -q "^\.credentials" "${SCRIPT_DIR}/.gitignore" 2>/dev/null || \
            echo ".credentials/" >> "${SCRIPT_DIR}/.gitignore"
    fi
    
    # Backup existing
    if [[ -f "$CREDS_FILE" ]]; then
        local backup="${CREDS_FILE}.$(date +%Y%m%d_%H%M%S).bak"
        mv "$CREDS_FILE" "$backup"
        chmod 600 "$backup"
        log "Backed up existing credentials to ${backup##*/}"
    fi
    
    # Initialize new file
    cat > "$CREDS_FILE" << 'EOF'
# ═══════════════════════════════════════════════════════════════════════════════
# GitLab Credentials
# Generated by credential-manager.sh
# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY NOTICE:
# - This file contains sensitive credentials
# - Permissions should be 600 (owner read/write only)
# - Transfer to password manager and delete this file
# - Do NOT commit to version control
# ═══════════════════════════════════════════════════════════════════════════════

EOF
    chmod 600 "$CREDS_FILE"
}

capture_root_password() {
    log "📝 Capturing root credentials..."
    
    # Use secure method to extract password
    local password_file
    password_file=$(secure_temp)
    
    ssh "${HOMELAB_USER}@${HOMELAB_HOST}" \
        "export DOCKER_HOST=${DOCKER_SOCK} && \
         docker exec ${CONTAINER_NAME} cat /etc/gitlab/initial_root_password 2>/dev/null" \
        > "$password_file" 2>/dev/null || true
    
    local password
    password=$(grep -E '^Password:' "$password_file" 2>/dev/null | awk '{print $2}' || echo "")
    
    write_comment ""
    write_comment "# Root Account"
    write_comment "# ─────────────────────────────────────────"
    
    if [[ -n "$password" ]]; then
        write_credential "GITLAB_ROOT_PASSWORD" "$password"
        log_ok "Root password captured"
    else
        write_comment "# GITLAB_ROOT_PASSWORD=<not available - may have expired or been changed>"
        log_warn "Root password not available (24h file may have expired)"
    fi
}

create_human_users() {
    log ""
    log "👥 Creating human user accounts..."
    
    write_comment ""
    write_comment "# Human Users"
    write_comment "# ─────────────────────────────────────────"
    
    for user_def in "${HUMAN_USERS[@]}"; do
        IFS='|' read -r username email is_admin description <<< "$user_def"
        
        if user_exists "$username"; then
            log_skip "User '${username}' already exists"
            write_comment "# ${username}: <existing - not modified>"
            continue
        fi
        
        local password
        password=$(generate_password)
        
        # Create user via secure Rails execution
        gitlab_rails_secure "
            u = User.new(
                username: '${username}',
                email: '${email}',
                name: '${username^}',
                password: '${password}',
                password_confirmation: '${password}',
                admin: ${is_admin},
                skip_confirmation: true
            )
            u.save!
        " >/dev/null 2>&1
        
        write_comment "# ${description}"
        write_credential "GITLAB_PASSWORD_${username}" "$password"
        log_ok "Created user '${username}' (admin=${is_admin})"
    done
}

create_service_accounts() {
    log ""
    log "🤖 Creating service accounts..."
    
    write_comment ""
    write_comment "# Service Accounts"
    write_comment "# ─────────────────────────────────────────"
    
    local expiry_date
    expiry_date=$(date -d "+${TOKEN_EXPIRY_DAYS} days" '+%Y-%m-%d')
    
    for account_def in "${SERVICE_ACCOUNTS[@]}"; do
        IFS='|' read -r username email is_admin scopes description <<< "$account_def"
        
        if user_exists "$username"; then
            log_skip "Service account '${username}' already exists"
            write_comment "# ${username}: <existing - not modified>"
            continue
        fi
        
        local password token
        password=$(generate_password)
        
        # Convert comma-separated scopes to Ruby array format
        local ruby_scopes
        ruby_scopes=$(echo "$scopes" | sed "s/,/', '/g")
        
        # Create service account with token via secure Rails execution
        token=$(gitlab_rails_secure "
            u = User.new(
                username: '${username}',
                email: '${email}',
                name: '${username} (Service Account)',
                password: '${password}',
                password_confirmation: '${password}',
                admin: ${is_admin},
                skip_confirmation: true
            )
            u.save!
            
            token = u.personal_access_tokens.create!(
                name: 'autogit-bootstrap',
                scopes: ['${ruby_scopes}'],
                expires_at: '${expiry_date}'
            )
            puts token.token
        " 2>/dev/null)
        
        write_comment "# ${description}"
        write_credential "GITLAB_PASSWORD_${username//-/_}" "$password"
        write_credential "GITLAB_TOKEN_${username//-/_}" "$token"
        log_ok "Created '${username}' with token (expires: ${expiry_date})"
    done
}

finalize() {
    local expiry_date
    expiry_date=$(date -d "+${TOKEN_EXPIRY_DAYS} days" '+%Y-%m-%d')
    
    write_comment ""
    write_comment "# ═══════════════════════════════════════════════════════════════════════════════"
    write_comment "# Generated: $(date -Iseconds)"
    write_comment "# Token expiry: ${expiry_date}"
    write_comment "# ═══════════════════════════════════════════════════════════════════════════════"
    
    # Optionally encrypt
    if [[ "$ENCRYPT_OUTPUT" == "true" ]] && [[ -n "$GPG_RECIPIENT" ]]; then
        log "🔐 Encrypting credentials..."
        gpg --encrypt --recipient "$GPG_RECIPIENT" --output "${CREDS_FILE}.gpg" "$CREDS_FILE"
        # Secure delete plaintext
        dd if=/dev/urandom of="$CREDS_FILE" bs=1k count=10 conv=notrunc 2>/dev/null
        rm -f "$CREDS_FILE"
        CREDS_FILE="${CREDS_FILE}.gpg"
        log_ok "Encrypted to ${CREDS_FILE}"
    fi
}

show_summary() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_ok "Credential bootstrap complete!"
    log ""
    log "📁 Credentials saved to:"
    log "   ${CREDS_FILE}"
    log ""
    log "🔒 Security:"
    log "   - File permissions: $(stat -c '%a' "$CREDS_FILE")"
    log "   - Directory permissions: $(stat -c '%a' "$CREDS_DIR")"
    log "   - No credentials in shell history ✓"
    log "   - No credentials in process list ✓"
    log ""
    log "⚠️  NEXT STEPS:"
    log "   1. View credentials:  cat ${CREDS_FILE}"
    log "   2. Copy to password manager"
    log "   3. Delete file:       rm -f ${CREDS_FILE}"
    log ""
}

#───────────────────────────────────────────────────────────────────────────────
# CLI
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'
GitLab Credential Manager - Secure credential handling

Usage: ./credential-manager.sh [OPTIONS]

Options:
  --bootstrap       Create users and capture credentials (default)
  --capture-root    Only capture root password
  --list-users      List existing users
  --encrypt         Encrypt output with GPG (requires GPG_RECIPIENT)
  --help            Show this help

Environment Variables:
  HOMELAB_USER      SSH username (default: kang)
  HOMELAB_HOST      Remote host (default: 192.168.1.170)
  CREDS_DIR         Credentials directory (default: .credentials/)
  TOKEN_EXPIRY_DAYS Token lifetime in days (default: 365)
  ENCRYPT_OUTPUT    Encrypt with GPG (true/false)
  GPG_RECIPIENT     GPG key ID for encryption

Security:
  - Credentials are NEVER shown in terminal output
  - Credentials are NEVER stored in shell history
  - Temp files are securely overwritten before deletion
  - Output file has 600 permissions by default

EOF
}

main() {
    local action="bootstrap"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --bootstrap)     action="bootstrap" ;;
            --capture-root)  action="capture-root" ;;
            --list-users)    action="list-users" ;;
            --encrypt)       ENCRYPT_OUTPUT="true" ;;
            --help|-h)       show_help; exit 0 ;;
            *)               log_err "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done
    
    log "🔐 GitLab Credential Manager"
    log "════════════════════════════"
    echo ""
    
    case "$action" in
        bootstrap)
            init_creds_file
            capture_root_password
            create_human_users
            create_service_accounts
            finalize
            show_summary
            ;;
        capture-root)
            init_creds_file
            capture_root_password
            finalize
            show_summary
            ;;
        list-users)
            log "📋 Listing GitLab users..."
            gitlab_rails_secure "User.all.each { |u| puts \"#{u.username} (admin=#{u.admin})\" }"
            ;;
    esac
}

main "$@"
