# AutoGit: Self-Hosted GitOps Platform

# Architecture Specification v1.0

# ═══════════════════════════════════════════════════════════════════════════════

## Vision

One-touch deployment of a complete self-hosted GitOps platform:

- Self-hosted Git (GitLab CE) with full-depth mirroring
- Automated lifecycle-managed compute runners (CPU + GPU)
- Local and remote GPU support for inference/render workloads
- Dynamic, idempotent, self-correcting, adaptive, self-healing

## Target Environment

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HOMELAB NETWORK                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │   kang (server)  │  │  Desktop 1       │  │  Desktop 2       │         │
│  │  192.168.1.170   │  │  RTX 3090 Ti     │  │  RTX 5080        │         │
│  │                  │  │  (inference)     │  │  (render/train)  │         │
│  │  ┌────────────┐  │  │                  │  │                  │         │
│  │  │ GitLab CE  │  │  │  ┌────────────┐  │  │  ┌────────────┐  │         │
│  │  │ (autogit)  │  │  │  │ GPU Runner │  │  │  │ GPU Runner │  │         │
│  │  └────────────┘  │  │  └────────────┘  │  │  └────────────┘  │         │
│  │  ┌────────────┐  │  └──────────────────┘  └──────────────────┘         │
│  │  │ CPU Runner │  │                                                      │
│  │  └────────────┘  │                                                      │
│  └──────────────────┘                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. `autogit` - Main Package

```
autogit/
├── __init__.py
├── cli.py                    # Typer-based CLI
├── config/
│   ├── __init__.py
│   ├── loader.py            # YAML/env config loading
│   ├── schema.py            # Pydantic models for config validation
│   └── defaults.py          # Sensible defaults
├── core/
│   ├── __init__.py
│   ├── state.py             # State management (idempotent operations)
│   ├── health.py            # Health check framework
│   └── reconcile.py         # Self-healing reconciliation loop
├── gitlab/
│   ├── __init__.py
│   ├── client.py            # GitLab API client (existing: tools/gitlab_client.py)
│   ├── bootstrap.py         # User/token setup
│   ├── mirror.py            # Repository mirroring (existing: setup-mirroring.py)
│   └── deploy.py            # Container deployment
├── runners/
│   ├── __init__.py
│   ├── manager.py           # Runner lifecycle management
│   ├── cpu.py               # CPU runner configuration
│   ├── gpu.py               # GPU runner configuration (NVIDIA)
│   └── discovery.py         # Auto-discover available runners on LAN
├── compute/
│   ├── __init__.py
│   ├── scheduler.py         # Job scheduling across runners
│   ├── inference.py         # Inference workload management
│   └── render.py            # Render workload management
└── utils/
    ├── __init__.py
    ├── docker.py            # Docker/compose helpers
    ├── ssh.py               # SSH remote execution
    └── logging.py           # Structured logging
```

### 2. Configuration Schema

```yaml
# autogit.yml
version: "1.0"

gitlab:
  hostname: gitlab.vectorweight.com
  external_url: http://gitlab.vectorweight.com
  ports:
    http: 8080
    https: 8443
    ssh: 2222
  resources:
    preset: homelab  # minimal | homelab | team | beast
    # Or custom:
    # cpu: 6
    # memory: 6G

mirroring:
  enabled: true
  sources:
    github:
      username: tzervas
      token_env: GITHUB_PAT_MIRROR
    gitlab:
      username: vector_weight
      token_env: GITLAB_PAT_MIRROR
  schedule: "0 */6 * * *"  # Every 6 hours

runners:
  cpu:
    - name: homelab-cpu
      host: 192.168.1.170
      executor: docker
      concurrent: 4
  gpu:
    - name: desktop-3090ti
      host: 192.168.1.X  # Auto-discover or specify
      executor: docker
      gpu: nvidia
      capabilities: [inference, render]
    - name: desktop-5080
      host: 192.168.1.Y
      executor: docker
      gpu: nvidia
      capabilities: [inference, render, train]

health:
  check_interval: 60
  reconcile_interval: 300
  self_heal: true
  notify:
    - type: log
    # - type: webhook
    #   url: https://...
```

### 3. State Machine

```
┌─────────────┐     install      ┌─────────────┐
│   ABSENT    │ ───────────────► │  DEPLOYING  │
└─────────────┘                  └──────┬──────┘
       ▲                                │
       │ uninstall                      │ success
       │                                ▼
┌──────┴──────┐     reconcile    ┌─────────────┐
│   FAILED    │ ◄─────────────── │   HEALTHY   │
└─────────────┘                  └──────┬──────┘
       │                                │
       │ self_heal                      │ degraded
       ▼                                ▼
┌─────────────┐                  ┌─────────────┐
│  REPAIRING  │ ───────────────► │  DEGRADED   │
└─────────────┘      fixed       └─────────────┘
```

