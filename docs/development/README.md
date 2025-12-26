# Development Guide

Welcome to AutoGit development!

## Getting Started

New to the project? Start here:

1. [Development Setup](setup.md) - Set up your local environment
1. [Project Structure](project-structure.md) - Understand the codebase
1. [Coding Standards](standards.md) - Follow our conventions
1. [Testing Guide](testing.md) - Write and run tests

## Development Workflow

### 1. Setup Development Environment

```bash
# Clone repository
git clone https://github.com/yourusername/autogit.git
cd autogit

# Run setup script
./scripts/setup-dev.sh

# Start development services
make dev-up
```

See [Development Setup](setup.md) for detailed instructions.

### 2. Make Changes

Follow our [Coding Standards](standards.md):

- Write clean, SOLID-compliant code
- Follow PEP 8 and Black formatting
- Add docstrings to all public functions
- Update documentation with code changes

### 3. Write Tests

All changes must include tests:

- Unit tests for business logic
- Integration tests for component interactions
- E2E tests for critical user flows

See [Testing Guide](testing.md) for details.

### 4. Run Quality Checks

```bash
# Format code
make format

# Lint code
make lint

# Run tests
make test

# Check coverage
make coverage
```

### 5. Update Documentation

**CRITICAL**: Update documentation with every code change!

- Check [docs/INDEX.md](../INDEX.md) for affected docs
- Update component documentation
- Update API docs if interfaces changed
- Create ADR for architectural decisions

See [Documentation Guide](documentation.md) for standards.

### 6. Submit Pull Request

- Create feature branch: `git checkout -b feature/my-feature`
- Commit with conventional commits: `feat: add GPU detection`
- Push and create PR
- Ensure CI passes
- Request review

## Development Tools

### Required Tools

- **Python 3.11+** - Primary language
- **UV** - Python dependency management
- **Docker** - Container runtime
- **Make** - Build automation
- **Git** - Version control

### Recommended Tools

- **VS Code** or **PyCharm** - IDEs with Python support
- **Pre-commit** - Git hooks for quality checks
- **k9s** - Kubernetes cluster management

See [Development Setup](setup.md) for installation.

## Project Structure

```
autogit/
├── .github/
│   ├── workflows/        # CI/CD pipelines
│   └── agents/           # AI agent configuration
├── src/
│   ├── fleeting-plugin/  # Custom runner autoscaling
│   ├── gpu-detector/     # GPU detection service
│   └── runner-manager/   # Runner lifecycle management
├── services/
│   ├── git-server/       # Git server implementation
│   └── runner-coordinator/ # Runner coordination
├── docs/                 # Documentation
├── tests/                # Test suites
├── config/               # Configuration files
├── scripts/              # Utility scripts
└── charts/               # Helm charts
```

See [Project Structure](project-structure.md) for details.

## Common Tasks

Quick reference for common development tasks:

- [Adding a New Component](common-tasks.md#new-component)
- [Modifying Runner Behavior](common-tasks.md#runner-behavior)
- [Adding GPU Support](common-tasks.md#gpu-support)
- [Writing Tests](common-tasks.md#writing-tests)
- [Debugging](common-tasks.md#debugging)

See [Common Tasks](common-tasks.md) for step-by-step guides.

## Testing

AutoGit requires comprehensive testing:

- **Unit Tests** - 80%+ coverage required
- **Integration Tests** - Component interactions
- **E2E Tests** - Full system workflows

```bash
# Run all tests
make test

# Run specific test
pytest tests/test_runner_manager.py

# Run with coverage
make coverage
```

See [Testing Guide](testing.md) for details.

## CI/CD

All changes go through automated CI/CD:

1. **Linting** - Black, flake8, mypy
1. **Testing** - Full test suite with coverage
1. **Building** - Multi-arch Docker images
1. **Security** - Vulnerability scanning
1. **Documentation** - Link validation

See [CI/CD Guide](ci-cd.md) for pipeline details.

## Agentic Workflow

AutoGit uses an agentic development workflow with specialized personas:

- **Project Manager** - Task coordination
- **Software Engineer** - Implementation
- **DevOps Engineer** - Infrastructure
- **Security Engineer** - Security review
- **Documentation Engineer** - Documentation
- **Evaluator** - Quality assurance

See [Agentic Workflow](agentic-workflow.md) for details.

## Code Review

All PRs require:

- [ ] Code follows standards
- [ ] Tests pass with good coverage
- [ ] Documentation updated
- [ ] Security review passed
- [ ] Performance acceptable

See [Code Review Guidelines](code-review.md) for criteria.

## Release Process

Releases follow semantic versioning:

- **Major** - Breaking changes
- **Minor** - New features (backward compatible)
- **Patch** - Bug fixes

See [Release Process](release-process.md) for details.

## Getting Help

- **Documentation** - Check [docs/INDEX.md](../INDEX.md)
- **Issues** - Search existing issues on GitHub
- **Discussions** - Ask questions in GitHub Discussions
- **Contributing** - See [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Resources

- [Architecture Overview](../architecture/README.md)
- [API Documentation](../api/README.md)
- [Security Guidelines](../security/README.md)
- [Operations Guide](../operations/README.md)
