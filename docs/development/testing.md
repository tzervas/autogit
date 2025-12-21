# Testing Guide
Comprehensive testing guide for AutoGit development.

**Related Documentation**:
- [Development Overview](README.md)
- [Coding Standards](standards.md)
- [Development Setup](setup.md)
- [CI/CD Guide](ci-cd.md)
## Testing Philosophy
AutoGit follows Test-Driven Development (TDD) principles:
1. **Write tests first** - Define expected behavior before implementation
2. **Red-Green-Refactor** - Fail, pass, improve cycle
3. **Comprehensive coverage** - Aim for 80%+ coverage
4. **Fast feedback** - Tests should run quickly
5. **Reliable** - Tests should not be flaky
6. **Maintainable** - Tests should be easy to understand and modify
## Test Pyramid
```
/\
/

\

/E2E \
/------\
/

Integ \

/----------\
/

Unit

\

/--------------\
```
- **Unit Tests** (70%): Test individual functions/classes in isolation
- **Integration Tests** (20%): Test component interactions
- **End-to-End Tests** (10%): Test complete user workflows
## Testing Stack
- **pytest** - Test framework
- **pytest-cov** - Coverage reporting
- **pytest-mock** - Mocking utilities
- **pytest-asyncio** - Async test support
- **pytest-docker** - Docker integration testing
- **factory_boy** - Test data factories
- **faker** - Fake data generation
## Project Test Structure
```
tests/
├── conftest.py

# Shared fixtures

├── unit/

# Unit tests

│

├── conftest.py

│

├── test_runner_manager.py

│

├── test_gpu_detector.py

│

└── test_fleeting_plugin.py

├── integration/

# Integration tests

│

├── conftest.py

│

├── test_docker_integration.py

│

└── test_kubernetes_integration.py

├── e2e/

# End-to-end tests

│

├── conftest.py

│

└── test_full_pipeline.py

├── fixtures/
│

├── configs/

│

├── data/

│

└── mocks/

└── utils/

# Test data and fixtures

# Test utilities

├── factories.py
└── helpers.py
```
## Writing Unit Tests
### Basic Test Structure
```python
"""Test suite for RunnerManager.
Documentation: docs/runners/README.md
"""
import pytest
from unittest.mock import Mock, patch, call
from autogit.runners import RunnerManager, ProvisionError

class TestRunnerManager:
"""Test suite for RunnerManager class."""
@pytest.fixture
def docker_client(self):
"""Mock Docker client."""
return Mock()
@pytest.fixture
def config(self):
"""Test configuration."""
return {
"max_instances": 10,
"idle_timeout": 300,
"architectures": ["amd64", "arm64"]
}
@pytest.fixture
def manager(self, docker_client, config):
"""RunnerManager instance."""
return RunnerManager(docker_client, config)
def test_provision_amd64_runner(self, manager, docker_client):
"""Test provisioning an amd64 runner without GPU."""
# Arrange
expected_id = "runner-123"
docker_client.containers.run.return_value.id = expected_id
# Act
runner_id = manager.provision("amd64")
# Assert
assert runner_id == expected_id

docker_client.containers.run.assert_called_once()
call_args = docker_client.containers.run.call_args
assert call_args[1]["image"].endswith(":amd64")
def test_provision_with_nvidia_gpu(self, manager, docker_client):
"""Test provisioning runner with NVIDIA GPU."""
# Arrange
expected_id = "runner-gpu-123"
docker_client.containers.run.return_value.id = expected_id
# Act
runner_id = manager.provision("amd64", gpu_type="nvidia")
# Assert
assert runner_id == expected_id
call_args = docker_client.containers.run.call_args[1]
assert "device_requests" in call_args
assert call_args["device_requests"][0].driver == "nvidia"
def test_provision_unsupported_architecture(self, manager):
"""Test provisioning with unsupported architecture raises error."""
# Act & Assert
with pytest.raises(ProvisionError, match="Unsupported architecture"):
manager.provision("mips")
def test_provision_max_instances_exceeded(self, manager):
"""Test provisioning fails when max instances reached."""
# Arrange
manager._current_instances = manager._config["max_instances"]
# Act & Assert
with pytest.raises(ProvisionError, match="Max instances reached"):
manager.provision("amd64")
@pytest.mark.asyncio
async def test_provision_async(self, manager):
"""Test async provisioning."""
# Arrange
runner_id = await manager.provision_async("amd64")
# Assert
assert runner_id is not None
```
### Testing Best Practices
1. **Use descriptive test names**:
```python
# Good
def test_provision_fails_when_docker_unavailable(self):
# Bad
def test_provision_error(self):
```
2. **Follow Arrange-Act-Assert pattern**:
```python
def test_something(self):
# Arrange - Set up test data

config = {"key": "value"}
# Act - Execute the code under test
result = function_under_test(config)
# Assert - Verify the results
assert result == expected
```
3. **One assertion per test** (when possible):
```python
# Good - focused test
def test_provision_returns_valid_id(self):
runner_id = manager.provision("amd64")
assert runner_id.startswith("runner-")
# Good - related assertions
def test_provision_configures_runner_correctly(self):
runner_id = manager.provision("amd64")
runner = manager.get_runner(runner_id)
assert runner.architecture == "amd64"
assert runner.status == "running"
```
4. **Use fixtures for setup**:
```python
@pytest.fixture
def sample_config():
"""Reusable configuration fixture."""
return {
"max_instances": 5,
"idle_timeout": 300
}
```
5. **Mock external dependencies**:
```python
@patch('autogit.runners.docker_client')
def test_with_mock(self, mock_docker):
mock_docker.containers.run.return_value.id = "test-id"
# Test implementation
```
### Testing Exceptions
```python
def test_provision_raises_error_on_invalid_config(self):
"""Test that invalid configuration raises ConfigError."""
with pytest.raises(ConfigError) as exc_info:
RunnerManager({})
assert "max_instances" in str(exc_info.value)
def test_provision_logs_warning_on_gpu_unavailable(self, caplog):
"""Test warning logged when GPU unavailable."""
with caplog.at_level(logging.WARNING):
manager.provision("amd64", gpu_type="nvidia")
assert "GPU not available" in caplog.text

```
### Testing Async Code
```python
@pytest.mark.asyncio
async def test_async_provision(self):
"""Test asynchronous runner provisioning."""
runner_id = await manager.provision_async("amd64")
assert runner_id is not None
@pytest.mark.asyncio
async def test_concurrent_provisioning(self):
"""Test multiple concurrent provisions."""
tasks = [
manager.provision_async("amd64")
for _ in range(5)
]
runner_ids = await asyncio.gather(*tasks)
assert len(runner_ids) == 5
assert len(set(runner_ids)) == 5

# All unique

```
## Writing Integration Tests
Integration tests verify that components work together correctly.
```python
"""Integration tests for Runner Manager with Docker.
Documentation: docs/runners/README.md
"""
import pytest
import docker
from autogit.runners import RunnerManager

@pytest.fixture(scope="module")
def docker_client():
"""Real Docker client for integration testing."""
return docker.from_env()

@pytest.fixture(scope="module")
def runner_manager(docker_client):
"""Runner manager with real Docker client."""
config = {
"max_instances": 3,
"idle_timeout": 60,
"image": "gitlab/gitlab-runner:alpine"
}
return RunnerManager(docker_client, config)

class TestDockerIntegration:
"""Integration tests with Docker."""
def test_provision_real_runner(self, runner_manager):

"""Test provisioning a real Docker container."""
# Act
runner_id = runner_manager.provision("amd64")
# Assert
assert runner_id is not None
# Verify container exists
container = runner_manager._docker.containers.get(runner_id)
assert container.status == "running"
# Cleanup
runner_manager.deprovision(runner_id)
def test_provision_with_volumes(self, runner_manager):
"""Test runner provisioning with volume mounts."""
# Act
runner_id = runner_manager.provision(
"amd64",
volumes={"/cache": {"bind": "/cache", "mode": "rw"}}
)
# Assert
container = runner_manager._docker.containers.get(runner_id)
mounts = container.attrs['Mounts']
assert any(m['Destination'] == '/cache' for m in mounts)
# Cleanup
runner_manager.deprovision(runner_id)
def test_autoscaling_behavior(self, runner_manager):
"""Test runner autoscaling up and down."""
# Arrange - simulate job queue
job_queue = [
{"arch": "amd64"},
{"arch": "amd64"},
{"arch": "arm64"}
]
# Act - scale up
runner_ids = []
for job in job_queue:
runner_id = runner_manager.scale_for_job(job)
runner_ids.append(runner_id)
# Assert - runners provisioned
assert len(runner_ids) == 3
# Act - scale down after idle timeout
import time
time.sleep(65)

# Wait for idle timeout

runner_manager.cleanup_idle()
# Assert - runners deprovisioned
active = runner_manager.get_active_runners()
assert len(active) == 0
```
### Database Integration Tests

