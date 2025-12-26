#!/usr/bin/env bash
# CLI Authentication Setup for GitLab
# Configures git and other tools to authenticate with GitLab

set -euo pipefail

# Load configuration
if [[ ! -f gitlab-fresh-config.json ]]; then
    echo "❌ gitlab-fresh-config.json not found. Run configure-gitlab-fresh.py first."
    exit 1
fi

GITLAB_URL=$(jq -r '.gitlab_url' gitlab-fresh-config.json)
CI_TOKEN=$(jq -r '.tokens.ci_token.token' gitlab-fresh-config.json)

echo "🔐 Setting up CLI authentication for GitLab..."

# Configure git credential helper
echo "📝 Configuring git credentials..."
git config --global credential.helper store

# Create .git-credentials file
CREDENTIALS_FILE="$HOME/.git-credentials"
GITLAB_HOST=$(echo "$GITLAB_URL" | sed 's|http://||' | sed 's|https://||')

# Add GitLab credentials
echo "http://ci-user:$CI_TOKEN@$GITLAB_HOST" >>"$CREDENTIALS_FILE"

# Set proper permissions
chmod 600 "$CREDENTIALS_FILE"

echo "✅ Git credentials configured"

# Configure GitLab CLI if available
if command -v glab >/dev/null 2>&1; then
    echo "🛠️  Configuring GitLab CLI (glab)..."
    glab auth login --hostname "$GITLAB_HOST" --token "$CI_TOKEN"
    echo "✅ GitLab CLI configured"
else
    echo "ℹ️  GitLab CLI (glab) not found. Install with: https://gitlab.com/gitlab-org/cli"
fi

# Test authentication
echo "🧪 Testing authentication..."
if git ls-remote "$GITLAB_URL/ci-user/test.git" >/dev/null 2>&1; then
    echo "✅ Authentication test passed"
else
    echo "⚠️  Authentication test failed (this is normal if no test repo exists)"
fi

echo ""
echo "🎉 CLI authentication setup complete!"
echo ""
echo "📋 Usage:"
echo "  git clone $GITLAB_URL/projects/github-repo-name.git"
echo "  glab project list"
echo ""
echo "🔑 Credentials stored in: $CREDENTIALS_FILE"
echo "⚠️  Keep this file secure and don't share it!"
