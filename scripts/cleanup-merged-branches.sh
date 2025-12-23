#!/bin/bash
# Script to clean up merged branches
# Usage: ./cleanup-merged-branches.sh [--dry-run]

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

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    print_info "Running in dry-run mode (no branches will be deleted)"
fi

# Fetch latest changes
print_info "Fetching latest changes..."
git fetch origin --prune

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Protected branches that should never be deleted
PROTECTED_BRANCHES=("main" "dev")

# Find merged branches
print_info "Finding merged branches..."
echo ""

# Check branches merged into dev
print_info "Branches merged into dev:"
MERGED_INTO_DEV=$(git branch --merged dev | grep -v "^\*" | grep -v "main" | grep -v "dev" || true)

if [ -z "$MERGED_INTO_DEV" ]; then
    print_info "  No branches merged into dev"
else
    echo "$MERGED_INTO_DEV" | while read -r branch; do
        branch=$(echo "$branch" | xargs) # Trim whitespace

        # Skip if protected
        IS_PROTECTED=false
        for protected in "${PROTECTED_BRANCHES[@]}"; do
            if [ "$branch" = "$protected" ]; then
                IS_PROTECTED=true
                break
            fi
        done
        if [ "$IS_PROTECTED" = true ]; then
            continue
        fi

        # Skip if current branch
        if [ "$branch" == "$CURRENT_BRANCH" ]; then
            print_warn "  Skipping current branch: $branch"
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            print_info "  Would delete: $branch"
        else
            print_info "  Deleting: $branch"
            git branch -d "$branch" 2>/dev/null || print_warn "    Could not delete $branch (may have unmerged changes)"
        fi
    done
fi

echo ""

# Check branches merged into main
print_info "Branches merged into main:"
MERGED_INTO_MAIN=$(git branch --merged main | grep -v "^\*" | grep -v "main" | grep -v "dev" || true)

if [ -z "$MERGED_INTO_MAIN" ]; then
    print_info "  No branches merged into main"
else
    echo "$MERGED_INTO_MAIN" | while read -r branch; do
        branch=$(echo "$branch" | xargs) # Trim whitespace

        # Skip if protected
        IS_PROTECTED=false
        for protected in "${PROTECTED_BRANCHES[@]}"; do
            if [ "$branch" = "$protected" ]; then
                IS_PROTECTED=true
                break
            fi
        done
        if [ "$IS_PROTECTED" = true ]; then
            continue
        fi

        # Skip if current branch
        if [ "$branch" == "$CURRENT_BRANCH" ]; then
            print_warn "  Skipping current branch: $branch"
            continue
        fi

        # Skip if already deleted in previous step
        if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            print_info "  Would delete: $branch"
        else
            print_info "  Deleting: $branch"
            git branch -d "$branch" 2>/dev/null || print_warn "    Could not delete $branch (may have unmerged changes)"
        fi
    done
fi

echo ""

# Clean up remote tracking branches
print_info "Cleaning up remote tracking branches..."
git remote prune origin

echo ""

if [ "$DRY_RUN" = true ]; then
    print_info "✅ Dry-run complete. Run without --dry-run to actually delete branches."
else
    print_info "✅ Cleanup complete!"
fi

echo ""
print_info "Remaining local branches:"
git branch | grep -v "^\*" | while read -r branch; do
    branch=$(echo "$branch" | xargs)
    if [ "$branch" == "$CURRENT_BRANCH" ]; then
        print_info "  * $branch (current)"
    else
        print_info "    $branch"
    fi
done
