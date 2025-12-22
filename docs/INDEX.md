# AutoGit Documentation Index
**Last Updated**: [Auto-generated timestamp]
This index provides a complete map of all AutoGit documentation. Always check this file first when looking for
information.
##

📚 Documentation Structure

```
docs/

├── INDEX.md

# This file - complete documentation map

├── installation/

# Installation and setup

├── configuration/

# Configuration references

├── architecture/

# Architecture and design decisions

├── development/

# Development guides and standards

├── runners/

# Runner management

├── gpu/

# GPU support

├── security/

# Security guidelines

├── operations/

# Operations and monitoring

├── api/

# API documentation

├── cli/

# CLI reference

├── tutorials/

# Step-by-step tutorials

├── troubleshooting/

# Common issues and solutions

└── FAQ.md

# Frequently asked questions

```
##

🚀 Getting Started

New to AutoGit? Start here:
1. [README.md](../README.md) - Project overview and quick start
2. [Installation Guide](installation/README.md) - Detailed installation instructions
3. [Quick Start Tutorial](tutorials/quickstart.md) - Your first AutoGit deployment
4. [Configuration Basics](configuration/README.md) - Essential configuration
##

📖 Core Documentation

### Installation & Setup
| Document | Description | Audience |
|----------|-------------|----------|
| [Installation Overview](installation/README.md) | Complete installation guide | All users |
| [Prerequisites](installation/prerequisites.md) | System requirements and dependencies | All users |
| [Docker Compose Setup](installation/docker-compose.md) | Development setup with Docker Compose | Developers |
| [Kubernetes Setup](installation/kubernetes.md) | Production setup with Kubernetes | Operators |
| [Migration Guide](installation/migration.md) | Docker Compose → Kubernetes migration | Operators |
### Configuration
| Document | Description | Audience |
|----------|-------------|----------|
| [Configuration Overview](configuration/README.md) | Configuration system overview | All users |
| [GitLab Configuration](configuration/gitlab.md) | GitLab CE configuration | Administrators |
| [Runner Configuration](configuration/runners.md) | Runner management configuration | Administrators |
| [DNS Configuration](configuration/dns.md) | CoreDNS setup and configuration | Administrators |
| [SSL/TLS Configuration](configuration/ssl.md) | cert-manager and certificate setup | Administrators |
| [SSO Configuration](configuration/sso.md) | Authelia SSO setup | Administrators |
| [Ingress Configuration](configuration/ingress.md) | Traefik ingress setup | Administrators |
| [Storage Configuration](configuration/storage.md) | Persistent storage setup | Administrators |
| [Environment Variables](configuration/environment-variables.md) | All environment variables reference | All
users |
### Architecture & Design
| Document | Description | Audience |
|----------|-------------|----------|
| [Architecture Overview](architecture/README.md) | System architecture overview | All users |
| [Component Design](architecture/components.md) | Individual component designs | Developers |
| [Networking](architecture/networking.md) | Network architecture and policies | Operators |

| [Data Flow](architecture/data-flow.md) | How data flows through the system | Developers |
| [Scaling Strategy](architecture/scaling.md) | Horizontal and vertical scaling | Architects |
| [High Availability](architecture/high-availability.md) | HA configuration | Operators |
| [ADR Index](architecture/adr/README.md) | All architecture decisions | Architects |
#### Architecture Decision Records (ADRs)
| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](architecture/adr/001-traefik-vs-nginx.md) | Traefik vs NGINX Ingress | Accepted | YYYY-MM-DD |
| [ADR-002](architecture/adr/002-fleeting-plugin.md) | Custom Fleeting Plugin Design | Accepted | YYYY-MM-DD |
| [ADR-003](architecture/adr/003-multi-architecture.md) | Multi-Architecture Strategy | Accepted | YYYY-MM-DD |
| [ADR-004](architecture/adr/004-sso-solution.md) | SSO Solution Selection | Accepted | YYYY-MM-DD |
| [ADR-005](architecture/adr/005-dns-management.md) | DNS Management Approach | Accepted | YYYY-MM-DD |
| [ADR-006](architecture/adr/006-storage-architecture.md) | Storage Architecture | Accepted | YYYY-MM-DD |
### Development
| Document | Description | Audience |
|----------|-------------|----------|
| [Development Overview](development/README.md) | Development environment setup | Developers |
| [Setup Guide](development/setup.md) | Local development setup | Developers |
| [Coding Standards](development/standards.md) | Code style and standards | Developers |
| [Testing Guide](development/testing.md) | Testing strategy and guidelines | Developers |
| [Agentic Workflow](development/agentic-workflow.md) | AI-assisted development workflow | Developers |
| [Project Structure](development/project-structure.md) | Codebase organization | Developers |
| [Common Tasks](development/common-tasks.md) | Common development tasks | Developers |
| [Licensing Guide](development/licensing.md) | License compliance guidelines | Developers |
| [Documentation Guide](development/documentation.md) | Writing and maintaining docs | All contributors |
| [CI/CD Guide](development/ci-cd.md) | Continuous integration setup | Developers |
| [Release Process](development/release-process.md) | How to cut a release | Maintainers |
### Runner Management
| Document | Description | Audience |
|----------|-------------|----------|
| [Runner Overview](runners/README.md) | Runner management overview | All users |
| [Autoscaling](runners/autoscaling.md) | Autoscaling configuration and behavior | Operators |
| [Multi-Architecture](runners/multi-arch.md) | Multi-arch runner setup | Operators |
| [Fleeting Plugin](runners/fleeting-plugin.md) | Custom fleeting plugin guide | Developers |
| [Provisioning](runners/provisioning.md) | Runner provisioning logic | Developers |
| [Tags and Labels](runners/tags-and-labels.md) | Runner tagging strategy | Administrators |
| [Monitoring](runners/monitoring.md) | Runner monitoring and metrics | Operators |
| [Troubleshooting](runners/troubleshooting.md) | Runner issues and solutions | All users |
### GPU Support
| Document | Description | Audience |
|----------|-------------|----------|
| [GPU Overview](gpu/README.md) | GPU support overview | All users |
| [NVIDIA GPUs](gpu/nvidia.md) | NVIDIA GPU setup and configuration | Operators |
| [AMD GPUs](gpu/amd.md) | AMD GPU setup and configuration | Operators |
| [Intel GPUs](gpu/intel.md) | Intel GPU setup and configuration | Operators |
| [Detection Logic](gpu/detection.md) | GPU detection implementation | Developers |
| [Scheduling](gpu/scheduling.md) | GPU-aware job scheduling | Developers |
| [Troubleshooting](gpu/troubleshooting.md) | GPU-related issues | All users |
### Security

