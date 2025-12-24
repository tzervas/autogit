# Release CI Workflow Update Summary

**Date**: 2024-12-24  
**Branch**: copilot/update-ci-release-process

## Problem Statement

Update the release CI workflow to:
1. Enable running on self-hosted runners with ample resources for parallel builds
2. Run automatically on merge from dev into main
3. Support manual trigger from dev or main branches
4. Parse release data from last merged PR
5. Auto-generate proper naming and tagging conventions
6. Provide manual version override option

## Solution Implemented

### 1. Enhanced Trigger Mechanisms

The workflow now supports four trigger types:

#### a) Automatic Release on PR Merge (dev → main)
- Trigger: `pull_request.types: [closed]` on main branch
- Validation: Checks `github.event.pull_request.merged == true` 
- **Critical**: Only merged PRs trigger releases, not closed/cancelled PRs
- Auto-extracts version from PR title (e.g., "Release v0.3.0")
- Generates release notes from PR description

#### b) Manual Dispatch with Options
New workflow_dispatch inputs:
- `source_branch`: Choose between `dev` or `main` (dropdown)
- `version_mode`: Choose between `auto` or `manual` (dropdown)
- `manual_version`: Custom version input (e.g., v0.3.0)
- `create_tag`: Boolean to create tag if missing

#### c) Tag Push (existing)
- Maintains backward compatibility with tag-based releases

#### d) Direct Push to Main (existing)
- Supports direct commits to main branch

### 2. Intelligent Version Detection

#### Auto Mode
1. **PR Title Parsing**: Extracts version pattern `v\d+\.\d+\.\d+` from PR title
   - Works with: "Release v0.3.0", "v0.3.0 - New Features", etc.

2. **Auto-Increment Fallback**: When no version found in PR
   - Analyzes recent commits for semantic versioning hints:
     - "BREAKING CHANGE" or "major" → Major bump (v1.0.0 → v2.0.0)
     - "feat", "feature", "minor" → Minor bump (v0.2.0 → v0.3.0)
     - Default → Patch bump (v0.2.1 → v0.2.2)

#### Manual Mode
- Uses provided `manual_version` input
- Validates format: `vX.Y.Z`

### 3. Self-Hosted Runners with Parallel Builds

#### Configuration
- All jobs run on `self-hosted` runners
- Matrix strategy for parallel Docker builds:
  ```yaml
  strategy:
    fail-fast: false
    matrix:
      service: [git-server, runner-coordinator]
  ```
- `fail-fast: false` ensures all builds complete even if one fails

#### Benefits
- Simultaneous builds reduce total build time
- Ample runner resources handle multiple concurrent jobs
- Multi-layer cache strategy optimizes build performance

### 4. Enhanced Release Notes Generation

Automatically generates release notes from:
- PR title and author attribution
- PR description (for merged PRs)
- Last merged PR data (for manual triggers with auto mode)
- CHANGELOG.md sections (if available)
- GitHub's auto-generated release notes (as supplement)

### 5. Validation and Documentation

#### Validation Script (`scripts/validate-release-workflow.sh`)
Checks:
- YAML syntax validity
- Required triggers (pull_request, workflow_dispatch)
- Merged PR validation (`merged == true`)
- Self-hosted runner configuration
- Matrix strategy presence
- Version mode options (auto/manual)
- Branch selection options (dev/main)

#### Documentation (`docs/workflows/RELEASE_WORKFLOW.md`)
Comprehensive guide covering:
- All trigger mechanisms
- Version detection logic
- Usage scenarios with examples
- Troubleshooting guide
- Permissions requirements

## Technical Details

### Key Changes in `release.yml`

1. **Line 33**: Added comment explaining merged PR validation
2. **Line 73-77**: Job-level `if` condition to filter PR events
3. **Line 98-113**: Enhanced PR validation with detailed logging
4. **Line 161-257**: New version determination logic with multiple strategies
5. **Line 286-347**: Enhanced release notes generation from PR data
6. **Line 369**: Added `fail-fast: false` for parallel builds

### File Changes

```
Modified: .github/workflows/release.yml (+284, -58 lines)
Created:  scripts/validate-release-workflow.sh
Created:  docs/workflows/RELEASE_WORKFLOW.md
```

## Usage Examples

### Example 1: Automatic Release
```
1. Create PR: dev → main, title "Release v0.3.0"
2. Add changes description in PR body
3. Get approval and merge
4. Workflow automatically creates v0.3.0 release
```

### Example 2: Manual with Auto-Detection
```
1. GitHub Actions → Release workflow → Run workflow
2. Select: source_branch=dev, version_mode=auto
3. Workflow finds last merged PR into dev
4. Extracts version from PR title or auto-increments
```

### Example 3: Manual with Custom Version
```
1. GitHub Actions → Release workflow → Run workflow
2. Select: source_branch=main, version_mode=manual
3. Enter: manual_version=v0.4.0
4. Workflow creates v0.4.0 release from main
```

## Validation

Run validation script to verify configuration:
```bash
./scripts/validate-release-workflow.sh
```

Expected output:
```
✅ YAML syntax valid
✅ pull_request trigger present
✅ Merged PR validation present
✅ Self-hosted runners configured
✅ Matrix strategy present
✅ Version mode options (auto/manual) present
✅ Branch options (dev/main) present
```

## Testing Checklist

- [x] YAML syntax validation
- [x] Workflow structure verification
- [x] Documentation completeness
- [ ] Test automatic release on PR merge (requires actual PR)
- [ ] Test manual release with auto mode (requires actual PR)
- [ ] Test manual release with manual mode (can be done in staging)
- [ ] Verify parallel Docker builds work correctly
- [ ] Confirm version detection from PR titles
- [ ] Validate auto-increment logic

## Rollback Plan

If issues arise, revert by:
1. Restore previous `.github/workflows/release.yml` from git history
2. Remove new files: `scripts/validate-release-workflow.sh`, `docs/workflows/RELEASE_WORKFLOW.md`
3. Previous workflow only supported tag-based and manual releases

## Security Considerations

- Workflow requires `contents: write` permission for creating releases/tags
- Workflow requires `packages: write` for Docker image publishing
- Workflow requires `pull-requests: read` for PR data access
- All permissions are scoped to minimum required
- Manual triggers require repository write access

## Future Enhancements

Potential improvements for future iterations:
1. Support for pre-release versions (alpha, beta, rc)
2. Automatic CHANGELOG.md generation from commits
3. Release approval workflow before publishing
4. Multi-repository release synchronization
5. Rollback/revert capabilities
6. Slack/Discord notifications for releases
7. Release metrics and analytics

## Conclusion

The updated release workflow provides a flexible, automated solution that:
- ✅ Runs on self-hosted runners with parallel build support
- ✅ Automatically releases on dev→main PR merges
- ✅ Supports manual triggers from dev or main branches
- ✅ Intelligently detects versions from PR data
- ✅ Provides manual version override option
- ✅ Properly validates merged vs closed PRs
- ✅ Includes comprehensive documentation and validation tools

The implementation addresses all requirements from the problem statement while maintaining backward compatibility with existing tag-based releases.
