# Release Workflow Documentation

## Overview

The updated release workflow provides flexible, automated release management with support for:
- Automatic releases triggered by PR merges
- Manual releases with version control options
- Intelligent version detection from PR data
- Parallel Docker image builds on self-hosted runners

## Trigger Mechanisms

### 1. Automatic Release on PR Merge (dev → main)

When a PR is merged from `dev` into `main`, the workflow automatically:
- Detects the merge event (filters out closed-without-merge PRs)
- Extracts version information from the PR title (e.g., "Release v0.3.0")
- Falls back to auto-increment if no version found in PR title
- Generates release notes from the PR description
- Creates the release and publishes Docker images

**Important**: The workflow uses `pull_request.types: [closed]` but checks `merged == true` to ensure only merged PRs trigger releases, not cancelled/closed PRs.

### 2. Manual Release via Workflow Dispatch

Trigger manually from GitHub Actions UI with:

#### Inputs:
- **source_branch**: Choose `dev` or `main` (default: dev)
- **version_mode**: Choose `auto` or `manual` (default: auto)
  - `auto`: Automatically detect version from last merged PR or auto-increment
  - `manual`: Provide custom version override
- **manual_version**: Custom version (e.g., v0.3.0) - only used when version_mode is "manual"
- **create_tag**: Create git tag if it doesn't exist (default: true)

### 3. Tag Push

Traditional release trigger - pushing a version tag (v*.*.*) triggers the workflow.

### 4. Direct Push to Main

Pushing directly to main branch also triggers a release.

## Version Detection Logic

### Auto Mode (version_mode: auto)

1. **From PR Title**: Extracts version pattern like `v0.3.0` from PR title
   - Examples: "Release v0.3.0", "Merge v0.3.0 changes", "v0.3.0"
   
2. **Auto-increment**: If no version in PR title, increments from latest tag
   - Checks recent commits for version bump hints:
     - "BREAKING CHANGE" or "major" → major version bump (v1.0.0 → v2.0.0)
     - "feat", "feature", or "minor" → minor version bump (v0.2.0 → v0.3.0)
     - Otherwise → patch version bump (v0.2.1 → v0.2.2)

### Manual Mode (version_mode: manual)

Uses the provided `manual_version` input directly. Must match format: `vX.Y.Z`

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

### Scenario 1: Automatic Release from PR
1. Create PR from `dev` to `main` with title: "Release v0.3.0"
2. Add detailed changes in PR description
3. Merge the PR
4. Workflow automatically:
   - Creates release v0.3.0
   - Uses PR description for release notes
   - Builds and publishes Docker images

### Scenario 2: Manual Release with Auto-detection
1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Select:
   - source_branch: `dev`
   - version_mode: `auto`
4. Workflow automatically:
   - Gets last merged PR into dev
   - Extracts version from PR title
   - Creates release with PR details

### Scenario 3: Manual Release with Custom Version
1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Select:
   - source_branch: `main`
   - version_mode: `manual`
   - manual_version: `v0.4.0`
4. Workflow creates release v0.4.0 from main branch

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
