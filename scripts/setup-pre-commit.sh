#!/bin/bash

# Setup Pre-commit Hooks for AutoGit
# This script installs and configures pre-commit hooks for automatic code quality checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     AutoGit Pre-commit Hook Setup                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed. Please install Python 3.11+${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${GREEN}✓ Found Python $PYTHON_VERSION${NC}"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}❌ pip3 is not installed. Please install pip3${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found pip3${NC}"
echo ""

# Install or upgrade pre-commit
echo -e "${YELLOW}📦 Installing/upgrading pre-commit...${NC}"
pip3 install --user --upgrade pre-commit

# Verify installation
if ! command -v pre-commit &> /dev/null; then
    echo -e "${YELLOW}⚠️  pre-commit not found in PATH${NC}"
    echo -e "${YELLOW}   Adding ~/.local/bin to PATH for this session${NC}"
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v pre-commit &> /dev/null; then
        echo -e "${RED}❌ Failed to install pre-commit${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ pre-commit installed successfully${NC}"
echo ""

# Navigate to repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2> /dev/null || pwd)
cd "$REPO_ROOT"

echo -e "${YELLOW}📍 Repository root: $REPO_ROOT${NC}"
echo ""

# Install pre-commit hooks
echo -e "${YELLOW}🔧 Installing pre-commit hooks...${NC}"
pre-commit install --install-hooks

# Install commit-msg hook for conventional commits
echo -e "${YELLOW}🔧 Installing commit-msg hook...${NC}"
pre-commit install --hook-type commit-msg

# Install pre-push hook
echo -e "${YELLOW}🔧 Installing pre-push hook...${NC}"
pre-commit install --hook-type pre-push

echo -e "${GREEN}✓ Pre-commit hooks installed${NC}"
echo ""

# Update hook environments
echo -e "${YELLOW}🔄 Updating hook environments (this may take a few minutes)...${NC}"
pre-commit install-hooks

echo -e "${GREEN}✓ Hook environments updated${NC}"
echo ""

# Run on all files to establish baseline
echo -e "${YELLOW}🧪 Running pre-commit on all files to establish baseline...${NC}"
echo -e "${YELLOW}   (This will auto-fix any issues found)${NC}"
echo ""

if pre-commit run --all-files; then
    echo -e "${GREEN}✓ All checks passed! Your repository is clean.${NC}"
else
    echo -e "${YELLOW}⚠️  Some files were auto-fixed by pre-commit${NC}"
    echo -e "${YELLOW}   Please review the changes and commit them:${NC}"
    echo ""
    echo -e "   ${BLUE}git add -u${NC}"
    echo -e "   ${BLUE}git commit -m 'style: apply pre-commit auto-fixes'${NC}"
    echo ""
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Setup Complete!                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✨ Pre-commit hooks are now active!${NC}"
echo ""
echo -e "${YELLOW}What happens next:${NC}"
echo -e "  • Every commit will automatically run code quality checks"
echo -e "  • Files will be auto-fixed for formatting issues"
echo -e "  • Commits will be blocked if critical issues are found"
echo -e "  • Commit messages will be validated for conventional format"
echo ""
echo -e "${YELLOW}Commit message format:${NC}"
echo -e "  ${BLUE}type(scope): description${NC}"
echo -e "  Examples:"
echo -e "    • ${BLUE}feat(api): add new endpoint for user management${NC}"
echo -e "    • ${BLUE}fix(auth): resolve token expiration issue${NC}"
echo -e "    • ${BLUE}docs(readme): update installation instructions${NC}"
echo -e "    • ${BLUE}style(format): apply black formatting${NC}"
echo ""
echo -e "${YELLOW}To manually run pre-commit on all files:${NC}"
echo -e "  ${BLUE}pre-commit run --all-files${NC}"
echo ""
echo -e "${YELLOW}To skip hooks (not recommended):${NC}"
echo -e "  ${BLUE}git commit --no-verify${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
