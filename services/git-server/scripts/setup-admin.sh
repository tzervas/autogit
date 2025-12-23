#!/bin/bash
# Setup Admin User Script for GitLab
# This script creates the initial admin user with secure settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
ADMIN_USERNAME="${GITLAB_ROOT_USERNAME:-root}"
ADMIN_PASSWORD="${GITLAB_ROOT_PASSWORD:-}"

print_info "GitLab Admin User Setup Script"
print_info "================================"
echo ""

# Check if GitLab is running
if ! docker compose ps git-server | grep -q "Up"; then
    print_error "GitLab container is not running. Please start it first with: docker compose up -d git-server"
    exit 1
fi

# Check if admin password is set
if [ -z "$ADMIN_PASSWORD" ]; then
    print_error "GITLAB_ROOT_PASSWORD environment variable is not set!"
    print_info "Please set it in your .env file or export it: export GITLAB_ROOT_PASSWORD='your-secure-password'"
    exit 1
fi

# Validate password strength
if [ ${#ADMIN_PASSWORD} -lt 12 ]; then
    print_error "Password must be at least 12 characters long"
    exit 1
fi

print_info "Waiting for GitLab to be fully initialized..."
print_info "This may take 3-5 minutes on first startup..."

# Wait for GitLab to be ready
MAX_WAIT=300 # 5 minutes
WAITED=0
while ! docker compose exec -T git-server gitlab-rake gitlab:check SANITIZE=true >/dev/null 2>&1; do
    if [ $WAITED -ge $MAX_WAIT ]; then
        print_error "GitLab did not become ready within $MAX_WAIT seconds"
        exit 1
    fi
    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
done
echo ""

print_info "GitLab is ready!"

# Reset root password
print_info "Setting up admin user: $ADMIN_USERNAME"
if docker compose exec -T git-server gitlab-rake "gitlab:password:reset[${ADMIN_USERNAME}]" <<EOF; then
${ADMIN_PASSWORD}
${ADMIN_PASSWORD}
EOF
    print_info "✅ Admin user password has been set successfully!"
    echo ""
    print_info "Login Details:"
    print_info "  URL: http://localhost:3000"
    print_info "  Username: ${ADMIN_USERNAME}"
    print_info "  Password: (the password you set in GITLAB_ROOT_PASSWORD)"
    echo ""
    print_warn "Please login and change the password if needed"
    print_warn "It's recommended to enable 2FA for the admin account"
else
    print_error "Failed to set admin password"
    exit 1
fi

# Disable signup if configured
if docker compose exec -T git-server grep -q "gitlab_signup_enabled.*false" /etc/gitlab/gitlab.rb 2>/dev/null; then
    print_info "✅ User signup is disabled (recommended for private installations)"
else
    print_warn "User signup is currently enabled. Consider disabling it in gitlab.rb"
fi

print_info ""
print_info "Setup complete! You can now login to GitLab."
