# AutoGit

**Self-Hosted GitOps Platform with Dynamic Multi-Architecture Runner Management**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)]()
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)]()

## Overview

AutoGit is a fully self-hosted GitOps platform that automatically manages and scales GitLab runners across multiple architectures (amd64, arm64, RISC-V) with GPU-aware scheduling (AMD, NVIDIA, Intel). Built with security, lightweight performance, and ease of deployment in mind.

> 🎯 **v0.2.0 Milestone**: As of December 24, 2025, all CI/CD for this project runs on a fully self-hosted Homeland instance with automated, lifecycle-managed runners. While some manual tasks remain, this release proves the concept and provides a functioning foundation for continued refinement toward the 1.0.0 release.

### Key Features

- 🚀 **Dynamic Runner Autoscaling** - Automatically provisions right-sized runners based on job queue
- 🏗️ **Multi-Architecture Support** - AMD64 native (MVP), ARM64 native + QEMU emulation (planned), RISC-V QEMU (future)
- 🎮 **GPU-Aware Scheduling** - Intelligent allocation of AMD, NVIDIA, and Intel GPUs
- 🔐 **Centralized SSO** - Unified authentication with Authelia
- 🔒 **Automated SSL/TLS** - Let's Encrypt integration via cert-manager
- 🌐 **Self-Hosted DNS** - LAN-isolated access with CoreDNS
- 📦 **Flexible Deployment** - Scale from Docker Compose to Kubernetes/Helm
- ⚖️ **MIT Licensed** - Using only compatible FOSS components

**Architecture Focus**:
- **MVP**: AMD64 native only (current testing)
- **Phase 2**: ARM64 native support + QEMU fallback (post-deployment)
- **Phase 3**: RISC-V QEMU emulation (future)

## Architecture

```
┌─────────────────────────────────────────────┐
│         Docker Compose Orchestration         │
├──────────────────┬──────────────────────────┤
│   Git Server     │   Runner Coordinator     │
│   Port: 3000     │   Port: 8080             │
│   SSH: 2222      │   Manages: Runners       │
└──────────────────┴──────────────────────────┘
```

## Quick Start

> ⚠️ **Important**: Please review [DEPLOYMENT_READINESS.md](DEPLOYMENT_READINESS.md) before deploying to understand what features are production-ready vs. experimental.

### Prerequisites

- Docker 24.0+ or Kubernetes 1.28+
- Debian 12+ or Ubuntu 22.04+ (host OS)
- Minimum 8GB RAM, 50GB storage
- **Architecture**: AMD64 (MVP) - ✅ Production Ready
- **ARM64/RISC-V**: Planned, not yet implemented
- Optional: GPU for accelerated workloads (⚠️ Not yet implemented)

### Docker Compose (Development) - ✅ Validated & Production-Ready

```bash
git clone https://github.com/tzervas/autogit.git
cd autogit
cp .env.example .env
# Edit .env with your configuration
docker compose up -d
```

### Kubernetes/Helm (Production) - ⚠️ Planned, Not Yet Implemented

```bash
# Kubernetes deployment is planned for future releases
# Currently, use Docker Compose for all deployments
# See DEPLOYMENT_READINESS.md for current status
```

See [Installation Guide](docs/installation/README.md) and [DEPLOYMENT_READINESS.md](DEPLOYMENT_READINESS.md) for detailed instructions and current feature status.

## Project Structure

```
autogit/
├── docker-compose.yml          # Service orchestration
├── .env.example                # Environment template
├── services/                   # Service implementations
│   ├── git-server/            # Git server service
│   └── runner-coordinator/    # Runner management service
├── config/                     # Configuration files
├── scripts/                    # Utility scripts
│   └── setup.sh               # Initial setup
└── docs/                       # Documentation
```

## Services

### Git Server
- **Purpose**: Version control system
- **Ports**: 3000 (HTTP), 2222 (SSH)
- **Features**: Repository management, SSH access

### Runner Coordinator
- **Purpose**: Manage automated runners
- **Port**: 8080
- **Features**: Runner lifecycle, GPU/compute coordination

## Documentation

Complete documentation available at [docs/INDEX.md](docs/INDEX.md).

### Quick Links

- [Installation Guide](docs/installation/README.md) - Get started with AutoGit
- [Configuration Guide](docs/configuration/README.md) - Configure your deployment
- [Architecture Overview](docs/architecture/README.md) - Understand the system
- [Development Guide](docs/development/README.md) - Contributing to AutoGit
- [Runner Management](docs/runners/README.md) - Dynamic runner autoscaling
- [GPU Support](docs/gpu/README.md) - GPU-aware scheduling
- [Security Guide](docs/security/README.md) - Security best practices
- [Operations Guide](docs/operations/README.md) - Day-to-day operations
- [API Documentation](docs/api/README.md) - Programmatic access
- [Troubleshooting](docs/troubleshooting/README.md) - Problem solving

## Development

We welcome contributions! See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone repository
git clone https://github.com/tzervas/autogit.git
cd autogit

# Run setup script
./scripts/setup.sh

# Start development environment
docker compose -f compose/dev/docker-compose.yml up -d
```

See [Development Setup](docs/development/setup.md) for detailed instructions.

### Project Structure

- `src/` - Source code for core components
- `services/` - Service implementations
- `docs/` - Documentation
- `config/` - Configuration files
- `charts/` - Helm charts for Kubernetes
- `scripts/` - Utility scripts

See [Project Structure](docs/development/project-structure.md) for details.

## Community

- **Issues**: [GitHub Issues](https://github.com/tzervas/autogit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/tzervas/autogit/discussions)
- **Contributing**: [Contributing Guide](docs/CONTRIBUTING.md)

## License

MIT License - see [LICENSE](LICENSE) file for details.

All dependencies are MIT-compatible. See [LICENSES.md](LICENSES.md) for dependency licenses.
