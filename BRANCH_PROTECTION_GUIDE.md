# Branch Protection Configuration Guide

## Overview

Branch protection rules can block automated workflows if not configured correctly. This guide explains the required settings for AutoGit's automated workflow system to function properly.

## Current Issue

**Problem**: Branch protection rules on `main` (and potentially `dev`) may block automated workflows from:
- Creating tags (versioning workflow)
- Pushing commits (auto-fix workflow)
- Creating releases (release workflow)
- Merging PRs (auto-merge workflows)

## Required Branch Protection Settings

### For `main` Branch

```yaml
Branch Protection Rules for: main

✅ REQUIRED SETTINGS (Keep Enabled):
  ☑ Require pull request before merging
    - Require approvals: 1
    - Dismiss stale PR approvals when new commits are pushed
  ☑ Require status checks to pass before merging
    - Require branches to be up to date before merging
    - Status checks: (add your CI checks here)
  ☑ Require conversation resolution before merging
  ☑ Do not allow bypassing the above settings

⚠️  SETTINGS THAT MAY BLOCK AUTOMATION (Configure Carefully):
  ☐ Require signed commits
    - If enabled: GitHub Actions commits ARE signed automatically
    - Safe to enable
    
  ☐ Require linear history
    - If enabled: May block merge commits
    - Recommended: Keep DISABLED for main
    
  ☐ Require deployments to succeed before merging
    - Configure based on your deployment strategy
    
  ☐ Lock branch
    - Must be DISABLED for automation to work
    - Blocks ALL pushes including from GitHub Actions

🔑 CRITICAL SETTINGS (Must Be Configured):
  ☑ Allow force pushes
    - MUST be DISABLED (already should be)
    
  ☑ Allow deletions
    - MUST be DISABLED (already should be)
    
  ☑ Allow GitHub Actions to create and approve pull requests
    - MUST be ENABLED in Repository Settings → Actions → General
    - This is separate from branch protection!
```

### For `dev` Branch

```yaml
Branch Protection Rules for: dev

✅ REQUIRED SETTINGS (Keep Enabled):
  ☑ Require pull request before merging
    - Require approvals: 1 (can be less strict than main)
  ☑ Require status checks to pass before merging
    - Status checks: (add your CI checks here)

⚠️  LESS STRICT (Development Branch):
  ☐ Require conversation resolution
    - Optional for dev
  ☐ Require signed commits
    - Optional for dev
  ☐ Require linear history
    - Recommended: DISABLED

🔑 CRITICAL SETTINGS (Same as main):
  ☑ Allow force pushes: DISABLED
  ☑ Allow deletions: DISABLED
  ☐ Lock branch: DISABLED
```

### For Feature Branches

```yaml
Branch Protection Rules for: feature/**

Recommendation: Minimal or no branch protection

Why?
- Feature branches are temporary
- Work-in-progress code is expected
- Developers need flexibility
- Auto-merge workflows handle merging to dev

If you DO protect feature branches:
  - Allow force pushes (for rebasing)
  - No approval requirements
  - Basic status checks only
```

## GitHub Actions Permissions

### Repository Settings → Actions → General

```yaml
Workflow Permissions:
  ☑ Read and write permissions
    - Required for: Creating tags, pushing commits, commenting on PRs
  
  ☑ Allow GitHub Actions to create and approve pull requests
    - CRITICAL: Must be enabled for automated workflows
    - Without this: Versioning and auto-merge workflows will fail
```

### Actions Secrets and Variables

No additional secrets are required for the automated workflows. They use `GITHUB_TOKEN` which is automatically provided.

## Common Issues and Solutions

### Issue 1: Versioning Workflow Can't Push Tags

**Symptoms:**
```
Error: refusing to allow a GitHub Actions bot to create or update workflow
Error: Resource not accessible by integration
```

**Solution:**
Enable in Settings → Actions → General:
```
☑ Allow GitHub Actions to create and approve pull requests
```

### Issue 2: Auto-fix Workflow Can't Push Commits

**Symptoms:**
```
Error: Protected branch update failed
Error: Required status checks must pass
```

**Solution:**
Either:
1. Add `github-actions[bot]` as an exception to branch protection, OR
2. Ensure the workflow runs BEFORE the PR is created (not after)

**Our approach**: The auto-fix workflow runs on the PR branch (before merge), so it doesn't need to push to protected branches.

### Issue 3: Release Workflow Fails

**Symptoms:**
```
Error: Cannot create release
Error: Insufficient permissions
```

**Solution:**
Check workflow permissions in the YAML file:
```yaml
permissions:
  contents: write  # Required for creating releases
  packages: write  # Required for publishing Docker images
```

