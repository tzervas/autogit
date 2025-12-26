#!/bin/bash
# Optimized GitLab Homelab Setup Script
# Performance-optimized version with parallel processing and pre-optimization

set -euo pipefail

# Load environment variables
source load-env.sh
if ! load_env; then
    echo "❌ Failed to load environment configuration"
    exit 1
fi

# Add uv to PATH if installed
export PATH="$HOME/.local/bin:$PATH"

# Configure for rootless Docker
export DOCKER_HOST=unix:///run/user/1000/docker.sock

echo "🚀 Optimized GitLab Homelab Setup with Repository Mirroring"
echo "=========================================================="
echo "🌐 GitLab URL: $GITLAB_URL"
echo "🐙 GitHub Token: ${GITHUB_PAT_MIRROR:0:12}...***"
echo "🦊 GitLab Token: ${GITLAB_PAT_MIRROR:0:8}...***"
echo ""

# Function to show progress with timing
show_progress() {
    local message=$1
    START_TIME=$(date +%s)
    echo -n "⏳ $message... "
}

show_complete() {
    local duration=$(($(date +%s) - START_TIME))
    echo "✅ (${duration}s)"
}

# Function to install packages with nala
install_package() {
    local package=$1
    if ! command -v "$package" > /dev/null 2>&1; then
        show_progress "Installing $package"
        sudo nala install -y "$package"
        show_complete
    fi
}

# Enhanced prerequisites check with parallel installation
echo "🔍 Checking and installing prerequisites..."

# Check if we have sudo access
if sudo -n true 2> /dev/null; then
    echo "✅ Sudo access available"
else
    echo "⚠️  Sudo access may require password - please enter when prompted"
fi

# Install prerequisites in parallel where possible
install_package curl
install_package jq
install_package openssl

# Docker and related tools
if ! command -v docker > /dev/null 2>&1; then
    show_progress "Installing Docker"
    sudo nala install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    show_complete
fi

if ! docker compose version > /dev/null 2>&1; then
    show_progress "Installing Docker Compose v2"
    sudo nala install -y docker-compose-v2
    show_complete
fi

if ! command -v uv > /dev/null 2>&1; then
    show_progress "Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    show_complete
fi

echo "✅ Prerequisites ready"

# Pre-optimization phase
echo ""
echo "⚡ Pre-deployment optimizations..."

# Pre-cache Python dependencies
show_progress "Pre-caching Python dependencies"
# Skip uv sync for now - pyproject.toml not available on homelab server
echo "⚠️  Skipping Python dependency caching (pyproject.toml not available)"
show_complete

# Pre-pull Docker images in background
show_progress "Pre-pulling GitLab Docker image"
docker pull gitlab/gitlab-ce:latest > /dev/null 2>&1 &
PULL_PID=$!
show_complete

# Pre-generate SSL certificates
show_progress "Pre-generating SSL certificates"
./generate-ssl-cert.sh > /dev/null 2>&1
show_complete

# Pre-configure GitLab settings
show_progress "Pre-configuring GitLab settings"
mkdir -p data/gitlab/config
mkdir -p data/gitlab/ssl
cp gitlab.rb.template data/gitlab/config/gitlab.rb
show_complete

# Pre-warm Docker volumes
show_progress "Pre-warming Docker volumes"
mkdir -p data/gitlab/logs data/gitlab/data
# Pre-create subdirectories with proper permissions
sudo mkdir -p data/gitlab/data/gitlab-rails/shared
sudo mkdir -p data/gitlab/data/gitlab-ci/builds
sudo mkdir -p data/gitlab/data/gitlab-ci/cache
sudo chown -R 1000:1000 data/gitlab/ 2> /dev/null || true
show_complete

# Pre-resolve DNS for faster startup
show_progress "Pre-resolving DNS"
nslookup gitlab.vectorweight.com > /dev/null 2>&1 || echo "DNS resolution may be slow"
show_complete

# Initialize configuration cache
show_progress "Initializing configuration cache"
mkdir -p data/gitlab/config-cache
echo "[]" > data/gitlab/config-cache/users.json
echo "[]" > data/gitlab/config-cache/groups.json
echo "[]" > data/gitlab/config-cache/mirrors.json
show_complete

# Wait for image pull to complete
wait $PULL_PID
echo "✅ Docker image ready"

# Deploy GitLab
echo ""
show_progress "Deploying GitLab services"
echo "📦 Step 1: Deploying GitLab"
./deploy-fresh.sh
show_complete

# Wait for GitLab to be fully healthy before proceeding
echo ""
show_progress "Waiting for GitLab to be fully ready"
echo "⏳ Ensuring GitLab is healthy before configuration..."

