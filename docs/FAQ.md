# Frequently Asked Questions (FAQ)

## General

### What is AutoGit?

AutoGit is a self-hosted GitOps platform that automatically manages and scales GitLab runners across multiple architectures with GPU-aware scheduling. Think of it as your own GitHub Actions or GitLab CI/CD infrastructure that you control completely.

### Why would I use AutoGit?

- **Privacy**: All your code and CI/CD runs on your infrastructure
- **Cost**: No per-minute charges for CI/CD
- **GPU Support**: First-class support for GPU workloads
- **Multi-Architecture**: Build for amd64, arm64, and RISC-V
- **Flexibility**: Full control over configuration and resources

### Is AutoGit production-ready?

AutoGit is currently in active development. The documentation and foundational architecture are in place, with core features being implemented. See the [Roadmap](ROADMAP.md) for details.

## Installation & Setup

### What are the minimum requirements?

- **OS**: Debian 12+, Ubuntu 22.04+, or equivalent
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 50GB free space
- **CPU**: 4 cores minimum
- **Software**: Docker 24.0+ or Kubernetes 1.28+

### Can I run AutoGit on a single machine?

Yes! AutoGit can run on a single machine using Docker Compose for development and testing. For production, we recommend Kubernetes for better scalability and reliability.

### Do I need a GPU?

No, GPUs are optional. AutoGit works perfectly fine without GPUs. GPU support is for workloads that benefit from GPU acceleration (ML training, rendering, etc.).

### Can I use my existing GitLab instance?

AutoGit is designed to integrate with GitLab CE. You can either:
- Use AutoGit's bundled GitLab instance
- Connect to an existing GitLab instance (coming in future versions)

## Architecture

### What architectures are supported?

- **Native**: amd64 (x86_64), arm64 (ARM 64-bit)
- **Emulated**: RISC-V (via QEMU)

### How does GPU scheduling work?

AutoGit's GPU detector service identifies available GPUs (NVIDIA, AMD, Intel) and their capabilities. The runner coordinator then matches jobs to runners with appropriate GPU resources based on job requirements.

### Can I mix architectures in one deployment?

Yes! AutoGit can manage runners across multiple architectures simultaneously. Jobs are routed to runners matching the required architecture.

### What's the difference between Docker Compose and Kubernetes deployment?

- **Docker Compose**: Simple, single-host deployment. Great for development and small deployments.
- **Kubernetes**: Multi-host, highly available, scalable. Recommended for production.

## Runners

### How many runners can AutoGit manage?

The number of runners is limited by your available resources. AutoGit's autoscaling will provision runners based on job demand up to configured limits.

### How long does it take to provision a new runner?

Typically 10-30 seconds for Docker runners, depending on image pull times. Kubernetes runners can be faster with pre-warmed node pools.

### What happens to idle runners?

Idle runners are automatically deprovisioned after a configurable timeout (default: 10 minutes) to save resources.

### Can I have persistent runners?

Yes, you can configure a minimum number of persistent runners that stay active regardless of load.

## GPU Support

### Which GPU vendors are supported?

- NVIDIA (CUDA)
- AMD (ROCm)
- Intel (oneAPI)

### Do I need special drivers?

Yes, you need appropriate drivers installed on the host:
- NVIDIA: NVIDIA drivers + NVIDIA Container Toolkit
- AMD: ROCm drivers
- Intel: Intel GPU drivers + Level Zero runtime

See [GPU Documentation](docs/gpu/README.md) for details.

### Can I use multiple GPU types?

Yes! AutoGit can manage systems with mixed GPU types and will schedule jobs to the appropriate GPU based on requirements.

### What if a job requests a GPU that's unavailable?

The job will wait in the queue until a runner with the requested GPU becomes available, or timeout if configured.

## Security

### Is AutoGit secure?

AutoGit follows security best practices:
- TLS encryption for all connections
- No hardcoded secrets
- RBAC for access control
- Regular security updates
- Comprehensive audit logging

See [Security Guide](docs/security/README.md) for details.

### How are secrets managed?

Secrets are managed through:
- Environment variables (not committed to Git)
- Kubernetes Secrets
- Optional: Sealed Secrets or external secret management

### Can I use SSO?

**Current Status**: SSO is **planned but not yet implemented**.

During initial planning, Okta and Keycloak were evaluated as SSO solutions, but the decision was made to focus on building and proving the core platform functionality first. SSO integration will be addressed in a future release.

**Future Plans**:
- LDAP/Active Directory integration
- OAuth2/OIDC support
- Multi-factor authentication
- Evaluation of Okta, Keycloak, or other SSO solutions

For now, authentication is handled directly by the Git server (GitLab CE) using its built-in user management.

## Performance

### How fast are builds?

