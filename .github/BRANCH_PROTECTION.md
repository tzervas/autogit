# Branch Protection Rules Configuration

This document describes the branch protection rules that should be configured in GitHub repository
settings.

## Overview

AutoGit uses automated merge workflows with different approval requirements based on the branch
hierarchy:

- **Work → Subtask**: Auto-merge with evaluator approval or `auto-merge` label
- **Subtask → Feature**: Auto-merge with evaluator approval or `auto-merge` label
- **Feature → Dev**: Auto-merge after owner (@tzervas) approval
- **Dev → Main**: Manual merge after owner review (requires explicit approval)

## Branch Protection Rules

### Main Branch

**Branch name pattern**: `main`

**Protection rules**:

- ✅ Require pull request reviews before merging
  - Required approving reviews: 1
  - Dismiss stale pull request approvals when new commits are pushed: Yes
  - Require review from Code Owners: Yes
  - Require approval from specific users: @tzervas
- ✅ Require status checks to pass before merging
  - Require branches to be up to date before merging: Yes
  - Required status checks:
    - `CI / Lint Shell Scripts`
    - `CI / Lint YAML Files`
    - `CI / Validate Docker Files`
    - `Docker Build and Test / Build Git Server Image`
    - `Docker Build and Test / Build Runner Coordinator Image`
- ✅ Require conversation resolution before merging
- ✅ Require linear history (squash or rebase)
- ✅ Include administrators
- ✅ Restrict who can push to matching branches
  - Allowed: @tzervas (owner only)
- ✅ Allow force pushes: No
- ✅ Allow deletions: No

### Dev Branch

**Branch name pattern**: `dev`

**Protection rules**:

- ✅ Require pull request reviews before merging
  - Required approving reviews: 1
  - Dismiss stale pull request approvals when new commits are pushed: Yes
  - Require review from Code Owners: Yes
  - Require approval from specific users: @tzervas (for feature→dev merges)
- ✅ Require status checks to pass before merging
  - Require branches to be up to date before merging: Yes
  - Required status checks:
    - `CI / Lint Shell Scripts`
    - `CI / Lint YAML Files`
    - `CI / Validate Docker Files`
    - `Docker Build and Test / Build Git Server Image`
    - `Docker Build and Test / Build Runner Coordinator Image`
    - `PR Validation / Validate Branch Naming Convention`
    - `PR Validation / Validate PR Target Branch`
- ✅ Require conversation resolution before merging
- ✅ Require linear history (squash)
- ❌ Include administrators: No (allows auto-merge)
- ✅ Restrict who can push to matching branches
  - Allowed: @tzervas, github-actions bot
- ✅ Allow force pushes: No
- ✅ Allow deletions: No

### Feature Branches (Level 1)

**Branch name pattern**: `feature/*`

**Protection rules**:

- ✅ Require pull request reviews before merging
  - Required approving reviews: 1
  - Dismiss stale pull request approvals when new commits are pushed: No
  - Require review from Code Owners: No
  - Allow specified actors to bypass: @tzervas
- ✅ Require status checks to pass before merging
  - Require branches to be up to date before merging: No
  - Required status checks:
    - `CI / Lint Shell Scripts`
    - `CI / Validate Docker Files`
- ✅ Require conversation resolution before merging
- ✅ Require linear history (squash)
- ❌ Include administrators: No (allows auto-merge)
- ✅ Restrict who can push to matching branches
  - Allowed: @tzervas, github-actions bot
- ✅ Allow force pushes: No
- ✅ Allow deletions: No

### Subtask Branches (Level 2)

**Branch name pattern**: `feature/*/*`

**Protection rules**:

- ✅ Require pull request reviews before merging
  - Required approving reviews: 1
  - Dismiss stale pull request approvals when new commits are pushed: No
  - Require review from Code Owners: No
  - Allow any approver (evaluator agent or auto-merge label)
- ✅ Require status checks to pass before merging
  - Require branches to be up to date before merging: No
  - Required status checks:
    - `CI / Lint Shell Scripts`
    - `CI / Validate Docker Files`
- ❌ Require conversation resolution before merging: No (optional)
- ✅ Require linear history (squash)
- ❌ Include administrators: No (allows auto-merge)
- ✅ Restrict who can push to matching branches
  - Allowed: @tzervas, github-actions bot, contributors
- ✅ Allow force pushes: No
- ✅ Allow deletions: Yes (after merge)

### Work Branches (Level 3)

**Branch name pattern**: `feature/*/*/*`

**Protection rules**:

- ❌ No protection rules required
- Work branches are ephemeral and deleted after merge

## Auto-Merge Configuration

### Prerequisites for Auto-Merge

All auto-merge workflows require:

1. All required CI checks must pass
1. Branch must be mergeable (no conflicts)
1. PR must not have `no-auto-merge` label

### Work → Subtask Auto-Merge

**Workflow**: `.github/workflows/auto-merge-subtasks.yml`

**Trigger conditions**:

- PR from `feature/x/y/z` to `feature/x/y`
- Approved by evaluator OR has `auto-merge` label
- All CI checks pass

**Merge method**: Squash

**Permissions needed**:

- `contents: write`
- `pull-requests: write`

### Subtask → Feature Auto-Merge

**Workflow**: `.github/workflows/auto-merge-subtasks.yml`

