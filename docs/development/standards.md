# Coding Standards

This document defines the coding standards for AutoGit.

## Python Code Style

### PEP 8 Compliance

All Python code must follow [PEP 8](https://peps.python.org/pep-0008/).

### Black Formatting

Use Black for automatic formatting:

```bash
black src/ tests/
```

Configuration in `pyproject.toml`:

```toml
[tool.black]
line-length = 100
target-version = ['py311']
```

### Import Order

Use `isort` for consistent import ordering:

```python
# Standard library imports
import os
import sys
from typing import Optional, Protocol

# Third-party imports
import pytest
from pydantic import BaseModel

# Local application imports
from autogit.core import Runner
from autogit.utils import logger
```

### Type Hints

All public functions must have type hints:

```python
def provision_runner(architecture: str, gpu_type: Optional[str] = None) -> str:
    """Provision a new runner instance.

    Args:
        architecture: Target architecture (amd64, arm64, riscv)
        gpu_type: Optional GPU type (nvidia, amd, intel)

    Returns:
        Runner instance ID

    Raises:
        ProvisionError: If provisioning fails
    """
    ...
```

## Docstrings

Use Google-style docstrings:

```python
def complex_function(param1: str, param2: int) -> bool:
    """Short description of function.

    Longer description with more details about what this
    function does and why it exists.

    Args:
        param1: Description of param1
        param2: Description of param2

    Returns:
        Description of return value

    Raises:
        ValueError: When param2 is negative
        TypeError: When param1 is not a string

    Example:
        >>> complex_function("test", 42)
        True

    Note:
        Additional notes about edge cases or performance.

    See Also:
        related_function: For related functionality
    """
    ...
```

## SOLID Principles

### Single Responsibility Principle

Each class/function should have one reason to change:

```python
# Good - Single responsibility
class RunnerProvisioner:
    """Handles runner provisioning only."""

    def provision(self, config: RunnerConfig) -> Runner: ...


class RunnerMonitor:
    """Handles runner monitoring only."""

    def check_health(self, runner: Runner) -> bool: ...
```

### Open/Closed Principle

Extend behavior without modifying existing code:

```python
# Use Protocol for extensibility
class StorageBackend(Protocol):
    """Protocol for storage backends."""

    def store(self, key: str, value: bytes) -> None: ...

    def retrieve(self, key: str) -> bytes: ...


# Implementations can be added without modifying existing code
class S3Storage:
    def store(self, key: str, value: bytes) -> None: ...


class LocalStorage:
    def store(self, key: str, value: bytes) -> None: ...
```

### Dependency Inversion Principle

Depend on abstractions, not concretions:

```python
# Good - Depends on Protocol
class RunnerManager:
    def __init__(self, storage: StorageBackend):
        self.storage = storage

    def save_runner(self, runner: Runner) -> None:
        data = runner.serialize()
        self.storage.store(runner.id, data)
```

## Testing Standards

### Test Organization

```python
import pytest
from unittest.mock import Mock


class TestRunnerProvisioner:
    """Tests for RunnerProvisioner."""

    @pytest.fixture
    def provisioner(self):
        """Create provisioner instance."""
        return RunnerProvisioner()

    def test_provision_amd64_runner(self, provisioner):
        """Test provisioning amd64 runner."""
        runner = provisioner.provision("amd64")
        assert runner.architecture == "amd64"

    def test_provision_with_invalid_arch_raises(self, provisioner):
        """Test that invalid architecture raises error."""
        with pytest.raises(ValueError):
            provisioner.provision("invalid")
```

### Test Naming

- Test functions: `test_<what>_<condition>_<expected>`
- Test classes: `Test<ClassName>`
- Fixtures: Descriptive nouns

### Test Coverage

- Minimum 80% coverage required
- Focus on edge cases and error paths
- Mock external dependencies

## Error Handling

### Custom Exceptions

```python
class AutoGitError(Exception):
    """Base exception for AutoGit."""

    pass


class ProvisionError(AutoGitError):
    """Raised when runner provisioning fails."""

    pass


class GPUNotFoundError(AutoGitError):
    """Raised when requested GPU is not available."""

    pass
```

### Error Messages

```python
# Good - Descriptive error messages
raise ProvisionError(
    f"Failed to provision {architecture} runner: "
    f"insufficient resources (requested: {required}, available: {available})"
)

# Bad - Vague error messages
raise ProvisionError("Provisioning failed")
```

## Configuration

### Use Pydantic for Configuration

```python
from pydantic import BaseModel, Field, validator


class RunnerConfig(BaseModel):
    """Configuration for runner."""

    architecture: str = Field(..., description="Target architecture")
    max_runners: int = Field(10, ge=1, le=100)
    idle_timeout: int = Field(600, ge=60)

    @validator("architecture")
    def validate_architecture(cls, v):
        allowed = ["amd64", "arm64", "riscv"]
        if v not in allowed:
            raise ValueError(f"Architecture must be one of {allowed}")
        return v
```

## Logging

### Use Structured Logging

```python
import logging

logger = logging.getLogger(__name__)

# Good - Structured with context
logger.info(
    "Runner provisioned",
    extra={
        "runner_id": runner.id,
        "architecture": runner.architecture,
        "gpu_type": runner.gpu_type,
    },
)

# Bad - Unstructured
logger.info(f"Runner {runner.id} provisioned")
```

### Log Levels

- **DEBUG** - Detailed diagnostic information
- **INFO** - Confirmation that things are working
- **WARNING** - Something unexpected but handled
- **ERROR** - Error that prevented an operation
- **CRITICAL** - Serious error that may cause system failure

## Security

### No Hardcoded Secrets

```python
# Good - Use environment variables
import os

secret = os.getenv("API_SECRET")

# Bad - Hardcoded secret
secret = "my-secret-key-123"
```

### Input Validation

```python
# Always validate external input
def process_architecture(arch: str) -> str:
    allowed = ["amd64", "arm64", "riscv"]
    if arch not in allowed:
        raise ValueError(f"Invalid architecture: {arch}")
    return arch
```

## Documentation Standards

### Module Docstrings

```python
"""Runner provisioning module.

This module provides functionality for provisioning and managing
runner instances across multiple architectures.

See docs/runners/README.md for usage examples.
"""
```

### Inline Comments

```python
# Use comments sparingly - prefer self-documenting code
# Only comment WHY, not WHAT

# Good - Explains reasoning
# Use exponential backoff to avoid overwhelming the API
retry_delay = 2**attempt

# Bad - States the obvious
# Increment counter by 1
counter += 1
```

## File Organization

### Module Structure

```python
"""Module docstring."""

# Imports
import os
from typing import Optional

# Constants
MAX_RETRIES = 3
DEFAULT_TIMEOUT = 30

# Type definitions
RunnerID = str

# Classes
class Runner:
    ...

# Functions
def provision_runner(...) -> Runner:
    ...

# Entry point (if applicable)
if __name__ == "__main__":
    ...
```

## Performance

### Avoid Premature Optimization

Write clear code first, optimize if needed:

```python
# Good - Clear and maintainable
runners = [r for r in all_runners if r.is_idle()]

# Only optimize if profiling shows this is a bottleneck
```

### Use Appropriate Data Structures

```python
# Use sets for membership testing
active_ids = {r.id for r in runners}
if runner_id in active_ids:  # O(1)
    ...

# Use dicts for lookups
runners_by_id = {r.id: r for r in runners}
runner = runners_by_id.get(runner_id)  # O(1)
```

## Git Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add GPU detection for AMD GPUs
fix: correct runner idle timeout calculation
docs: update installation guide for Kubernetes
test: add integration tests for runner lifecycle
refactor: extract provisioning logic into separate module
chore: update dependencies
```

Include affected documentation:

```
feat: add GPU detection [docs: gpu/amd.md, api/gpu-detector.md]
```

## References

- [PEP 8](https://peps.python.org/pep-0008/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
