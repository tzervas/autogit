# Common Development Tasks

Quick reference guide for common development tasks in AutoGit.

## Adding a New Component

### Step-by-Step Process

1. **Check License Compatibility**
   ```bash
   # Verify dependency license
   pip-licenses --from=mixed --format=markdown
   ```
   Update `LICENSES.md` with new dependency

2. **Create Component Structure**
   ```bash
   mkdir -p src/new-component/{core,models,adapters,utils,tests}
   touch src/new-component/{__init__.py,README.md}
   ```

3. **Implement Component**
   - Follow [coding standards](standards.md)
   - Use SOLID principles
   - Add type hints
   - Write docstrings

4. **Write Tests**
   ```bash
   # Create test file
   touch src/new-component/tests/test_component.py

   # Run tests
   pytest src/new-component/tests/
   ```

5. **Update Documentation**
   - Create `docs/new-component/README.md`
   - Update `docs/INDEX.md`
   - Create ADR if architectural change

6. **Update Configuration**
   - Add to Docker Compose: `compose/dev/docker-compose.yml`
   - Add to Kubernetes: `charts/autogit/templates/`
   - Add configuration examples

7. **Update Build System**
   - Add to `pyproject.toml` if new module
   - Update `Makefile` if new commands

## Modifying Runner Behavior

### Adding a New Runner Feature

1. **Identify Affected Components**
   - Fleeting plugin: `src/fleeting-plugin/`
   - Runner manager: `src/runner-manager/`
   - Configuration: `config/runners/`

2. **Update Plugin Code**
   ```python
   # src/fleeting-plugin/core/plugin.py
   def new_feature(self, param: str) -> Result:
       """Implement new feature.

       See docs/runners/new-feature.md for details.
       """
       ...
   ```

3. **Update Configuration**
   ```yaml
   # config/runners/config.yml
   runner:
     new_feature:
       enabled: true
       parameter: value
   ```

4. **Add Tests**
   ```python
   # src/fleeting-plugin/tests/test_new_feature.py
   def test_new_feature():
       plugin = FleetingPlugin()
       result = plugin.new_feature("test")
       assert result.success
   ```

5. **Update Documentation**
   - Update `docs/runners/README.md`
   - Add `docs/runners/new-feature.md`
   - Update API docs: `docs/api/fleeting-plugin.md`
   - Add example: `examples/runners/new-feature/`

6. **Update INDEX**
   ```bash
   # Add to docs/INDEX.md
   ```

## Adding GPU Support for New Vendor

### Example: Adding Intel GPU Support

1. **Research Vendor Requirements**
   - Driver requirements
   - Runtime requirements
   - Detection method
   - Device paths

2. **Add Detection Logic**
   ```python
   # src/gpu-detector/detectors/intel.py
   from .base import GPUDetector

   class IntelGPUDetector(GPUDetector):
       """Detector for Intel GPUs.

       See docs/gpu/intel.md for details.
       """

       def detect(self) -> List[GPU]:
           # Implementation
           ...
   ```

3. **Update Configuration**
   ```yaml
   # config/gpu/gpu-config.yaml
   gpu:
     intel:
       enabled: true
       runtime: level-zero
       devices: all
   ```

4. **Update Kubernetes Device Plugin**
   ```yaml
   # charts/autogit/templates/gpu-device-plugin.yaml
   # Add Intel device plugin configuration
   ```

5. **Write Tests**
   ```python
   # src/gpu-detector/tests/test_intel.py
   def test_intel_detection():
       detector = IntelGPUDetector()
       gpus = detector.detect()
       assert len(gpus) > 0
   ```

6. **Update Documentation**
   - Create `docs/gpu/intel.md`
   - Update `docs/gpu/README.md`
   - Update `docs/INDEX.md`
   - Add example: `examples/gpu/intel/`

7. **Add Integration Test**
   ```python
   # tests/integration/test_intel_gpu.py
   def test_intel_gpu_scheduling():
       # Test end-to-end GPU scheduling
       ...
   ```

## Writing Tests

### Unit Test Template

```python
import pytest
from unittest.mock import Mock, patch

class TestMyComponent:
    """Tests for MyComponent."""

    @pytest.fixture
    def component(self):
        """Create component instance."""
        return MyComponent()

    @pytest.fixture
    def mock_dependency(self):
        """Mock external dependency."""
        return Mock()

    def test_basic_functionality(self, component):
        """Test basic functionality works."""
        result = component.do_something()
        assert result is not None

    def test_error_handling(self, component):
        """Test error handling."""
        with pytest.raises(ValueError):
            component.do_something_invalid()

    @patch('my_module.external_call')
    def test_with_mock(self, mock_external, component):
        """Test with mocked external call."""
        mock_external.return_value = "mocked"
        result = component.use_external()
        assert result == "mocked"
```

### Integration Test Template

