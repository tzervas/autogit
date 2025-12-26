# Project Structure

This document explains the AutoGit project structure and organization.

## Repository Layout

```
autogit/
├── .github/                    # GitHub configuration
│   ├── workflows/             # CI/CD pipelines
│   │   ├── ci.yml            # Main CI pipeline
│   │   ├── release.yml       # Release automation
│   │   └── docs.yml          # Documentation validation
│   └── agents/               # AI agent configuration
│       └── agent.md          # Agent guidelines
│
├── src/                       # Source code
│   ├── fleeting-plugin/      # Custom autoscaling plugin
│   │   ├── core/            # Core plugin logic
│   │   ├── adapters/        # Docker/K8s adapters
│   │   ├── models/          # Data models
│   │   └── tests/           # Plugin tests
│   │
│   ├── gpu-detector/         # GPU detection service
│   │   ├── detectors/       # Vendor-specific detectors
│   │   ├── models/          # GPU models
│   │   └── tests/           # Detector tests
│   │
│   └── runner-manager/       # Runner lifecycle management
│       ├── core/            # Manager core logic
│       ├── api/             # REST API
│       └── tests/           # Manager tests
│
├── services/                  # Service implementations
│   ├── git-server/           # Git server service
│   │   ├── Dockerfile       # Container definition
│   │   ├── config/          # Service configuration
│   │   └── README.md        # Service documentation
│   │
│   └── runner-coordinator/   # Runner coordination service
│       ├── Dockerfile       # Container definition
│       ├── config/          # Service configuration
│       └── README.md        # Service documentation
│
├── docs/                      # Documentation
│   ├── INDEX.md              # Documentation index
│   ├── installation/         # Installation guides
│   ├── configuration/        # Configuration docs
│   ├── architecture/         # Architecture docs
│   │   └── adr/             # Architecture Decision Records
│   ├── development/          # Development guides
│   ├── runners/              # Runner documentation
│   ├── gpu/                  # GPU documentation
│   ├── security/             # Security guides
│   ├── operations/           # Operations guides
│   ├── api/                  # API documentation
│   ├── cli/                  # CLI reference
│   ├── tutorials/            # Tutorials
│   └── troubleshooting/      # Troubleshooting guides
│
├── tests/                     # Integration and E2E tests
│   ├── integration/          # Integration tests
│   ├── e2e/                  # End-to-end tests
│   └── fixtures/             # Test fixtures
│
├── config/                    # Configuration files
│   ├── config.yml            # Main configuration
│   ├── runners/              # Runner configurations
│   ├── gpu/                  # GPU configurations
│   └── examples/             # Example configurations
│
├── scripts/                   # Utility scripts
│   ├── setup.sh              # Initial setup
│   ├── setup-dev.sh          # Development setup
│   ├── verify-doc-index.sh   # Documentation validation
│   └── deploy.sh             # Deployment script
│
├── charts/                    # Helm charts
│   └── autogit/              # Main chart
│       ├── Chart.yaml        # Chart metadata
│       ├── values.yaml       # Default values
│       └── templates/        # Kubernetes templates
│
├── compose/                   # Docker Compose files
│   ├── dev/                  # Development compose
│   │   └── docker-compose.yml
│   └── prod/                 # Production compose
│       └── docker-compose.yml
│
├── examples/                  # Usage examples
│   ├── runners/              # Runner examples
│   ├── gpu/                  # GPU examples
│   └── pipelines/            # CI/CD pipeline examples
│
├── docker-compose.yml         # Main Docker Compose
├── .env.example               # Environment template
├── .gitignore                # Git ignore rules
├── .pre-commit-config.yaml   # Pre-commit hooks
├── pyproject.toml            # Python project config
├── uv.lock                   # Dependency lock file
├── Makefile                  # Build automation
├── README.md                 # Project README
├── LICENSE                   # MIT License
├── CONTRIBUTING.md           # Contribution guide
├── CHANGELOG.md              # Version history
├── ROADMAP.md                # Future plans
└── LICENSES.md               # Dependency licenses
```

## Source Code Organization

### Python Modules

Each Python module follows this structure:

```
module/
├── __init__.py               # Module exports
├── __main__.py               # CLI entry point (if applicable)
├── README.md                 # Module documentation
├── core/                     # Core business logic
│   ├── __init__.py
│   ├── manager.py           # Main manager class
│   └── provisioner.py       # Provisioning logic
├── adapters/                 # External integrations
│   ├── __init__.py
│   ├── docker.py            # Docker adapter
│   └── kubernetes.py        # Kubernetes adapter
├── models/                   # Data models
│   ├── __init__.py
│   ├── config.py            # Configuration models
│   └── instance.py          # Instance models
├── utils/                    # Utility functions
│   ├── __init__.py
│   ├── logging.py           # Logging utilities
│   └── validation.py        # Validation utilities
└── tests/                    # Unit tests
    ├── __init__.py
    ├── test_manager.py
    ├── test_provisioner.py
    └── fixtures/             # Test fixtures
        └── __init__.py
```

