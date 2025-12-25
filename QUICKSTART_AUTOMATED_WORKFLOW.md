# Quick Start: Automated Development Workflow

## Overview

AutoGit now includes a fully automated development workflow that handles:

- ✅ Code quality checks before every commit
- ✅ Automatic code formatting and fixing
- ✅ Verified and signed commits
- ✅ Automated versioning on merge
- ✅ Automatic release creation

## Getting Started (5 Minutes)

### Step 1: Initial Setup

After cloning the repository, run these two setup scripts:

```bash
# Install pre-commit hooks
./scripts/setup-pre-commit.sh

# Configure git signing (optional but recommended)
./scripts/setup-git-signing.sh
```

That's it! You're ready to develop.

### Step 2: Make Changes

Work on your code normally:

```bash
# Create a feature branch
git checkout -b feature/my-awesome-feature

# Make your changes
vim services/runner-coordinator/main.py

# Stage your changes
git add .
```

### Step 3: Commit Your Changes

When you commit, pre-commit hooks automatically run:

```bash
git commit -m "feat(runners): add new feature"
```

**What happens:**

1. Pre-commit hooks check your code
1. Auto-fixes are applied (formatting, whitespace, etc.)
1. If fixes were made, you'll see what changed
1. Commit succeeds with clean code

**Use this commit format:**

```
<type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore, ci
Scope: The component you changed (runners, auth, workflows)
```

### Step 4: Push and Create PR

```bash
git push origin feature/my-awesome-feature
```

Then create a PR on GitHub targeting `dev` branch.

**What happens automatically:**

1. Pre-commit auto-fix workflow runs
1. Any missed fixes are applied
1. Changes are committed back to your PR
1. You get a comment showing what was fixed

### Step 5: Merge

Once approved, merge your PR into `dev`.

**What happens automatically:**

1. Versioning workflow creates a version tag (e.g., `v0.3.1-dev.20241225`)
1. Release workflow triggers
1. GitHub release is created
1. Docker images are published

**For production releases:**

- Merge `dev` → `main`
- Creates production version (e.g., `v0.3.0`)
- Publishes production release

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Tests
- `chore`: Maintenance
- `ci`: CI/CD changes

### Examples

```bash
# Good commit messages
git commit -m "feat(runners): add GPU detection support"
git commit -m "fix(auth): resolve token expiration bug"
git commit -m "docs(readme): update installation guide"
git commit -m "ci(workflows): optimize build cache"

# Bad commit messages (will be rejected)
git commit -m "fixed stuff"
git commit -m "WIP"
git commit -m "Update file.py"
```

## What Gets Auto-Fixed?

Pre-commit hooks automatically fix:

### File Hygiene

- Trailing whitespace
- Missing newlines at end of file
- Mixed line endings (converts to LF)
- Large files check

### Code Formatting

- **Python**: Black formatter, isort imports
- **Shell scripts**: shfmt formatting
- **YAML**: Pretty formatting
- **Markdown**: Consistent formatting

### Validation

- YAML/JSON syntax
- Shell scripts (shellcheck)
- Dockerfiles (hadolint)
- Secrets detection
- Merge conflict markers

## Skipping Hooks (Not Recommended)

In rare cases, you might need to skip pre-commit hooks:

```bash
# Skip pre-commit hooks (use with caution!)
git commit --no-verify -m "fix: emergency hotfix"
```

**Warning:** Skipped commits may fail CI checks and won't be automatically fixed.

## Troubleshooting

### Pre-commit hook fails

```bash
# Run manually to see the issue
pre-commit run --all-files

# Fix issues and try again
git add .
git commit -m "fix: resolve lint issues"
```

### Hook is too strict

If a hook is blocking you incorrectly:

1. Try to fix the underlying issue first
1. Check `.pre-commit-config.yaml` for hook configuration
1. Report the issue so we can adjust the hooks

### Need to update hooks

```bash
# Update to latest hook versions
pre-commit autoupdate

# Reinstall hooks
pre-commit install --install-hooks
```

## Advanced: Manual Pre-commit Run

Run pre-commit on specific files:

```bash
# Run on all files
pre-commit run --all-files

# Run on specific files
pre-commit run --files services/runner-coordinator/*.py

# Run specific hook
pre-commit run black --all-files
```

## CI/CD Workflow Chain

Here's the complete automated workflow:

```
1. Developer commits
   ↓ (pre-commit hooks auto-fix)
2. Commit succeeds
   ↓
3. Push to feature branch
   ↓
4. Create PR to dev
   ↓ (pre-commit-auto-fix workflow)
5. PR auto-fixed if needed
   ↓
6. Review and merge
   ↓ (versioning workflow)
7. Version tag created
   ↓ (release workflow)
8. Release + Docker images published
```

## Files You Should Know About

- `.pre-commit-config.yaml` - Hook configuration
- `.gitmessage` - Commit message template
- `scripts/setup-pre-commit.sh` - Pre-commit installer
- `scripts/setup-git-signing.sh` - Git signing setup
- `docs/AUTOMATED_WORKFLOWS.md` - Complete documentation

## Getting Help

- **Documentation**: See `docs/AUTOMATED_WORKFLOWS.md`
- **Implementation Details**: See `IMPLEMENTATION_SUMMARY.md`
- **Issues**: Open a GitHub issue
- **Questions**: Start a GitHub discussion

## Benefits of This System

✅ **Consistent Code Quality**: All code is automatically formatted ✅ **Fewer Review Comments**:
Linting catches issues before review ✅ **Faster Reviews**: Reviewers focus on logic, not style ✅
**Automatic Releases**: Version and release on merge ✅ **Verified Commits**: All commits are signed
and verified ✅ **Less Manual Work**: Automation handles routine tasks

______________________________________________________________________

**Ready to contribute?** Run the setup scripts and start coding! 🚀
