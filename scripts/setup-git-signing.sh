#!/bin/bash

# Configure Git for Verified Commits
# This script configures Git to sign commits, ensuring all commits are verified

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Git Commit Signing Configuration                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running in GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
    echo -e "${YELLOW}🤖 Running in GitHub Actions${NC}"
    echo -e "${YELLOW}   Commits will be automatically signed by GitHub${NC}"

    # Configure git for GitHub Actions
    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

    # GitHub Actions commits are automatically signed via web interface
    # No need to configure GPG

    echo -e "${GREEN}✓ Git configured for GitHub Actions${NC}"
    exit 0
fi

# For local development
echo -e "${YELLOW}📍 Configuring for local development${NC}"
echo ""

# Set commit message template
REPO_ROOT=$(git rev-parse --show-toplevel 2> /dev/null || pwd)
git config commit.template "$REPO_ROOT/.gitmessage"
echo -e "${GREEN}✓ Commit message template configured${NC}"

# Check if GPG is available
if command -v gpg &> /dev/null; then
    echo -e "${YELLOW}🔐 GPG is available${NC}"

    # Check if user has a GPG key
    if gpg --list-secret-keys --keyid-format LONG 2> /dev/null | grep -q "sec"; then
        echo -e "${GREEN}✓ GPG key found${NC}"

        # Get the first GPG key ID
        KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)

        if [ -n "$KEY_ID" ]; then
            echo -e "${YELLOW}   Using GPG key: $KEY_ID${NC}"
            git config user.signingkey "$KEY_ID"
            git config commit.gpgsign true
            echo -e "${GREEN}✓ GPG signing enabled${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No GPG key found${NC}"
        echo -e "${YELLOW}   To enable signed commits, generate a GPG key:${NC}"
        echo -e "   ${BLUE}gpg --full-generate-key${NC}"
        echo -e "   ${BLUE}git config user.signingkey YOUR_KEY_ID${NC}"
        echo -e "   ${BLUE}git config commit.gpgsign true${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  GPG not found${NC}"
    echo -e "${YELLOW}   Install GPG to enable commit signing${NC}"
    echo ""
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Configuration Complete                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✨ Git is configured!${NC}"
echo ""
echo -e "${YELLOW}Current configuration:${NC}"
git config --get user.name && echo -e "  Name: $(git config --get user.name)"
git config --get user.email && echo -e "  Email: $(git config --get user.email)"
git config --get commit.template &> /dev/null && echo -e "  Template: Configured"
git config --get commit.gpgsign &> /dev/null && echo -e "  GPG Signing: Enabled" || echo -e "  GPG Signing: Disabled"
echo ""
