#!/bin/bash
# Script to validate branch name follows conventions
# Usage: ./validate-branch-name.sh <branch-name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

if [ $# -ne 1 ]; then
    print_error "Usage: $0 <branch-name>"
    exit 1
fi

BRANCH_NAME=$1

# Validate branch name patterns
validate_branch() {
    local branch=$1

    # Protected branches
    if [[ $branch == "main" || $branch == "dev" ]]; then
        print_success "Protected branch: $branch"
        return 0
    fi

    # Feature branches
    if [[ $branch =~ ^feature/[a-z0-9-]+$ ]]; then
        print_success "Valid feature branch: $branch"
        return 0
    fi

    # Sub-feature branches
    if [[ $branch =~ ^feature/[a-z0-9-]+/[a-z0-9-]+$ ]]; then
        print_success "Valid sub-feature branch: $branch"
        return 0
    fi

    # Work branches
    if [[ $branch =~ ^feature/[a-z0-9-]+/[a-z0-9-]+/[a-z0-9-]+$ ]]; then
        print_success "Valid work branch: $branch"
        return 0
    fi

    # Hotfix branches
    if [[ $branch =~ ^hotfix/[a-z0-9-]+$ ]]; then
        print_success "Valid hotfix branch: $branch"
        return 0
    fi

    # Release branches
    if [[ $branch =~ ^release/v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_success "Valid release branch: $branch"
        return 0
    fi

    # Copilot branches (special case for GitHub Copilot)
    if [[ $branch =~ ^copilot/.+$ ]]; then
        print_info "Copilot branch: $branch"
        return 0
    fi

    # If we get here, branch name is invalid
    print_error "Invalid branch name: $branch"
    echo ""
    print_info "Valid patterns:"
    print_info "  - feature/<name>"
    print_info "  - feature/<name>/<subtask>"
    print_info "  - feature/<name>/<subtask>/<work-item>"
    print_info "  - hotfix/<description>"
    print_info "  - release/v<major>.<minor>.<patch>"
    print_info "  - main (protected)"
    print_info "  - dev (protected)"
    echo ""
    print_info "Branch names must use lowercase letters, numbers, and hyphens only"
    return 1
}

validate_branch "$BRANCH_NAME"
