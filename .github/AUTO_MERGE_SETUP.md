# Auto-Merge Setup Guide

This guide will help you configure GitHub repository settings to enable the automated merge
workflows.

## Prerequisites

- Repository admin access
- GitHub CLI installed (optional, but recommended)

## Quick Setup

### Step 1: Enable Auto-Merge Feature

1. Go to your repository on GitHub
1. Click **Settings**
1. Scroll down to **Pull Requests** section
1. Check ✅ **Allow auto-merge**
1. Check ✅ **Automatically delete head branches**
1. Click **Save changes**

### Step 2: Configure GitHub Actions Permissions

1. In Settings, click **Actions** → **General**
1. Under **Workflow permissions**, select:
   - ✅ **Read and write permissions**
   - ✅ **Allow GitHub Actions to create and approve pull requests**
1. Click **Save**

### Step 3: Create Labels

Run these commands with GitHub CLI:

```bash
cd /home/runner/work/autogit/autogit

# Create auto-merge labels
gh label create "auto-merge" \
  --description "Enable automatic merging when checks pass" \
  --color "0e8a16"

gh label create "owner-approved" \
  --description "Approved by repository owner for merge to dev" \
  --color "0e8a16"

gh label create "no-auto-merge" \
  --description "Prevent automatic merging" \
  --color "d93f0b"

gh label create "merge-conflict" \
  --description "Has merge conflicts that need resolution" \
  --color "b60205"
```

Or create all labels from the configuration file:

```bash
gh label create --force $(cat .github/labels.yml | yq -r '.[] | "--name \(.name) --description \"\(.description)\" --color \(.color)"')
```

### Step 4: Set Up Branch Protection Rules

#### Protect Main Branch

```bash
gh api repos/:owner/:repo/branches/main/protection \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI / Lint Shell Scripts",
      "CI / Lint YAML Files",
      "Docker Build and Test / Build Git Server Image"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismissal_restrictions": {},
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": {
    "users": ["tzervas"],
    "teams": []
  },
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "required_linear_history": true
}
EOF
```

#### Protect Dev Branch

```bash
gh api repos/:owner/:repo/branches/dev/protection \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI / Lint Shell Scripts",
      "CI / Lint YAML Files",
      "Docker Build and Test / Build Git Server Image",
      "PR Validation / Validate Branch Naming Convention"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismissal_restrictions": {},
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "required_linear_history": true
}
EOF
```

#### Protect Feature Branches

```bash
# Feature branches (feature/*)
gh api repos/:owner/:repo/branches/feature%2F*/protection \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "CI / Lint Shell Scripts",
      "CI / Validate Docker Files"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "required_linear_history": true
}
EOF
```

## Manual Setup (Web UI)

If you prefer to use the GitHub web interface:

### Main Branch Protection

1. Go to Settings → Branches
1. Click **Add branch protection rule**
1. Branch name pattern: `main`
1. Configure:
   - ✅ Require a pull request before merging
     - Required approvals: 1
     - ✅ Dismiss stale pull request approvals
     - ✅ Require review from Code Owners
   - ✅ Require status checks to pass
     - ✅ Require branches to be up to date
     - Add: `CI / Lint Shell Scripts`
     - Add: `CI / Lint YAML Files`
     - Add: `Docker Build and Test / Build Git Server Image`
   - ✅ Require conversation resolution
   - ✅ Require linear history
   - ✅ Do not allow bypassing the above settings
   - ✅ Restrict who can push to matching branches
     - Add: `tzervas` (your username)
1. Click **Create**

### Dev Branch Protection

1. Go to Settings → Branches
1. Click **Add branch protection rule**
1. Branch name pattern: `dev`
1. Configure:
   - ✅ Require a pull request before merging
     - Required approvals: 1
     - ✅ Dismiss stale pull request approvals
     - ✅ Require review from Code Owners
   - ✅ Require status checks to pass
     - ✅ Require branches to be up to date
     - Add status checks (same as main)
   - ✅ Require conversation resolution
   - ✅ Require linear history
   - ❌ Do not allow bypassing the above settings (must remain unchecked so github-actions bot can
     auto-merge)
