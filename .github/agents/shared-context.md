# AutoGit Shared Agent Context

This file contains shared context and requirements that all AutoGit AI agents must follow.

## Project Context

You are an AI agent working on **AutoGit**, an MIT-licensed self-hosted GitOps platform with dynamic
multi-architecture runner management. Your role is to assist with development, following the
project's architecture, principles, and constraints.

## 📋 Documentation Tracking Protocol

**CRITICAL**: Before making ANY changes that affect project behavior, architecture, or standards:

1. **Check Documentation Index** at `docs/INDEX.md` to find relevant documentation
1. **Update ALL affected documentation** in the same commit as code changes
1. **Update Documentation Index** if adding/removing documentation
1. **Create/Update ADRs** for architectural decisions at `docs/architecture/adr/`
1. **Notify in commit message** which docs were updated:
   `feat: add GPU detection [docs: gpu/nvidia.md, adr/003]`

### Documentation Update Checklist

When you make changes, check if these need updates:

- [ ] **README.md** - If changing core features or setup
- [ ] **docs/INDEX.md** - If adding/removing documentation
- [ ] **Component docs** - If modifying component behavior
- [ ] **Configuration docs** - If adding/changing config options
- [ ] **API docs** - If changing interfaces or APIs
- [ ] **ADRs** - If making architectural decisions
- [ ] **CHANGELOG.md** - For all changes in a release
- [ ] **Agent guidelines** - If changing development standards
- [ ] **Testing docs** - If adding new testing requirements
- [ ] **Security docs** - If adding security features/requirements

### Where to Find Documentation

Refer to `docs/INDEX.md` for the complete documentation map. Key locations:

```
docs/
├── INDEX.md                 # ⭐ START HERE - Complete documentation map
├── installation/            # Installation guides
├── configuration/           # Configuration references
├── architecture/            # Architecture and ADRs
│   └── adr/                # Architecture Decision Records
├── development/            # Development guides
├── runners/                # Runner management docs
├── gpu/                    # GPU support docs
├── security/               # Security guidelines
└── operations/             # Operations and monitoring
```

## Core Project Requirements

### Technical Stack

- **Languages**: Python 3.11+, Bash, YAML
- **Container Orchestration**: Docker Compose → Kubernetes/Helm
- **Infrastructure**: Debian 12.9, Ubuntu 22.04+
- **Testing**: pytest, codecov
- **CI/CD**: GitHub Actions
- **Tools**: UV (Python), Docker, Kubernetes, Helm, Terraform

### Architecture Principles

- **SRP**: Single Responsibility Principle - one purpose per module
- **OCP**: Open/Closed Principle - extensible without modification
- **LSP**: Liskov Substitution Principle - subtypes substitutable
- **ISP**: Interface Segregation Principle - small, specific interfaces
- **DIP**: Dependency Inversion Principle - depend on abstractions
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It
- **LoD**: Law of Demeter - minimal coupling
- **SoC**: Separation of Concerns

### Design Patterns

- **Composition over Inheritance** - prefer composition for all extensibility
- **PEP 8 Compliance** - follow Python style guide
- **Black Formatting** - use Black code formatter standards

## Core Components

### 1. GitLab CE (MIT License)

**Documentation**: `docs/configuration/gitlab.md`

- Self-hosted Git server
- Integrated CI/CD pipeline
- Container registry
- Package registry

### 2. Runner Management System

**Documentation**: `docs/runners/`, `docs/architecture/adr/002-fleeting-plugin.md`

- **Custom Fleeting Plugin** (to be developed)
  - Manages VM/container lifecycle
  - Implements fleeting API specification
  - Supports amd64, arm64, RISC-V (via QEMU)
  - GPU-aware scheduling (AMD, NVIDIA, Intel)
- **Runner Autoscaler**
  - Queue-based provisioning
  - Right-sizing logic
  - Idle resource cleanup

### 3. Multi-Architecture Support

**Documentation**: `docs/runners/multi-arch.md`

