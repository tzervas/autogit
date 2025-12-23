#!/bin/bash
# Script to sync branches with their base branches
# Usage: ./sync-branches.sh [branch-name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Get current branch if not specified
if [ $# -eq 0 ]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    print_info "No branch specified, using current branch: $BRANCH"
else
    BRANCH=$1
    print_info "Syncing branch: $BRANCH"
    git checkout "$BRANCH"
fi

# Determine base branch based on branch name
get_base_branch() {
    local branch=$1

    # Protected branches sync with origin
    if [[ $branch == "main" ]]; then
        echo "origin/main"
        return
    fi

    if [[ $branch == "dev" ]]; then
        echo "origin/dev"
        return
    fi

    # Feature branches sync with dev
    if [[ $branch =~ ^feature/[a-z0-9-]+$ ]]; then
        echo "dev"
        return
    fi

    # Sub-feature branches sync with parent feature
    if [[ $branch =~ ^feature/([a-z0-9-]+)/[a-z0-9-]+$ ]]; then
        echo "feature/${BASH_REMATCH[1]}"
        return
    fi

    # Work branches sync with parent sub-feature
    if [[ $branch =~ ^feature/([a-z0-9-]+)/([a-z0-9-]+)/[a-z0-9-]+$ ]]; then
        echo "feature/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
        return
    fi

    # Hotfix branches sync with main
    if [[ $branch =~ ^hotfix/ ]]; then
        echo "main"
        return
    fi

    # Release branches sync with dev
    if [[ $branch =~ ^release/ ]]; then
        echo "dev"
        return
    fi

    # Default to dev for unknown patterns
    print_warn "Unknown branch pattern, defaulting to dev"
    echo "dev"
}

BASE_BRANCH=$(get_base_branch "$BRANCH")

print_info "Base branch: $BASE_BRANCH"

# Fetch latest changes
print_info "Fetching latest changes..."
git fetch origin

# Update base branch if it's local
if [[ ! $BASE_BRANCH =~ ^origin/ ]]; then
    print_info "Updating base branch: $BASE_BRANCH"
    git checkout "$BASE_BRANCH"
    git pull origin "$BASE_BRANCH"
    git checkout "$BRANCH"
fi

# Check if there are any conflicts before rebasing
print_info "Rebasing $BRANCH onto $BASE_BRANCH..."

if git rebase "$BASE_BRANCH"; then
    print_info "✅ Successfully synced $BRANCH with $BASE_BRANCH"
    print_info ""
    print_info "To push changes:"
    print_info "  git push origin $BRANCH --force-with-lease"
else
    print_error "Rebase failed! Please resolve conflicts manually."
    print_info ""
    print_info "To resolve conflicts:"
    print_info "  1. Fix conflicts in the listed files"
    print_info "  2. git add <resolved-files>"
    print_info "  3. git rebase --continue"
    print_info ""
    print_info "To abort rebase:"
    print_info "  git rebase --abort"
    exit 1
fi
