# AutoGit Documentation

> **Self-Hosted GitOps Platform with Dynamic Multi-Architecture Runner Management**

______________________________________________________________________

## 📊 Documentation Overview

```
                              ┌──────────────────────────────────────┐
                              │         📚 DOCUMENTATION             │
                              │              INDEX                    │
                              └──────────────────────────────────────┘
                                              │
           ┌──────────────────────────────────┼──────────────────────────────────┐
           │                                  │                                  │
           ▼                                  ▼                                  ▼
┌─────────────────────┐          ┌─────────────────────┐          ┌─────────────────────┐
│    🚀 GETTING       │          │    🏗️ ARCHITECTURE  │          │    ⚙️ CONFIGURATION │
│       STARTED       │          │                     │          │                     │
├─────────────────────┤          ├─────────────────────┤          ├─────────────────────┤
│ • Installation      │          │ • System Design     │          │ • GitLab Setup      │
│ • Quick Start       │          │ • Components        │          │ • Runner Config     │
│ • Prerequisites     │          │ • ADRs              │          │ • Networking        │
└─────────────────────┘          └─────────────────────┘          └─────────────────────┘
           │                                  │                                  │
           └──────────────────────────────────┼──────────────────────────────────┘
                                              │
           ┌──────────────────────────────────┼──────────────────────────────────┐
           │                                  │                                  │
           ▼                                  ▼                                  ▼
┌─────────────────────┐          ┌─────────────────────┐          ┌─────────────────────┐
│    💻 DEVELOPMENT   │          │    🔧 OPERATIONS    │          │    📖 REFERENCE     │
│                     │          │                     │          │                     │
├─────────────────────┤          ├─────────────────────┤          ├─────────────────────┤
│ • Setup Guide       │          │ • Monitoring        │          │ • API Docs          │
│ • Standards         │          │ • Backup/Recovery   │          │ • CLI Reference     │
│ • Testing           │          │ • Troubleshooting   │          │ • Glossary          │
└─────────────────────┘          └─────────────────────┘          └─────────────────────┘
```

______________________________________________________________________

## 🚀 Quick Navigation

| I want to...                       | Start here                                         |
| ---------------------------------- | -------------------------------------------------- |
| **Get started quickly**            | [Quick Start Tutorial](tutorials/quickstart.md)    |
| **Install AutoGit**                | [Installation Guide](installation/README.md)       |
| **Configure the platform**         | [Configuration Guide](configuration/README.md)     |
| **Understand the architecture**    | [Architecture Overview](architecture/README.md)    |
| **Set up development environment** | [Development Setup](development/setup.md)          |
| **Debug an issue**                 | [Troubleshooting Guide](troubleshooting/README.md) |
| **Contribute code**                | [Contributing Guide](../CONTRIBUTING.md)           |

______________________________________________________________________

## 📁 Documentation Structure

