#!/bin/bash
# Setup GitHub Actions Runner on Homelab
# This script configures a self-hosted runner that connects to GitHub Actions

set -e

echo "🚀 Setting up GitHub Actions Runner on Homelab"
echo "=============================================="

# Configuration
RUNNER_VERSION="2.317.0"
RUNNER_DIR="/opt/github-runner"
REPO_URL="https://github.com/tzervas/autogit"
RUNNER_NAME="homelab-runner-$(hostname)"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
apt-get update
apt-get install -y curl jq

# Create runner user
if ! id -u github-runner > /dev/null 2>&1; then
    echo "👤 Creating github-runner user..."
    useradd --create-home --shell /bin/bash github-runner
fi

# Create runner directory
echo "📁 Creating runner directory..."
mkdir -p $RUNNER_DIR
chown github-runner:github-runner $RUNNER_DIR

# Download and extract runner
echo "⬇️ Downloading GitHub Actions Runner v${RUNNER_VERSION}..."
cd $RUNNER_DIR
su github-runner -c "
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
"

# Get registration token
echo "🔑 Getting runner registration token..."
# This would need to be done interactively or with a PAT that has repo admin access
echo "⚠️  Manual step required:"
echo "   1. Go to https://github.com/tzervas/autogit/settings/actions/runners"
echo "   2. Click 'New self-hosted runner'"
echo "   3. Copy the registration token"
echo "   4. Run the registration command below with the token:"
echo ""
echo "   cd $RUNNER_DIR"
echo "   sudo -u github-runner ./config.sh --url $REPO_URL --token YOUR_TOKEN --name $RUNNER_NAME --labels homelab,self-hosted,linux,x64"
echo ""
echo "   Then start the runner:"
echo "   sudo -u github-runner ./run.sh"
echo ""

# Create systemd service
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/github-runner.service << EOF
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=github-runner
WorkingDirectory=$RUNNER_DIR
ExecStart=$RUNNER_DIR/run.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo "✅ GitHub Actions Runner setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Register the runner with GitHub (see commands above)"
echo "2. Start the service: systemctl enable --now github-runner"
echo "3. Check status: systemctl status github-runner"
echo ""
echo "The runner will automatically:"
echo "• Connect to GitHub Actions"
echo "• Pick up jobs labeled with 'self-hosted'"
echo "• Run them on your homelab hardware"
