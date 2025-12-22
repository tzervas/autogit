# GitHub Workflows

This directory contains GitHub Actions workflows for the AutoGit project.

## Workflows

### CI and Code Quality

#### `ci.yml`
Runs on push and PR to main branches. Performs code quality checks:
- **Shell Script Linting**: Uses ShellCheck to validate bash scripts
- **YAML Linting**: Uses yamllint to validate YAML files
- **Markdown Linting**: Uses markdownlint-cli to check documentation
- **Docker Validation**: Validates Docker Compose configuration
- **Script Permissions**: Checks that scripts are executable

**Triggers**: Push/PR to main, dev, and feature branches

#### `docker-build.yml`
Builds and tests Docker images:
- **Build Git Server**: Builds GitLab CE container
- **Build Runner Coordinator**: Builds runner coordinator container
- **Test Docker Compose**: Validates docker-compose configuration and service startup

**Triggers**: Push/PR to main, dev, and feature branches (when Docker files change)

#### `pr-validation.yml`
Validates pull requests follow project conventions:
- **Branch Naming**: Validates branch names follow convention
- **PR Target**: Ensures PR targets correct branch in hierarchy
- **PR Description**: Checks that PR has a description

**Triggers**: PR opened/edited/synchronized/reopened

#### `docs-validation.yml`
Validates documentation quality:
- **Link Checking**: Checks for broken links in markdown files
- **Structure Validation**: Ensures required documentation exists
- **Code Block Syntax**: Validates code blocks are properly closed
- **Frontmatter**: Checks documentation has proper headers

**Triggers**: Push/PR when documentation files change

### Automation

#### `auto-merge-subtasks.yml`
Automatically merges work branches to subtasks and subtasks to features:
- **Work → Subtask**: Auto-merges after evaluator approval or `auto-merge` label
- **Subtask → Feature**: Auto-merges after evaluator approval or `auto-merge` label
- **Requirements**: All CI checks pass, no `no-auto-merge` label, branch is mergeable
- **Merge Method**: Squash

**Triggers**: PR review submitted, PR labeled/unlabeled

#### `auto-merge-feature-to-dev.yml`
Automatically merges feature branches to dev after owner approval:
- **Feature → Dev**: Auto-merges after @tzervas approval or `owner-approved` label
- **Requirements**: Owner approval, all CI checks pass, no `no-auto-merge` label
- **Notifications**: Comments on PR status and what's needed
- **Merge Method**: Squash

**Triggers**: PR review submitted (by owner), PR labeled with `owner-approved`

#### `sync-dev-to-features.yml`
Automatically syncs dev changes back to feature branches:
- Merges dev into active feature branches
- Creates issues for merge conflicts
- Can be triggered manually for specific branches
- Runs automatically when dev is updated

**Triggers**: Push to dev, manual dispatch

#### `auto-label.yml`
Automatically labels PRs based on:
- Branch type (feature, hotfix, release, copilot)
- Target branch (to-main, to-dev)
- Modified files (documentation, github-actions)
- Feature area (git-server, runner-coordinator, docker, api, security)

**Triggers**: PR opened/reopened

#### `stale.yml`
Manages stale issues and PRs:
- Marks issues stale after 60 days of inactivity
- Marks PRs stale after 30 days of inactivity
- Closes stale items after 7 additional days
- Exempts pinned, security, and milestone items
- Exempts draft PRs

**Triggers**: Daily at 00:00 UTC (cron), manual dispatch

### Release and Deployment

#### `release.yml`
Automates release process:
- Creates GitHub releases from tags
- Extracts changelog from CHANGELOG.md
- Builds and publishes Docker images to GitHub Container Registry
- Supports both automatic (on tag push) and manual triggers

**Triggers**: Tag push (v*.*.*), manual dispatch

## Configuration Files

### `.yamllint.yml`
Configuration for yamllint with project-specific rules:
- Max line length: 120 characters (warning)
- Indentation: 2 spaces
- Allows common truthy values

### `dependabot.yml`
Configures Dependabot for automated dependency updates:
- GitHub Actions (weekly)
- Docker images for git-server (weekly)
- Docker images for runner-coordinator (weekly)

### `labels.yml`
Defines standard labels for the repository:
- **Priority**: critical, high, medium, low
- **Type**: feature, bug, enhancement, hotfix, release
- **Area**: git-server, runner-coordinator, docker, documentation, api, security
- **Status**: work-in-progress, blocked, stale, needs-review, needs-testing
- **Target**: to-main, to-dev
- **Special**: pinned, good-first-issue, help-wanted, long-term

## Workflow Status

You can see the status of all workflows in the [Actions tab](../../actions).

## Local Testing

### Test Shell Scripts
```bash
# Install shellcheck
sudo apt-get install shellcheck

# Run shellcheck
shellcheck scripts/*.sh
```

### Test YAML Files
```bash
# Install yamllint
pip install yamllint

# Run yamllint
yamllint -c .yamllint.yml .
```

### Test Docker Build
```bash
# Validate compose file
docker compose config

# Build services
docker compose build
```

### Test Markdown
```bash
# Install markdownlint
npm install -g markdownlint-cli

# Run markdownlint
markdownlint '**/*.md' --ignore node_modules
```

## Workflow Maintenance

### Adding New Workflows

1. Create workflow file in `.github/workflows/`
2. Use YAML document start (`---`)
3. Follow naming convention: `kebab-case.yml`
4. Add description in this README
5. Test locally before committing

### Modifying Workflows

1. Test changes in a feature branch
2. Ensure all checks pass
3. Update this README if behavior changes
4. Consider impact on existing PRs

## Secrets and Permissions

Workflows use the following:
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions
- `secrets.GITHUB_TOKEN`: Used for container registry authentication

No additional secrets are currently required.

## Troubleshooting

### Workflow Not Running
- Check trigger conditions match your branch/event
- Verify workflow syntax is valid (use yamllint)
- Check Actions tab for error messages

### Permission Errors
- Check workflow has correct `permissions` set
- Verify `GITHUB_TOKEN` has required scopes

### Build Failures
- Check CI logs in Actions tab
- Run tests locally first
- Ensure Docker images can build

## Future Enhancements

Potential workflow additions:
- [ ] Security scanning (CodeQL, container scanning)
- [ ] Performance testing
- [ ] Integration tests
- [ ] Deployment automation
- [ ] Notification workflows (Slack, Discord)
- [ ] Issue triage automation

## Related Documentation

- [Branching Strategy](../../docs/development/branching-strategy.md)
- [Contributing Guide](../../docs/CONTRIBUTING.md)
- [Development Guide](../../docs/development/README.md)
