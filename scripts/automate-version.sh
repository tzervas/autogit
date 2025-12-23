#!/bin/bash

# AutoGit Versioning Script
# Automates semantic versioning and tagging for the AutoGit project.

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to get the current version from git tags
get_current_version() {
    local version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "$version"
}

# Function to increment semantic version
increment_version() {
    local version=$1
    local type=$2 # major, minor, patch
    
    local major=$(echo $version | cut -d. -f1 | tr -d 'v')
    local minor=$(echo $version | cut -d. -f2)
    local patch=$(echo $version | cut -d. -f3 | cut -d- -f1)
    
    case $type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "v$major.$minor.$patch"
}

# Main logic
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_VERSION=$(get_current_version)

echo -e "${YELLOW}Current Branch:${NC} $CURRENT_BRANCH"
echo -e "${YELLOW}Current Version:${NC} $CURRENT_VERSION"

if [[ "$CURRENT_BRANCH" == "main" ]]; then
    # On main, we do full releases
    echo -e "${YELLOW}Detected main branch. Preparing for a full release...${NC}"
    # Logic for determining major/minor/patch could be based on commit messages (e.g., feat:, fix:, BREAKING CHANGE:)
    # For now, default to patch unless specified
    TYPE=${1:-patch}
    NEW_VERSION=$(increment_version $CURRENT_VERSION $TYPE)
    
elif [[ "$CURRENT_BRANCH" == "dev" ]]; then
    # On dev, we do pre-releases
    echo -e "${YELLOW}Detected dev branch. Preparing for a pre-release...${NC}"
    PATCH_VERSION=$(increment_version $CURRENT_VERSION patch)
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    NEW_VERSION="${PATCH_VERSION}-dev.${TIMESTAMP}"
    
else
    # On feature/sub-feature branches, we do dev tags
    echo -e "${YELLOW}Detected feature/work branch. Preparing for a dev tag...${NC}"
    # Sanitize branch name for tag
    SAFE_BRANCH=$(echo $CURRENT_BRANCH | sed 's/[^a-zA-Z0-9]/-/g')
    PATCH_VERSION=$(increment_version $CURRENT_VERSION patch)
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    NEW_VERSION="${PATCH_VERSION}-${SAFE_BRANCH}.${TIMESTAMP}"
fi

echo -e "${GREEN}New Version:${NC} $NEW_VERSION"

# Create the tag
git tag -a "$NEW_VERSION" -m "AutoGit Version $NEW_VERSION (Branch: $CURRENT_BRANCH)"
echo -e "${GREEN}Successfully created tag $NEW_VERSION${NC}"

# Push the tag
echo -e "${YELLOW}Pushing tag to origin...${NC}"
git push origin "$NEW_VERSION"
echo -e "${GREEN}Successfully pushed tag $NEW_VERSION${NC}"
