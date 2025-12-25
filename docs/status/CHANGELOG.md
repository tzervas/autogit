# Changelog

All notable changes to AutoGit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note on Versioning**: Prior to v0.2.0, git tags (e.g., v0.1.16) were used for releases while
> `pyproject.toml` remained at 0.1.0. Starting with v0.2.0, we now maintain version consistency
> between git tags and `pyproject.toml`.

## [Unreleased]

### Added

- **Automated Workflow System**: Complete automation for code quality and releases
  - Pre-commit auto-fix workflow for PRs (`.github/workflows/pre-commit-auto-fix.yml`)
  - Automated changelog generation from merged PRs (`.github/workflows/auto-changelog.yml`)
  - Enhanced pre-commit configuration with 10+ hook types
  - Setup scripts for pre-commit hooks and git signing
  - Commit message template for conventional commits
  - Comprehensive documentation (35KB across 5 guides)

### Fixed

- **Workflow Trigger Issues**: Release workflow now properly handles all tag patterns
  - Intelligent source branch detection from git history
  - Supports production (`vX.Y.Z`), dev (`vX.Y.Z-dev.TIMESTAMP`), and feature branch tags
  - Fixed permission issues preventing cross-workflow triggers

### Changed

- **Documentation Updates**:
  - Fixed "Homeland" → "homelab" terminology throughout
  - Clarified SSO status: planned but not implemented (Okta/Keycloak evaluation deferred)
  - Updated architecture docs to reflect MVP status accurately
  - Added branch protection configuration guide
  - Added security summary for automated workflows

### Documentation

- `docs/AUTOMATED_WORKFLOWS.md` - Complete system guide (7KB)
- `IMPLEMENTATION_SUMMARY.md` - Technical implementation details (7KB)
- `QUICKSTART_AUTOMATED_WORKFLOW.md` - User-friendly quick start (6KB)
- `SECURITY_SUMMARY.md` - Security considerations (6KB)
- `BRANCH_PROTECTION_GUIDE.md` - Required repository settings (10KB)
- `AUTOMATED_WORKFLOW_DOCS_INDEX.md` - Documentation index (8KB)

### Infrastructure

- All GitHub Actions commits now auto-signed by GitHub
- Pre-commit hooks enforce code quality before commits
- Conventional commit message validation
- Secret detection and security scanning

## [0.2.0] - 2025-12-24

### ⚠️ Deployment Status & Validation

**Production-Ready Components**:

- ✅ Core Docker Compose orchestration (validated and working)
- ✅ Git Server service with GitLab CE (tested and operational)
- ✅ Basic runner coordinator service (functional in Docker)
- ✅ Documentation structure and development guides (complete)
- ✅ CI/CD workflows for GitHub Actions (validated)

**Experimental/Early Phase Components** (⚠️ Not Fully Validated):

- 🔶 **Homelab Terraform Deployment** - **EARLY PHASE**

  - Status: Initial implementation, not fully tested in production
  - Known Issues:
    - Requires manual SSH key setup and configuration
    - Deployment validation scripts need more testing
    - Rootless Docker configuration may need adjustment per environment
    - Timeout values may need tuning for different network speeds
    - Limited error recovery and rollback mechanisms
  - Recommendation: Use for testing only, manual verification required
  - See `infrastructure/homelab/README.md` for setup prerequisites

- 🟡 **Dynamic Runner Management** - **CORE FUNCTIONALITY VALIDATED**

  - Status: Core automated lifecycle validated in local GitLab and GitHub self-hosted runners
  - ✅ Validated Features:
    - Automated runner lifecycle (zero-runner start, job detection, spin-up, execution, 5-min idle
      spin-down)
    - Job queue monitoring and detection
    - Runner allocation and job execution
    - Tested with local self-hosted GitLab instance
    - Tested as GitHub self-hosted runners
  - ⚠️ Needs Further Testing:
    - Scale testing under high load
    - Long-term stability validation
    - GPU detection and allocation (not yet implemented)
    - Multi-architecture support (ARM64, RISC-V) is planned but not implemented
  - Recommendation: Core functionality working, suitable for testing with monitoring; scale testing
    needed for production

- 🔶 **GitLab CI/CD Integration** - **INITIAL SETUP**

  - Status: Configuration templates provided, end-to-end testing pending
  - Known Issues:
    - GitLab automation scripts need validation against live GitLab instance
    - Runner registration may require manual token configuration
    - SSO/authentication integration not yet implemented
  - Recommendation: Review and customize configurations for your environment

- 🔶 **Self-Hosted GitHub Runners** - **PROOF OF CONCEPT**

  - Status: Workflows created, testing on actual self-hosted infrastructure incomplete
  - Known Issues:
    - Runner lifecycle management needs validation
    - Security hardening pending review
    - Scale testing not performed
  - Recommendation: Test in isolated environment before production use

### Added

