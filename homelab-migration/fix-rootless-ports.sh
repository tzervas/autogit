#!/bin/bash
# Fix for Rootless Docker Privileged Port Issue
# GitLab needs ports 80/443 but rootless Docker can't bind to ports < 1024

set -euo pipefail

echo "🔧 Fixing Rootless Docker Port Configuration"
echo "=============================================="
echo ""

# Option 1: Lower unprivileged port start (requires sudo)
echo "Option 1: Allow rootless Docker to bind to ports 80 and 443"
echo ""
echo "This will add: net.ipv4.ip_unprivileged_port_start=80"
echo "to /etc/sysctl.conf (requires sudo password)"
echo ""
read -p "Apply this fix? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📝 Updating sysctl configuration..."

    # Backup existing config
    sudo cp /etc/sysctl.conf "/etc/sysctl.conf.backup-$(date +%Y%m%d-%H%M%S)"

    # Add unprivileged port config if not already present
    if ! grep -q "net.ipv4.ip_unprivileged_port_start" /etc/sysctl.conf; then
        echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee -a /etc/sysctl.conf
    fi

    # Apply immediately
    sudo sysctl -p

    echo "✅ Port configuration updated!"
    echo ""
    echo "You can now run: ./deploy.sh"
else
    echo ""
    echo "⚠️  Alternative: Use non-privileged ports"
    echo ""
    echo "Modify docker-compose.yml to use:"
    echo "  - 8080:80   (HTTP)"
    echo "  - 8443:443  (HTTPS)"
    echo "  - 2222:22   (SSH) ← already non-privileged"
    echo ""
    echo "Then access GitLab at: http://localhost:8080"
fi
