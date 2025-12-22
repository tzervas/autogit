# Development Setup Guide
This guide will help you set up a local development environment for AutoGit.

**Related Documentation**:
- [Development Overview](README.md)
- [Coding Standards](standards.md)
- [Testing Guide](testing.md)
- [Project Structure](project-structure.md)
## Prerequisites
### Required Software
- **Python 3.11+** - Language runtime
- **UV** - Python project management
- **Docker 24.0+** - Container runtime
- **Docker Compose 2.20+** - Multi-container orchestration
- **Git** - Version control
- **Make** (optional) - Build automation
### Optional Software
- **Kubernetes** (k3s, kind, or minikube) - For Kubernetes development
- **Helm 3.12+** - Kubernetes package manager
- **kubectl** - Kubernetes CLI
- **Pre-commit** - Git hooks for code quality
### System Requirements
- **OS**: Debian 12+, Ubuntu 22.04+, or macOS 13+
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 50GB free space
- **CPU**: 4 cores minimum
## Quick Start
```bash
# Clone the repository
git clone https://github.com/yourusername/autogit.git
cd autogit
# Run setup script
./scripts/setup-dev.sh
# Start development environment
make dev-up
# Run tests
make test
```
## Detailed Setup
### 1. Install Python Dependencies
```bash
# Install UV (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh
# Create virtual environment and install dependencies
uv sync

# Activate virtual environment
source .venv/bin/activate
```
### 2. Install Pre-commit Hooks
```bash
# Install pre-commit
pip install pre-commit
# Install git hooks
pre-commit install
# Run hooks manually (optional)
pre-commit run --all-files
```
### 3. Configure Development Environment
```bash
# Copy example environment file
cp .env.example .env.dev
# Edit configuration
nano .env.dev
# Required variables for development:
# - GITLAB_ROOT_PASSWORD
# - RUNNER_REGISTRATION_TOKEN
# - AUTHELIA_JWT_SECRET
# - POSTGRES_PASSWORD
```
### 4. Start Development Services
```bash
# Start all services with Docker Compose
docker compose -f compose/dev/docker-compose.yml up -d
# Check service status
docker compose -f compose/dev/docker-compose.yml ps
# View logs
docker compose -f compose/dev/docker-compose.yml logs -f
```
### 5. Verify Installation
```bash
# Run health checks
./scripts/health-check.sh
# Run unit tests
uv run pytest
# Run integration tests
uv run pytest tests/integration/

# Check code formatting
black --check src/
flake8 src/
mypy src/
```
## IDE Setup
### VS Code
1. Install recommended extensions:
```bash
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.black-formatter
code --install-extension ms-azuretools.vscode-docker
```
2. Open workspace:
```bash
code autogit.code-workspace
```
3. VS Code will automatically:
- Use the project's Python interpreter
- Format on save with Black
- Run linters (flake8, mypy)
- Provide devcontainer support
### PyCharm
1. Open project directory in PyCharm
2. Configure interpreter:
- Go to `Settings` → `Project` → `Python Interpreter`
- Add interpreter → Select `.venv/bin/python`
3. Configure Black formatter:
- Go to `Settings` → `Tools` → `Black`
- Set Black executable to `.venv/bin/black`
4. Enable pytest:
- Go to `Settings` → `Tools` → `Python Integrated Tools`
- Set default test runner to `pytest`
## Development Workflow
### Creating a New Feature
1. **Create feature branch**:
```bash
git checkout -b feature/my-new-feature
```
2. **Check documentation**:
- Review `docs/INDEX.md` for relevant documentation
- Read related architecture docs
3. **Implement feature**:
- Follow [Coding Standards](standards.md)
- Write tests alongside code (TDD)
- Update documentation as you go

