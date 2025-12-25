# CI/CD Pipeline

This document describes the CI/CD pipeline for AutoGit.

## Overview

AutoGit uses GitHub Actions for continuous integration and deployment.

## Pipeline Stages

### 1. Linting

Ensures code quality and style consistency.

```yaml
lint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    - name: Install dependencies
      run: pip install black flake8 mypy isort
    - name: Check formatting
      run: black --check .
    - name: Lint with flake8
      run: flake8 src/ tests/
    - name: Type check
      run: mypy src/
    - name: Check import order
      run: isort --check-only .
```

### 2. Testing

Runs all tests with coverage reporting.

```yaml
test:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      python-version: ['3.11', '3.12']
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}
    - name: Install UV
      run: pip install uv
    - name: Install dependencies
      run: uv sync
    - name: Run tests
      run: uv run pytest --cov --cov-report=xml
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
```

### 3. Security Scanning

Scans for security vulnerabilities.

```yaml
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run Bandit
      run: |
        pip install bandit
        bandit -r src/
    - name: Run Safety
      run: |
        pip install safety
        safety check
    - name: Run Trivy (container scan)
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
```

### 4. Build

Builds Docker images for multiple architectures.

```yaml
build:
  runs-on: ubuntu-latest
  needs: [lint, test, security]
  steps:
    - uses: actions/checkout@v4
    - name: Set up QEMU
      uses: docker/setup-qemu-action@v3
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    - name: Build multi-arch images
      run: |
        docker buildx build \
          --platform linux/amd64,linux/arm64 \
          --tag autogit/runner-coordinator:${{ github.sha }} \
          services/runner-coordinator/
```

### 5. Documentation

Validates documentation.

```yaml
docs:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Check documentation links
      run: |
        npm install -g markdown-link-check
        find docs -name "*.md" -exec markdown-link-check {} \;
    - name: Verify INDEX.md is up to date
      run: ./scripts/verify-doc-index.sh
    - name: Check for broken cross-references
      run: ./scripts/check-doc-refs.sh
```

### 6. Integration Tests

Runs integration tests with Docker Compose.

```yaml
integration:
  runs-on: ubuntu-latest
  needs: build
  steps:
    - uses: actions/checkout@v4
    - name: Start services
      run: docker compose -f compose/dev/docker-compose.yml up -d
    - name: Wait for services
      run: ./scripts/wait-for-services.sh
    - name: Run integration tests
      run: pytest tests/integration/
    - name: Stop services
      run: docker compose down
```

### 7. E2E Tests

Runs end-to-end tests.

```yaml
e2e:
  runs-on: ubuntu-latest
  needs: integration
  steps:
    - uses: actions/checkout@v4
    - name: Deploy to test environment
      run: ./scripts/deploy-test.sh
    - name: Run E2E tests
      run: pytest tests/e2e/
    - name: Cleanup
      if: always()
      run: ./scripts/cleanup-test.sh
```

## Release Pipeline

Triggered when a tag is pushed.

```yaml
release:
  runs-on: ubuntu-latest
  if: startsWith(github.ref, 'refs/tags/')
  needs: [lint, test, security, build, integration, e2e]
  steps:
    - uses: actions/checkout@v4

    - name: Extract version
      id: version
      run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

    - name: Build and push images
      run: |
        docker login -u ${{ secrets.DOCKER_USERNAME }} -p ${{ secrets.DOCKER_PASSWORD }}
        docker buildx build \
          --platform linux/amd64,linux/arm64 \
          --tag autogit/runner-coordinator:${{ steps.version.outputs.VERSION }} \
          --tag autogit/runner-coordinator:latest \
          --push \
          services/runner-coordinator/

    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ steps.version.outputs.VERSION }}
        body_path: CHANGELOG.md

    - name: Deploy Helm chart
      run: |
        helm package charts/autogit/
        helm push autogit-${{ steps.version.outputs.VERSION }}.tgz oci://ghcr.io/yourusername/charts
```

## Branch Protection

### Main Branch

Required checks:

- ✓ Linting passes
- ✓ All tests pass (80%+ coverage)
- ✓ Security scan passes
- ✓ Documentation validation passes
- ✓ At least one approval
- ✓ Up to date with base branch

### Release Branches

Additional requirements:

- ✓ Integration tests pass
- ✓ E2E tests pass
- ✓ CHANGELOG.md updated
- ✓ Version bumped

## Coverage Requirements

### Minimum Coverage

- **Overall**: 80%
- **Critical paths**: 90%
- **New code**: 85%

### Coverage Reporting

```yaml
- name: Check coverage
  run: |
    coverage report --fail-under=80
    coverage html
- name: Upload coverage report
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: htmlcov/
```

## Performance Testing

### Load Testing

```yaml
performance:
  runs-on: ubuntu-latest
  steps:
    - name: Run load tests
      run: |
        pip install locust
        locust -f tests/load/locustfile.py \
          --headless \
          --users 100 \
          --spawn-rate 10 \
          --run-time 5m \
          --host http://localhost:8080
```

### Benchmark Tests

```yaml
- name: Run benchmarks
  run: pytest tests/benchmarks/ --benchmark-only
- name: Compare with baseline
  run: pytest-benchmark compare
```

## Secrets Management

### Required Secrets

- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password
- `CODECOV_TOKEN` - Codecov token
- `GITHUB_TOKEN` - GitHub token (automatic)

### Managing Secrets

```bash
# Add secret via GitHub CLI
gh secret set DOCKER_USERNAME

# List secrets
gh secret list

# Remove secret
gh secret remove DOCKER_USERNAME
```

## Deployment Targets

### Development

- **Trigger**: Push to `develop` branch
- **Environment**: Development cluster
- **Auto-deploy**: Yes

### Staging

- **Trigger**: Push to `staging` branch
- **Environment**: Staging cluster
- **Auto-deploy**: Yes
- **Smoke tests**: Required

### Production

- **Trigger**: Tag push (e.g., `v1.0.0`)
- **Environment**: Production cluster
- **Auto-deploy**: No (manual approval)
- **Full tests**: Required

## Rollback Procedure

### Automatic Rollback

If health checks fail after deployment:

```yaml
- name: Health check
  run: ./scripts/health-check.sh
- name: Rollback on failure
  if: failure()
  run: |
    helm rollback autogit
```

### Manual Rollback

```bash
# List releases
helm history autogit

# Rollback to previous version
helm rollback autogit

# Rollback to specific version
helm rollback autogit 3
```

## Monitoring

### Pipeline Metrics

- Build duration
- Test duration
- Success rate
- Flaky tests

### Notifications

```yaml
- name: Notify on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Build failed'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Local CI Execution

### Run with Act

```bash
# Install act
brew install act

# Run all workflows
act

# Run specific workflow
act -W .github/workflows/ci.yml

# Run specific job
act -j test
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
      - id: mypy
```

## Troubleshooting

### Common Issues

**Tests failing in CI but passing locally**

- Check Python version match
- Ensure dependencies are locked
- Verify environment variables

**Build timeout**

- Increase timeout in workflow
- Optimize Docker layer caching
- Use multi-stage builds

**Flaky tests**

- Identify flaky tests: `pytest --lf`
- Add retries for network-dependent tests
- Use proper test isolation

## Best Practices

1. **Fast Feedback** - Fail fast on linting/formatting
1. **Parallel Execution** - Run independent jobs in parallel
1. **Caching** - Cache dependencies and build artifacts
1. **Matrix Testing** - Test multiple Python versions
1. **Branch Protection** - Require status checks before merge

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [Codecov](https://docs.codecov.com/)
- [Pre-commit](https://pre-commit.com/)