- **Native Architectures**: amd64, arm64
- **Emulated**: RISC-V via QEMU user-space emulation
- **Build Strategy**: docker buildx for multi-platform images
- **Runner Tags**: Architecture-specific job routing

### 4. GPU Detection and Allocation

**Documentation**: `docs/gpu/README.md`, `docs/gpu/nvidia.md`, `docs/gpu/amd.md`,
`docs/gpu/intel.md`

- **AMD GPUs**: ROCm driver detection (`/dev/dri/renderD*`)
- **NVIDIA GPUs**: CUDA toolkit detection (`nvidia-smi`)
- **Intel GPUs**: OneAPI detection (`/dev/dri/card*`)
- **Kubernetes Integration**: Device plugins and node selectors

### 5. Ingress and Load Balancing

**Documentation**: `docs/configuration/ingress.md`, `docs/architecture/adr/001-traefik-vs-nginx.md`

- **Traefik** (MIT License) - Primary choice due to NGINX retirement (EOL March 2026)
  - Automatic service discovery
  - Let's Encrypt integration
  - Dynamic configuration
  - Dashboard for monitoring

### 6. SSL/TLS Management

**Documentation**: `docs/configuration/ssl.md`

- **cert-manager** (Apache 2.0)
  - Automatic certificate issuance
  - Let's Encrypt ACME protocol
  - Automatic renewal
  - HTTP-01 and DNS-01 challenge support

### 7. SSO Authentication

**Documentation**: `docs/configuration/sso.md`, `docs/architecture/adr/004-sso-solution.md`

- **Authelia** (Apache 2.0) - Primary choice for lightweight deployment
  - OpenID Connect certified
  - Forward authentication with Traefik
  - MFA support
  - Session management

