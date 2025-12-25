# Release Workflow Documentation

## Overview

The release system consists of two workflows working together:
1. **Versioning Workflow** - Automatically creates version tags on PR merges
2. **Release Workflow** - Creates GitHub releases and publishes Docker images when tags are pushed

### Versioning Workflow (Automatic Tagging)

- Triggers when PRs are merged into `main` or `dev`
- Only runs if there are actual code changes (excludes docs-only PRs)
- Creates production tags (e.g., `v0.3.0`) for main branch
- Creates dev tags (e.g., `v0.3.1-dev.20241224`) for dev branch

### Release Workflow (Release Creation)

- Triggers when version tags are pushed (from versioning workflow)
- Creates GitHub releases with auto-generated notes
- Builds and publishes Docker images to GHCR in parallel
- Supports manual triggers with version override options

## Workflow Integration

```
PR Merge → dev/main
    ↓
Versioning Workflow
    ├─ Check for code changes
    ├─ Create version tag
    └─ Push tag to GitHub
        ↓
Release Workflow (triggered by tag push)
    ├─ Create GitHub release
    └─ Build & publish Docker images
```

## Trigger Mechanisms

### 1. Automatic Release (Recommended)

**For Production Releases:**
1. Merge feature PR into `dev` for testing
2. Create PR from `dev` to `main` with code changes
3. Merge PR - versioning workflow creates production tag
4. Release workflow automatically creates release and publishes images

**For Development Releases:**
1. Merge feature PR into `dev` with code changes
2. Versioning workflow creates dev tag
3. Release workflow creates pre-release

**Note**: Documentation-only PRs won't trigger versioning or releases.

### 2. Manual Release via Workflow Dispatch

Trigger manually from GitHub Actions UI with:

#### Inputs:
- **source_branch**: Choose `dev` or `main` (default: dev)
- **version_mode**: Choose `auto` or `manual` (default: auto)
  - `auto`: Automatically detect version from last merged PR or auto-increment
  - `manual`: Provide custom version override
- **manual_version**: Custom version (e.g., v0.3.0) - only used when version_mode is "manual"
- **create_tag**: Create git tag if it doesn't exist (default: true)

## Code Change Detection

The versioning workflow only triggers on PRs with actual code changes. The following file patterns are excluded:

**Excluded (Won't Trigger Versioning):**
- `*.md` - Markdown documentation
- `docs/` - Documentation directory
- `.github/workflows/` - Workflow files
- `.gitignore`, `LICENSE`, `README.md`, `CHANGELOG.md`
- `*.txt` - Text files

**Included (Will Trigger Versioning):**
- Source code files (`*.py`, `*.js`, `*.go`, etc.)
- Service files in `services/`
- Scripts in `scripts/`
- Configuration files (`*.yml`, `*.json`, `*.toml`)
- Docker files

## Version Detection Logic

### Versioning Workflow (Automatic Tags)

For production releases (main branch):
- Creates semantic version tags: `v0.3.0`, `v1.0.0`, etc.
- Version based on automate-version.sh script

For development releases (dev branch):
- Creates pre-release tags: `v0.3.1-dev.20241224130354`
- Includes timestamp for uniqueness

### Release Workflow (From Tags)

When triggered by tag push:
- Uses the tag version directly (no recalculation needed)
- Determines release type from tag pattern:
  - Production: `v0.3.0` (no suffix)
  - Development: `v0.3.1-dev.*` (has -dev suffix)

When triggered manually:
1. **Auto Mode**: Extracts version from last merged PR title
2. **Manual Mode**: Uses provided version directly

## Release Notes Generation

The workflow automatically generates release notes from:
- PR title and description (for PR-triggered releases)
- PR author attribution
- CHANGELOG.md sections (if available)
- GitHub's auto-generated release notes

## Docker Image Publishing

### Parallel Builds
- Uses matrix strategy to build multiple services in parallel
- Services: `git-server`, `runner-coordinator`
- `fail-fast: false` ensures all builds complete even if one fails

### Image Tags
For version `v0.3.0`, creates:
- `v0.3.0` (full version)
- `v0.3` (major.minor)
- `v0` (major only)
- `latest`
- `sha-<commit>` (commit hash)

### Layer Caching
Multi-source cache strategy for optimal build performance:
- Registry cache (previous builds)
- Dev images
- Latest release images
- GitHub Actions cache

## Self-Hosted Runner Configuration

All jobs run on self-hosted runners with ample resources for:
- Fast checkout and builds
- Parallel Docker builds
- Large-scale image layer caching

## Validation

Run the validation script to verify workflow configuration:

```bash
./scripts/validate-release-workflow.sh
```

This checks for:
- YAML syntax validity
- Required triggers and inputs
- PR merge validation (merged == true)
- Self-hosted runner configuration
- Parallel build setup
- Version mode options
- Branch selection options

## Example Usage

### Scenario 1: Automatic Production Release
```
1. Develop features on feature branches
2. Merge features into dev for testing
3. Create PR: dev → main (with code changes)
4. Merge PR
5. Versioning workflow:
   - Detects code changes
   - Creates tag v0.3.0
6. Release workflow:
   - Triggered by tag push
   - Creates GitHub release
   - Publishes Docker images
```

### Scenario 2: Automatic Development Release
```
1. Create feature PR to dev (with code changes)
2. Merge PR into dev
3. Versioning workflow:
   - Detects code changes
   - Creates tag v0.3.1-dev.20241224
4. Release workflow:
   - Triggered by tag push
   - Creates pre-release
   - Publishes Docker images
```

### Scenario 3: Documentation Update (No Release)
```
1. Update documentation files only
2. Create PR to main or dev
3. Merge PR
4. Versioning workflow:
   - Checks changed files
   - Detects only docs changes
   - Skips versioning (no tag created)
5. No release created
```

### Scenario 4: Manual Release
```
1. Go to Actions → Release workflow → Run workflow
2. Select:
   - source_branch: dev
   - version_mode: manual
   - manual_version: v0.4.0
3. Workflow creates v0.4.0 release manually
```

## Permissions Required

The workflow needs:
- `contents: write` - Create releases and tags
- `packages: write` - Publish Docker images to GHCR
- `pull-requests: read` - Read PR data for version detection

## Branch Strategy

Recommended workflow:
1. Develop on feature branches
2. Merge features into `dev` for testing
3. When ready for release, create PR: dev → main
4. Title PR with version (e.g., "Release v0.3.0")
5. Merge PR - automatic release triggered
6. Docker images published to GHCR

## Troubleshooting

### Workflow doesn't trigger on PR merge
- Ensure PR was merged (not closed without merge)
- Check that PR is from `dev` to `main`
- Verify workflow file syntax with validation script

### Version not detected from PR
- PR title must contain version in format: `vX.Y.Z`
- Check workflow logs for version extraction step
- Falls back to auto-increment if not found

### Docker build fails
- Check self-hosted runner has Docker installed
- Verify GHCR credentials are valid
- Check service Dockerfiles exist in `services/` directory

## Future Enhancements

Potential improvements:
- Support for pre-release versions (alpha, beta, rc)
- Changelog generation from commit messages
- Release approval workflow
- Multi-repository synchronization
- Rollback capabilities