4. **Run tests**:
```bash
# Unit tests
uv run pytest tests/unit/
# Integration tests
uv run pytest tests/integration/
# Coverage report
uv run pytest --cov --cov-report=html
```
5. **Update documentation**:
- Update relevant docs in `docs/`
- Update `docs/INDEX.md` if adding new docs
- Create ADR if making architectural decisions
6. **Commit changes**:
```bash
git add .
git commit -m "feat: add new feature
- Implement feature X
- Add tests for feature X
- Update docs: docs/path/to/doc.md"
```
7. **Push and create PR**:
```bash
git push origin feature/my-new-feature
# Create PR on GitHub with documentation checklist
```
### Running Tests
```bash
# All tests
make test
# Unit tests only
make test-unit
# Integration tests only
make test-integration
# Specific test file
uv run pytest tests/unit/test_runner_manager.py
# Specific test
uv run pytest tests/unit/test_runner_manager.py::TestRunnerManager::test_provision
# With coverage
make test-coverage
# Watch mode (re-run on file changes)
uv run pytest-watch
```

### Code Quality Checks
```bash
# Format code
make format
# Lint code
make lint
# Type check
make typecheck
# All quality checks
make quality
```
### Building and Testing Locally
```bash
# Build Docker images
make build
# Build multi-arch images
make build-multiarch
# Run integration tests with Docker Compose
make test-integration-docker
# Run end-to-end tests
make test-e2e
```
## Troubleshooting
### Port Conflicts
If you see port binding errors:
```bash
# Check what's using the port
sudo lsof -i :80
sudo lsof -i :443
# Stop conflicting services
sudo systemctl stop nginx
sudo systemctl stop apache2
```
### Docker Permission Issues
If you get permission denied errors:
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
```

### Python Import Errors
If you encounter import errors:
```bash
# Ensure virtual environment is activated
source .venv/bin/activate
# Reinstall dependencies
uv sync --reinstall
# Install package in editable mode
uv pip install -e .
```
### Database Connection Issues
If GitLab can't connect to PostgreSQL:
```bash
# Check PostgreSQL container
docker compose -f compose/dev/docker-compose.yml logs postgres
# Restart services
docker compose -f compose/dev/docker-compose.yml restart
```
## Development Tools
### Makefile Commands
```bash
# Development
make dev-up

# Start dev environment

make dev-down

# Stop dev environment

make dev-logs

# View logs

make dev-shell

# Open shell in container

# Testing
make test

# Run all tests

make test-unit

# Unit tests only

make test-integration # Integration tests
make test-e2e

# End-to-end tests

make test-coverage

# Generate coverage report

# Code Quality
make format

# Format code with Black

make lint

# Run linters

make typecheck

# Type checking with mypy

make quality

# All quality checks

# Building
make build

# Build Docker images

make build-multiarch # Multi-architecture build
# Documentation
make docs

# Build documentation

make docs-serve

# Serve docs locally

make docs-check

# Check documentation links

# Cleanup
make clean

# Remove build artifacts

make clean-all

# Deep clean including containers

```
### Helper Scripts
```bash
# Setup development environment
./scripts/setup-dev.sh
# Health checks
./scripts/health-check.sh
# Generate configuration
./scripts/generate-config.sh
# Database migrations
./scripts/db-migrate.sh
# Verify documentation index
./scripts/verify-doc-index.sh
```
## Next Steps
Now that your development environment is set up:
1. Read the [Coding Standards](standards.md)
2. Review the [Testing Guide](testing.md)
3. Check out [Common Tasks](common-tasks.md)
4. Browse the [Architecture documentation](../architecture/README.md)
5. Join the [development discussion](https://github.com/yourusername/autogit/discussions)
## Getting Help
- **Documentation**: Check [docs/INDEX.md](../INDEX.md)
- **Issues**: [GitHub Issues](https://github.com/yourusername/autogit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/autogit/discussions)
- **Contributing**: See [CONTRIBUTING.md](../../CONTRIBUTING.md)

---

**Documentation Version**: 1.0.0
**Last Updated**: YYYY-MM-DD
**Related Docs**: [Development Overview](README.md) | [Standards](standards.md) | [Testing](testing.md)