- **Homelab Deployment Infrastructure** (⚠️ EXPERIMENTAL - See status above)

  - Enhanced Terraform configuration with SSH key authentication (no passwords)
  - Rootless Docker support for improved security
  - Dynamic deploy path configuration based on SSH user
  - Comprehensive deployment scripts and monitoring tools
  - Automated deployment with `scripts/deploy-homelab.sh`
  - Health monitoring with `scripts/check-homelab-status.sh`
  - Log retrieval with `scripts/fetch-homelab-logs.sh`
  - **Note**: Requires manual setup and validation - see deployment status above

- **Self-Hosted CI/CD Workflows**: GitHub Actions workflows for self-hosted runners

  - `github-actions-runner.yml` - GitHub Actions runner workflow
  - `self-hosted-ci-status.yml` - Self-hosted CI status reporting
  - `self-hosted-runner-demo.yml` - Self-hosted runner demo workflow
  - CI result capture automation with `scripts/capture-ci-results.sh`

- **Dynamic Runner Management**: Autonomous runner automation and testing (✅ Core validated)

  - `docs/runners/AUTONOMOUS_RUNNERS.md` - Comprehensive autonomous runner documentation
  - `docs/runners/dynamic-runner-testing.md` - Dynamic runner testing guide
  - `scripts/test-dynamic-runners.sh` - Dynamic runner testing automation
  - `scripts/verify-dynamic-runners.sh` - Dynamic runner verification (340 lines)
  - Runner registration automation with `scripts/register-runners.sh`
  - **Validated**: Automated lifecycle (zero-runner → job detection → spin-up → execution → 5-min
    idle spin-down)
  - **Validated**: Job queue management and runner allocation
  - **Tested**: Local self-hosted GitLab instance and GitHub self-hosted runners

- **GitLab Integration**: GitLab CI/CD configuration and automation

  - `.gitlab-ci.yml` - Main GitLab CI configuration
  - `.gitlab-ci-simple.yml` - Simplified GitLab CI configuration
  - `.gitlab-ci.example.yml` - Example GitLab CI configuration
  - GitLab automation setup with `scripts/setup-gitlab-automation.sh` (373 lines)
  - GitLab helper functions with `scripts/gitlab-helpers.sh`
  - GitLab password generation with `scripts/generate-gitlab-password.sh`

- **Security & Credentials Management**:

  - `docs/security/CREDENTIALS_MANAGEMENT.md` - Comprehensive credentials management guide (270
    lines)
  - `.secrets.baseline` - Secrets baseline for detect-secrets tool
  - GitHub runner setup with `scripts/setup-github-runner.sh`

- **Deployment Documentation**:

  - `docs/status/DEPLOYMENT_STATUS.md` - Deployment status tracking (284 lines)
  - `docs/status/HOMELAB_DEPLOYMENT_COMPLETE.md` - Homelab deployment summary (243 lines)
  - `SETUP_COMPLETE.md` - Setup completion documentation (330 lines)

- **Infrastructure Scripts**:

  - `scripts/first-time-setup.sh` - Initial setup automation (262 lines)
  - `scripts/first-time-setup-complete.sh` - Setup completion script (252 lines)
  - `scripts/homelab-manager.sh` - Homelab management CLI (138 lines)
  - `scripts/monitor-deployment.sh` - Deployment monitoring (79 lines)
  - `scripts/deploy-and-monitor.sh` - Combined deployment and monitoring
  - `scripts/sync-to-homelab.sh` - Homelab sync utility (70 lines)
  - `scripts/setup-storage.sh` - Storage configuration (55 lines)
  - `scripts/test-all-workflows.sh` - Comprehensive workflow testing (184 lines)

### Changed