### Issue 4: Signed Commits Required

**Symptoms:**
```
Error: Commits must be signed
```

**Solution:**
Good news! GitHub Actions commits ARE automatically signed by GitHub. If you're seeing this error:

1. Check if you're using a PAT (Personal Access Token) - these don't sign commits
2. Use `GITHUB_TOKEN` instead - it provides automatic signing
3. Verify the commit is from `github-actions[bot]`

## Checking Current Protection Rules

### Via GitHub UI

1. Go to: Repository → Settings → Branches
2. Look for "Branch protection rules"
3. Check settings for `main`, `dev`, and any patterns

### Via GitHub CLI

```bash
# Check protection rules for main branch
gh api repos/:owner/:repo/branches/main/protection

# Check protection rules for dev branch
gh api repos/:owner/:repo/branches/dev/protection

# Check Actions permissions
gh api repos/:owner/:repo --jq '.permissions'
```

### Via API

```bash
# Check main branch protection
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/tzervas/autogit/branches/main/protection

# Check Actions settings
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/tzervas/autogit/actions/permissions
```

## Recommended Configuration for AutoGit

### Optimal Settings Matrix

| Feature | main | dev | feature/** |
|---------|------|-----|------------|
| Require PR | ✅ Yes | ✅ Yes | ❌ No |
| Require approvals | ✅ 1+ | ✅ 1 | ❌ No |
| Require status checks | ✅ Yes | ✅ Yes | ⚠️ Optional |
| Signed commits | ✅ Yes | ⚠️ Optional | ❌ No |
| Linear history | ❌ No | ❌ No | ❌ No |
| Allow force pushes | ❌ No | ❌ No | ✅ Yes |
| Allow deletions | ❌ No | ❌ No | ✅ Yes |
| Lock branch | ❌ No | ❌ No | ❌ No |

### Actions Permissions

```
✅ Workflow permissions: Read and write
✅ Allow Actions to create PRs: Enabled
```

## Testing Branch Protection

### Test Versioning Workflow

```bash
# This should succeed if permissions are correct
gh workflow run versioning.yml
```

### Test Release Workflow

```bash
# Manual trigger should work
gh workflow run release.yml --field source_branch=dev --field version_mode=auto
```

### Test Auto-fix Workflow

1. Create a test PR with formatting issues
2. Auto-fix workflow should run
3. Commits should be pushed back to PR branch
4. No protection errors should occur

## Updating Branch Protection

### Via GitHub UI

1. Go to: Settings → Branches
2. Click "Edit" on the rule for `main`
3. Adjust settings per recommendations above
4. Click "Save changes"
5. Repeat for `dev` if needed

### Via GitHub CLI

```bash
# Update main branch protection
gh api -X PUT repos/:owner/:repo/branches/main/protection \
  --input protection-config.json

# Enable Actions to create PRs (repository-level setting)
gh api -X PUT repos/:owner/:repo/actions/permissions \
  -f default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true
```

### Via Terraform (if using Infrastructure as Code)

```hcl
resource "github_branch_protection" "main" {
  repository_id = github_repository.autogit.node_id
  pattern       = "main"

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
    required_approving_review_count = 1
  }

  required_status_checks {
    strict = true
    contexts = ["CI"]
  }

  enforce_admins = false  # Allow admins to bypass for emergencies
  
  # Critical: Don't lock the branch
  lock_branch = false
  
  # Allow Actions to work
  allows_force_pushes = false
  allows_deletions    = false
}
```

## Troubleshooting Checklist

If automated workflows are failing, check:

- [ ] Repository Settings → Actions → General → "Allow GitHub Actions to create and approve pull requests" is ENABLED
- [ ] Branch protection rule does NOT have "Lock branch" enabled
- [ ] Workflow YAML files have correct `permissions:` sections
- [ ] You're using `GITHUB_TOKEN` not a PAT
- [ ] Status checks (if required) are passing
- [ ] Branch is not protected from the bot account

## Priority Actions for Repository Owner

### 🔴 CRITICAL (Do This First)
1. Check if "Allow GitHub Actions to create and approve pull requests" is enabled
2. Verify `main` branch is not locked
3. Test versioning workflow manually

### 🟡 RECOMMENDED (Do Soon)
1. Review and update branch protection rules per this guide
2. Test the complete workflow chain
3. Document any custom protection rules

### 🟢 OPTIONAL (Nice to Have)
1. Set up branch protection for `dev`
2. Configure status check requirements
3. Set up CODEOWNERS file

## Documentation References

- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
- [Workflow Permissions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#permissions)

---

**Status**: Configuration guide for automated workflows
**Date**: 2025-12-25
**Action Required**: Repository owner should review and adjust branch protection rules
