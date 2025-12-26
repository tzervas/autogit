#!/bin/bash
# Quick Fix: Deploy GitLab with Rootless Docker
# Uses non-privileged ports (8080/8443) instead of 80/443

set -euo pipefail

echo "🚀 GitLab Rootless Docker Deployment"
echo "====================================="
echo ""
echo "📋 Configuration:"
echo "  - HTTP: http://localhost:8080"
echo "  - HTTPS: https://localhost:8443 (if SSL configured)"
echo "  - SSH: ssh://git@localhost:2222"
echo ""

# Copy rootless config
if [ ! -f "docker-compose.rootless.yml" ]; then
    echo "❌ docker-compose.rootless.yml not found"
    echo "   Run deployment from local machine first"
    exit 1
fi

# Use rootless config
cp docker-compose.rootless.yml docker-compose.yml

# Pull images
echo "📥 Pulling images..."
docker compose pull

# Start services
echo "🚢 Starting services..."
docker compose up -d

echo ""
echo "✅ Deployment initiated!"
echo ""
echo "📊 Monitor with:"
echo "  docker compose logs -f gitlab"
echo ""
echo "🔍 Check health:"
echo "  curl http://localhost:8080/-/health"
echo ""
echo "🌐 Access GitLab:"
echo "  http://localhost:8080"
echo "  (Use port forwarding if accessing remotely)"
echo ""
echo "⏱️  Expected init time: 8-10 minutes"
