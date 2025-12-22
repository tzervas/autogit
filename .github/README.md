# .github Directory

This directory contains GitHub-specific configuration, workflows, and documentation for the AutoGit project.

## Contents

### Configuration Files

- **`CODEOWNERS`** - Defines code ownership and review requirements
- **`dependabot.yml`** - Automated dependency updates configuration
- **`labels.yml`** - Standard labels for issues and PRs

### Documentation

- **`BRANCH_PROTECTION.md`** - Comprehensive guide to branch protection rules and auto-merge setup
- **`AUTO_MERGE_SETUP.md`** - Quick start guide for configuring automated merges
- **`workflows/README.md`** - Documentation for all GitHub Actions workflows

### Subdirectories

- **`agents/`** - AI agent configurations (not accessible to current agent)
- **`PULL_REQUEST_TEMPLATE/`** - PR templates for different merge types
- **`workflows/`** - GitHub Actions workflow definitions

## Quick Links

### Setting Up Auto-Merge

If you're setting up this repository for the first time:

1. Read [`AUTO_MERGE_SETUP.md`](AUTO_MERGE_SETUP.md) - Quick setup guide
2. Read [`BRANCH_PROTECTION.md`](BRANCH_PROTECTION.md) - Detailed configuration
3. Configure repository settings following the guides
4. Test workflows with a sample PR

### Understanding Workflows

To understand the CI/CD pipeline:

1. Read [`workflows/README.md`](workflows/README.md) - Workflow overview
2. Review individual workflow files in `workflows/`
3. Check Actions tab in repository for run history

### Contributing

For contributors:

1. Review [`CODEOWNERS`](CODEOWNERS) to see who reviews what
2. Use PR templates in `PULL_REQUEST_TEMPLATE/`
3. Follow branching strategy in [`BRANCH_PROTECTION.md`](BRANCH_PROTECTION.md)
4. Ensure labels from [`labels.yml`](labels.yml) are applied

## Workflows Overview

### CI/CD Workflows

- `ci.yml` - Code quality checks (linting, validation)
- `docker-build.yml` - Docker image building and testing
- `pr-validation.yml` - PR naming and structure validation
- `docs-validation.yml` - Documentation quality checks

### Automation Workflows

- `auto-merge-subtasks.yml` - Auto-merge work→subtask and subtask→feature
- `auto-merge-feature-to-dev.yml` - Auto-merge feature→dev (owner approval)
- `sync-dev-to-features.yml` - Sync dev changes to feature branches
- `auto-label.yml` - Automatic PR labeling
- `stale.yml` - Stale issue/PR management
- `release.yml` - Release automation

## Branch Protection Strategy

AutoGit uses a hierarchical branching strategy with different protection levels:

```
main (fully protected)
  └─ dev (protected, auto-merge enabled)
      └─ feature/name (protected, auto-merge enabled)
          └─ feature/name/subtask (protected, auto-merge enabled)
              └─ feature/name/subtask/work (ephemeral, no protection)
```

### Merge Rules

| From | To | Approval Required | Auto-Merge |
|------|----|--------------------|------------|
| Work | Subtask | Evaluator or label | ✅ Yes |
| Subtask | Feature | Evaluator or label | ✅ Yes |
| Feature | Dev | Owner (@tzervas) | ✅ Yes |
| Dev | Main | Owner (manual) | ❌ No |

## Code Ownership

- **Owner**: @tzervas
  - Final approval for all feature→dev merges
  - Final approval for all dev→main merges
  - Owns critical infrastructure files

- **Evaluator Agent**:
  - Reviews work→subtask merges
  - Reviews subtask→feature merges
  - Automated approval via label

## Labels

### Auto-Merge Labels

- `auto-merge` - Enable automatic merging
- `no-auto-merge` - Prevent automatic merging
- `owner-approved` - Owner approval for feature→dev
- `merge-conflict` - Auto-created for conflicts

### Status Labels

- `work-in-progress` - Not ready for review
- `needs-review` - Ready for review
- `needs-testing` - Needs testing
- `blocked` - Blocked by dependency

### Priority Labels

- `priority-critical` - Immediate attention
- `priority-high` - High priority
- `priority-medium` - Medium priority
- `priority-low` - Low priority

### Type Labels

- `feature` - New feature
- `bug` - Bug fix
- `enhancement` - Improvement
- `hotfix` - Critical production fix
- `release` - Release-related

### Area Labels

- `git-server` - GitLab CE git server
- `runner-coordinator` - Runner service
- `docker` - Containerization
- `documentation` - Documentation
- `github-actions` - CI/CD workflows
- `api` - API changes
- `security` - Security-related

See [`labels.yml`](labels.yml) for complete list.

## Dependabot

Automated dependency updates for:
- GitHub Actions (weekly)
- Docker base images (weekly)

Configuration in [`dependabot.yml`](dependabot.yml).

## Pull Request Templates

Different templates for different merge levels:

- `work_template.md` - Work → Subtask
- `sub_feature_template.md` - Subtask → Feature
- `feature_template.md` - Feature → Dev
- `release_template.md` - Dev → Main

Templates are in `PULL_REQUEST_TEMPLATE/` directory.

## Security

### Branch Protection

- **Main**: Fully protected, owner-only access
- **Dev**: Protected, auto-merge enabled for approved PRs
- **Features**: Protected, auto-merge enabled with evaluator

### Workflow Permissions

All workflows use minimal required permissions:
- Read access by default
- Write access only when needed (merge, label)
- Token scoped to repository only

### Secrets

No repository secrets currently required. All workflows use:
- `GITHUB_TOKEN` - Automatically provided

## Maintenance

### Regular Tasks

- [ ] Review auto-merge success rate monthly
- [ ] Update required checks as CI evolves
- [ ] Review and update labels quarterly
- [ ] Audit branch protection rules quarterly
- [ ] Update dependencies via Dependabot
- [ ] Review stale PRs weekly

### Updating Configuration

When making changes:

1. Update configuration files
2. Update relevant documentation
3. Test changes in feature branch
4. Get owner review before merging
5. Communicate changes to team

## Related Documentation

- [Development Guide](../docs/development/README.md)
- [Branching Strategy](../docs/development/branching-strategy.md)
- [Contributing Guide](../docs/CONTRIBUTING.md)
- [Roadmap](../ROADMAP.md)

## Support

For help with GitHub configuration:

- Check documentation in this directory
- Review GitHub Actions logs
- Open an issue with `github-actions` label
- Contact repository owner

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [Auto-merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)