- **Terraform Configuration**: Enhanced `infrastructure/homelab/main.tf`

  - Migrated from password to SSH key authentication
  - Added support for rootless Docker (unix:///run/user/1000/docker.sock)
  - Dynamic deploy path based on SSH user variable
  - Improved error handling and logging
  - Added comprehensive output variables (deployment status, paths, docker host)
  - Increased timeout to 15 minutes for image pulls

- **Environment Configuration**:

  - Enhanced `.env.example` with homelab-specific variables and detailed documentation
  - Added `.env.homelab.example` - Homelab-specific environment template

- **CI/CD Workflows**: Updated GitHub Actions workflows for better integration

  - Updated `pr-validation.yml` for enhanced PR validation
  - Updated workflow README with new workflows documentation

- **Docker Compose**: Enhanced `docker-compose.yml` for homelab deployment compatibility

- **Documentation Updates**:

  - Updated `docs/status/ROADMAP.md` with homelab deployment milestones
  - Updated `docs/status/TASK_TRACKER.md` with deployment progress tracking

- **Scripts**: Enhanced `scripts/create-feature-branch.sh` with improvements

- **Version Control**:

  - Updated `.gitignore` with homelab artifacts and deployment logs
  - Updated `.pre-commit-config.yaml` with additional checks

### Security

- Migrated from password-based to SSH key-based authentication for Terraform
- Added rootless Docker support for improved container security
- Implemented comprehensive credentials management documentation
- Added secrets baseline for automated secret detection

### Infrastructure

- Complete homelab deployment automation stack
- Support for self-hosted GitHub Actions runners
- GitLab CE integration with automated setup
- Dynamic runner provisioning and management
- Comprehensive monitoring and health checking

### Added - 2025-12-21

- **Task Tracker System**: Comprehensive project task tracking in `TASK_TRACKER.md`

  - Milestone tracking with detailed subtasks
  - Progress metrics and velocity tracking
  - Agent assignments and resource allocation
  - Risk and blocker management
  - 163 checklist items for complete task management

- **QC Workflow**: Quality control procedures in `QC_WORKFLOW.md`

  - 6 quality gates (Code, Testing, Documentation, Security, Performance, Infrastructure)
  - Detailed checklists and acceptance criteria
  - QC tools and automated checks
  - Continuous improvement tracking
  - Quality metrics dashboard

- **Manager Delegation System**: Worker task assignment in `MANAGER_DELEGATION.md`

  - Git Server Docker Setup broken into 8 worker assignments
  - Clear agent responsibilities and timelines
  - Acceptance criteria for each assignment
  - Daily standup and status reporting structure
  - Escalation procedures

- **Project Management Summary**: High-level status in `PROJECT_MANAGEMENT_SUMMARY.md`

  - Current project state overview
  - Completion metrics and progress tracking
  - Next steps and action items
  - Success criteria and milestones

### Changed - 2025-12-21

- **docs/INDEX.md**: Added "Project Management" section with links to new documents
  - Task Tracker reference
  - QC Workflow reference
  - Manager Delegation reference
  - Project Management Summary reference
  - Feature planning documents

### Added

- Initial project setup with Docker Compose orchestration
- Comprehensive documentation structure
- Agent configuration for agentic development workflow
- Development guides and coding standards
- Architecture documentation with ADR system
- Documentation for runners, GPU support, security, and operations

### Documentation

- Created complete documentation structure in `docs/`
- Added documentation index at `docs/INDEX.md`
- Added AI agent configuration at `.github/agents/agent.md`
- Added development guides for setup, testing, standards, and common tasks
- Added architecture overview and ADR system
- Added component documentation for installation, configuration, runners, GPU, security, operations,
  and API

## [0.1.0] - 2025-12-23

### Added

- **Project Reorganization**: Cleaned up root directory and moved documentation to `docs/`
  subdirectories.
- **Automated Versioning**: Implemented `scripts/automate-version.sh` and GitHub Actions workflow
  for semantic versioning.
- **Homelab Infrastructure**: Added Terraform/OpenTofu configuration for deployment to homelab
  server (192.168.1.170).
- **CI/CD Improvements**: Fixed release workflow permissions and triggers.
- **Dependency Updates**: Bumped multiple GitHub Actions and service images (GitLab CE, Python).

### Added - 2025-12-21

- **Task Tracker System**: Comprehensive project task tracking in `TASK_TRACKER.md`

  - Milestone tracking with detailed subtasks
  - Progress metrics and velocity tracking
  - Agent assignments and resource allocation
  - Risk and blocker management
  - 163 checklist items for complete task management

- **QC Workflow**: Quality control procedures in `QC_WORKFLOW.md`

  - 6 quality gates (Code, Testing, Documentation, Security, Performance, Infrastructure)
  - Detailed checklists and acceptance criteria
  - QC tools and automated checks
  - Continuous improvement tracking
  - Quality metrics dashboard

- **Manager Delegation System**: Worker task assignment in `MANAGER_DELEGATION.md`

  - Git Server Docker Setup broken into 8 worker assignments
  - Clear agent responsibilities and timelines
  - Acceptance criteria for each assignment
  - Daily standup and status reporting structure
  - Escalation procedures

- **Project Management Summary**: High-level status in `PROJECT_MANAGEMENT_SUMMARY.md`

  - Current project state overview
  - Completion metrics and progress tracking
  - Next steps and action items
  - Success criteria and milestones

### Changed - 2025-12-21

- **docs/INDEX.md**: Added "Project Management" section with links to new documents
  - Task Tracker reference
  - QC Workflow reference
  - Manager Delegation reference
  - Project Management Summary reference
  - Feature planning documents

### Added

- Initial project setup with Docker Compose orchestration
- Comprehensive documentation structure
- Agent configuration for agentic development workflow
- Development guides and coding standards
- Architecture documentation with ADR system
- Documentation for runners, GPU support, security, and operations

### Documentation

- Created complete documentation structure in `docs/`
- Added documentation index at `docs/INDEX.md`
- Added AI agent configuration at `.github/agents/agent.md`
- Added development guides for setup, testing, standards, and common tasks
- Added architecture overview and ADR system
- Added component documentation for installation, configuration, runners, GPU, security, operations,
  and API

[0.1.0]: https://github.com/tzervas/autogit/releases/tag/v0.1.0
[0.2.0]: https://github.com/tzervas/autogit/compare/v0.1.16...v0.2.0
[unreleased]: https://github.com/tzervas/autogit/compare/v0.2.0...HEAD
