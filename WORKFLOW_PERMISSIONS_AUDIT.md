# GitHub Actions Workflow Permissions Audit

**Date**: 2024-12-25  
**Issue**: CI failures due to missing workflow permissions  
**Resolution**: Added `actions: write` permission to all workflows that trigger other workflows

## Problem Statement

Multiple workflows were failing because they didn't have permission to trigger other workflows. By default, `GITHUB_TOKEN` in GitHub Actions cannot trigger other workflow runs to prevent infinite loops.

## Solution

Added `actions: write` permission to all workflows that need to trigger other workflows by:
- Pushing tags or branches
- Creating or merging PRs
- Making any code changes that should trigger CI/CD

## Complete Workflow Permissions Audit

### Workflows Requiring `actions: write` Permission (ALL FIXED)

#### 1. versioning.yml - Automated Versioning Workflow

**Purpose**: Creates version tags on PR merge  
**Triggers**: Release workflow via tag push  
**Permission Added**: `actions: write`

```yaml
tag-version:
  permissions:
    contents: write    # Create and push tags
    actions: write     # Trigger release workflow when pushing tags
```

**Why needed**: When this workflow pushes a tag (e.g., `v0.3.0`), it needs to trigger the release workflow. Without `actions: write`, the tag push is recorded but doesn't trigger other workflows.

---

#### 2. release.yml - Release Creation Workflow

**Purpose**: Creates GitHub releases and publishes Docker images  
**Triggers**: None (terminal workflow)  
**Permission Added**: `actions: write`

```yaml
create-release:
  permissions:
    contents: write      # Create releases and tags
    pull-requests: read  # Read PR data for release notes
    actions: write       # Trigger workflows if creating tags in manual mode
```

**Why needed**: In manual dispatch mode with `create_tag: true`, this workflow may create tags. If those tags should trigger other workflows, `actions: write` is required.

---

#### 3. auto-fix-ci.yml - Automatic Fix PR Creation

**Purpose**: Creates fix branches and PRs when CI fails  
**Triggers**: PR validation workflows  
**Permission Added**: `actions: write`

```yaml
permissions:
  contents: write       # Create branches and commits
  pull-requests: write  # Create PRs
  issues: write         # Update issues
  actions: write        # Trigger PR workflows when creating PRs
```

**Why needed**: When this workflow creates a new branch and PR, it should trigger PR validation and other PR-related workflows.

---

#### 4. pr-validation.yml - PR Validation and Auto-fix

**Purpose**: Validates PRs and applies automatic fixes  
**Triggers**: PR workflows on the same PR  
**Permission Added**: `actions: write`

```yaml
permissions:
  contents: write       # Push commits
  pull-requests: write  # Update PRs
  actions: write        # Trigger PR workflows when pushing commits
```

**Why needed**: When this workflow pushes auto-fix commits to a PR branch, it should re-trigger PR validation workflows.

---

#### 5. sync-dev-to-features.yml - Branch Synchronization

**Purpose**: Syncs dev changes to feature branches  
**Triggers**: Branch protection and CI workflows  
**Permission Added**: `actions: write`

```yaml
permissions:
  contents: write       # Push to branches
  pull-requests: write  # Update PRs if needed
  actions: write        # Trigger workflows when pushing to branches
```

**Why needed**: When this workflow pushes changes to feature branches, it should trigger CI workflows and branch protection checks.

---

#### 6. auto-merge-feature-to-dev.yml - Automatic Feature Merging

**Purpose**: Auto-merges approved feature PRs to dev  
**Triggers**: Dev branch workflows (including versioning)  
**Permission Added**: `actions: write`

```yaml
permissions:
  contents: write       # Merge PRs
  pull-requests: write  # Update PR status
  checks: read          # Check CI status
  actions: write        # Trigger workflows when merging PRs
```

**Why needed**: When this workflow merges a PR, the merge commit should trigger dev branch workflows like versioning and CI.

---

#### 7. auto-merge-subtasks.yml - Automatic Subtask Merging

**Purpose**: Auto-merges subtask PRs to parent branches  
**Triggers**: Branch workflows  
**Permission Added**: `actions: write`

```yaml
permissions:
  contents: write       # Merge PRs
  pull-requests: write  # Update PR status
  checks: read          # Check CI status
  actions: write        # Trigger workflows when merging PRs
```