### Service Organization

Each service is a standalone component:

```
service-name/
├── Dockerfile                # Container definition
├── README.md                 # Service documentation
├── requirements.txt          # Dependencies
├── config/                   # Configuration
│   ├── default.yml          # Default config
│   └── production.yml       # Production config
├── src/                      # Service source code
│   ├── __init__.py
│   ├── main.py              # Entry point
│   ├── api/                 # API endpoints
│   ├── handlers/            # Request handlers
│   └── models/              # Data models
└── tests/                    # Service tests
    └── test_api.py
```

## Configuration Organization

### Environment Variables

Environment variables in `.env`:

```bash
# Service Configuration
SERVICE_NAME=autogit
SERVICE_PORT=8080

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=autogit
DB_USER=autogit
DB_PASSWORD=<from-secrets>

# Feature Flags
ENABLE_GPU_SUPPORT=true
ENABLE_MULTI_ARCH=true
```

### YAML Configuration

Structured configuration in `config/config.yml`:

```yaml
runner:
  default_architecture: amd64
  max_runners: 50
  idle_timeout: 600

gpu:
  detection_interval: 60
  vendors:
    - nvidia
    - amd
    - intel

monitoring:
  enabled: true
  interval: 30
```

## Test Organization

### Test Structure

```
tests/
├── unit/                     # Unit tests
│   ├── test_provisioner.py
│   └── test_gpu_detector.py
├── integration/              # Integration tests
│   ├── test_runner_lifecycle.py
│   └── test_gpu_scheduling.py
├── e2e/                      # End-to-end tests
│   ├── test_full_pipeline.py
│   └── test_multi_arch.py
├── fixtures/                 # Shared test fixtures
│   ├── __init__.py
│   ├── runners.py           # Runner fixtures
│   └── configs.py           # Config fixtures
└── conftest.py               # Pytest configuration
```

### Test Naming

- **Unit tests**: `test_<function>_<condition>_<expected>`
- **Integration tests**: `test_<feature>_<scenario>`
- **E2E tests**: `test_<user_story>`

## Documentation Organization

### Documentation Hierarchy

1. **Root README.md** - Project overview and quick start
1. **docs/INDEX.md** - Complete documentation map
1. **Category READMEs** - Overview of each category
1. **Specific docs** - Detailed documentation

### Cross-References

Use relative links to connect related documentation:

```markdown
See [Runner Configuration](../runners/configuration.md) for details.
Refer to [ADR-001](../architecture/adr/001-traefik-vs-nginx.md).
```

## File Naming Conventions

### Python Files

- **Modules**: `lowercase_with_underscores.py`
- **Classes**: Match filename: `runner_manager.py` → `RunnerManager`
- **Tests**: `test_<module_name>.py`

### Configuration Files

- **YAML**: `kebab-case.yml` or `snake_case.yml`
- **Environment**: `.env`, `.env.example`
- **Docker**: `Dockerfile`, `docker-compose.yml`

### Documentation Files

- **Markdown**: `kebab-case.md` or `snake_case.md`
- **Index files**: `README.md` or `INDEX.md`
- **ADRs**: `NNN-title-in-kebab-case.md`

## Directory Naming

- Use `kebab-case` for directory names
- Use descriptive names: `gpu-detector` not `gpudet`
- Group related files in directories

## Import Conventions

### Absolute Imports

Use absolute imports from project root:

```python
from autogit.core.manager import RunnerManager
from autogit.models.config import RunnerConfig
from autogit.utils.logging import get_logger
```

### Relative Imports

Use relative imports within a module:

```python
from .models import RunnerConfig
from ..utils import get_logger
```

## Build Artifacts

Build artifacts are not committed to Git:

- `__pycache__/` - Python bytecode
- `.pytest_cache/` - Pytest cache
- `.mypy_cache/` - Mypy cache
- `*.egg-info/` - Python package metadata
- `dist/` - Distribution packages
- `.coverage` - Coverage data
- `htmlcov/` - Coverage HTML reports

See `.gitignore` for complete list.

## Working with the Structure

### Adding a New Component

1. Create directory in appropriate location
1. Add `README.md` with component overview
1. Implement component following module structure
1. Add tests in parallel structure
1. Update `docs/INDEX.md` with new docs
1. Create ADR if architectural change

### Adding Documentation

1. Determine category (installation, development, etc.)
1. Create markdown file in appropriate directory
1. Follow documentation templates
1. Update `docs/INDEX.md`
1. Add cross-references to related docs

### Refactoring

When refactoring:

- Maintain existing structure where possible
- Update imports if moving files
- Update documentation references
- Update tests
- Create ADR for major structural changes

## References

- [Development Guide](README.md)
- [Coding Standards](standards.md)
- [Testing Guide](testing.md)
- [Documentation Guidelines](documentation.md)