**Trigger conditions**:

- PR from `feature/x/y` to `feature/x`
- Approved by evaluator OR has `auto-merge` label
- All CI checks pass

**Merge method**: Squash

**Permissions needed**:

- `contents: write`
- `pull-requests: write`

### Feature → Dev Auto-Merge

**Workflow**: `.github/workflows/auto-merge-feature-to-dev.yml`

**Trigger conditions**:

- PR from `feature/x` to `dev`
- Approved by @tzervas (owner) OR has `owner-approved` label
- All CI checks pass

**Merge method**: Squash

**Permissions needed**:

- `contents: write`
- `pull-requests: write`

## Repository Settings

### General Settings

- **Allow merge commits**: No
- **Allow squash merging**: Yes (default merge method)
- **Allow rebase merging**: Yes
- **Always suggest updating pull request branches**: Yes
- **Allow auto-merge**: Yes (required for workflows)
- **Automatically delete head branches**: Yes

### Actions Permissions

Navigate to: Settings → Actions → General

- **Actions permissions**: Allow all actions and reusable workflows
- **Workflow permissions**: Read and write permissions
  - Allow GitHub Actions to create and approve pull requests: Yes

This is required for auto-merge workflows to function.

### Branch Settings

Navigate to: Settings → Branches

- **Default branch**: `dev` (not main)
  - Main is protected and only receives releases
  - All development happens in dev and feature branches

## Labels Required

The following labels must exist in the repository (defined in `.github/labels.yml`):

- `auto-merge` - Allows auto-merge without explicit review
- `owner-approved` - Indicates owner approval for feature→dev
- `no-auto-merge` - Prevents auto-merge even if criteria met
- `merge-conflict` - Auto-created when sync fails

## Setup Instructions

### 1. Configure Branch Protection Rules

For each branch pattern above:

1. Go to Settings → Branches
1. Click "Add branch protection rule"
1. Enter the branch name pattern
1. Configure the protection rules as specified
1. Save changes

### 2. Enable Auto-Merge

1. Go to Settings → General
1. Scroll to "Pull Requests"
1. Check "Allow auto-merge"
1. Check "Automatically delete head branches"
1. Save changes

### 3. Configure Actions Permissions

1. Go to Settings → Actions → General
1. Under "Actions permissions", select "Allow all actions and reusable workflows"
1. Under "Workflow permissions", select "Read and write permissions"
1. Check "Allow GitHub Actions to create and approve pull requests"
1. Save changes

### 4. Create Required Labels

Run this command to create labels from `.github/labels.yml`:

```bash
# Using GitHub CLI
gh label create auto-merge --description "Auto-merge when ready" --color "0e8a16"
gh label create owner-approved --description "Approved by repository owner" --color "0e8a16"
gh label create no-auto-merge --description "Prevent automatic merging" --color "d93f0b"
gh label create merge-conflict --description "Automatic merge conflict" --color "b60205"
```

Or use a label sync action to apply all labels from `.github/labels.yml`.

### 5. Test Auto-Merge

Create a test work branch and PR:

```bash
# Create test branches
git checkout dev
git checkout -b feature/test-feature
git push -u origin feature/test-feature

git checkout -b feature/test-feature/test-subtask
git push -u origin feature/test-feature/test-subtask

git checkout -b feature/test-feature/test-subtask/test-work
echo "test" > test.txt
git add test.txt
git commit -m "test: verify auto-merge"
git push -u origin feature/test-feature/test-subtask/test-work

# Create PR from test-work → test-subtask
# Add auto-merge label or get evaluator approval
# Watch it auto-merge when checks pass
```

## Troubleshooting

### Auto-merge not working

1. Check Actions permissions are set correctly
1. Verify branch protection rules don't include administrators
1. Ensure PR doesn't have `no-auto-merge` label
1. Check all required status checks are passing
1. Verify workflow has `contents: write` permission

### Permission denied errors

1. Go to Settings → Actions → General
1. Ensure "Read and write permissions" is selected
1. Ensure "Allow GitHub Actions to create and approve pull requests" is checked

### Workflow not triggering

1. Check workflow file syntax
1. Verify trigger conditions match your PR
1. Check Actions tab for error messages
1. Ensure workflows are enabled in repository settings

## Security Considerations

### Protected Main Branch

Main branch is fully protected and requires:

- Owner approval only
- All CI checks pass
- Manual review of changes
- No force pushes allowed

### Dev Branch Protection

Dev branch allows automated merges from feature branches but:

- Still requires owner approval for feature merges
- All CI checks must pass
- Automated actors have limited permissions

### Feature Branch Flexibility

Feature and subtask branches have looser protection to enable:

- Fast iteration cycles
- Automated evaluator approvals
- Quick subtask merges

## Maintenance

### Regular Reviews

- Review auto-merge patterns monthly
- Adjust required checks as needed
- Update approval requirements based on team changes
- Review and update labels

### Monitoring

- Monitor auto-merge success rate
- Review failed auto-merges
- Check for merge conflicts requiring manual resolution
- Track time from PR open to merge

## Related Documentation

- [Branching Strategy](../../docs/development/branching-strategy.md)
- [Auto-Merge Workflows](./README.md)
- [Contributing Guide](../../docs/CONTRIBUTING.md)
