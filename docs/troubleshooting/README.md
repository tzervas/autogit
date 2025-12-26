# Troubleshooting Guide

Common issues and solutions for AutoGit.

## Overview

This guide helps you diagnose and resolve common issues with AutoGit.

## Quick Diagnosis

### Check Service Status

```bash
# Docker Compose
docker compose ps
docker compose logs -f

# Kubernetes
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Common Issues

#### Services Won't Start

**Symptoms**: Containers fail to start or restart repeatedly

**Possible Causes**:

- Port conflicts
- Missing environment variables
- Insufficient resources
- Configuration errors

**Solutions**:

1. Check logs: `docker compose logs <service>`
1. Verify ports are available: `netstat -tulpn | grep <port>`
1. Check `.env` file for missing variables
1. Verify resource limits

See [Installation Issues](installation.md) for details.

#### Runners Not Connecting

**Symptoms**: Runners don't appear in GitLab or can't execute jobs

**Possible Causes**:

- Incorrect registration token
- Network connectivity issues
- Runner service not running
- Configuration mismatch

**Solutions**:

1. Verify registration token in GitLab
1. Check network connectivity: `docker compose logs runner-coordinator`
1. Restart runner service: `docker compose restart runner-coordinator`
1. Review configuration in `config/config.yml`

See [Runner Issues](runners.md) for details.

#### GPU Not Detected

**Symptoms**: GPUs not visible to runners

**Possible Causes**:

- Missing drivers
- Missing container runtime (nvidia-container-toolkit)
- Incorrect configuration
- GPU not supported

**Solutions**:

1. Verify drivers: `nvidia-smi` (NVIDIA) or equivalent
1. Check container runtime: `docker run --gpus all nvidia/cuda:11.0-base nvidia-smi`
1. Review configuration in `config/gpu/gpu-config.yaml`
1. Check GPU compatibility

See [GPU Issues](gpu.md) for details.

#### Performance Issues

**Symptoms**: Slow builds, high latency, resource exhaustion

**Possible Causes**:

- Insufficient resources
- Network bottlenecks
- Poor caching
- Too many concurrent jobs

**Solutions**:

1. Monitor resource usage: `docker stats` or `kubectl top nodes`
1. Check network: `docker compose logs traefik`
1. Enable caching in `.gitlab-ci.yml`
1. Adjust runner limits in configuration

See [Performance Issues](performance.md) for details.

## Issue Categories

### Installation Issues

Problems during initial setup and installation.

See [Installation Troubleshooting](installation.md)

### Configuration Issues

Problems with configuration files and settings.

- [Environment Variables](configuration.md#environment-variables)
- [YAML Configuration](configuration.md#yaml-config)
- [SSL/TLS Issues](configuration.md#tls)

### Network Issues

Problems with connectivity and networking.

See [Network Troubleshooting](network.md)

### Runner Issues

Problems with runner provisioning and execution.

See [Runner Troubleshooting](runners.md)

### GPU Issues

Problems with GPU detection and scheduling.

See [GPU Troubleshooting](gpu.md)

### Performance Issues

Problems with system performance and resource usage.

See [Performance Troubleshooting](performance.md)

## Debugging Tools

### Log Collection

```bash
# Collect all logs
docker compose logs > autogit-logs.txt

# Kubernetes logs
kubectl logs -l app=autogit > autogit-k8s-logs.txt
```

### Health Checks

```bash
# Check service health
curl http://localhost:8080/health

# Check runner coordinator
curl http://localhost:8080/api/v1/runners
```

### Network Diagnostics

```bash
# Test connectivity
docker compose exec runner-coordinator ping gitlab

# Check DNS
docker compose exec runner-coordinator nslookup gitlab
```

## Getting Help

If you can't resolve the issue:

1. **Search Documentation**

   - Check [FAQ](../FAQ.md)
   - Review [Configuration Guide](../configuration/README.md)
   - Read relevant component docs

1. **Search Existing Issues**

   - Search [GitHub Issues](https://github.com/tzervas/autogit/issues)
   - Check for similar problems

1. **Gather Information**

   - Service logs
   - Configuration files (sanitize secrets!)
   - System information
   - Steps to reproduce

1. **Ask for Help**

   - Open a [GitHub Issue](https://github.com/tzervas/autogit/issues/new)
   - Post in [GitHub Discussions](https://github.com/tzervas/autogit/discussions)
   - Include all gathered information

## Diagnostic Checklist

Before asking for help, check:

- [ ] Logs reviewed for error messages
- [ ] Configuration verified
- [ ] Services are running
- [ ] Network connectivity tested
- [ ] Resources adequate (CPU, memory, disk)
- [ ] Documentation consulted
- [ ] Existing issues searched
- [ ] Minimal reproduction steps identified

## References

- [Installation Guide](../installation/README.md)
- [Configuration Guide](../configuration/README.md)
- [Operations Guide](../operations/README.md)
- [FAQ](../FAQ.md)
- [GitHub Issues](https://github.com/tzervas/autogit/issues)
