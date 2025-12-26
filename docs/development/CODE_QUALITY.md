# Code Quality & CI/CD Standards

This document describes the standardized code quality checks used in AutoGit to ensure local
development and CI environments produce identical results.

## Philosophy: "If It Works Here, It Works There"

The primary goal is **local/remote parity** - the exact same checks run locally (via pre-commit) and
remotely (via CI), using the same tools, same versions, and same configuration.

## Tool Stack

### Python Ecosystem

| Tool         | Purpose              | Replaces                                   |
| ------------ | -------------------- | ------------------------------------------ |
| **Ruff**     | Linting + Formatting | Black, isort, flake8, pyupgrade, autoflake |
| **Mypy**     | Static type checking | -                                          |
| **Pytest**   | Testing framework    | unittest (optional migration)              |
| **Coverage** | Code coverage        | -                                          |

**Why Ruff?**

- 10-100x faster than Black + isort + flake8 combined
- Single tool, single configuration
- Written in Rust, extremely fast
- Active development, excellent Python 3.13 support

### Shell Scripts

| Tool           | Purpose                 |
| -------------- | ----------------------- |
| **ShellCheck** | Shell script linting    |
| **shfmt**      | Shell script formatting |

### Documentation

| Tool             | Purpose             |
| ---------------- | ------------------- |
| **markdownlint** | Markdown linting    |
| **mdformat**     | Markdown formatting |
| **yamllint**     | YAML linting        |

### Security

| Tool               | Purpose            |
| ------------------ | ------------------ |
| **detect-secrets** | Secret detection   |
| **hadolint**       | Dockerfile linting |

## Configuration Files

All configuration is centralized in these files:

```
pyproject.toml           # Python tools (ruff, mypy, pytest, coverage)
.editorconfig            # Universal editor settings
.markdownlint.json       # Markdown linting rules
config/.yamllint.yml     # YAML linting rules
.pre-commit-config.yaml  # Pre-commit hook configuration
```

### Configuration Hierarchy

```
pyproject.toml (PRIMARY - Python tooling)
       ↓
.pre-commit-config.yaml (uses pyproject.toml)
       ↓
CI Workflows (use same tools + configs)
```

## Pre-commit Hooks

Pre-commit hooks run automatically on every commit. Setup:

```bash
# Initial setup
make setup

# Or manually:
uv run pre-commit install
uv run pre-commit install --hook-type commit-msg
```

### Hook Stages

1. **File Hygiene** - Whitespace, line endings, file validation
1. **Python** - Ruff lint + format
1. **Shell** - ShellCheck + shfmt
1. **YAML** - yamllint
1. **Markdown** - markdownlint + mdformat
1. **Docker** - hadolint
1. **Security** - detect-secrets
1. **Commit Message** - Conventional commit validation

### Running Manually

```bash
# Run all hooks on all files
make check

# Or directly:
uv run pre-commit run --all-files

# Run specific hook
uv run pre-commit run ruff --all-files
```

## CI Pipeline

### GitHub Actions

The PR validation workflow (`pr-validation.yml`) runs:

1. Branch naming validation
1. PR target validation
1. Lint & auto-fix (self-healing)
1. Syntax validation (Python, Shell, YAML, JSON)
1. Documentation checks
1. Docker validation

### GitLab CI

The GitLab CI pipeline (`.gitlab-ci.yml`) runs:

1. Syntax validation
1. Dependency checks
1. Unit tests
1. Integration tests
1. Docker builds

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `style` - Formatting, no code change
- `refactor` - Code change that neither fixes nor adds
- `perf` - Performance improvement
- `test` - Adding tests
- `chore` - Maintenance tasks
- `ci` - CI/CD changes
- `build` - Build system changes

### Examples

```
feat(runner): add GPU scheduling support
fix(coordinator): resolve memory leak in job queue
docs(readme): update installation instructions
ci(github): add self-hosted runner support
```

## Testing

### Running Tests

```bash
# Full test suite with coverage
make test

# Fast tests (no coverage)
make test-fast

# Unit tests only
make test-unit

# Specific test file
uv run pytest tests/test_gitlab_client.py -v
```

### Coverage Requirements

- Minimum coverage: 60%
- Coverage reports: `coverage_html/index.html`

### Test Markers

```python
@pytest.mark.slow          # Slow-running tests
@pytest.mark.integration   # Requires external services
@pytest.mark.unit          # Fast, isolated tests
```

## Type Checking

Mypy is configured for gradual typing adoption:

```bash
# Run type checking
make typecheck

# Or directly:
uv run mypy services tools --config-file pyproject.toml
```

### Current Configuration

- Strict mode disabled (gradual adoption)
- Missing imports ignored
- Tests excluded from strict checking

## Quick Reference

### Common Commands

```bash
make setup      # First-time setup
make check      # Run all checks
make lint       # Run linters only
make format     # Format all code
make test       # Run tests
make ci         # Simulate full CI locally
make clean      # Clean artifacts
```

### Fixing Issues

```bash
# Auto-fix Python issues
uv run ruff check --fix .
uv run ruff format .

# Auto-fix shell scripts
find scripts -name "*.sh" -exec shfmt -w {} +

# Auto-fix markdown
uv run mdformat docs/
```

## Troubleshooting

### Pre-commit fails on first run

```bash
# Clear cache and reinstall
uv run pre-commit clean
uv run pre-commit install --install-hooks
```

### CI passes locally but fails remotely

1. Ensure you're using the same Python version (3.13)
1. Run `make ci` to simulate CI locally
1. Check for environment-specific issues

### Type errors in third-party libraries

Add stubs or ignore in `pyproject.toml`:

```toml
[[tool.mypy.overrides]]
module = "problematic_library.*"
ignore_missing_imports = true
```

## Adding New Checks

1. Add to `pyproject.toml` if Python-related
1. Add to `.pre-commit-config.yaml`
1. Add to relevant CI workflow
1. Update this documentation

## Version Pinning

Tool versions are pinned in:

- `.pre-commit-config.yaml` - Hook versions
- `pyproject.toml` - Dev dependency versions

Update with:

```bash
make update
```