Build performance depends on:
- Runner resources (CPU, memory, disk)
- Network speed (for pulling images/dependencies)
- Architecture (native vs emulated)
- Caching configuration

Native builds are fastest. Emulated RISC-V builds are slower due to emulation overhead.

### Can I use build caching?

Yes! AutoGit supports:
- Docker layer caching
- GitLab CI/CD cache
- Artifact caching
- Registry mirror for images

### How do I optimize performance?

See [Performance Tuning Guide](docs/operations/performance-tuning.md) for optimization strategies.

## Operations

### How do I monitor AutoGit?

AutoGit can integrate with:
- Prometheus for metrics
- Grafana for dashboards
- Standard logging systems

See [Monitoring Guide](docs/operations/monitoring.md) for setup.

### How do I backup AutoGit?

Backup these components:
- GitLab data (repositories, database)
- Configuration files
- Secrets
- Audit logs

See [Backup Guide](docs/operations/backup.md) for procedures.

### What if something breaks?

1. Check [Troubleshooting Guide](docs/troubleshooting/README.md)
2. Review logs: `docker compose logs` or `kubectl logs`
3. Search [GitHub Issues](https://github.com/tzervas/autogit/issues)
4. Ask in [GitHub Discussions](https://github.com/tzervas/autogit/discussions)

### How do I upgrade AutoGit?

See [Upgrade Guide](docs/operations/upgrades.md) for version-specific instructions. Always backup before upgrading!

## Development

### How can I contribute?

See [Contributing Guide](docs/CONTRIBUTING.md) for:
- Code contribution process
- Development setup
- Coding standards
- Testing requirements

### Where's the code?

- Core components: `src/`
- Services: `services/`
- Documentation: `docs/`
- Configurations: `config/`

See [Project Structure](docs/development/project-structure.md) for details.

### How do I report bugs?

Open an issue on [GitHub Issues](https://github.com/tzervas/autogit/issues) with:
- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Relevant logs

### How do I request features?

1. Check [Roadmap](ROADMAP.md) to see if it's planned
2. Search existing issues for similar requests
3. Open a new issue with the `enhancement` label
4. Provide use case and expected behavior

## Licensing

### What license is AutoGit under?

MIT License. See [LICENSE](LICENSE) file for full text.

### Can I use AutoGit commercially?

Yes! The MIT license allows commercial use without restrictions.

### Are all dependencies MIT licensed?

AutoGit uses only MIT-compatible dependencies. See [LICENSES.md](LICENSES.md) for complete dependency licenses.

### Can I modify AutoGit?

Yes! You can modify AutoGit freely under the MIT license. Contributions back to the project are welcomed but not required.

## Cost

### Is AutoGit free?

Yes! AutoGit is open-source under the MIT license. You only pay for:
- Your infrastructure (servers, cloud resources)
- Optional support services (if available)

### What are the typical running costs?

Depends on your setup:
- **Development** (single machine): Cost of one server
- **Production** (Kubernetes): Cost of cluster nodes + storage
- **Cloud**: Pay for compute/storage used

No per-minute CI/CD charges like SaaS offerings.

## Comparison

### How does AutoGit compare to GitHub Actions?

| Feature | AutoGit | GitHub Actions |
|---------|---------|----------------|
| Hosting | Self-hosted | Cloud |
| Cost | Infrastructure only | Per-minute |
| Privacy | Complete | Shared cloud |
| GPU Support | Native | Limited |
| Multi-arch | Native | Emulation |

### How does AutoGit compare to GitLab CI/CD?

AutoGit uses GitLab CI/CD but adds:
- Automated runner management
- GPU-aware scheduling
- Multi-architecture support
- Advanced autoscaling
- Kubernetes-native deployment

### Can I migrate from GitHub Actions?

Yes, but you'll need to:
1. Convert workflows to `.gitlab-ci.yml` format
2. Update any GitHub-specific actions
3. Adjust secrets management

Migration guide coming soon.

## Support

### Where can I get help?

- **Documentation**: [docs/INDEX.md](docs/INDEX.md)
- **Issues**: [GitHub Issues](https://github.com/tzervas/autogit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/tzervas/autogit/discussions)
- **Contributing**: [CONTRIBUTING.md](docs/CONTRIBUTING.md)

### Is commercial support available?

Not currently, but may be available in the future. Check back for updates.

### How do I stay updated?

- Watch the [GitHub repository](https://github.com/tzervas/autogit)
- Follow [CHANGELOG.md](CHANGELOG.md) for updates
- Check [Roadmap](ROADMAP.md) for upcoming features

---

**Don't see your question?** Open a [GitHub Discussion](https://github.com/tzervas/autogit/discussions) or add it to this FAQ by submitting a PR!

*Last updated: 2025-12-21*