```python
@pytest.fixture
def database():
"""Test database fixture."""
db = create_test_database()
yield db
db.drop_all()

def test_runner_state_persistence(runner_manager, database):
"""Test that runner state is persisted correctly."""
# Arrange
runner_id = runner_manager.provision("amd64")
# Act
runner_manager.save_state(database)
runner_manager_new = RunnerManager.load_state(database)
# Assert
runners = runner_manager_new.get_active_runners()
assert runner_id in [r.id for r in runners]
```
## Writing End-to-End Tests
E2E tests verify complete user workflows.
```python
"""End-to-end tests for AutoGit platform.
Documentation: docs/tutorials/quickstart.md
"""
import pytest
import requests
from time import sleep

@pytest.fixture(scope="module")
def autogit_instance():
"""Deploy a complete AutoGit instance for testing."""
# Start all services
subprocess.run(["docker", "compose", "-f", "compose/test/docker-compose.yml", "up", "-d"])
# Wait for services to be ready
wait_for_gitlab()
wait_for_traefik()
yield "https://gitlab.test.local"
# Cleanup
subprocess.run(["docker", "compose", "-f", "compose/test/docker-compose.yml", "down", "-v"])

def wait_for_gitlab(timeout=300):
"""Wait for GitLab to be ready."""
start = time.time()
while time.time() - start < timeout:

try:
response = requests.get("https://gitlab.test.local/-/health")
if response.status_code == 200:
return
except requests.exceptions.RequestException:
pass
sleep(5)
raise TimeoutError("GitLab did not become ready")

class TestE2EWorkflow:
"""End-to-end workflow tests."""
def test_complete_cicd_pipeline(self, autogit_instance):
"""Test complete CI/CD pipeline from push to deployment."""
# Arrange - Create project
project = create_test_project(autogit_instance)
# Act - Push code with .gitlab-ci.yml
push_test_code(project)
# Assert - Pipeline runs successfully
pipeline = wait_for_pipeline(project)
assert pipeline.status == "success"
# Assert - Runner was auto-provisioned
runners = get_active_runners()
assert len(runners) > 0
# Assert - Runner auto-deprovisioned after idle
sleep(70)
runners = get_active_runners()
assert len(runners) == 0
def test_multi_arch_build_pipeline(self, autogit_instance):
"""Test multi-architecture build pipeline."""
# Arrange
project = create_test_project(autogit_instance)
# Act - Push multi-arch build config
push_multiarch_config(project)
# Assert - Pipeline uses correct runners
pipeline = wait_for_pipeline(project)
jobs = pipeline.jobs
amd64_job = next(j for j in jobs if "amd64" in j.name)
arm64_job = next(j for j in jobs if "arm64" in j.name)
assert amd64_job.runner.tags == ["amd64"]
assert arm64_job.runner.tags == ["arm64"]
def test_gpu_accelerated_job(self, autogit_instance):
"""Test GPU-accelerated job scheduling."""
# Arrange
project = create_test_project(autogit_instance)
# Act - Push GPU job config
push_gpu_job_config(project)

# Assert - Job runs on GPU-enabled runner
pipeline = wait_for_pipeline(project)
gpu_job = next(j for j in pipeline.jobs if "gpu" in j.name)
assert "nvidia" in gpu_job.runner.tags or "amd" in gpu_job.runner.tags
assert gpu_job.status == "success"
def test_sso_authentication(self, autogit_instance):
"""Test SSO authentication flow."""
# Act - Attempt to access GitLab
response = requests.get(f"{autogit_instance}/projects", allow_redirects=False)
# Assert - Redirected to Authelia
assert response.status_code == 302
assert "authelia" in response.headers["Location"]
# Act - Login via Authelia
session = login_via_authelia("testuser", "testpass")
# Assert - Can access GitLab
response = session.get(f"{autogit_instance}/projects")
assert response.status_code == 200
```
## Test Coverage
### Measuring Coverage
```bash
# Run tests with coverage
pytest --cov=src --cov-report=html --cov-report=term
# View HTML report
open htmlcov/index.html
# Check coverage threshold
pytest --cov=src --cov-fail-under=80
```
### Coverage Configuration
```ini
# .coveragerc
[run]
source = src/
omit =
*/tests/*
*/venv/*
*/__pycache__/*
*/site-packages/*
[report]
exclude_lines =
pragma: no cover
def __repr__
raise AssertionError
raise NotImplementedError
if __name__ == .__main__.:

if TYPE_CHECKING:
@abstractmethod
```
### Coverage Goals
- **Overall**: 80%+ coverage
- **Critical paths**: 95%+ coverage (runner management, GPU detection)
- **New code**: 90%+ coverage (enforced in CI)
## Continuous Integration
### GitHub Actions Integration
```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
test:
runs-on: ubuntu-latest
strategy:
matrix:
python-version: ['3.11', '3.12']
steps:
- uses: actions/checkout@v4
- name: Set up Python
uses: actions/setup-python@v5
with:
python-version: ${{ matrix.python-version }}
- name: Install dependencies
run: |
pip install uv
uv sync
- name: Run unit tests
run: uv run pytest tests/unit/ --cov --cov-report=xml
- name: Upload coverage
uses: codecov/codecov-action@v3
with:
file: ./coverage.xml
- name: Run integration tests
run: uv run pytest tests/integration/
- name: Check coverage threshold
run: uv run pytest --cov --cov-fail-under=80
```
## Test Data Management
### Using Factories

