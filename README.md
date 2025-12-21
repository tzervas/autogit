# AutoGit

**Self-Hosted GitOps Platform with Dynamic Multi-Architecture Runner Management**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)]()
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)]()

## Overview

AutoGit is a fully self-hosted GitOps platform that automatically manages and scales GitLab runners across multiple architectures (amd64, arm64, RISC-V) with GPU-aware scheduling (AMD, NVIDIA, Intel). Built with security, lightweight performance, and ease of deployment in mind.

### Key Features

- 🚀 **Dynamic Runner Autoscaling** - Automatically provisions right-sized runners based on job queue
- 🏗️ **Multi-Architecture Support** - Native amd64/arm64, QEMU emulation for RISC-V
- 🎮 **GPU-Aware Scheduling** - Intelligent allocation of AMD, NVIDIA, and Intel GPUs
- 🔐 **Centralized SSO** - Unified authentication with Authelia
- 🔒 **Automated SSL/TLS** - Let's Encrypt integration via cert-manager
- 🌐 **Self-Hosted DNS** - LAN-isolated access with CoreDNS
- 📦 **Flexible Deployment** - Scale from Docker Compose to Kubernetes/Helm
- ⚖️ **MIT Licensed** - Using only compatible FOSS components

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

### Prerequisites

- Docker 24.0+ or Kubernetes 1.28+
- Debian 12+ or Ubuntu 22.04+ (host OS)
- Minimum 8GB RAM, 50GB storage
- Optional: GPU for accelerated workloads

### Docker Compose (Development)

```bash
git clone https://github.com/tzervas/autogit.git
cd autogit
cp .env.example .env
# Edit .env with your configuration
docker compose up -d
```

### Kubernetes/Helm (Production)

```bash
# Install with Helm
helm repo add autogit https://tzervas.github.io/autogit
helm install autogit autogit/autogit -f values.yaml
```

See [Installation Guide](docs/installation/README.md) for detailed instructions.

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
