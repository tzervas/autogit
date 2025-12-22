#!/bin/bash
# Script to create a feature branch structure
# Usage: ./create-feature-branch.sh <feature-name> [subtask1] [subtask2] ...

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate branch name
validate_branch_name() {
    local name=$1
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        print_error "Branch name must contain only lowercase letters, numbers, and hyphens"
        return 1
    fi
    return 0
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check if feature name is provided
if [ $# -lt 1 ]; then
    print_error "Usage: $0 <feature-name> [subtask1] [subtask2] ..."
    print_info "Example: $0 gpu-scheduling detection-service scheduler-logic"
    exit 1
fi

FEATURE_NAME=$1
shift
SUBTASKS=("$@")

# Validate feature name
if ! validate_branch_name "$FEATURE_NAME"; then
    exit 1
fi

# Validate subtask names
for subtask in "${SUBTASKS[@]}"; do
    if ! validate_branch_name "$subtask"; then
        print_error "Invalid subtask name: $subtask"
        exit 1
    fi
done

# Ensure we're on dev branch and it's up to date
print_info "Checking out dev branch..."
git checkout dev

print_info "Updating dev branch..."
git pull origin dev

# Create feature branch
FEATURE_BRANCH="feature/$FEATURE_NAME"
print_info "Creating feature branch: $FEATURE_BRANCH"
git checkout -b "$FEATURE_BRANCH"
git push -u origin "$FEATURE_BRANCH"

# Create subtask branches if provided
if [ ${#SUBTASKS[@]} -gt 0 ]; then
    print_info "Creating sub-feature branches..."
    
    for subtask in "${SUBTASKS[@]}"; do
        SUBTASK_BRANCH="feature/$FEATURE_NAME/$subtask"
        print_info "Creating sub-feature branch: $SUBTASK_BRANCH"
        git checkout "$FEATURE_BRANCH"
        git checkout -b "$SUBTASK_BRANCH"
        git push -u origin "$SUBTASK_BRANCH"
    done
    
    # Return to feature branch
    git checkout "$FEATURE_BRANCH"
fi

print_info ""
print_info "✅ Feature branch structure created successfully!"
print_info ""
print_info "Branch structure:"
print_info "  └─ $FEATURE_BRANCH (current)"

if [ ${#SUBTASKS[@]} -gt 0 ]; then
    for subtask in "${SUBTASKS[@]}"; do
        print_info "      └─ feature/$FEATURE_NAME/$subtask"
    done
fi

print_info ""
print_info "Next steps:"
print_info "1. Work on sub-feature branches for individual subtasks"
print_info "2. Create PRs from sub-features to feature branch"
print_info "3. When all sub-features are merged, create PR from feature to dev"
print_info ""
print_info "To create a work branch from a sub-feature:"
print_info "  git checkout feature/$FEATURE_NAME/<subtask>"
print_info "  git checkout -b feature/$FEATURE_NAME/<subtask>/<work-item>"
print_info ""