### 4. CLI Interface

```bash
# Installation
autogit install                    # Full install with defaults
autogit install --preset beast     # BEAST MODE
autogit install --config custom.yml

# Status
autogit status                     # Overall health
autogit status gitlab              # GitLab health
autogit status runners             # Runner health

# Mirroring
autogit mirror sync                # Sync all mirrors now
autogit mirror list                # List configured mirrors
autogit mirror add github/repo     # Add specific repo

# Runners
autogit runner list                # List all runners
autogit runner discover            # Scan LAN for GPU hosts
autogit runner register <host>     # Register new runner
autogit runner health              # Runner health check

# GPU Compute
autogit compute list               # List available GPUs
autogit compute run <job>          # Submit compute job
autogit compute status <job_id>    # Job status

# Maintenance
autogit reconcile                  # Force reconciliation
autogit backup                     # Backup GitLab data
autogit restore <backup>           # Restore from backup
autogit logs [component]           # View logs
```

## Implementation Phases

### Phase 1: Shell Foundation (CURRENT)

- [x] GitLab deployment (docker-compose)
- [x] Port conflict fix
- [x] Resource right-sizing
- [x] User bootstrap script
- [ ] Credential capture
- [ ] Mirroring setup

### Phase 2: Python Consolidation

- [ ] Port existing Python scripts to unified package
- [ ] Pydantic config schema
- [ ] Typer CLI scaffolding
- [ ] GitLab client cleanup

### Phase 3: Runner Management

- [ ] CPU runner auto-registration
- [ ] GPU runner discovery (NVIDIA)
- [ ] Runner health monitoring
- [ ] Dynamic scaling

### Phase 4: Self-Healing

- [ ] State machine implementation
- [ ] Reconciliation loop
- [ ] Failure detection
- [ ] Auto-repair actions

### Phase 5: GPU Compute

- [ ] NVIDIA container toolkit integration
- [ ] Inference job scheduling
- [ ] Render workload management
- [ ] Multi-GPU coordination

## Threat Model

| Risk                    | Impact                 | Mitigation                          |
| ----------------------- | ---------------------- | ----------------------------------- |
| Credentials leak        | Full system compromise | File perms 600, env vars, no logs   |
| Runner compromise       | Lateral movement       | Network isolation, limited scopes   |
| GitLab corruption       | Data loss              | Automated backups, BTRFS snapshots  |
| GPU resource exhaustion | Workload starvation    | Resource quotas, scheduling         |
| Network partition       | Split brain            | Health checks, graceful degradation |
| Self-heal loop          | System thrashing       | Backoff, human intervention flag    |

## Dependencies

```toml
[project]
name = "autogit"
version = "0.3.0"
requires-python = ">=3.12"

dependencies = [
    "typer>=0.12",          # CLI framework
    "pydantic>=2.0",        # Config validation
    "httpx>=0.27",          # Async HTTP client
    "pyyaml>=6.0",          # YAML config
    "python-dotenv>=1.0",   # Env file loading
    "rich>=13.0",           # Pretty terminal output
    "structlog>=24.0",      # Structured logging
]

[project.optional-dependencies]
gpu = [
    "pynvml>=11.0",         # NVIDIA GPU monitoring
]
```

## File Mapping: Shell → Python

| Shell Script                  | Python Module               | Status  |
| ----------------------------- | --------------------------- | ------- |
| `deploy-clean.sh`             | `autogit.gitlab.deploy`     | Planned |
| `bootstrap-gitlab-users.sh`   | `autogit.gitlab.bootstrap`  | Planned |
| `setup-mirroring.py`          | `autogit.gitlab.mirror`     | Exists  |
| `check-status.sh`             | `autogit.core.health`       | Planned |
| `diagnose.sh`                 | `autogit.utils.diagnostics` | Planned |
| `tools/gitlab_client.py`      | `autogit.gitlab.client`     | Exists  |
| `scripts/register-runners.sh` | `autogit.runners.manager`   | Planned |

## Next Steps

1. **Immediate**: Run bootstrap, capture creds, verify mirroring
1. **This week**: Document all working shell scripts
1. **Next sprint**: Create `autogit` Python package scaffold
1. **Following**: Port scripts incrementally, test each
