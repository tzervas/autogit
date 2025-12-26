# AutoGit Copilot Instructions

## Project Overview

AutoGit is a self-hosted GitOps platform with dynamic multi-architecture runner management. It
orchestrates GitLab CE with a custom Runner Coordinator service that automatically provisions
Docker-based GitLab runners based on job demand.

## Architecture

- **GitLab CE**: Self-hosted Git server (port 3000, SSH 2222) with CI/CD pipelines
- **Runner Coordinator**: FastAPI service (port 8080) managing runner lifecycle
- **Database**: SQLite for runner state (`runner_coordinator.db`)
- **Orchestration**: Docker Compose (production-ready) → Kubernetes (planned)

## Core Components

- `services/git-server/`: GitLab CE container with custom build
- `services/runner-coordinator/app/`: Python FastAPI application with runner management logic
- `docker-compose.yml`: Service orchestration with resource limits and health checks
- `scripts/`: Bash utilities for deployment, monitoring, and Git operations

## Key Workflows

### Development Setup

```bash
git clone https://github.com/tzervas/autogit.git
cd autogit
cp .env.example .env  # Configure environment variables
docker compose up -d  # Start services
```

### Runner Management

- Monitors GitLab job queue every 10 seconds
- Automatically provisions Docker containers as runners
- Supports AMD64 (current), ARM64/RISC-V (planned)
- GPU-aware scheduling (AMD/NVIDIA/Intel planned)

### Testing

```bash
cd services/runner-coordinator
python -m pytest ../../tests/ -v
```

## Code Patterns

### Python Standards

- **Type hints**: Use `from __future__ import annotations`
- **Logging**: `logger = logging.getLogger(__name__)`
- **Docstrings**: Comprehensive with Args/Returns/Raises sections
- **Protocols**: Define interfaces with `Protocol` classes
- **Error handling**: Custom exceptions with descriptive messages

### FastAPI Patterns

```python
@app.post("/runners/register")
async def register_runner(request: RunnerRegistrationRequest):
    # Validate input with Pydantic models
    # Use dependency injection for database
    # Return structured responses
```

### Docker Integration

- Use `docker.DockerClient()` for container management
- Mount Docker socket: `-v /var/run/docker.sock:/var/run/docker.sock`
- Resource limits: `cpu_limit=4.0, mem_limit="6g"`
- Network management: Custom bridge networks for service isolation

## Project Conventions

### Documentation Protocol

**CRITICAL**: Update documentation with every code change

- Reference `docs/INDEX.md` for documentation map
- Update component docs when behavior changes
- Create ADRs for architectural decisions in `docs/architecture/adr/`
- Commit message format: `feat: add feature [docs: updated-docs.md, adr/003]`

### Multiagent Development

- Use specialized agents from `.github/agents/` for different tasks
- Follow shared context in `.github/agents/shared-context.md`
- Threat model every change: sensitive data, failure modes, blast radius, mitigations

### License Compliance

- **MIT-compatible only**: MIT, Apache 2.0, BSD-3-Clause
- Document licenses in `LICENSES.md`
- Avoid copyleft licenses (GPL/LGPL) except as standalone services

### Branch Strategy

- `main`: Production releases
- `dev`: Development integration
- `feature/*`: Feature branches with automatic PR validation
- Automated merging with status checks

## Integration Points

### GitLab API

- REST API for project/job monitoring
- Webhook endpoints for job notifications
- Runner registration tokens for authentication
- Instance-wide runner management

### Docker Engine

- Container lifecycle management
- Network creation and attachment
- Volume mounting for persistent data
- GPU device passthrough (planned)

### External Services

- **Authelia**: SSO authentication (Apache 2.0)
- **Traefik**: Ingress/load balancing (MIT)
- **cert-manager**: SSL/TLS certificates (Apache 2.0)
- **CoreDNS**: DNS management (Apache 2.0)

## Common Patterns

### Environment Configuration

```python
GITLAB_URL = os.getenv("GITLAB_URL", "http://autogit-git-server:3000")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN", "")
COOLDOWN_MINUTES = int(os.getenv("RUNNER_COOLDOWN_MINUTES", "5"))
```

### Database Operations

```python
# Use SQLAlchemy ORM with session management
db = SessionLocal()
try:
    runners = db.query(Runner).filter(Runner.status == "idle").all()
    # ... operations ...
    db.commit()
finally:
    db.close()
```

### Async Lifecycle Management

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup tasks
    manager_task = asyncio.create_task(lifecycle_manager())
    yield
    # Shutdown tasks
    manager_task.cancel()
```

## Key Files

- `services/runner-coordinator/app/main.py`: FastAPI application with REST endpoints
- `services/runner-coordinator/app/runner_manager.py`: Core runner lifecycle logic
- `services/runner-coordinator/app/models.py`: SQLAlchemy database models
- `docker-compose.yml`: Service definitions and resource allocation
- `docs/INDEX.md`: Complete documentation map
- `.github/agents/shared-context.md`: Project standards and requirements</content>
  <parameter name="filePath">.github/copilot-instructions.md
