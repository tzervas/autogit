# Next 10 Work Items

**Generated**: 2025-12-25

## Priority 1: Merge Ready PRs to dev

### 1. PR: autogit-core CLI v0.1.0
- **Branch**: `feature/autogit-core-cli-v0.1.0`
- **Action**: Create PR → dev
- **Scope**: Complete Rust CLI with GitLab API integration
- **Size**: Large (31 files, ~5000 LOC)

### 2. PR: Homelab GitLab Deployment
- **Branch**: `feature/homelab-gitlab-deployment`
- **Action**: Create PR → dev
- **Scope**: Docker compose, deploy scripts, bootstrap
- **Size**: Medium (14 files)

### 3. PR: Observability Stack
- **Branch**: `feature/observability-stack`
- **Action**: Create PR → dev
- **Scope**: Prometheus, Grafana, Loki, Tempo configs
- **Size**: Small (9 files)

### 4. PR: Architecture Docs
- **Branch**: `feature/docs-architecture`
- **Action**: Create PR → dev
- **Scope**: Platform architecture, code quality docs
- **Size**: Small (4 files)

### 5. PR: Dev Tooling
- **Branch**: `feature/dev-tooling`
- **Action**: Create PR → dev
- **Scope**: Makefile, editorconfig, scripts
- **Size**: Small (7 files)

---

## Priority 2: autogit-core Enhancements

### 6. Integration Tests for autogit CLI
- **Branch**: Create `feature/autogit-core-tests`
- **Tasks**:
  - Mock GitLab API responses
  - Test bootstrap command flow
  - Test mirror add/sync/remove
  - Test runner registration
  - CI pipeline for Rust tests
- **Depends**: PR #1 merged

### 7. autogit-core Package & Release
- **Branch**: Create `feature/autogit-core-release`
- **Tasks**:
  - GitHub Actions for Rust build
  - Multi-arch binary builds (x86_64, aarch64)
  - Release artifact publishing
  - Homebrew formula / Cargo publish
- **Depends**: PR #1 merged

---

## Priority 3: Infrastructure

### 8. Runner Registration Automation
- **Branch**: Create `feature/runner-automation`
- **Tasks**:
  - Use autogit CLI to register runners
  - GPU runner with CUDA support
  - ARM64 runner configuration
  - Runner token rotation
- **Depends**: GitLab deployment stable

### 9. Mirror Sync Pipeline
- **Branch**: Create `feature/mirror-sync`
- **Tasks**:
  - Cron job or webhook trigger
  - Auto-sync GitHub → GitLab
  - Initial repo list: autogit itself
  - Conflict detection and alerting
- **Depends**: autogit mirror commands

### 10. Terraform State & Secrets
- **Branch**: Review `feature/homelab-deployment-terraform-config`
- **Tasks**:
  - Terraform state backend (S3/GitLab)
  - Secrets management (Vault or GitLab CI variables)
  - Infrastructure drift detection
- **Depends**: Review existing branch

---

## Branch Cleanup (After Merges)

Delete after PRs merged:
```bash
# Local
git branch -D feature/homelab-migration-recovery
git branch -D copilot/fix-workflow-trigger-issues
git branch -D feature/homelab-deployment-deployment-verification
git branch -D feature/homelab-deployment-docker-compose-sync
git branch -D feature/homelab-deployment-runner-registration

# Remote
git push origin --delete feature/homelab-migration-recovery
git push origin --delete copilot/fix-workflow-trigger-issues
git push origin --delete copilot/review-dev-branch-merge
git push origin --delete copilot/sub-pr-37
git push origin --delete copilot/sub-pr-37-again
git push origin --delete copilot/update-ci-release-process
```

---

## Quick Reference

| # | Item | Branch | Priority | Status |
|---|------|--------|----------|--------|
| 1 | autogit-core PR | feature/autogit-core-cli-v0.1.0 | P1 | Ready |
| 2 | Homelab deploy PR | feature/homelab-gitlab-deployment | P1 | Ready |
| 3 | Observability PR | feature/observability-stack | P1 | Ready |
| 4 | Architecture docs PR | feature/docs-architecture | P1 | Ready |
| 5 | Dev tooling PR | feature/dev-tooling | P1 | Ready |
| 6 | CLI integration tests | (to create) | P2 | Blocked |
| 7 | CLI release pipeline | (to create) | P2 | Blocked |
| 8 | Runner automation | (to create) | P3 | Blocked |
| 9 | Mirror sync pipeline | (to create) | P3 | Blocked |
| 10 | Terraform review | feature/homelab-deployment-terraform-config | P3 | Review |