```python
import pytest
from testcontainers.postgres import PostgresContainer

class TestRunnerLifecycle:
    """Integration tests for runner lifecycle."""

    @pytest.fixture(scope="class")
    def postgres(self):
        """Start PostgreSQL container."""
        with PostgresContainer() as pg:
            yield pg

    @pytest.fixture
    def runner_manager(self, postgres):
        """Create runner manager with real database."""
        config = create_config(postgres.get_connection_url())
        return RunnerManager(config)

    def test_provision_and_deprovision(self, runner_manager):
        """Test full runner lifecycle."""
        # Provision
        runner = runner_manager.provision("amd64")
        assert runner.status == "running"

        # Verify
        found = runner_manager.get(runner.id)
        assert found.id == runner.id

        # Deprovision
        runner_manager.deprovision(runner.id)
        assert runner_manager.get(runner.id) is None
```

## Debugging

### Local Debugging

```bash
# Start services with debug logging
DEBUG=1 docker compose up

# Attach to running container
docker compose exec runner-coordinator bash

# View logs
docker compose logs -f runner-coordinator

# Check service status
docker compose ps
```

### Python Debugging

```python
# Add breakpoint in code
def my_function():
    import pdb; pdb.set_trace()
    # Code continues here
```

### Remote Debugging (VS Code)

```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Remote Attach",
            "type": "python",
            "request": "attach",
            "connect": {
                "host": "localhost",
                "port": 5678
            },
            "pathMappings": [
                {
                    "localRoot": "${workspaceFolder}/src",
                    "remoteRoot": "/app"
                }
            ]
        }
    ]
}
```

## Database Migrations

### Creating a Migration

```bash
# Generate migration
alembic revision -m "add_gpu_support"

# Edit migration file
nano alembic/versions/xxx_add_gpu_support.py

# Apply migration
alembic upgrade head
```

### Rollback Migration

```bash
# Rollback one version
alembic downgrade -1

# Rollback to specific version
alembic downgrade <revision>
```

## Updating Dependencies

### Update Python Dependencies

```bash
# Update all dependencies
uv sync --upgrade

# Update specific dependency
uv add package-name@latest

# Check for security vulnerabilities
pip-audit
```

### Update Docker Images

```bash
# Pull latest base images
docker compose pull

# Rebuild with new base images
docker compose build --pull
```

## Performance Profiling

### Profile Python Code

```python
import cProfile
import pstats

# Profile function
cProfile.run('my_function()', 'profile.stats')

# Analyze results
stats = pstats.Stats('profile.stats')
stats.sort_stats('cumulative')
stats.print_stats(20)
```

### Profile API Endpoints

```bash
# Install locust for load testing
pip install locust

# Run load test
locust -f tests/load/locustfile.py
```

## Code Quality Checks

### Run All Checks

```bash
# Format code
make format

# Lint code
make lint

# Type check
make typecheck

# Run tests
make test

# Check coverage
make coverage
```

### Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## Working with Docker

### Build Images

```bash
# Build single service
docker compose build git-server

# Build all services
docker compose build

# Build without cache
docker compose build --no-cache
```

### Manage Containers

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart service
docker compose restart runner-coordinator

# View logs
docker compose logs -f
```

## Working with Kubernetes

### Deploy to Kubernetes

```bash
# Install with Helm
helm install autogit charts/autogit/

# Upgrade deployment
helm upgrade autogit charts/autogit/

# Check status
kubectl get pods
kubectl describe pod <pod-name>
```

### Debug Kubernetes Issues

```bash
# View logs
kubectl logs <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- bash

# Port forward
kubectl port-forward <pod-name> 8080:8080
```

## CI/CD

### Run CI Locally

```bash
# Install act
brew install act

# Run GitHub Actions locally
act push
```

### Trigger Release

```bash
# Tag version
git tag v1.0.0

# Push tag
git push origin v1.0.0

# GitHub Actions will build and release
```

## Documentation Tasks

### Generate API Docs

```bash
# Generate API documentation
pdoc --html --output-dir docs/api src/
```

### Check Documentation Links

```bash
# Install markdown-link-check
npm install -g markdown-link-check

# Check all links
find docs -name "*.md" -exec markdown-link-check {} \;
```

### Preview Documentation

```bash
# Install MkDocs
pip install mkdocs mkdocs-material

# Serve documentation locally
mkdocs serve

# Build static site
mkdocs build
```

## Getting Help

If you're stuck:

1. Check [Troubleshooting Guide](../troubleshooting/README.md)
2. Search [existing issues](https://github.com/yourusername/autogit/issues)
3. Ask in [GitHub Discussions](https://github.com/yourusername/autogit/discussions)
4. Review [documentation](../INDEX.md)

## References

- [Development Setup](setup.md)
- [Coding Standards](standards.md)
- [Testing Guide](testing.md)
- [Project Structure](project-structure.md)
