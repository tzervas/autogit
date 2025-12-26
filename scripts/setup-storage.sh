#!/bin/bash
# Setup 200GB storage for GitLab and prepare for CI testing

set -e

echo "========================================================================="
echo " AutoGit Storage Setup - 200GB Allocation"
echo "========================================================================="

# Configuration
STORAGE_PATH="/home/kang/autogit-storage"
STORAGE_SIZE="200G"

# Create storage directory structure
echo "📁 Creating storage directories..."
ssh homelab "
    sudo mkdir -p ${STORAGE_PATH}/config ${STORAGE_PATH}/logs ${STORAGE_PATH}/data
    sudo chown -R kang:kang ${STORAGE_PATH}
    chmod -R 755 ${STORAGE_PATH}
"

# Check available disk space
echo ""
echo "💾 Checking available disk space on homelab..."
ssh homelab "df -h /home | tail -1"

# Update environment configuration
echo ""
echo "🔧 Creating environment configuration..."
cat > .env.homelab.local << EOF
# AutoGit Homelab Storage Configuration
GITLAB_DATA_PATH=${STORAGE_PATH}

# GitLab Configuration
GITLAB_HTTP_PORT=3000
GITLAB_HTTPS_PORT=3443
GITLAB_SSH_PORT=2222
GITLAB_OMNIBUS_CONFIG=external_url "http://192.168.1.170:3000"
GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD:-CHANGE_ME_SECURE_PASSWORD}

# Docker Configuration
DOCKER_HOST=unix:///run/user/1000/docker.sock
EOF

echo ""
echo "✅ Storage setup complete!"
echo ""
echo "Storage location: ${STORAGE_PATH}"
echo "Total allocation: ${STORAGE_SIZE}"
echo ""
echo "Next steps:"
echo "  1. Deploy with: ./scripts/homelab-manager.sh deploy"
echo "  2. Push code to GitLab: git push homelab-gitlab work/homelab-deployment-terraform-config-init:main"
echo "  3. Monitor CI: ssh homelab 'watch -n 2 docker ps'"
echo "========================================================================="