```
docs/
├── 📋 INDEX.md                    # ← You are here
├── 📜 CHANGELOG.md                # Version history
├── 🗺️ ROADMAP.md                  # Future plans
├── ❓ FAQ.md                       # Frequently asked questions
├── 📖 GLOSSARY.md                 # Terms and definitions
├── ⚖️ LICENSES.md                 # Dependency licenses
│
├── 🚀 installation/               # Installation guides
│   ├── README.md                  # Installation overview
│   ├── kubernetes.md              # Kubernetes/Helm deployment
│   └── argocd.md                  # ArgoCD GitOps deployment
│
├── ⚙️ configuration/              # Configuration references
│   ├── README.md                  # Configuration overview
│   └── CI_CD_SECRETS.md           # CI/CD secrets management
│
├── 🏗️ architecture/               # Architecture documentation
│   ├── README.md                  # Architecture overview
│   ├── PLATFORM_ARCHITECTURE.md   # Detailed platform design
│   ├── AUTOGIT_SPEC.md            # Technical specification
│   └── adr/                       # Architecture Decision Records
│       ├── README.md              # ADR index
│       ├── template.md            # ADR template
│       └── 001-traefik-vs-nginx.md
│
├── 💻 development/                # Development guides
│   ├── README.md                  # Development overview
│   ├── setup.md                   # Local development setup
│   ├── standards.md               # Coding standards
│   ├── testing.md                 # Testing guide
│   ├── ci-cd.md                   # CI/CD configuration
│   ├── agentic-workflow.md        # AI-assisted development
│   ├── branching-strategy.md      # Git branching model
│   ├── project-structure.md       # Codebase organization
│   ├── documentation.md           # Documentation standards
│   ├── common-tasks.md            # Common dev tasks
│   ├── workflow-optimization.md   # Workflow tips
│   ├── ghcr-setup.md              # GitHub Container Registry
│   ├── chat-context.md            # AI chat context
│   └── CODE_QUALITY.md            # Code quality standards
│
├── 🏃 runners/                    # Runner management
│   ├── README.md                  # Runner overview
│   ├── AUTONOMOUS_RUNNERS.md      # Autonomous runner system
│   ├── MULTI_ARCH_STRATEGY.md     # Multi-architecture support
│   └── dynamic-runner-testing.md  # Dynamic runner testing
│
├── 🎮 gpu/                        # GPU support
│   └── README.md                  # GPU configuration guide
│
├── 🔐 security/                   # Security documentation
│   ├── README.md                  # Security overview
│   └── CREDENTIALS_MANAGEMENT.md  # Credentials handling
│
├── 🔧 operations/                 # Operations guides
│   └── README.md                  # Operations overview
│
├── 📡 api/                        # API documentation
│   └── README.md                  # API reference
│
├── 💻 cli/                        # CLI reference
│   └── README.md                  # CLI commands
│
├── 📚 tutorials/                  # Step-by-step tutorials
│   └── README.md                  # Tutorial index
│
├── 🔧 troubleshooting/            # Problem solving
│   └── README.md                  # Troubleshooting guide
│
├── 🖥️ git-server/                 # Git server documentation
│   ├── README.md                  # Git server overview
│   ├── quickstart.md              # Quick setup guide
│   ├── docker-setup.md            # Docker deployment
│   ├── docker-setup-summary.md    # Setup summary
│   ├── user-guide.md              # User documentation
│   ├── admin-guide.md             # Administration guide
│   ├── authentication.md          # Auth configuration
│   ├── ssh-access.md              # SSH setup
│   ├── http-access.md             # HTTP/HTTPS setup
│   ├── repository-management.md   # Repo management
│   ├── api-integration.md         # API usage
│   ├── security-config.md         # Security settings
│   ├── backup-recovery.md         # Backup procedures
│   └── GIT_SERVER_FEATURE_PLAN.md # Feature roadmap
│
├── 🛠️ tools/                      # Tool documentation
│   └── tasker.md                  # Task automation tool
│
├── 📋 workflows/                  # Workflow documentation
│   └── RELEASE_WORKFLOW.md        # Release process
│
└── 📦 archive/                    # Historical documentation
    ├── README.md                  # Archive index
    ├── work-summaries/            # Development session logs
    ├── branch-management/         # Branch cleanup records
    ├── pr-documentation/          # Historical PR docs
    └── release-history/           # Past release notes
```

______________________________________________________________________

## 📖 Core Documentation

### 🚀 Installation & Setup

| Document                                        | Description                 | Audience  |
| ----------------------------------------------- | --------------------------- | --------- |
| [Installation Overview](installation/README.md) | Complete installation guide | All users |
| [Kubernetes Setup](installation/kubernetes.md)  | Production K8s deployment   | Operators |
| [ArgoCD Deployment](installation/argocd.md)     | GitOps deployment method    | Operators |

### ⚙️ Configuration

| Document                                          | Description                | Audience       |
| ------------------------------------------------- | -------------------------- | -------------- |
| [Configuration Overview](configuration/README.md) | System configuration guide | Administrators |
| [CI/CD Secrets](configuration/CI_CD_SECRETS.md)   | Secrets management         | Administrators |

### 🏗️ Architecture & Design

| Document                                                       | Description               | Audience   |
| -------------------------------------------------------------- | ------------------------- | ---------- |
| [Architecture Overview](architecture/README.md)                | System design overview    | All users  |
| [Platform Architecture](architecture/PLATFORM_ARCHITECTURE.md) | Detailed component design | Architects |
| [AutoGit Specification](architecture/AUTOGIT_SPEC.md)          | Technical specification   | Developers |
| [ADR Index](architecture/adr/README.md)                        | Architecture decisions    | Architects |

### 💻 Development

| Document                                                | Description                      | Audience         |
| ------------------------------------------------------- | -------------------------------- | ---------------- |
| [Development Overview](development/README.md)           | Getting started with development | Developers       |
| [Setup Guide](development/setup.md)                     | Local environment setup          | Developers       |
| [Coding Standards](development/standards.md)            | Code style and conventions       | Developers       |
| [Testing Guide](development/testing.md)                 | Testing strategies               | Developers       |
| [CI/CD Guide](development/ci-cd.md)                     | Continuous integration setup     | Developers       |
| [Branching Strategy](development/branching-strategy.md) | Git workflow                     | All contributors |
| [Agentic Workflow](development/agentic-workflow.md)     | AI-assisted development          | Developers       |
| [Code Quality](development/CODE_QUALITY.md)             | Quality standards                | Developers       |

### 🏃 Runner Management

| Document                                             | Description                | Audience   |
| ---------------------------------------------------- | -------------------------- | ---------- |
| [Runner Overview](runners/README.md)                 | Runner system introduction | All users  |
| [Autonomous Runners](runners/AUTONOMOUS_RUNNERS.md)  | Self-managing runners      | Operators  |
| [Multi-Architecture](runners/MULTI_ARCH_STRATEGY.md) | Multi-arch support         | Operators  |
| [Dynamic Testing](runners/dynamic-runner-testing.md) | Runner testing guide       | Developers |

