#!/bin/bash
# Validate release workflow configuration
# This script checks the release.yml workflow for common issues

set -e

WORKFLOW_FILE=".github/workflows/release.yml"
ERRORS=0

echo "🔍 Validating release workflow..."
echo ""

# Check 1: File exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi
echo "✅ Workflow file exists"

# Check 2: YAML syntax
if ! python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2> /dev/null; then
    echo "❌ Invalid YAML syntax"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ YAML syntax valid"
fi

# Check 3: Required triggers
if ! grep -q "pull_request:" "$WORKFLOW_FILE"; then
    echo "❌ Missing pull_request trigger"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ pull_request trigger present"
fi

if ! grep -q "workflow_dispatch:" "$WORKFLOW_FILE"; then
    echo "❌ Missing workflow_dispatch trigger"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ workflow_dispatch trigger present"
fi

# Check 4: Merged PR validation
if ! grep -q "github.event.pull_request.merged == true" "$WORKFLOW_FILE"; then
    echo "❌ Missing merged PR validation (should check 'merged == true')"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Merged PR validation present"
fi

# Check 5: Self-hosted runners
if ! grep -q "runs-on: self-hosted" "$WORKFLOW_FILE"; then
    echo "❌ Not configured for self-hosted runners"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Self-hosted runners configured"
fi

# Check 6: Matrix strategy for parallel builds
if ! grep -q "matrix:" "$WORKFLOW_FILE"; then
    echo "❌ Missing matrix strategy for parallel builds"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Matrix strategy present"
fi

# Check 7: Version mode choices
if ! grep -q "version_mode:" "$WORKFLOW_FILE"; then
    echo "❌ Missing version_mode input"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ version_mode input present"
fi

if ! grep -q "\- auto" "$WORKFLOW_FILE" || ! grep -q "\- manual" "$WORKFLOW_FILE"; then
    echo "❌ Missing auto/manual version mode options"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Version mode options (auto/manual) present"
fi

# Check 8: Branch selection
if ! grep -q "source_branch:" "$WORKFLOW_FILE"; then
    echo "❌ Missing source_branch input"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ source_branch input present"
fi

if ! grep -q "\- dev" "$WORKFLOW_FILE" || ! grep -q "\- main" "$WORKFLOW_FILE"; then
    echo "❌ Missing dev/main branch options"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Branch options (dev/main) present"
fi

# Check 9: GitHub CLI usage for PR data
if ! grep -q "gh pr list" "$WORKFLOW_FILE"; then
    echo "⚠️  Warning: No GitHub CLI usage found for PR data extraction"
fi

# Check 10: Parallel build optimization
if ! grep -q "fail-fast: false" "$WORKFLOW_FILE"; then
    echo "⚠️  Warning: fail-fast not set to false (may stop parallel builds early)"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Validation passed! No errors found."
    echo ""
    echo "Key features verified:"
    echo "  • Triggers on merged PRs (not closed PRs)"
    echo "  • Manual dispatch with branch selection"
    echo "  • Version mode selection (auto/manual)"
    echo "  • Self-hosted runners configured"
    echo "  • Parallel builds via matrix strategy"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
fi
