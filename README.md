# AutoGit

<!-- FLEET-BADGES:BEGIN -->
[![CI](https://github.com/tzervas/autogit/actions/workflows/fleet-ci.yml/badge.svg?branch=main)](https://github.com/tzervas/autogit/actions/workflows/fleet-ci.yml?query=branch%3Amain)
[![Security](https://github.com/tzervas/autogit/actions/workflows/fleet-security.yml/badge.svg?branch=main)](https://github.com/tzervas/autogit/actions/workflows/fleet-security.yml?query=branch%3Amain)
<!-- FLEET-BADGES:END -->

<div align="center">

**Self-Hosted GitOps Platform with Dynamic Multi-Architecture Runner Management**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![GitLab](https://img.shields.io/badge/gitlab-%23181717.svg?style=flat&logo=gitlab&logoColor=white)](https://about.gitlab.com/)

[Documentation](docs/INDEX.md) • [Installation](docs/installation/README.md) •
[Contributing](CONTRIBUTING.md) • [Roadmap](docs/ROADMAP.md)

</div>

______________________________________________________________________

## Overview

AutoGit is a fully self-hosted GitOps platform that automatically manages and scales GitLab runners
across multiple architectures (amd64, arm64, RISC-V) with GPU-aware scheduling (AMD, NVIDIA, Intel).
Built with security, lightweight performance, and ease of deployment in mind.

### ✨ Key Features

| Feature                           | Description                                            | Status         |
| --------------------------------- | ------------------------------------------------------ | -------------- |
| 🚀 **Dynamic Runner Autoscaling** | Auto-provisions right-sized runners based on job queue | ✅ Ready       |
| 🏗️ **Multi-Architecture Support** | AMD64, ARM64, RISC-V via QEMU                          | 🔄 AMD64 Ready |
| 🎮 **GPU-Aware Scheduling**       | Intelligent allocation of AMD, NVIDIA, Intel GPUs      | 📋 Planned     |
| 🔐 **Centralized SSO**            | Unified authentication with Authelia                   | 📋 Planned     |
| 🔒 **Automated SSL/TLS**          | Let's Encrypt integration via cert-manager             | ✅ Ready       |
| 🌐 **Self-Hosted DNS**            | LAN-isolated access with CoreDNS                       | 📋 Planned     |
| 📦 **Flexible Deployment**        | Docker Compose → Kubernetes/Helm                       | ✅ Ready       |
| ⚖️ **MIT Licensed**               | Using only compatible FOSS components                  | ✅             |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AutoGit Platform                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐      │
│  │   Git Server    │    │     Runner      │    │    Ingress      │      │
│  │   (GitLab CE)   │◄──►│   Coordinator   │◄──►│   (Traefik)     │      │
│  │                 │    │                 │    │                 │      │
│  │  Port: 3000     │    │  Port: 8080     │    │  Port: 80/443   │      │
│  │  SSH: 2222      │    │                 │    │                 │      │
│  └────────┬────────┘    └────────┬────────┘    └─────────────────┘      │
│           │                      │                                       │
│           └──────────┬───────────┘                                       │
│                      ▼                                                   │
│           ┌─────────────────────────────────────┐                        │
│           │        Dynamic Runners              │                        │
│           │  ┌──────┐ ┌──────┐ ┌──────┐        │                        │
│           │  │AMD64 │ │ARM64 │ │ GPU  │  ...   │                        │
│           │  └──────┘ └──────┘ └──────┘        │                        │
│           └─────────────────────────────────────┘                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker 24.0+ or Kubernetes 1.28+
- Debian 12+ / Ubuntu 22.04+ (host OS)
- Minimum 8GB RAM, 50GB storage
- AMD64 architecture (ARM64/RISC-V planned)

### Docker Compose (Development)

```bash
git clone https://github.com/tzervas/autogit.git
cd autogit
cp .env.example .env
# Edit .env with your configuration
docker compose up -d
```

### Kubernetes / ArgoCD (Production)

```bash
# Configure environment
cp .env.k8s.example .env.k8s
nano .env.k8s  # Set DOMAIN, LETSENCRYPT_EMAIL

# Deploy via ArgoCD
kubectl apply -f argocd/apps/root.yaml
```

📖 See [Installation Guide](docs/installation/README.md) for detailed instructions.

______________________________________________________________________

## 📁 Project Structure

```
autogit/
├── 📄 docker-compose.yml       # Service orchestration
├── 📄 .env.example             # Environment template
├── 📂 services/                # Service implementations
│   ├── git-server/             # GitLab CE container
│   └── runner-coordinator/     # Runner management service
├── 📂 config/                  # Configuration files
├── 📂 scripts/                 # Utility scripts
├── 📂 charts/                  # Helm charts
├── 📂 argocd/                  # ArgoCD applications
├── 📂 autogit-core/            # Rust CLI tool
└── 📂 docs/                    # Documentation
```

______________________________________________________________________

## 📖 Documentation

<div align="center">

| Category                                             | Description                  |
| ---------------------------------------------------- | ---------------------------- |
| [📚 Full Documentation](docs/INDEX.md)               | Complete documentation index |
| [🚀 Installation](docs/installation/README.md)       | Get started with AutoGit     |
| [⚙️ Configuration](docs/configuration/README.md)     | Configure your deployment    |
| [🏗️ Architecture](docs/architecture/README.md)       | System design and ADRs       |
| [💻 Development](docs/development/README.md)         | Contributing guide           |
| [🏃 Runners](docs/runners/README.md)                 | Dynamic runner autoscaling   |
| [🔐 Security](docs/security/README.md)               | Security best practices      |
| [🔧 Operations](docs/operations/README.md)           | Day-to-day operations        |
| [🐛 Troubleshooting](docs/troubleshooting/README.md) | Problem solving              |

</div>

______________________________________________________________________

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
# Clone and setup
git clone https://github.com/tzervas/autogit.git
cd autogit
./scripts/setup.sh

# Start development environment
docker compose up -d
```

📖 See [Development Guide](docs/development/README.md) for detailed setup instructions.

______________________________________________________________________

## 📋 Project Status

| Milestone                  | Status         | Target  |
| -------------------------- | -------------- | ------- |
| Core Platform              | ✅ Complete    | -       |
| Docker Compose Deployment  | ✅ Complete    | -       |
| Kubernetes/ArgoCD          | ✅ Complete    | -       |
| Multi-Architecture (ARM64) | 🔄 In Progress | Q1 2026 |
| GPU Support                | 📋 Planned     | Q2 2026 |
| SSO Integration            | 📋 Planned     | Q3 2026 |

📖 See [ROADMAP](docs/ROADMAP.md) for detailed plans.

______________________________________________________________________

## 📄 License

MIT License - see [LICENSE](docs/LICENSE) for details.

All dependencies are MIT-compatible. See [docs/LICENSES.md](docs/LICENSES.md) for dependency
licenses.

______________________________________________________________________

<div align="center">

**[Documentation](docs/INDEX.md)** • **[Issues](https://github.com/tzervas/autogit/issues)** •
**[Discussions](https://github.com/tzervas/autogit/discussions)**

Made with ❤️ by the AutoGit community

</div>
