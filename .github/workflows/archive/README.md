# Archived Workflows

This directory contains disabled/archived workflow files that are kept for reference.

## Why Archive Instead of Delete?

These workflows were disabled for specific reasons but kept for:
- Historical reference
- Potential future re-enablement
- Learning from previous implementations

## Archived Workflows

| File | Original Purpose | Reason Disabled |
|------|-----------------|-----------------|
| `ci.yml.disabled` | General CI pipeline | Replaced by `pr-validation.yml` |
| `docker-build.yml.disabled` | Docker image builds | Functionality moved to release workflow |
| `docker-dev-build.yml.disabled` | Dev Docker builds | Consolidated with other workflows |
| `docs-validation.yml.disabled` | Documentation checks | Integrated into PR validation |
| `release-test.yml.disabled` | Release testing | Superseded by `release.yml` |

## Re-enabling a Workflow

To re-enable a workflow:

1. Review the workflow for current compatibility
2. Update any outdated actions or paths
3. Remove the `.disabled` extension
4. Move back to parent directory
5. Test with a dry-run if possible

```bash
# Example
mv archive/ci.yml.disabled ../ci.yml
```

## Note

Consider deleting these entirely once the current workflows are proven stable.
