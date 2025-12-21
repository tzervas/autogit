# Tutorials

Step-by-step guides for common AutoGit tasks.

## Getting Started

New to AutoGit? Start here:

### [Quick Start Tutorial](quickstart.md)
Get AutoGit up and running in 15 minutes. Covers installation, basic configuration, and your first CI/CD pipeline.

**Topics**: Installation, Configuration, First Pipeline
**Duration**: 15 minutes
**Difficulty**: Beginner

## Core Tutorials

### [First CI/CD Pipeline](first-pipeline.md)
Create your first GitLab CI/CD pipeline with AutoGit. Learn job configuration, runner tags, and artifact handling.

**Topics**: .gitlab-ci.yml, Jobs, Runners, Artifacts
**Duration**: 30 minutes
**Difficulty**: Beginner

### [Multi-Architecture Builds](multi-arch-builds.md)
Build Docker images for multiple architectures (amd64, arm64, RISC-V) using AutoGit's multi-architecture support.

**Topics**: Multi-arch, Docker Buildx, QEMU
**Duration**: 45 minutes
**Difficulty**: Intermediate

### [GPU Workloads](gpu-workloads.md)
Run GPU-accelerated workloads (ML training, rendering) with AutoGit's GPU-aware scheduling.

**Topics**: GPU Detection, CUDA, Job Scheduling
**Duration**: 1 hour
**Difficulty**: Intermediate

## Advanced Tutorials

### [Custom Runner Configuration](custom-runner.md)
Create custom runner configurations for specific workloads. Configure resource limits, caching, and environment.

**Topics**: Runner Config, Resources, Caching
**Duration**: 1 hour
**Difficulty**: Advanced

### [High Availability Setup](high-availability.md)
Deploy AutoGit in a high-availability configuration with Kubernetes, redundancy, and failover.

**Topics**: Kubernetes, HA, Redundancy
**Duration**: 2 hours
**Difficulty**: Advanced

### [Security Hardening](security-hardening.md)
Harden your AutoGit deployment with TLS, network policies, secrets management, and audit logging.

**Topics**: TLS, Network Policies, Secrets
**Duration**: 1.5 hours
**Difficulty**: Advanced

## Specialized Tutorials

### [Machine Learning Pipelines](ml-pipelines.md)
Build complete ML pipelines with training, evaluation, and model deployment using AutoGit.

**Topics**: ML, GPU, Model Registry
**Duration**: 2 hours
**Difficulty**: Advanced

### [Infrastructure as Code](iac-tutorial.md)
Use AutoGit for infrastructure deployment with Terraform, Ansible, and GitOps workflows.

**Topics**: Terraform, Ansible, GitOps
**Duration**: 1.5 hours
**Difficulty**: Intermediate

### [Monitoring and Observability](monitoring-tutorial.md)
Set up comprehensive monitoring with Prometheus, Grafana, and alerting for AutoGit.

**Topics**: Prometheus, Grafana, Alerts
**Duration**: 1 hour
**Difficulty**: Intermediate

## Integration Tutorials

### [GitHub Migration](github-migration.md)
Migrate your CI/CD pipelines from GitHub Actions to AutoGit/GitLab CI.

**Topics**: Migration, GitHub Actions, GitLab CI
**Duration**: 2 hours
**Difficulty**: Intermediate

### [Cloud Provider Integration](cloud-integration.md)
Integrate AutoGit with AWS, GCP, or Azure for hybrid cloud deployments.

**Topics**: AWS, GCP, Azure, Hybrid
**Duration**: 1.5 hours
**Difficulty**: Advanced

## Tutorial Format

Each tutorial follows this structure:

1. **Prerequisites** - What you need before starting
2. **Overview** - What you'll learn and build
3. **Step-by-Step Instructions** - Detailed walkthrough
4. **Verification** - How to verify it works
5. **Troubleshooting** - Common issues and solutions
6. **Next Steps** - Where to go from here

## Learning Paths

### Path 1: Complete Beginner

1. [Quick Start](quickstart.md)
2. [First Pipeline](first-pipeline.md)
3. [Multi-Architecture Builds](multi-arch-builds.md)
4. [Monitoring Tutorial](monitoring-tutorial.md)

**Time**: 3-4 hours
**Result**: Working AutoGit deployment with CI/CD

### Path 2: GPU User

1. [Quick Start](quickstart.md)
2. [GPU Workloads](gpu-workloads.md)
3. [ML Pipelines](ml-pipelines.md)
4. [Custom Runners](custom-runner.md)

**Time**: 4-5 hours
**Result**: GPU-accelerated ML pipeline

### Path 3: Production Deployment

1. [Quick Start](quickstart.md)
2. [High Availability](high-availability.md)
3. [Security Hardening](security-hardening.md)
4. [Monitoring Tutorial](monitoring-tutorial.md)

**Time**: 5-6 hours
**Result**: Production-ready HA deployment

## Video Tutorials

Coming soon! Video versions of these tutorials will be available on YouTube.

## Community Tutorials

Have you created a tutorial for AutoGit? Share it with the community!

1. Submit a PR to add your tutorial
2. Or create a link to your blog/video

See [Contributing Guide](../CONTRIBUTING.md) for details.

## Feedback

Found an issue with a tutorial? Have suggestions?

- Open an [issue](https://github.com/tzervas/autogit/issues)
- Submit a PR with improvements
- Discuss in [GitHub Discussions](https://github.com/tzervas/autogit/discussions)

## Additional Resources

- [Documentation Index](../INDEX.md) - Complete documentation
- [FAQ](../../FAQ.md) - Frequently asked questions
- [Examples Repository](https://github.com/tzervas/autogit-examples) - Code examples
- [Troubleshooting Guide](../troubleshooting/README.md) - Problem solving

---

*New tutorials are added regularly. Watch the repository for updates!*

*Last updated: 2024-12-21*
