# Runner Management

This guide covers AutoGit's dynamic runner management system.

## Overview

AutoGit automatically manages GitLab runners across multiple architectures with intelligent scaling
based on job demand.

## Features

- **Dynamic Autoscaling** - Automatically provisions runners based on job queue
- **Multi-Architecture Support** - amd64, arm64, and RISC-V (via QEMU)
- **GPU-Aware Scheduling** - Intelligent GPU allocation for accelerated workloads
- **Resource Management** - Right-sized runner allocation

## Architecture Support

### Native Architectures

- **amd64** - x86_64 processors (Intel, AMD)
- **arm64** - ARM 64-bit processors (Apple Silicon, AWS Graviton, etc.)

### Emulated Architectures

- **RISC-V** - Via QEMU emulation

See [Multi-Architecture Guide](multi-architecture.md) for details.

## GPU Support

AutoGit supports GPU-aware scheduling for:

- NVIDIA GPUs
- AMD GPUs
- Intel GPUs

See [GPU Documentation](../gpu/README.md) for GPU-specific configuration.

## Runner Configuration

### Basic Runner Setup

```yaml
runners:
  - name: docker-runner
    executor: docker
    limit: 10
    idle_time: 600
```

See [Runner Configuration Guide](configuration.md) for detailed options.

## Autoscaling

AutoGit uses a custom fleeting plugin for dynamic runner scaling.

Key concepts:

- **Scale-up triggers** - Job queue depth, wait time
- **Scale-down triggers** - Idle time, resource utilization
- **Resource limits** - Maximum runners, CPU, memory

See [Autoscaling Guide](autoscaling.md) for details.

## Operations

- [Monitoring Runners](monitoring.md)
- [Troubleshooting Runners](../troubleshooting/runners.md)
- [Runner Lifecycle](lifecycle.md)

## API Reference

See [Runner Manager API](../api/runner-manager.md) for programmatic access.
