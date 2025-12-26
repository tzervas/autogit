# AutoGit Scripts

This directory contains shell scripts organized by purpose.

## Directory Structure

```
scripts/
├── setup/              # Initial setup and installation
├── deployment/         # Deployment and sync operations
├── ci/                 # CI/CD automation utilities
├── git/                # Git branch operations
├── gitlab/             # GitLab-specific automation
├── testing/            # Testing and verification
├── management/         # System and credential management
└── utilities/          # General utility scripts
```

## Categories

### Setup (`setup/`)

Initial system and environment setup scripts.

| Script | Description |
|--------|-------------|
| `first-time-setup.sh` | Interactive first-time setup wizard |
| `first-time-setup-complete.sh` | Automated complete setup |
| `setup-git-signing.sh` | Configure GPG signing for Git |
| `setup-pre-commit.sh` | Install and configure pre-commit hooks |
| `setup-storage.sh` | Set up storage directories |
| `setup-github-runner.sh` | Configure GitHub Actions runner |

### Deployment (`deployment/`)

Scripts for deploying and syncing to homelab.

| Script | Description |
|--------|-------------|
| `deploy-homelab.sh` | Deploy to homelab environment |
| `deploy-and-monitor.sh` | Deploy with monitoring |
| `monitor-deployment.sh` | Monitor deployment status |
| `sync-to-homelab.sh` | Sync files to homelab |

### CI/CD (`ci/`)

Continuous integration automation utilities.

| Script | Description |
|--------|-------------|
| `automate-version.sh` | Automated version bumping |
| `capture-ci-results.sh` | Capture CI run results |
| `validate-branch-name.sh` | Validate branch naming conventions |
| `validate-release-workflow.sh` | Validate release workflow |

### Git Operations (`git/`)

Git branch and repository operations.

| Script | Description |
|--------|-------------|
| `create-feature-branch.sh` | Create feature branch with conventions |
| `cleanup-merged-branches.sh` | Clean up merged branches |
| `sync-branches.sh` | Synchronize branches |

### GitLab (`gitlab/`)

GitLab-specific automation scripts.

| Script | Description |
|--------|-------------|
| `gitlab-helpers.sh` | GitLab helper functions (source this) |
| `generate-gitlab-password.sh` | Generate secure GitLab password |
| `setup-gitlab-automation.sh` | Configure GitLab automation |
| `register-runners.sh` | Register GitLab runners |

### Testing (`testing/`)

Testing and verification scripts.

| Script | Description |
|--------|-------------|
| `test-all-workflows.sh` | Run all workflow tests |
| `test-dynamic-runners.sh` | Test dynamic runner functionality |
| `verify-dynamic-runners.sh` | Verify runner configuration |

### Management (`management/`)

System and credential management.

| Script | Description |
|--------|-------------|
| `homelab-manager.sh` | Homelab management CLI |
| `manage-credentials.sh` | Credential management |
| `migrate-env-files.sh` | Migrate environment files |

### Utilities (`utilities/`)

General-purpose utilities.

| Script | Description |
|--------|-------------|
| `check-homelab-status.sh` | Check homelab status |
| `fetch-homelab-logs.sh` | Fetch logs from homelab |

## Usage

All scripts should be run from the project root:

```bash
# Setup
./scripts/setup/first-time-setup.sh

# Deployment
./scripts/deployment/deploy-homelab.sh

# Testing
./scripts/testing/test-all-workflows.sh
```

## Environment Variables

Many scripts use these common environment variables:

- `HOMELAB_IP` - Homelab server IP address (default: 192.168.1.170)
- `GITLAB_URL` - GitLab server URL
- `COORDINATOR_URL` - Runner coordinator URL

See individual scripts for specific requirements.