### 🖥️ Git Server

| Document                                           | Description               | Audience       |
| -------------------------------------------------- | ------------------------- | -------------- |
| [Git Server Overview](git-server/README.md)        | GitLab CE setup guide     | All users      |
| [Quick Start](git-server/quickstart.md)            | Get started in minutes    | New users      |
| [Docker Setup](git-server/docker-setup.md)         | Docker Compose deployment | Operators      |
| [User Guide](git-server/user-guide.md)             | Using the git server      | Users          |
| [Admin Guide](git-server/admin-guide.md)           | Administration tasks      | Administrators |
| [Authentication](git-server/authentication.md)     | Auth configuration        | Administrators |
| [Backup & Recovery](git-server/backup-recovery.md) | Data protection           | Operators      |

### 🔐 Security

| Document                                                     | Description                | Audience  |
| ------------------------------------------------------------ | -------------------------- | --------- |
| [Security Overview](security/README.md)                      | Security best practices    | All users |
| [Credentials Management](security/CREDENTIALS_MANAGEMENT.md) | Secure credential handling | Operators |

### 🔧 Operations

| Document                                          | Description           | Audience    |
| ------------------------------------------------- | --------------------- | ----------- |
| [Operations Overview](operations/README.md)       | Day-to-day operations | Operators   |
| [Release Workflow](workflows/RELEASE_WORKFLOW.md) | Release process       | Maintainers |

______________________________________________________________________

## 🎯 Documentation by Role

### 👋 New Users

1. [README.md](../README.md) - Project overview
1. [Quick Start](git-server/quickstart.md) - Get running in minutes
1. [FAQ](FAQ.md) - Common questions answered
1. [Glossary](GLOSSARY.md) - Understand the terminology

### 👨‍💻 Developers

1. [Development Setup](development/setup.md) - Set up your environment
1. [Coding Standards](development/standards.md) - Follow the conventions
1. [Testing Guide](development/testing.md) - Write effective tests
1. [Architecture Overview](architecture/README.md) - Understand the system
1. [API Documentation](api/README.md) - API reference

### 🔧 Operators

1. [Installation Guide](installation/README.md) - Deploy AutoGit
1. [Configuration Guide](configuration/README.md) - Configure the platform
1. [Operations Guide](operations/README.md) - Day-to-day operations
1. [Troubleshooting](troubleshooting/README.md) - Fix common issues
1. [Security Guide](security/README.md) - Secure your deployment

### 🏛️ Architects

1. [Architecture Overview](architecture/README.md) - System design
1. [Platform Architecture](architecture/PLATFORM_ARCHITECTURE.md) - Deep dive
1. [ADR Index](architecture/adr/README.md) - Design decisions
1. [AutoGit Specification](architecture/AUTOGIT_SPEC.md) - Technical spec

______________________________________________________________________

## 📋 Project Status

| Document                  | Description                 |
| ------------------------- | --------------------------- |
| [CHANGELOG](CHANGELOG.md) | Version history and changes |
| [ROADMAP](ROADMAP.md)     | Future plans and milestones |
| [LICENSES](LICENSES.md)   | Third-party licenses        |

______________________________________________________________________

## 🔗 Quick Links

### Root Directory Files

| File                                  | Description                      |
| ------------------------------------- | -------------------------------- |
| [README.md](../README.md)             | Project overview and quick start |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Contribution guidelines          |
| [LICENSE](LICENSE)                    | MIT License                      |

### External Resources

| Resource                                              | Description                          |
| ----------------------------------------------------- | ------------------------------------ |
| [GitLab Runner Docs](https://docs.gitlab.com/runner/) | Official GitLab Runner documentation |
| [Traefik Docs](https://doc.traefik.io/traefik/)       | Traefik ingress controller           |
| [Kubernetes Docs](https://kubernetes.io/docs/)        | Kubernetes documentation             |
| [ArgoCD Docs](https://argo-cd.readthedocs.io/)        | ArgoCD GitOps documentation          |

______________________________________________________________________

## 📦 Archive

Historical documentation and development artifacts are preserved in [archive/](archive/README.md):

- **Work Summaries** - Development session logs and notes
- **Branch Management** - Historical branch analysis
- **PR Documentation** - Past pull request documentation
- **Release History** - Previous release notes

______________________________________________________________________

## 🔍 Can't Find Something?

1. **Search**: Use your editor's search across the `docs/` directory
1. **Glossary**: Check [GLOSSARY.md](GLOSSARY.md) for term definitions
1. **FAQ**: See [FAQ.md](FAQ.md) for common questions
1. **Ask**: [Open an issue](https://github.com/tzervas/autogit/issues) if documentation is missing

______________________________________________________________________

<div align="center">

**Last Updated**: January 2026 | **License**: MIT

[Back to Top](#autogit-documentation) | [Project README](../README.md) |
[Contributing](../CONTRIBUTING.md)

</div>
