# Architecture Overview

This document provides a high-level overview of AutoGit's architecture.

## System Architecture

AutoGit is a self-hosted GitOps platform built on a modular architecture with the following key components:

### Multi-Architecture Support

**Current Status (MVP)**: AMD64 Native Only
**Planned**: ARM64 Native + QEMU, RISC-V QEMU

AutoGit supports multiple CPU architectures:
- **AMD64 (x86_64)**: Native support (MVP focus, testing active)
- **ARM64 (aarch64)**: Native support (Phase 2) + QEMU emulation fallback
- **RISC-V**: QEMU emulation only (future/experimental)

See [Multi-Architecture Strategy](../../MULTI_ARCH_STRATEGY.md) for complete details.

### Core Components

1. **Git Server** - Version control and repository management
2. **Runner Coordinator** - Dynamic runner lifecycle management
3. **GPU Detector** - GPU discovery and allocation
4. **Fleeting Plugin** - Custom autoscaling implementation

### Infrastructure Components

1. **Traefik** - Ingress controller and reverse proxy
2. **Authelia** - Centralized SSO and authentication
3. **CoreDNS** - Internal DNS management
4. **cert-manager** - Automated TLS certificate management

### Data Layer

1. **PostgreSQL** - Primary relational database
2. **Redis** - Caching and session storage
3. **MinIO** - Object storage for artifacts

## Architectural Principles

AutoGit follows SOLID principles and clean architecture:

- **Single Responsibility** - Each component has one clear purpose
- **Open/Closed** - Extensible via plugins without modification
- **Liskov Substitution** - Interface-based design
- **Interface Segregation** - Small, focused interfaces
- **Dependency Inversion** - Depend on abstractions

See [Design Principles](design-principles.md) for details.

## Component Interactions

```
User Request
    ↓
Traefik (Ingress)
    ↓
Authelia (Auth) ← → GitLab/Git Server
    ↓
Runner Coordinator
    ↓
Runner Manager → GPU Detector
    ↓
Docker/K8s (Runtime)
```

See [Component Diagram](components.md) for detailed interactions.

## Deployment Architecture

### Docker Compose (Development)
- Single-host deployment
- All services in one compose file
- Easy local development

### Kubernetes (Production)
- Multi-node cluster
- High availability
- Horizontal scaling
- Resource isolation

See [Deployment Models](deployment-models.md) for details.

## Multi-Architecture Support

AutoGit runs on:
- **amd64** - x86_64 (Intel/AMD)
- **arm64** - ARM 64-bit (Apple Silicon, AWS Graviton)
- **RISC-V** - Via QEMU emulation

See [Multi-Architecture Strategy](multi-architecture.md) for implementation.

## Scaling Strategy

### Horizontal Scaling
- Multiple runner instances
- Database read replicas
- Redis clustering

### Vertical Scaling
- Resource limits per component
- GPU allocation optimization

See [Scaling Guide](scaling.md) for details.

## High Availability

For production deployments:
- Multiple replicas per service
- Load balancing
- Health checks and auto-recovery
- Data replication

See [High Availability](high-availability.md) for configuration.

## Security Architecture

Security is built into every layer:
- TLS everywhere (internal and external)
- Network policies (pod-to-pod isolation)
- RBAC (least privilege access)
- Secrets management (no hardcoded secrets)

See [Security Guide](../security/README.md) for details.

## Architecture Decision Records

All major architectural decisions are documented as ADRs.

See [ADR Index](adr/README.md) for all decisions.

## Technology Stack

- **Languages**: Python 3.11+, Bash, YAML
- **Container Runtime**: Docker 24.0+
- **Orchestration**: Kubernetes 1.28+
- **Package Management**: Helm 3.12+, UV (Python)
- **Testing**: pytest, codecov
- **CI/CD**: GitHub Actions

## Reference Documentation

- [Component Documentation](components.md)
- [Design Principles](design-principles.md)
- [Deployment Models](deployment-models.md)
- [Scaling Strategy](scaling.md)
- [High Availability](high-availability.md)
- [ADR Index](adr/README.md)
