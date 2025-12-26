# =============================================================================
# AutoGit Makefile - Common Development Operations
# =============================================================================
# This Makefile provides standardized commands that work identically
# locally and in CI environments.
#
# Usage: make <target>
# =============================================================================

.PHONY: help install lint format test check clean setup ci

# Default target
help:
	@echo "AutoGit Development Commands"
	@echo "============================"
	@echo ""
	@echo "Setup:"
	@echo "  make setup      - First-time setup (install deps + pre-commit)"
	@echo "  make install    - Install project dependencies"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint       - Run all linters (ruff, shellcheck, yamllint)"
	@echo "  make format     - Format all code (ruff, shfmt, mdformat)"
	@echo "  make check      - Run full pre-commit check (all hooks)"
	@echo "  make typecheck  - Run mypy type checking"
	@echo ""
	@echo "Testing:"
	@echo "  make test       - Run all tests with coverage"
	@echo "  make test-fast  - Run tests without coverage"
	@echo "  make test-unit  - Run only unit tests"
	@echo ""
	@echo "CI:"
	@echo "  make ci         - Run full CI pipeline locally"
	@echo "  make ci-lint    - Run CI-style lint checks"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make update     - Update all dependencies"

# =============================================================================
# Setup
# =============================================================================

setup: install
	@echo "📦 Installing pre-commit hooks..."
	uv run pre-commit install
	uv run pre-commit install --hook-type commit-msg
	@echo "✅ Setup complete!"

install:
	@echo "📦 Installing dependencies..."
	uv sync --all-extras
	@echo "✅ Dependencies installed!"

# =============================================================================
# Code Quality
# =============================================================================

lint:
	@echo "🔍 Running linters..."
	uv run ruff check .
	@echo "🔍 Checking shell scripts..."
	find scripts -name "*.sh" -exec shellcheck --severity=warning {} +
	@echo "🔍 Checking YAML files..."
	uv run yamllint -c config/.yamllint.yml .
	@echo "✅ Lint complete!"

format:
	@echo "🎨 Formatting code..."
	uv run ruff format .
	uv run ruff check --fix .
	@echo "🎨 Formatting shell scripts..."
	find scripts -name "*.sh" -exec shfmt -w -s -i 4 -bn -ci -sr {} +
	@echo "✅ Format complete!"

typecheck:
	@echo "🔍 Running type checker..."
	uv run mypy services tools --config-file pyproject.toml
	@echo "✅ Type check complete!"

check:
	@echo "🔍 Running pre-commit on all files..."
	uv run pre-commit run --all-files
	@echo "✅ All checks passed!"

# =============================================================================
# Testing
# =============================================================================

test:
	@echo "🧪 Running tests with coverage..."
	uv run pytest tests/ \
		--cov=services \
		--cov=tools \
		--cov-report=term-missing \
		--cov-report=html:coverage_html \
		--cov-fail-under=60
	@echo "✅ Tests complete! Coverage report: coverage_html/index.html"

test-fast:
	@echo "🧪 Running tests (no coverage)..."
	uv run pytest tests/ -v
	@echo "✅ Tests complete!"

test-unit:
	@echo "🧪 Running unit tests..."
	uv run pytest tests/ -v -m "not integration and not slow"
	@echo "✅ Unit tests complete!"

# =============================================================================
# CI Pipeline (Local Simulation)
# =============================================================================

ci: ci-lint test
	@echo "✅ CI pipeline complete!"

ci-lint:
	@echo "🔍 Running CI-style checks..."
	@echo "--- Python Syntax ---"
	find . -name "*.py" -not -path "./.venv/*" -not -path "./.git/*" | xargs python -m py_compile
	@echo "--- Ruff Lint ---"
	uv run ruff check . --output-format=github
	@echo "--- Ruff Format Check ---"
	uv run ruff format --check .
	@echo "--- YAML Syntax ---"
	find . -name "*.yml" -o -name "*.yaml" | grep -v node_modules | grep -v .git | xargs -I {} python -c "import yaml; yaml.safe_load(open('{}'))"
	@echo "✅ CI lint checks passed!"

# =============================================================================
# Maintenance
# =============================================================================

clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf __pycache__ .pytest_cache .mypy_cache .ruff_cache
	rm -rf coverage_html .coverage htmlcov
	rm -rf *.egg-info build dist
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	@echo "✅ Clean complete!"

update:
	@echo "📦 Updating dependencies..."
	uv lock --upgrade
	uv sync --all-extras
	uv run pre-commit autoupdate
	@echo "✅ Update complete!"