```python
# tests/utils/factories.py
import factory
from autogit.models import Runner, Job

class RunnerFactory(factory.Factory):
"""Factory for creating test Runner instances."""
class Meta:
model = Runner
id = factory.Sequence(lambda n: f"runner-{n}")
architecture = "amd64"
status = "running"
gpu_type = None
tags = factory.LazyAttribute(lambda obj: [obj.architecture])

class JobFactory(factory.Factory):
"""Factory for creating test Job instances."""
class Meta:
model = Job
id = factory.Sequence(lambda n: n)
name = factory.Sequence(lambda n: f"job-{n}")
stage = "build"
architecture = "amd64"
requires_gpu = False

# Usage in tests
def test_runner_assignment():
runner = RunnerFactory()
job = JobFactory(architecture="amd64")
assigned = assign_job_to_runner(job, runner)
assert assigned is True
```
### Using Faker for Realistic Data
```python
from faker import Faker
fake = Faker()
def test_with_realistic_data():
"""Test with realistic fake data."""
config = {
"project_name": fake.company(),
"repo_url": fake.url(),
"owner_email": fake.email()
}
project = create_project(config)
assert project.name == config["project_name"]
```

## Performance Testing
### Load Testing
```python
import pytest
from locust import HttpUser, task, between

class GitLabUser(HttpUser):
"""Load test user for GitLab."""
wait_time = between(1, 5)
@task(3)
def browse_projects(self):
self.client.get("/projects")
@task(1)
def trigger_pipeline(self):
self.client.post("/projects/1/pipeline", json={
"ref": "main"
})

# Run with: locust -f tests/performance/test_load.py --host=https://gitlab.test.local
```
### Benchmarking
```python
def test_provision_performance(benchmark):
"""Benchmark runner provisioning speed."""
result = benchmark(manager.provision, "amd64")
assert result is not None

def test_gpu_detection_performance(benchmark):
"""Benchmark GPU detection speed."""
result = benchmark(gpu_detector.detect_all)
assert len(result) > 0
```
## Mocking Strategies
### Mocking Docker Client
```python
@pytest.fixture
def mock_docker():
"""Mock Docker client."""
with patch('docker.from_env') as mock:
client = Mock()
mock.return_value = client
# Configure mock behavior
client.containers.run.return_value.id = "test-container-id"
client.containers.list.return_value = []

yield client
```
### Mocking Kubernetes API
```python
@pytest.fixture
def mock_k8s_client():
"""Mock Kubernetes client."""
with patch('kubernetes.client.CoreV1Api') as mock:
api = Mock()
mock.return_value = api
# Configure mock behavior
api.create_namespaced_pod.return_value = Mock(
metadata=Mock(name="test-pod")
)
yield api
```
### Mocking External APIs
```python
@pytest.fixture
def mock_gitlab_api():
"""Mock GitLab API responses."""
with requests_mock.Mocker() as m:
# Mock project endpoint
m.get(
'https://gitlab.test.local/api/v4/projects/1',
json={'id': 1, 'name': 'test-project'}
)
# Mock pipeline endpoint
m.post(
'https://gitlab.test.local/api/v4/projects/1/pipeline',
json={'id': 123, 'status': 'pending'}
)
yield m
```
## Debugging Tests
### Using pytest Debugging
```bash
# Drop into debugger on failure
pytest --pdb
# Drop into debugger at start of test
pytest --trace
# Show local variables on failure
pytest --showlocals
# Run specific test with verbose output

pytest -vv tests/unit/test_runner_manager.py::TestRunnerManager::test_provision
```
### Logging in Tests
```python
import logging
def test_with_logging(caplog):
"""Test with log capture."""
with caplog.at_level(logging.DEBUG):
manager.provision("amd64")
# Assert log messages
assert "Provisioning runner" in caplog.text
assert any("amd64" in record.message for record in caplog.records)
```
### Test Markers
```python
# Mark slow tests
@pytest.mark.slow
def test_long_running_operation():
pass
# Mark GPU tests
@pytest.mark.gpu
@pytest.mark.skipif(not has_gpu(), reason="GPU not available")
def test_gpu_detection():
pass
# Mark integration tests
@pytest.mark.integration
def test_docker_integration():
pass
# Run specific markers
# pytest -m "not slow"

# Skip slow tests

# pytest -m gpu

# Only GPU tests

```
## Testing Checklist
Before submitting a PR, ensure:
- [ ] All tests pass locally
- [ ] New code has tests (90%+ coverage)
- [ ] Tests follow naming conventions
- [ ] Tests are documented
- [ ] Integration tests added for new components
- [ ] E2E tests added for new user workflows
- [ ] Performance tests added if applicable
- [ ] Tests run in CI/CD
- [ ] Coverage threshold met (80%+)
- [ ] No flaky tests
- [ ] Test documentation updated
## Common Testing Pitfalls

