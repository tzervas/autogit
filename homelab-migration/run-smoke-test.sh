#!/bin/bash
# Smoke Test Deployment Script
# Deploys to homelab server and monitors GitLab initialization

set -euo pipefail

# Configuration
HOMELAB_USER="${HOMELAB_USER:-kang}"
HOMELAB_HOST="${HOMELAB_HOST:-192.168.1.170}"
HOMELAB_DIR="${HOMELAB_DIR:-/home/kang/autogit-homelab}"

echo "🧪 GitLab Homelab Smoke Test"
echo "================================"
echo "Target: ${HOMELAB_USER}@${HOMELAB_HOST}"
echo "Directory: ${HOMELAB_DIR}"
echo ""

# Function to run commands on homelab via SSH
run_remote() {
    ssh "${HOMELAB_USER}@${HOMELAB_HOST}" "$@"
}

# Step 1: Create remote directory
echo "📁 Creating remote directory..."
run_remote "mkdir -p ${HOMELAB_DIR}"

# Step 2: Copy docker-compose file
echo "📤 Copying docker-compose.homelab.yml..."
scp docker-compose.homelab.yml "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DIR}/docker-compose.yml"

# Step 3: Copy SSL certs if they exist
if [ -d "data/gitlab/ssl" ]; then
    echo "🔒 Copying SSL certificates..."
    run_remote "mkdir -p ${HOMELAB_DIR}/data/gitlab/ssl"
    scp -r data/gitlab/ssl/* "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DIR}/data/gitlab/ssl/"
else
    echo "⚠️  No SSL certs found - you'll need to generate them on homelab"
    echo "   Run: ./generate-ssl-cert.sh on homelab server"
fi

# Step 4: Copy smoke test checklist
echo "📋 Copying smoke test checklist..."
scp SMOKE_TEST.md "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DIR}/"

# Step 5: Check Docker Compose v2
echo "🔍 Verifying Docker Compose v2..."
if ! run_remote "docker compose version" 2> /dev/null; then
    echo "❌ Docker Compose v2 not found on homelab"
    echo "   Install: sudo apt install docker-compose-v2"
    exit 1
fi
echo "✅ Docker Compose v2 available"

# Step 6: Create deployment script on remote
echo "📝 Creating remote deployment script..."
ssh "${HOMELAB_USER}@${HOMELAB_HOST}" "cat > ${HOMELAB_DIR}/deploy.sh" << 'REMOTE_SCRIPT'
#!/bin/bash
set -euo pipefail

echo "🚀 Starting GitLab deployment..."
echo "Start time: $(date)"
echo ""

# Clean start (optional - uncomment for fresh deployment)
# echo "🧹 Cleaning previous data..."
# docker compose down -v
# rm -rf data/gitlab/data data/gitlab/logs

# Pull latest image
echo "📥 Pulling GitLab CE latest..."
docker compose pull

# Start services
echo "🚢 Starting services..."
docker compose up -d

echo ""
echo "✅ Deployment initiated"
echo "Monitor with: docker compose logs -f gitlab"
echo "Check health: curl -k https://localhost/-/health"
echo ""
echo "⏱️  Expected DB init time: 5-10 minutes"
echo "📊 Follow SMOKE_TEST.md for detailed monitoring"
REMOTE_SCRIPT

run_remote "chmod +x ${HOMELAB_DIR}/deploy.sh"

# Step 7: Instructions
echo ""
echo "✅ Smoke test files deployed!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next Steps - Run on Homelab Server:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. SSH to homelab:"
echo "   ssh ${HOMELAB_USER}@${HOMELAB_HOST}"
echo ""
echo "2. Navigate to deployment directory:"
echo "   cd ${HOMELAB_DIR}"
echo ""
echo "3. Start deployment:"
echo "   ./deploy.sh"
echo ""
echo "4. Monitor logs (in another terminal):"
echo "   docker compose logs -f gitlab"
echo ""
echo "5. Watch for these milestones:"
echo "   - PostgreSQL initialization (look for 'database system is ready')"
echo "   - GitLab DB migration (look for 'Migrating to')"
echo "   - Services ready (look for 'Workhorse successfully started')"
echo ""
echo "6. Test health endpoint (after ~5-10 min):"
echo "   curl -k https://localhost/-/health"
echo ""
echo "7. Check container status:"
echo "   docker compose ps"
echo ""
echo "8. Follow detailed checklist:"
echo "   cat SMOKE_TEST.md"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  IMPORTANT: Report back with results before proceeding!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
