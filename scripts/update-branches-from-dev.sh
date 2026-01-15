#!/usr/bin/env bash
# Update all feature branches from dev with auto-resolution

set -e

BRANCHES=(
    "feature/rust-gitlab-cli"
    "feature/homelab-migration-tooling"
    "feature/rust-build-infrastructure"
    "feature/homelab-gitlab-deployment"
    "feature/observability-stack"
    "feature/docs-architecture"
    "feature/dev-tooling"
    "feature/github-workflows"
)

# Files to auto-resolve by taking dev version (tracking/status files)
AUTO_RESOLVE_FILES=(
    "RELEASE_CI_UPDATE.md"
    "WORKFLOW_PERMISSIONS_AUDIT.md"
    ".github/AGENTIC_WORKFLOW.md"
    "AGENT_WORK_SUMMARY.md"
    "READY_TO_MERGE.md"
    ".github/MERGE_PLAN.md"
    "BRANCH_INDEX.md"
    "NEXT_10_ITEMS.md"
    "BRANCH_AUDIT_COMPLETE.md"
)

echo "🔄 Updating feature branches from dev..."
echo ""

for branch in "${BRANCHES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Processing: $branch"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Checkout branch
    if ! git checkout "$branch" 2> /dev/null; then
        echo "  ⚠️  Branch not found locally, skipping"
        echo ""
        continue
    fi

    # Pull latest
    git pull origin "$branch" --no-edit 2> /dev/null || true

    # Try to merge dev
    if git merge dev --no-edit -m "chore: merge dev to sync with PR #42 (pre-commit automation)"; then
        echo "  ✅ Clean merge!"
    else
        echo "  ⚠️  Conflicts detected - auto-resolving..."

        # Auto-resolve tracking files (take dev version)
        for file in "${AUTO_RESOLVE_FILES[@]}"; do
            if git diff --name-only --diff-filter=U 2> /dev/null | grep -q "^${file}$"; then
                echo "    📄 Auto-resolving: $file (using dev version)"
                git checkout --theirs "$file"
                git add "$file"
            fi
        done

        # Check for remaining conflicts
        REMAINING=$(git diff --name-only --diff-filter=U 2> /dev/null || true)
        if [ -n "$REMAINING" ]; then
            echo ""
            echo "  ❌ Manual conflicts remain:"
            printf '%s\n' "$REMAINING" | sed 's/^/      - /'
            echo ""
            echo "  🛑 Aborting merge for $branch"
            git merge --abort
            echo ""
            continue
        fi

        # Complete the merge
        if git commit --no-edit --no-verify -m "chore: merge dev to sync with PR #42 (pre-commit automation)"; then
            echo "  ✅ Auto-resolved all conflicts"
        else
            echo "  ❌ Commit failed"
            echo ""
            continue
        fi
    fi

    # Push
    echo "  📤 Pushing to origin..."
    if git push origin "$branch" --force-with-lease; then
        echo "  ✅ Successfully pushed $branch"
    else
        echo "  ⚠️  Push failed for $branch"
    fi

    echo ""
done

git checkout dev
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Branch update complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
