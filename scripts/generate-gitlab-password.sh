#!/bin/bash
# Generate secure random password for GitLab root user
# This script creates a strong password and stores it securely

set -e

SECRETS_DIR="${HOME}/.autogit"
PASSWORD_FILE="${SECRETS_DIR}/gitlab_root_password"
ENV_FILE=".env"

# Create secrets directory if it doesn't exist
mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"

# Check if password already exists
if [ -f "${PASSWORD_FILE}" ]; then
    echo "Password file already exists: ${PASSWORD_FILE}"
    echo "Using existing password."
    GITLAB_ROOT_PASSWORD=$(cat "${PASSWORD_FILE}")
else
    echo "Generating secure random password for GitLab root user..."

    # Generate a 32-character random password with special characters
    GITLAB_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

    # Save to secure file
    echo "${GITLAB_ROOT_PASSWORD}" > "${PASSWORD_FILE}"
    chmod 600 "${PASSWORD_FILE}"

    echo "✓ Password generated and saved to: ${PASSWORD_FILE}"
fi

# Update or create .env file
if [ -f "${ENV_FILE}" ]; then
    # Check if GITLAB_ROOT_PASSWORD already exists
    if grep -q "^GITLAB_ROOT_PASSWORD=" "${ENV_FILE}"; then
        # Update existing entry
        sed -i.bak "s|^GITLAB_ROOT_PASSWORD=.*|GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD}|" "${ENV_FILE}"
        echo "✓ Updated GITLAB_ROOT_PASSWORD in ${ENV_FILE}"
    else
        # Add new entry
        {
            echo ""
            echo "# GitLab root user password (auto-generated)"
            echo "GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD}"
        } >> "${ENV_FILE}"
        echo "✓ Added GITLAB_ROOT_PASSWORD to ${ENV_FILE}"
    fi
else
    # Create new .env file
    cat > "${ENV_FILE}" << EOF
# AutoGit Environment Configuration
# Generated: $(date)

# GitLab Configuration
GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD}

# Ports
GITLAB_HTTP_PORT=3000
GITLAB_HTTPS_PORT=3443
GITLAB_SSH_PORT=2222

# Data paths
GITLAB_DATA_PATH=/var/lib/autogit
EOF
    echo "✓ Created ${ENV_FILE} with GITLAB_ROOT_PASSWORD"
fi

chmod 600 "${ENV_FILE}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  GitLab Root Password Configuration Complete"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Password stored in: ${PASSWORD_FILE}"
echo "Environment file:   ${ENV_FILE}"
echo ""
echo "To view the password:"
echo "  cat ${PASSWORD_FILE}"
echo ""
echo "⚠️  IMPORTANT: Keep these files secure and never commit them!"
echo ""