1. Click **Create**

### Feature Branch Protection

1. Go to Settings → Branches
1. Click **Add branch protection rule**
1. Branch name pattern: `feature/*`
1. Configure:
   - ✅ Require a pull request before merging
     - Required approvals: 1
   - ✅ Require status checks to pass
     - Add: `CI / Lint Shell Scripts`
   - ✅ Require linear history
1. Click **Create**

## Testing the Setup

### Test Auto-Merge (Work → Subtask)

```bash
# Create test structure
git checkout dev
git pull origin dev

git checkout -b feature/test-auto-merge
git push -u origin feature/test-auto-merge

git checkout -b feature/test-auto-merge/test-subtask
git push -u origin feature/test-auto-merge/test-subtask

git checkout -b feature/test-auto-merge/test-subtask/test-work
echo "test" > test-auto-merge.txt
git add test-auto-merge.txt
git commit -m "test: verify auto-merge functionality"
git push -u origin feature/test-auto-merge/test-subtask/test-work

# Create PR from test-work → test-subtask
gh pr create \
  --base feature/test-auto-merge/test-subtask \
  --head feature/test-auto-merge/test-subtask/test-work \
  --title "Test: Auto-merge work to subtask" \
  --body "Testing automated merge workflow"

# Add auto-merge label to trigger automation
gh pr edit --add-label "auto-merge"

# Watch for auto-merge to occur
gh pr view --web
```

### Test Auto-Merge (Feature → Dev)

```bash
# Create PR from feature → dev
gh pr create \
  --base dev \
  --head feature/test-auto-merge \
  --title "Test: Auto-merge feature to dev" \
  --body "Testing automated merge workflow with owner approval"

# As owner, approve the PR
gh pr review --approve

# Watch for auto-merge to occur
gh pr view --web
```

## Verification Checklist

- [ ] Auto-merge is enabled in repository settings
- [ ] GitHub Actions has read/write permissions
- [ ] GitHub Actions can create/approve PRs
- [ ] All required labels exist
- [ ] Main branch is protected with admin enforcement
- [ ] Dev branch is protected but allows auto-merge
- [ ] Feature branches have basic protection
- [ ] CODEOWNERS file is recognized
- [ ] Test PR auto-merges successfully

## Troubleshooting

### Auto-merge not triggering

**Problem**: PR is approved and checks pass, but auto-merge doesn't happen

**Solutions**:

1. Check Actions permissions: Settings → Actions → General
1. Verify `enforce_admins` is disabled for dev/feature branches
1. Ensure PR doesn't have `no-auto-merge` label
1. Check workflow logs in Actions tab

### Permission errors

**Problem**: Workflow fails with "Resource not accessible by integration"

**Solutions**:

1. Enable "Read and write permissions" in Actions settings
1. Enable "Allow GitHub Actions to create and approve pull requests"
1. Check workflow has `contents: write` and `pull-requests: write` permissions

### Branch protection conflicts

**Problem**: Auto-merge blocked by branch protection

**Solutions**:

1. Ensure `enforce_admins` is false for branches that need auto-merge
1. Verify required checks are specified correctly in workflow
1. Add github-actions bot to allowed users for pushing

### Status checks not recognized

**Problem**: Required status checks never marked as passing

**Solutions**:

1. Verify exact name of check in workflow file
1. Check Actions tab for failed runs
1. Ensure check runs before merge attempt
1. Remove "Require branches to be up to date" temporarily for testing

## Next Steps

After setup is complete:

1. **Document for team**: Share this guide with contributors
1. **Create templates**: Use PR templates for consistency
1. **Monitor workflows**: Watch first few auto-merges closely
1. **Adjust as needed**: Fine-tune based on team feedback
1. **Regular reviews**: Audit permissions and rules monthly

## Support

For issues or questions:

- Check [Branch Protection Documentation](.github/BRANCH_PROTECTION.md)
- Review [Workflows README](.github/workflows/README.md)
- Open an issue in the repository
- Review GitHub Actions logs

## Resources

- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
- [Auto-merge Pull Requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)