| Document | Description | Audience |
|----------|-------------|----------|
| [Security Overview](security/README.md) | Security guidelines overview | All users |
| [Hardening Guide](security/hardening.md) | System hardening checklist | Operators |
| [Secrets Management](security/secrets.md) | Managing secrets securely | Developers |
| [Network Policies](security/network-policies.md) | Kubernetes network policies | Operators |
| [TLS Configuration](security/tls.md) | TLS/SSL security | Administrators |
| [Access Control](security/access-control.md) | RBAC and permissions | Administrators |
| [Audit Logging](security/audit-logging.md) | Security audit logs | Operators |
| [Vulnerability Management](security/vulnerability-management.md) | Handling vulnerabilities | Maintainers |
| [Incident Response](security/incident-response.md) | Security incident procedures | Operators |
### Operations
| Document | Description | Audience |
|----------|-------------|----------|
| [Operations Overview](operations/README.md) | Operations guide overview | Operators |
| [Monitoring](operations/monitoring.md) | Monitoring and observability | Operators |
| [Backup & Recovery](operations/backup.md) | Backup strategies | Operators |
| [Disaster Recovery](operations/disaster-recovery.md) | DR procedures | Operators |
| [Upgrades](operations/upgrades.md) | Upgrade procedures | Operators |
| [Performance Tuning](operations/performance-tuning.md) | Optimization guide | Operators |
| [Capacity Planning](operations/capacity-planning.md) | Resource planning | Architects |
| [Health Checks](operations/health-checks.md) | System health monitoring | Operators |
### API Documentation
| Document | Description | Audience |
|----------|-------------|----------|
| [API Overview](api/README.md) | API documentation overview | Developers |
| [Fleeting Plugin API](api/fleeting-plugin.md) | Fleeting plugin interface | Developers |
| [Runner Manager API](api/runner-manager.md) | Runner manager interface | Developers |
| [GPU Detector API](api/gpu-detector.md) | GPU detection interface | Developers |
| [Configuration API](api/configuration.md) | Configuration schemas | Developers |
| [REST API](api/rest.md) | REST API endpoints | Developers |
### CLI Reference
| Document | Description | Audience |
|----------|-------------|----------|
| [CLI Overview](cli/README.md) | Command-line tools overview | All users |
| [autogit CLI](cli/autogit.md) | Main CLI reference | All users |
| [runner-manager CLI](cli/runner-manager.md) | Runner management CLI | Operators |
| [gpu-detector CLI](cli/gpu-detector.md) | GPU detection CLI | Operators |
### Tutorials
| Document | Description | Audience |
|----------|-------------|----------|
| [Quick Start](tutorials/quickstart.md) | Get started in 15 minutes | New users |
| [First Pipeline](tutorials/first-pipeline.md) | Create your first CI/CD pipeline | New users |
| [Multi-Arch Builds](tutorials/multi-arch-builds.md) | Building for multiple architectures | Developers |
| [GPU Workloads](tutorials/gpu-workloads.md) | Running GPU-accelerated jobs | Developers |
| [Custom Runner](tutorials/custom-runner.md) | Creating custom runner configurations | Advanced users |
| [High Availability Setup](tutorials/high-availability.md) | Setting up HA deployment | Operators |
### Troubleshooting
| Document | Description | Audience |