**Why needed**: When this workflow merges a PR, the merge commit should trigger workflows on the target branch.

---

### Workflows NOT Requiring `actions: write`

These workflows don't push code or create changes that should trigger other workflows:

#### 8. auto-label.yml
- **Actions**: Adds labels to PRs/issues
- **Permissions**: `pull-requests: write`, `issues: write`
- **Status**: ✅ OK (no code changes, doesn't trigger workflows)

#### 9. auto-retry-failed.yml
- **Actions**: Retries failed workflow runs
- **Permissions**: `actions: write` (for retry, not for triggering new workflows)
- **Status**: ✅ OK (already has appropriate permissions)

#### 10. github-actions-runner.yml
- **Actions**: Manages GitHub Actions runners
- **Permissions**: Various for runner management
- **Status**: ✅ OK (no code changes)

#### 11. self-hosted-ci-status.yml
- **Actions**: Reports CI status
- **Permissions**: Read-only
- **Status**: ✅ OK (no code changes)

#### 12. self-hosted-runner-demo.yml
- **Actions**: Demo workflow
- **Permissions**: Read-only
- **Status**: ✅ OK (demo only)

#### 13. stale.yml
- **Actions**: Manages stale issues/PRs
- **Permissions**: `issues: write`, `pull-requests: write`
- **Status**: ✅ OK (no code changes, doesn't trigger workflows)

---

## Permission Matrix

| Workflow | Push Code/Tags | Merge PRs | Create PRs | actions:write | Status |
|----------|----------------|-----------|------------|---------------|--------|
| versioning.yml | ✅ Tags | ❌ | ❌ | ✅ Added | FIXED |
| release.yml | ✅ Tags (manual) | ❌ | ❌ | ✅ Added | FIXED |
| auto-fix-ci.yml | ✅ Branches | ❌ | ✅ | ✅ Added | FIXED |
| pr-validation.yml | ✅ Commits | ❌ | ❌ | ✅ Added | FIXED |
| sync-dev-to-features.yml | ✅ Branches | ❌ | ❌ | ✅ Added | FIXED |
| auto-merge-feature-to-dev.yml | ❌ | ✅ | ❌ | ✅ Added | FIXED |
| auto-merge-subtasks.yml | ❌ | ✅ | ❌ | ✅ Added | FIXED |
| auto-label.yml | ❌ | ❌ | ❌ | ❌ Not needed | OK |
| auto-retry-failed.yml | ❌ | ❌ | ❌ | ❌ Not needed | OK |
| github-actions-runner.yml | ❌ | ❌ | ❌ | ❌ Not needed | OK |
| self-hosted-ci-status.yml | ❌ | ❌ | ❌ | ❌ Not needed | OK |
| self-hosted-runner-demo.yml | ❌ | ❌ | ❌ | ❌ Not needed | OK |
| stale.yml | ❌ | ❌ | ❌ | ❌ Not needed | OK |

---

## Testing Recommendations

1. **Test versioning workflow**:
   - Merge a PR with code changes to dev or main
   - Verify tag is created
   - Verify release workflow is triggered by the tag

2. **Test PR auto-fix**:
   - Create a PR with formatting issues
   - Verify pr-validation applies fixes
   - Verify fixes trigger re-validation

3. **Test auto-merge**:
   - Create and approve a feature PR to dev
   - Verify auto-merge triggers versioning workflow

4. **Test sync workflow**:
   - Push to dev branch
   - Verify feature branches are synced
   - Verify CI runs on synced branches

5. **Verify no permission errors**:
   - Check all workflow logs for "Resource not accessible by integration" errors
   - Check workflow logs for permission denied errors

---

## References

- [GitHub Actions: Permissions](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token)
- [Triggering a workflow from a workflow](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow)
- [Using GITHUB_TOKEN in a workflow](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow)

---

## Key Insight

The `GITHUB_TOKEN` by default has limited permissions to prevent infinite workflow loops. When a workflow needs to trigger another workflow (e.g., by pushing tags, creating releases, merging PRs, or modifying code), it needs explicit `actions: write` permission. This is a security feature to ensure workflows don't accidentally trigger cascading runs.

**Summary**: Added `actions: write` to 7 workflows that perform operations triggering other workflows. All workflows now have appropriate permissions.