### 1. Flaky Tests
**Problem**: Tests that pass/fail randomly
**Solution**: Avoid timing dependencies, use proper mocking
```python
# Bad - timing dependent
def test_async_operation():
start_async_task()
time.sleep(1)

# Hope it's done

assert is_complete()
# Good - wait for condition
def test_async_operation():
start_async_task()
wait_until(lambda: is_complete(), timeout=5)
assert is_complete()
```
### 2. Test Interdependence
**Problem**: Tests that depend on execution order
**Solution**: Make each test independent
```python
# Bad - depends on previous test
def test_create_runner():
global runner_id
runner_id = manager.provision("amd64")
def test_delete_runner():
manager.deprovision(runner_id)

# Depends on previous test

# Good - independent tests
def test_create_and_delete_runner():
runner_id = manager.provision("amd64")
manager.deprovision(runner_id)
```
### 3. Over-Mocking
**Problem**: Mocking too much defeats the purpose of testing
**Solution**: Mock only external dependencies
```python
# Bad - mocking internal logic
@patch('autogit.runners.RunnerManager._validate_config')
def test_provision(mock_validate):
mock_validate.return_value = True
# Not testing real validation
# Good - testing real logic
def test_provision_with_invalid_config():
with pytest.raises(ConfigError):
RunnerManager({"invalid": "config"})
```
## Resources

- **pytest Documentation**: https://docs.pytest.org/
- **Testing Best Practices**: https://testdriven.io/blog/testing-best-practices/
- **Coverage.py**: https://coverage.readthedocs.io/
- **Factory Boy**: https://factoryboy.readthedocs.io/
## Next Steps
- Review [Coding Standards](standards.md)
- Set up [Development Environment](setup.md)
- Read [CI/CD Guide](ci-cd.md)
- Check [Common Tasks](common-tasks.md)
--**Documentation Version**: 1.0.0
**Last Updated**: YYYY-MM-DD
**Related Docs**: [Development Overview](README.md) | [Standards](standards.md) | [CI/CD](ci-cd.md)
```