|----------|-------------|----------|
| [Troubleshooting Overview](troubleshooting/README.md) | Common issues and solutions | All users |
| [Installation Issues](troubleshooting/installation.md) | Installation problems | All users |
| [Runner Issues](troubleshooting/runners.md) | Runner-related problems | Operators |
| [GPU Issues](troubleshooting/gpu.md) | GPU-related problems | Operators |
| [Network Issues](troubleshooting/network.md) | Networking problems | Operators |
| [Performance Issues](troubleshooting/performance.md) | Performance problems | Operators |
| [Debugging Guide](troubleshooting/debugging.md) | General debugging techniques | Developers |
### Project Management
| Document | Description | Audience |
|----------|-------------|----------|
| [Task Tracker](../TASK_TRACKER.md) | Project task tracking and progress | Project Managers |
| [QC Workflow](../QC_WORKFLOW.md) | Quality control procedures | All developers |
| [Manager Delegation](../MANAGER_DELEGATION.md) | Current task delegation and assignments | All agents |
| [Project Management Summary](../PROJECT_MANAGEMENT_SUMMARY.md) | Current project status summary | All stakeholders |
| [Git Server Feature Plan](../GIT_SERVER_FEATURE_PLAN.md) | Detailed Git Server implementation plan | Developers |
| [How to Start Next Feature](../HOW_TO_START_NEXT_FEATURE.md) | Feature workflow guide | Developers |

### Other
| Document | Description | Audience |
|----------|-------------|----------|
| [FAQ](FAQ.md) | Frequently asked questions | All users |
| [Glossary](GLOSSARY.md) | Terms and definitions | All users |
| [Contributing](../CONTRIBUTING.md) | How to contribute | Contributors |
| [License](../LICENSE) | MIT License text | All users |
| [Licenses](../LICENSES.md) | All dependency licenses | All users |
| [Changelog](../CHANGELOG.md) | Version history | All users |
| [Roadmap](../ROADMAP.md) | Future plans | All users |
##

🔍 Finding Documentation

### By Topic
- **Installation**: Start with `installation/README.md`
- **Configuration**: Start with `configuration/README.md`
- **Development**: Start with `development/README.md`
- **Troubleshooting**: Start with `troubleshooting/README.md`
- **API**: Start with `api/README.md`
### By Role
**New Users**:
1. [README.md](../README.md)
2. [Installation Guide](installation/README.md)
3. [Quick Start Tutorial](tutorials/quickstart.md)
4. [FAQ](FAQ.md)
**Developers**:
1. [Development Setup](development/setup.md)
2. [Coding Standards](development/standards.md)
3. [Testing Guide](development/testing.md)
4. [API Documentation](api/README.md)
5. [Architecture Overview](architecture/README.md)
**Operators**:
1. [Installation Guide](installation/README.md)
2. [Configuration Overview](configuration/README.md)
3. [Operations Guide](operations/README.md)
4. [Monitoring](operations/monitoring.md)
5. [Troubleshooting](troubleshooting/README.md)
**Architects**:
1. [Architecture Overview](architecture/README.md)
2. [ADR Index](architecture/adr/README.md)
3. [Scaling Strategy](architecture/scaling.md)
4. [High Availability](architecture/high-availability.md)

##

📝 Documentation Maintenance

### For Contributors
When modifying code that affects documentation:
1. **Check this INDEX.md** to find relevant documentation
2. **Update all affected documentation** in the same PR
3. **Add new documentation** if creating new features
4. **Update INDEX.md** if adding/removing documentation files
5. **Follow** [Documentation Guide](development/documentation.md)
### For Maintainers
- Review documentation in all PRs
- Keep INDEX.md up to date
- Ensure all documentation links work
- Archive outdated documentation
- Update ADRs for architectural changes
### Documentation Standards
- All documentation in Markdown
- Follow [Documentation Guide](development/documentation.md)
- Include code examples where appropriate
- Keep documentation current with code
- Use consistent terminology (see [Glossary](GLOSSARY.md))
##

🔗 External Resources

- [GitLab Runner Official Docs](https://docs.gitlab.com/runner/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Authelia Documentation](https://www.authelia.com/)
- [CoreDNS Documentation](https://coredns.io/)
- [cert-manager Documentation](https://cert-manager.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
##

📊 Documentation Statistics

- Total Documents: [Auto-generated count]
- Last Updated: [Auto-generated timestamp]
- Contributors: [Link to contributors]
---

**Note**: This index is automatically validated by CI/CD. All links are checked on every commit.
If you can't find what you're looking for, check the [FAQ](FAQ.md) or [open an issue](https://github.com/yourusername/autogit/issues).
