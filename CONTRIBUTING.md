# Contributing to AutoGit

Thank you for your interest in contributing to AutoGit! This guide will help you get started with
the development workflow.

## Quick Start

1. Fork the repository
1. Clone your fork
1. Run `./scripts/setup.sh`
1. Create a feature branch (see [Branching Strategy](#branching-strategy) below)
1. Make your changes
1. Test with `docker-compose up`
1. Submit a pull request

## Branching Strategy

AutoGit follows a structured branching model to maintain code quality and enable parallel
development. Please read our complete [Branching Strategy Guide](development/branching-strategy.md)
for detailed information.

### Quick Reference

#### Main Branches

- **`main`** - Production-ready code (protected)
- **`dev`** - Integration branch for features (protected)

#### Feature Development

```
dev
 └─ feature/<task-name>
     └─ feature/<task-name>/<subtask>
         └─ feature/<task-name>/<subtask>/<work-item>
```

#### Creating a Feature Branch

Use our helper script:

```bash
# Create feature with sub-features
./scripts/create-feature-branch.sh gpu-scheduling detection-service scheduler-logic

# Or manually
git checkout dev
git pull origin dev
git checkout -b feature/gpu-scheduling
git push -u origin feature/gpu-scheduling
```

#### Branch Naming Conventions

- Feature: `feature/<name>`
- Sub-feature: `feature/<name>/<subtask>`
- Work item: `feature/<name>/<subtask>/<work-item>`
- Hotfix: `hotfix/<description>`
- Release: `release/v<major>.<minor>.<patch>`

**Use lowercase letters, numbers, and hyphens only.**

#### Workflow

1. Create feature branch from `dev`
1. Break work into sub-features
1. Create work branches for specific changes
1. Merge work → sub-feature → feature → dev

See [Branching Strategy](development/branching-strategy.md) for complete workflow.

## Development Guidelines

- Follow Docker best practices
- Keep services loosely coupled
- Document all APIs
- Add tests where appropriate (80%+ coverage)
- Update documentation with code changes
- Follow SOLID principles
- Use conventional commit messages

## Service Development

Each service should:

- Have its own Dockerfile
- Include a README in its directory
- Expose health check endpoints
- Handle graceful shutdown
- Log to stdout/stderr

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`

**Examples**:

```
feat(gpu): add NVIDIA GPU detection service
fix(auth): resolve token expiration issue
docs: update branching strategy guide
```

## Pull Requests

### PR Templates

We provide templates for different PR types:

- **Release PR** (dev → main): Use `release_template.md`
- **Feature PR** (feature → dev): Use `feature_template.md`
- **Sub-Feature PR** (sub-feature → feature): Use `sub_feature_template.md`
- **Work PR** (work → sub-feature): Use `work_template.md`

### PR Requirements

All PRs must include:

- Clear description of changes
- Tests (unit, integration, E2E as appropriate)
- Updated documentation
- No linting errors
- Passing CI/CD checks
- Security scan passed

## Testing

```bash
# Build and test locally
docker-compose build
docker-compose up

# Run tests (when available)
# [Test commands will be added as features are implemented]
```

See [Testing Guide](development/testing.md) for comprehensive testing guidelines.

## Code Review

All PRs require:

- At least 1 approval
- Passing CI/CD checks
- No unresolved comments
- Up-to-date with base branch

## Helpful Scripts

We provide several helper scripts in `/scripts/`:

- **`create-feature-branch.sh`** - Create feature branch structure
- **`validate-branch-name.sh`** - Validate branch naming
- **`sync-branches.sh`** - Keep branch synced with base
- **`cleanup-merged-branches.sh`** - Clean up merged branches

## Documentation

Documentation is as important as code:

- Update relevant docs with code changes
- Follow markdown best practices
- Include code examples
- Update INDEX.md if adding new docs
- Create ADRs for architecture decisions

See [Documentation Guide](development/documentation.md) for details.

## Questions?

- Check [FAQ.md](../FAQ.md) for common questions
- Review [docs/INDEX.md](INDEX.md) for navigation
- Open an issue for discussion
- Ask in GitHub Discussions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
