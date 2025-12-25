# GitHub Actions Workflow Permissions Audit

**Date**: 2024-12-25  
**Issue**: CI failure due to missing workflow permissions  
**Resolution**: Added `actions: write` permission to workflows that trigger other workflows

## Problem Statement

The versioning workflow was failing because it didn't have permission to trigger the release workflow when pushing tags. By default, `GITHUB_TOKEN` in GitHub Actions cannot trigger other workflow runs to prevent infinite loops.

## Solution

Added `actions: write` permission to workflows that need to trigger other workflows by pushing tags or making changes that should trigger downstream workflows.

## Workflows Requiring `actions: write` Permission

### 1. versioning.yml - Automated Versioning Workflow

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

### 2. release.yml - Release Creation Workflow

**Purpose**: Creates GitHub releases and publishes Docker images  
**Triggers**: None (terminal workflow)  
**Permission Added**: `actions: write` (for manual mode tag creation)

```yaml
create-release:
  permissions:
    contents: write      # Create releases and tags
    pull-requests: read  # Read PR data for release notes
    actions: write       # Trigger workflows if creating tags in manual mode
```

**Why needed**: In manual dispatch mode with `create_tag: true`, this workflow may create tags. If those tags should trigger other workflows, `actions: write` is required.

## Workflows NOT Requiring `actions: write`

These workflows push code but don't need to trigger other workflows:

### 3. auto-fix-ci.yml
- **Pushes**: Fix branches
- **Permissions**: `contents: write`, `pull-requests: write`, `issues: write`
- **Status**: ✅ OK (doesn't need to trigger workflows)

### 4. pr-validation.yml
- **Pushes**: Commits to PR branches
- **Permissions**: `contents: write`, `pull-requests: write`
- **Status**: ✅ OK (doesn't need to trigger workflows)

### 5. sync-dev-to-features.yml
- **Pushes**: Updates to feature branches
- **Permissions**: `contents: write`, `pull-requests: write`
- **Status**: ✅ OK (doesn't need to trigger workflows)

## Permission Matrix

| Workflow | contents | pull-requests | issues | packages | actions | Reason for actions:write |
|----------|----------|---------------|--------|----------|---------|-------------------------|
| versioning.yml | write | read | - | - | **write** | Triggers release workflow via tag push |
| release.yml | write | read | - | write | **write** | May create tags in manual mode |
| auto-fix-ci.yml | write | write | write | - | - | Doesn't trigger other workflows |
| pr-validation.yml | write | write | - | - | - | Doesn't trigger other workflows |
| sync-dev-to-features.yml | write | write | - | - | - | Doesn't trigger other workflows |

## Testing Recommendations

1. **Test versioning workflow**:
   - Merge a PR with code changes to dev or main
   - Verify tag is created
   - Verify release workflow is triggered by the tag

2. **Test release workflow manual mode**:
   - Trigger manually with `create_tag: true`
   - Verify tag is created
   - Verify subsequent workflows (if any) are triggered

3. **Verify no permission errors**:
   - Check workflow logs for "Resource not accessible by integration" errors
   - Check workflow logs for permission denied errors

## References

- [GitHub Actions: Permissions](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token)
- [Triggering a workflow from a workflow](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow)
- [Using GITHUB_TOKEN in a workflow](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow)

## Key Insight

The `GITHUB_TOKEN` by default has limited permissions to prevent infinite workflow loops. When a workflow needs to trigger another workflow (e.g., by pushing tags, creating releases, or modifying code), it needs explicit `actions: write` permission. This is a security feature to ensure workflows don't accidentally trigger cascading runs.