**Alternatives** (if Authelia doesn't meet needs):

- Authentik (MIT-compatible): More features, higher resource usage
- Keycloak (Apache 2.0): Enterprise-grade, heaviest resource usage

### 8. DNS Management

**Documentation**: `docs/configuration/dns.md`

- **CoreDNS** (Apache 2.0)
  - Conditional forwarding to gateway router
  - LAN-only access to AutoGit services
  - Dynamic configuration reload
  - Plugin-based architecture

### 9. Storage

**Documentation**: `docs/configuration/storage.md`

- **GitLab Components**:
  - Gitaly: Git repositories (StatefulSet)
  - PostgreSQL: Database
  - Redis: Cache and sessions
  - Registry: Container images
  - MinIO: Object storage (artifacts, LFS, uploads)
- **Kubernetes**: Dynamic PVs with `Retain` policy
- **Sizing Guidelines**:
  - Gitaly: 50GB minimum
  - PostgreSQL: 8GB minimum
  - Redis: 5GB minimum
  - MinIO: 10GB minimum

## License Compliance Requirements

**Documentation**: `LICENSES.md`, `docs/development/licensing.md`

### MIT License Compatibility

All components must be MIT or compatible licenses:

- ✅ MIT
- ✅ Apache 2.0
- ✅ BSD-3-Clause
- ✅ PostgreSQL License
- ⚠️ AGPL-3.0 (MinIO) - used as standalone service without modification

### License Audit Checklist

When adding dependencies:

1. Verify license compatibility with MIT
1. Document in `LICENSES.md`
1. Include attribution in `NOTICE` file
1. Check transitive dependencies
1. Avoid copyleft licenses (GPL, LGPL) unless as standalone services

**UPDATE**: `docs/development/licensing.md` when adding new dependencies

## Development Standards

**Documentation**: `docs/development/standards.md`

### Python Code Style

```python
"""Module docstring with description.

This module implements [functionality].

Documentation: docs/[relevant-doc].md
"""

from typing import Protocol, Optional
import logging

logger = logging.getLogger(__name__)


class RunnerManagerProtocol(Protocol):
    """Protocol defining runner manager interface.

    See docs/api/runner-manager.md for full API documentation.
    """

    def provision(self, architecture: str, gpu_type: Optional[str]) -> str:
        """Provision a new runner instance.

        Args:
            architecture: Target architecture (amd64, arm64, riscv)
            gpu_type: Optional GPU type (nvidia, amd, intel)

        Returns:
            Runner instance ID

        Raises:
            ProvisionError: If provisioning fails

        Documentation:
            - docs/runners/provisioning.md
            - docs/gpu/README.md
        """
        ...
```

### Configuration Standards

- Use **environment variables** for secrets
- Use **YAML** for configuration files
- Provide **sensible defaults**
- Document all configuration options
- Use **validation schemas** (Pydantic)

### Documentation Standards

**Documentation**: `docs/development/documentation.md`

- **README.md** in every directory
- **Docstrings** for all public functions/classes
- **Architecture Decision Records** (ADRs) for major decisions
- **API documentation** generated from code
- **Examples** for common use cases
- **Keep INDEX.md updated** when adding/removing docs

## Key Technical Decisions

**Documentation**: All decisions in `docs/architecture/adr/`

### ADR Index

- **ADR-001**: Why Traefik over NGINX
- **ADR-002**: Custom Fleeting Plugin Design
- **ADR-003**: Multi-Architecture Strategy
- **ADR-004**: SSO Solution Selection
- **ADR-005**: DNS Management Approach
- **ADR-006**: Storage Architecture

**When making architectural decisions**: Create new ADR in `docs/architecture/adr/XXX-title.md`

## Testing Requirements

**Documentation**: `docs/development/testing.md`

### Unit Tests

- All public functions and classes
- Edge cases and error conditions
- Mock external dependencies
- Aim for 80%+ coverage

### Integration Tests

- Component interactions
- Docker Compose deployment
- Kubernetes deployment
- Multi-architecture builds

### End-to-End Tests

- Full GitLab CI/CD pipeline
- Runner provisioning and deprovisioning
- GPU workload scheduling
- SSO authentication flow

## Security Requirements

**Documentation**: `docs/security/README.md`

### Code Security

- No hardcoded secrets
- Input validation on all external inputs
- Dependency vulnerability scanning
- Regular security updates

### Infrastructure Security

- Network policies for pod-to-pod communication
- TLS everywhere (including internal traffic)
- RBAC with least privilege
- Secrets management (Kubernetes Secrets or Sealed Secrets)
- Image scanning in CI/CD

### Operational Security

- Regular backups (automated)
- Audit logging
- Access controls
- Incident response procedures

**UPDATE**: `docs/security/` when implementing new security features

## Questions to Ask When Uncertain

1. **License Compatibility**: Is this component MIT-compatible? → Check
   `docs/development/licensing.md`
1. **Architecture Fit**: Does this align with SOLID principles? → Review `docs/architecture/`
1. **Security Impact**: What are the security implications? → Consult `docs/security/`
1. **Testing Strategy**: How will this be tested? → See `docs/development/testing.md`
1. **Documentation**: Is this change documented? → Check `docs/INDEX.md` for relevant docs
1. **Breaking Changes**: Will this break existing deployments? → Review `CHANGELOG.md`
1. **Resource Impact**: What's the memory/CPU footprint? → Document in component docs
1. **Scalability**: How does this scale? → Discuss in architecture docs
1. **Which docs need updates**: → Consult Documentation Update Checklist above

## Resources

### Official Documentation

- [GitLab Runner Docs](https://docs.gitlab.com/runner/)
- [Fleeting Plugin Spec](https://gitlab.com/gitlab-org/fleeting/fleeting)
- [Traefik Docs](https://doc.traefik.io/traefik/)
- [Authelia Docs](https://www.authelia.com/)
- [CoreDNS Docs](https://coredns.io/)
- [cert-manager Docs](https://cert-manager.io/)

### Community Resources

- GitLab Runner Issue Tracker
- Traefik Community Forum
- Kubernetes Slack
- CNCF Landscape

### Project-Specific

- [AutoGit Docs](docs/)
- [Architecture ADRs](docs/architecture/adr/)
- [Contributing Guide](CONTRIBUTING.md)
- **[Documentation Index](docs/INDEX.md)**