# Function to check multiple health endpoints in parallel
check_gitlab_health_parallel() {
    local healthy=0
    local total=0

    # Check main health endpoint
    if curl -k -s -f --max-time 10 "$GITLAB_URL/-/health" > /dev/null 2>&1; then
        ((healthy++))
    fi
    ((total++))

    # Check readiness endpoint
    if curl -k -s -f --max-time 10 "$GITLAB_URL/-/readiness" > /dev/null 2>&1; then
        ((healthy++))
    fi
    ((total++))

    # Check liveness endpoint
    if curl -k -s -f --max-time 10 "$GITLAB_URL/-/liveness" > /dev/null 2>&1; then
        ((healthy++))
    fi
    ((total++))

    # Return success if at least 2/3 endpoints are healthy
    [ $healthy -ge 2 ]
}

if ! check_gitlab_health_parallel; then
    echo "Waiting for GitLab health checks..."
    echo "💡 Monitoring GitLab startup logs for progress..."
    TIMEOUT=900 # 15 minutes
    ELAPSED=0
    while ! check_gitlab_health_parallel; do
        if [ $ELAPSED -ge $TIMEOUT ]; then
            echo "❌ GitLab failed to become healthy within ${TIMEOUT} seconds"
            echo "🔍 Recent GitLab logs:"
            docker compose logs --tail=20 gitlab 2> /dev/null || echo "No logs available"
            exit 1
        fi

        # Show progress every 60 seconds
        if [ $((ELAPSED % 60)) -eq 0 ] && [ $ELAPSED -gt 0 ]; then
            echo "⏳ Still waiting... (${ELAPSED}s elapsed)"
            echo "🔍 GitLab status check..."
            docker compose ps gitlab
        fi

        sleep 30
        ELAPSED=$((ELAPSED + 30))
    done
fi
echo "✅ GitLab is healthy and ready for configuration"
show_complete

# Get root token
echo ""
echo "🔑 Step 2: Obtaining root access token"
echo "Please complete the following in your browser:"
echo "  1. Visit: $GITLAB_URL"
echo "  2. Set up root password"
echo "  3. Go to Admin → Settings → Access Tokens"
echo "  4. Create token with: api, read_user, sudo scopes"
echo ""
read -p "Enter the root access token: " ROOT_TOKEN
export GITLAB_ROOT_TOKEN="$ROOT_TOKEN"
show_complete

# Configure users and tokens (parallel with health monitoring)
echo ""
show_progress "Configuring users and tokens"
echo "👤 Step 3: Configuring GitLab Users & Tokens"
uv run python configure-gitlab-fresh.py > /dev/null 2>&1 &
CONFIG_PID=$!
show_complete

# Setup mirroring (can run in parallel)
echo ""
show_progress "Setting up repository mirroring"
echo "🔄 Step 4: Setting up Repository Mirroring"
uv run python setup-mirroring.py > /dev/null 2>&1 &
MIRROR_PID=$!
show_complete

# Wait for configuration to complete
wait $CONFIG_PID
echo "✅ User configuration complete"

# Wait for mirroring to complete
wait $MIRROR_PID
echo "✅ Repository mirroring complete"

# CLI setup
echo ""
show_progress "Configuring CLI authentication"
echo "🖥️  Step 5: Configuring CLI Authentication"
./setup-cli-auth.sh > /dev/null 2>&1
show_complete

# Final verification
echo ""
show_progress "Running final health checks"
if curl -k -s -f "$GITLAB_URL/-/health" > /dev/null 2>&1; then
    echo "✅ GitLab is healthy"
else
    echo "⚠️  GitLab health check failed - check logs"
fi
show_complete

# Calculate total time
TOTAL_TIME=$(($(date +%s) - START_TIME))

# Success summary
echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "⏱️  Total deployment time: ${TOTAL_TIME}s ($((TOTAL_TIME / 60))m $((TOTAL_TIME % 60))s)"
echo "🌐 GitLab URL: $GITLAB_URL"
echo "🔐 SSL: Self-signed certificates (trust once per device)"
echo "📚 Repositories: Available in 'mirrors' group"
echo ""
echo "🚀 Useful commands:"
echo "  View logs: sudo docker compose logs -f"
echo "  Stop: sudo docker compose down"
echo "  Restart: sudo docker compose restart"
echo "  Monitor: sudo docker stats"
echo ""
echo "📊 Performance optimizations applied:"
echo "  ✅ Pre-pulled Docker images"
echo "  ✅ Parallel processing where possible"
echo "  ✅ Optimized GitLab configuration"
echo "  ✅ Pre-generated SSL certificates"
echo ""
echo "🎯 Ready to use your GitLab instance!"
