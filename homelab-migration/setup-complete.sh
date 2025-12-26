#!/usr/bin/env bash
echo "🚀 GitLab Homelab Setup with Repository Mirroring"
echo "================================================"
echo "🌐 GitLab URL: $GITLAB_URL"
echo "🐙 GitHub Token: ${GITHUB_PAT_MIRROR:0:12}...***"
echo "🦊 GitLab Token: ${GITLAB_PAT_MIRROR:0:8}...***"
echo ""
# Complete GitLab Homelab Setup Script
# Automated setup with repository mirroring

set -euo pipefail

# Load environment variables
source load-env.sh
if ! load_env; then
    echo "❌ Failed to load environment configuration"
    exit 1
fi

echo "🚀 GitLab Homelab Setup with Repository Mirroring"
echo "================================================"
echo "🌐 GitLab URL: $GITLAB_URL"
echo "� GitHub Token: ${GITHUB_PAT_MIRROR:0:20}..."
echo "🦊 GitLab Token: ${GITLAB_PAT_MIRROR:0:20}..."
echo ""

# Function to install packages with nala
install_package() {
    local package=$1
    if ! command -v "$package" >/dev/null 2>&1; then
        echo "📦 Installing $package..."
        sudo nala install -y "$package"
    fi
}

# Check and install Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is required but not installed"
    install_package docker.io
fi

# Check and install Docker Compose v2
if ! docker compose version >/dev/null 2>&1; then
    echo "❌ Docker Compose v2 is required but not available"
    install_package docker-compose-v2
fi

# Check and install uv
if ! command -v uv >/dev/null 2>&1; then
    echo "❌ uv is required but not installed"
    install_package uv
fi

# Check and install curl
install_package curl

# Check and install jq
install_package jq

echo "✅ Prerequisites met"

# Configuration loaded from environment
echo ""
echo "🔧 Configuration"
echo "================"
echo "✅ Using configuration from .env file"
echo ""

# Step 1: Deploy GitLab
echo ""
echo "📦 Step 1: Deploying GitLab"
echo "==========================="
./deploy-fresh.sh

# Wait for user to get root token
echo ""
echo "⏳ Waiting for GitLab initialization..."
echo "📋 Please:"
echo "  1. Open ${GITLAB_URL} in your browser"
echo "  2. Log in with the root credentials shown above"
echo "  3. Go to Admin Area → Settings → Access Tokens"
echo "  4. Create a token with 'api', 'read_user', 'sudo' scopes"
echo "  5. Copy the token"
echo ""
read -p "Enter the root access token: " ROOT_TOKEN
export GITLAB_ROOT_TOKEN="$ROOT_TOKEN"

# Step 2: Configure GitLab
echo ""
echo "👤 Step 2: Configuring GitLab Users & Tokens"
echo "============================================"
uv run python configure-gitlab-fresh.py

# Step 3: Setup mirroring
echo ""
echo "🔄 Step 3: Setting up Repository Mirroring"
echo "=========================================="
uv run python setup-mirroring.py

# Step 4: Setup CLI auth
echo ""
echo "🖥️  Step 4: Configuring CLI Authentication"
echo "========================================="
./setup-cli-auth.sh

# Final summary
echo ""
echo "🎉 Setup Complete!"
echo "=================="

if [[ -f gitlab-fresh-config.json ]]; then
    CI_TOKEN=$(jq -r '.tokens.ci_token.token' gitlab-fresh-config.json 2>/dev/null || echo "N/A")
    echo "GitLab URL: ${GITLAB_URL}"
    echo "CI Token: ${CI_TOKEN}"
    echo ""
    echo "📁 Configuration files:"
    echo "  - gitlab-fresh-config.json: User and token configuration"
    echo "  - repository-mirrors.json: Mirror status and project list"
    echo ""
    echo "🔧 Useful commands:"
    echo "  View logs: docker compose logs -f"
    echo "  Stop: docker compose down"
    echo "  Restart: docker compose restart"
    echo "  Backup: ./backup-gitlab.sh"
    echo ""
    echo "📚 Repository access:"
    echo "  GitHub mirrors: ${GITLAB_URL}/projects/github-*"
    echo "  GitLab mirrors: ${GITLAB_URL}/projects/gitlab-*"
    echo ""
    echo "⚠️  IMPORTANT:"
    echo "  - Change default user passwords"
    echo "  - Store tokens securely"
    echo "  - Consider revoking the root token"
else
    echo "⚠️  Configuration file not found. Check setup logs above."
fi
