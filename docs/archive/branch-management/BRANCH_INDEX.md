# Branch Index & Cleanup Guide

**Last Updated**: 2025-12-25

## Active Development Branches

### 🟢 KEEP - Core Branches

| Branch | Purpose            | Status    |
| ------ | ------------------ | --------- |
| `main` | Production stable  | Protected |
| `dev`  | Integration branch | Protected |

### 🟢 KEEP - New Feature Branches (Ready for PR)

| Branch                              | Purpose              | Key Files                                          | Status          |
| ----------------------------------- | -------------------- | -------------------------------------------------- | --------------- |
| `feature/autogit-core-cli-v0.1.0`   | Rust CLI rewrite     | `autogit-core/`                                    | ✅ Ready for PR |
| `feature/homelab-gitlab-deployment` | GitLab CE deployment | `homelab-migration/` compose & deploy              | ✅ Ready for PR |
| `feature/observability-stack`       | Monitoring & logging | `observability/`                                   | ✅ Ready for PR |
| `feature/docs-architecture`         | Architecture docs    | `docs/architecture/`, `docs/development/`          | ✅ Ready for PR |
| `feature/dev-tooling`               | Dev environment      | `.editorconfig`, `Makefile`, etc                   | ✅ Ready for PR |
| `feature/github-workflows`          | CI organization      | `.github/chatmodes/`, `.github/workflows/archive/` | ✅ Ready for PR |

### 🟡 REVIEW - May Have Useful Work

| Branch                                        | Purpose               | Check For                   | Recommendation        |
| --------------------------------------------- | --------------------- | --------------------------- | --------------------- |
| `feature/homelab-deployment`                  | Original homelab work | Terraform configs           | Cherry-pick if needed |
| `feature/homelab-deployment-terraform-config` | Terraform setup       | `infrastructure/terraform/` | Review, likely merge  |
| `feature/multi-arch-support`                  | Multi-arch images     | Docker configs              | Review                |
| `feature/multi-arch-support-arm64-native`     | ARM64 support         | Dockerfile changes          | Review                |
| `feature/homelab-migration-recovery`          | Recovery session      | Superseded by new branches  | Archive               |

### 🔴 PRUNE - Stale/Superseded

| Branch                                               | Reason                 | Safe to Delete |
| ---------------------------------------------------- | ---------------------- | -------------- |
| `copilot/fix-workflow-trigger-issues`                | Copilot auto-branch    | ✅ Yes         |
| `copilot/review-dev-branch-merge`                    | Copilot auto-branch    | ✅ Yes         |
| `copilot/sub-pr-37`                                  | Copilot auto-branch    | ✅ Yes         |
| `copilot/sub-pr-37-again`                            | Copilot auto-branch    | ✅ Yes         |
| `copilot/update-ci-release-process`                  | Copilot auto-branch    | ✅ Yes         |
| `feature/homelab-deployment-deployment-verification` | Superseded by recovery | ✅ Yes         |
| `feature/homelab-deployment-docker-compose-sync`     | Superseded             | ✅ Yes         |
| `feature/homelab-deployment-runner-registration`     | Superseded             | ✅ Yes         |
| `feature/multi-arch-support-multi-arch-images`       | Merged or stale        | ✅ Yes         |
| `feature/multi-arch-support-qemu-fallback`           | Stale                  | ✅ Yes         |
| `feature/multi-arch-support-riscv-support`           | Experimental           | ✅ Yes         |
| `work/multi-arch-support-arm64-native-init`          | WIP stale              | ✅ Yes         |
| `work/homelab-deployment-terraform-config-init`      | WIP stale              | ✅ Yes         |

______________________________________________________________________

## Proposed New Feature Branches

Based on uncommitted work in workspace, split into:

### 1. `feature/homelab-gitlab-deployment` (from homelab-migration/)

**Purpose**: Production GitLab deployment scripts **Files**:

- `homelab-migration/docker-compose.gitlab.yml`
- `homelab-migration/docker-compose.homelab.yml`
- `homelab-migration/deploy.sh`
- `homelab-migration/deploy-clean.sh`
- `homelab-migration/check-status.sh`
- `homelab-migration/bootstrap-gitlab-*.sh`
- `homelab-migration/credential-manager.sh`
- `homelab-migration/gitlab.env.example`
- `homelab-migration/README.md`

### 2. `feature/observability-stack`

**Purpose**: Monitoring and observability **Files**:

- `observability/`
- `homelab-migration/monitor-*.sh`
- `homelab-migration/diagnose.sh`
- `homelab-migration/capture-logs.sh`
- `homelab-migration/debug-capture.sh`

### 3. `feature/docs-architecture`

**Purpose**: Architecture and development docs **Files**:

- `docs/architecture/AUTOGIT_SPEC.md`
- `docs/architecture/PLATFORM_ARCHITECTURE.md`
- `docs/development/CODE_QUALITY.md`
- `docs/development/RESTRUCTURING_PROPOSAL.md`

### 4. `feature/dev-tooling`

**Purpose**: Development environment setup **Files**:

- `.editorconfig`
- `.markdownlint.json`
- `.pre-commit-config.yaml.new`
- `Makefile`
- `docker-compose.platform.yml`
- `scripts/dns-manager.py`
- `tests/conftest.py`

### 5. `feature/github-workflows`

**Purpose**: CI/CD workflow organization **Files**:

- `.github/chatmodes/`
- `.github/workflows/archive/`

______________________________________________________________________

## Cleanup Commands

### Delete Local Stale Branches

```bash
# Delete copilot branches
git branch -D copilot/fix-workflow-trigger-issues

# Delete superseded homelab branches
git branch -D feature/homelab-deployment-deployment-verification
git branch -D feature/homelab-deployment-docker-compose-sync
git branch -D feature/homelab-deployment-runner-registration

# Delete stale multi-arch branches
git branch -D feature/multi-arch-support-multi-arch-images
git branch -D feature/multi-arch-support-qemu-fallback
git branch -D feature/multi-arch-support-riscv-support
git branch -D work/multi-arch-support-arm64-native-init
```

### Delete Remote Stale Branches

```bash
git push origin --delete copilot/fix-workflow-trigger-issues
git push origin --delete copilot/review-dev-branch-merge
git push origin --delete copilot/sub-pr-37
git push origin --delete copilot/sub-pr-37-again
git push origin --delete copilot/update-ci-release-process
git push origin --delete feature/homelab-deployment-deployment-verification
git push origin --delete feature/homelab-deployment-docker-compose-sync
git push origin --delete feature/homelab-deployment-runner-registration
git push origin --delete feature/multi-arch-support-multi-arch-images
git push origin --delete feature/multi-arch-support-qemu-fallback
git push origin --delete feature/multi-arch-support-riscv-support
git push origin --delete work/homelab-deployment-terraform-config-init
```

______________________________________________________________________

## Branch Workflow

```
main (stable)
  │
  └── dev (integration)
        │
        ├── feature/autogit-core-cli-v0.1.0      ✅ Ready for PR
        ├── feature/homelab-gitlab-deployment    🔄 To create
        ├── feature/observability-stack          🔄 To create
        ├── feature/docs-architecture            🔄 To create
        ├── feature/dev-tooling                  🔄 To create
        └── feature/github-workflows             🔄 To create
```
