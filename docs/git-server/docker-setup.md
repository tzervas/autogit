# Docker Setup and Configuration - Git Server

**Component**: Git Server (GitLab CE) **Version**: 16.11.0-ce.0 **Status**: Production Ready (MVP -
AMD64), Supported (ARM64), Experimental (RISC-V) **Last Updated**: 2025-12-22

## Overview

This document describes the Docker setup and configuration for the AutoGit Git Server, which uses
GitLab Community Edition (CE) as the underlying Git server platform.

## Architecture Support

AutoGit Git Server supports multiple architectures with different maturity levels:

| Architecture         | Support Level | Native/Emulated | Status     | Use Case                |
| -------------------- | ------------- | --------------- | ---------- | ----------------------- |
| **AMD64** (x86_64)   | Production    | Native          | ✅ Ready   | Primary deployment, MVP |
| **ARM64** (aarch64)  | Supported     | Native          | ✅ Ready   | ARM-based hosts, future |
| **RISC-V** (riscv64) | Experimental  | QEMU Emulation  | ⚠️ Testing | Future compatibility    |

### Architecture Detection

The setup includes automatic architecture detection:

```bash
# Run architecture detection
./services/git-server/detect-arch.sh

# Output example:
# [INFO] AutoGit Git Server - Architecture Detection
# [SUCCESS] Detected Architecture: AMD64 (x86_64) - Native
# [INFO] Support Status: Production Ready (MVP)
# [SUCCESS] Using Dockerfile: services/git-server/Dockerfile.amd64
```

## Prerequisites

### System Requirements

**Minimum** (Development/Testing):

- **CPU**: 2 cores
- **Memory**: 4 GB RAM
- **Storage**: 60 GB
- **OS**: Linux (Docker-compatible)
- **Docker**: 20.10+ or Docker Compose V2

**Recommended** (Production):

- **CPU**: 4+ cores
- **Memory**: 8+ GB RAM
- **Storage**: 120+ GB
- **OS**: Debian 12+ or Ubuntu 22.04+
- **Docker**: Latest stable version

### Architecture-Specific Requirements

#### AMD64 (x86_64)

- Standard x86_64 processor (Intel/AMD)
- No special requirements
- Best performance

#### ARM64 (aarch64)

- ARM64 processor (e.g., Apple M1/M2, AWS Graviton, Raspberry Pi 4)
- Docker with ARM64 support
- Comparable performance to AMD64

#### RISC-V (riscv64)

- QEMU installed for emulation
- Significantly slower (10-20x) than native
- For testing/development only

## Docker Files

The Git Server setup consists of multiple Dockerfiles for different architectures:

```
services/git-server/
├── Dockerfile              # Default (AMD64, for compatibility)
├── Dockerfile.amd64        # AMD64 native (production)
├── Dockerfile.arm64        # ARM64 native
├── Dockerfile.riscv        # RISC-V QEMU emulation (experimental)
├── detect-arch.sh          # Architecture detection script
├── .env.example            # Configuration template
└── README.md               # Service documentation
```

### Dockerfile.amd64 (Production - MVP)

Primary production Dockerfile for AMD64 hosts:

- Based on `gitlab/gitlab-ce:16.11.0-ce.0`
- Includes management utilities (curl, jq, vim, htop)
- Health checks configured
- Optimized for production use

### Dockerfile.arm64 (Supported)

ARM64 native support for ARM-based hosts:

- Same base image as AMD64
- Native ARM64 execution (no emulation)
- Comparable performance to AMD64
- Available for Phase 2 deployment

### Dockerfile.riscv (Experimental)

RISC-V support via QEMU emulation:

- Uses Debian base (GitLab doesn't support RISC-V yet)
- QEMU emulation layer
- Placeholder for future compatibility
- **Not for production use**

## Configuration

### Environment Variables

Create `.env` from template:

```bash
cp services/git-server/.env.example .env
vi .env
```

Key variables:

```bash
# GitLab External URL - change to your domain
GITLAB_OMNIBUS_CONFIG=external_url "http://localhost:3000"

# Root admin password - MUST CHANGE
GITLAB_ROOT_PASSWORD=your_secure_password_here

# Port mappings
GITLAB_SSH_PORT=2222      # SSH access
GITLAB_HTTP_PORT=3000     # HTTP access
GITLAB_HTTPS_PORT=3443    # HTTPS access

# Volume configuration (optional - for bind mounts)
# GITLAB_CONFIG_VOLUME=./data/gitlab/config
# GITLAB_LOGS_VOLUME=./data/gitlab/logs
# GITLAB_DATA_VOLUME=./data/gitlab/data
```

### Volume Configuration

Three persistent volumes store GitLab data:

| Volume       | Purpose       | Size   | Contents                              |
| ------------ | ------------- | ------ | ------------------------------------- |
| `git-config` | Configuration | 1 GB   | gitlab.rb, SSL certs, secrets         |
| `git-logs`   | Logs          | 5 GB   | Application, access, error logs       |
| `git-data`   | Primary data  | 50+ GB | Repositories, artifacts, DB, registry |

**Storage Planning**:

- **Development**: 60 GB total (minimum)
- **Small team**: 120 GB total
- **Production**: 500+ GB total (with growth planning)

Rule of thumb: Plan for 3-5x your current repo size to account for CI/CD artifacts and growth.

## Building the Docker Image

### Automatic (Recommended)

Let the build system detect architecture and use appropriate Dockerfile:

```bash
# Build for current architecture
docker-compose build git-server
```

### Manual Architecture Selection

Build for specific architecture:

```bash
# Build for AMD64
docker build -f services/git-server/Dockerfile.amd64 \
  -t autogit-git-server:amd64 \
  services/git-server/

# Build for ARM64
docker build -f services/git-server/Dockerfile.arm64 \
  -t autogit-git-server:arm64 \
  services/git-server/

# Build for RISC-V (experimental)
docker build -f services/git-server/Dockerfile.riscv \
  -t autogit-git-server:riscv \
  services/git-server/
```

### Multi-Architecture Build (Future)

For building all architectures (requires buildx):

```bash
# Setup buildx (one-time)
docker buildx create --use --name autogit-builder

# Build all architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t autogit/git-server:latest \
  -f services/git-server/Dockerfile \
  services/git-server/
```

## Running the Service

### Start GitLab

```bash
# Start the service
docker-compose up -d git-server

# View logs
docker-compose logs -f git-server

# Check status
docker-compose ps git-server
```

### First Startup

First startup takes 3-5 minutes to:

1. Initialize PostgreSQL database
1. Configure GitLab services
1. Generate secrets and keys
1. Start web server

Monitor startup:

```bash
# Watch logs until you see "gitlab Reconfigured!"
docker-compose logs -f git-server
```

### Access GitLab

Once started:

- **Web UI**: http://localhost:3000
- **SSH**: `ssh://git@localhost:2222`
- **Username**: `root`
- **Password**: Value from `GITLAB_ROOT_PASSWORD` in .env

## Health Checks

GitLab includes built-in health check endpoints:

```bash
# Basic health check
curl http://localhost:3000/-/health

# Readiness check (all services ready)
curl http://localhost:3000/-/readiness

# Liveness check (service is alive)
curl http://localhost:3000/-/liveness
```

Docker health check runs automatically every 30 seconds:

- **Interval**: 30s
- **Timeout**: 10s
- **Start Period**: 180s (3 minutes)
- **Retries**: 3

Check container health:

```bash
docker inspect --format='{{.State.Health.Status}}' autogit-git-server
```

## Testing the Setup

### Verify Container is Running

```bash
# Check container status
docker ps | grep autogit-git-server

# Check health status
docker inspect autogit-git-server | jq '.[0].State.Health'

# Test health endpoint
curl -f http://localhost:3000/-/health || echo "Health check failed"
```

### Test Web Access

```bash
# Check if web UI is accessible
curl -I http://localhost:3000

# Should return HTTP 200 or 302 (redirect to login)
```

### Test SSH Access

```bash
# Check if SSH port is listening
nc -zv localhost 2222

# Should output: Connection to localhost port 2222 [tcp/*] succeeded!
```

### Architecture Verification

Verify which architecture is running:

```bash
# Check architecture label
docker inspect autogit-git-server | jq '.[0].Config.Labels.architecture'

# Should output: "amd64", "arm64", or "riscv64"
```

## Troubleshooting

### Container Won't Start

**Symptoms**: Container exits immediately or restarts continuously

**Diagnosis**:

```bash
# Check logs
docker-compose logs git-server

# Check container details
docker inspect autogit-git-server
```

**Common Causes**:

- Insufficient memory (needs 4GB+)
- Port conflicts (3000, 2222, 3443 already in use)
- Volume permission issues
- Incorrect environment variables

**Solutions**:

```bash
# Check port availability
netstat -tlnp | grep -E '3000|2222|3443'

# Free up ports if needed
# Increase Docker memory limit (Docker Desktop: Preferences > Resources)
# Fix volume permissions
sudo chown -R 998:998 ./data/gitlab  # If using bind mounts
```

### Slow Startup

**Symptoms**: Takes >10 minutes to start

**Diagnosis**:

```bash
# Monitor CPU and memory
docker stats autogit-git-server

# Watch specific log messages
docker-compose logs -f git-server | grep -i "reconfigured"
```

**Common Causes**:

- Insufficient resources
- Disk I/O bottleneck
- QEMU emulation (RISC-V)

**Solutions**:

- Allocate more CPU/memory
- Use SSD storage
- For AMD64/ARM64, ensure native execution (no emulation)

### Health Check Failing

**Symptoms**: Container shows "unhealthy" status

**Diagnosis**:

```bash
# Manual health check
docker exec autogit-git-server curl -f http://localhost/-/health

# Check GitLab services
docker exec autogit-git-server gitlab-ctl status
```

**Solutions**:

```bash
# Restart GitLab services
docker exec autogit-git-server gitlab-ctl restart

# Reconfigure GitLab
docker exec autogit-git-server gitlab-ctl reconfigure
```

### Architecture Mismatch

**Symptoms**: Container fails with "exec format error"

**Diagnosis**:

```bash
# Check host architecture
uname -m

# Check container architecture
docker inspect autogit-git-server | jq '.[0].Architecture'
```

**Solution**: Rebuild with correct architecture-specific Dockerfile:

```bash
# Detect and use correct architecture
./services/git-server/detect-arch.sh
docker-compose build git-server
```

## Upgrading GitLab

### Version Update Process

1. **Stop current container**:

   ```bash
   docker-compose stop git-server
   ```

1. **Update Dockerfile version**:

   ```dockerfile
   # In services/git-server/Dockerfile.amd64 (or appropriate arch)
   FROM gitlab/gitlab-ce:16.12.0-ce.0  # Update version
   ```

1. **Rebuild and restart**:

   ```bash
   docker-compose up -d --build git-server
   ```

1. **Verify upgrade**:

   ```bash
   docker exec autogit-git-server gitlab-rake gitlab:env:info
   ```

**Important**: Always backup before upgrading!

### Backup Before Upgrade

```bash
# Create backup
docker exec autogit-git-server gitlab-backup create

# Backups stored in: /var/opt/gitlab/backups
# Access from host via volume
```

## Performance Optimization

### AMD64 Optimization

Already optimized for production use. Consider:

- SSD storage for volumes
- Dedicated CPU cores
- 8GB+ RAM for active use

### ARM64 Optimization

Same as AMD64. ARM64 performance is comparable to AMD64 when running natively.

### RISC-V Performance

**Not recommended for production**. QEMU emulation is 10-20x slower than native execution. Use only
for:

- Compatibility testing
- Future planning
- Development experiments

## Security Considerations

### Required Security Steps

1. **Change default password**:

   ```bash
   # Set in .env before first start
   GITLAB_ROOT_PASSWORD=your_very_secure_password
   ```

1. **Enable HTTPS** (production): Configure SSL certificates in GitLab

1. **Disable signup** (optional): Set in GitLab admin settings to prevent unauthorized registrations

1. **Regular updates**: Keep GitLab CE updated with security patches

1. **Network isolation**: Use Docker networks to isolate services (already configured in
   docker-compose.yml)

### Security Checklist

- [ ] Changed `GITLAB_ROOT_PASSWORD` from default
- [ ] Configured HTTPS with valid SSL certificates (production)
- [ ] Disabled user signup (if not needed)
- [ ] Configured regular automated backups
- [ ] Network policies configured (firewall/security groups)
- [ ] Monitoring and alerting configured
- [ ] Regular security updates scheduled

## Integration Testing

### Test Script

Create `test-docker-setup.sh`:

```bash
#!/bin/bash
# Basic integration tests for GitLab setup

echo "Testing GitLab Docker Setup..."

# Test 1: Container is running
if docker ps | grep -q autogit-git-server; then
    echo "✓ Container is running"
else
    echo "✗ Container is not running"
    exit 1
fi

# Test 2: Health check passes
if curl -sf http://localhost:3000/-/health > /dev/null; then
    echo "✓ Health check passed"
else
    echo "✗ Health check failed"
    exit 1
fi

# Test 3: SSH port accessible
if nc -z localhost 2222 2>/dev/null; then
    echo "✓ SSH port accessible"
else
    echo "✗ SSH port not accessible"
    exit 1
fi

# Test 4: Web UI accessible
if curl -sf -I http://localhost:3000 | grep -q "HTTP"; then
    echo "✓ Web UI accessible"
else
    echo "✗ Web UI not accessible"
    exit 1
fi

echo "All tests passed!"
```

### Run Tests

```bash
chmod +x test-docker-setup.sh
./test-docker-setup.sh
```

## Next Steps

After Docker setup is complete:

1. **Configure Authentication** (Subtask 2):

   - Setup admin user
   - Configure user registration
   - Setup authentication policies

1. **Configure SSH Access** (Subtask 3):

   - Test SSH key management
   - Configure SSH settings
   - Document SSH usage

1. **Configure HTTP/HTTPS Access** (Subtask 4):

   - Setup SSL certificates
   - Configure reverse proxy
   - Test HTTPS access

## References

### Internal Documentation

- [Git Server README](../../services/git-server/README.md) - Service overview
- [TASK_ALLOCATION.md](../../TASK_ALLOCATION.md) - Task details
- [GIT_SERVER_FEATURE_PLAN.md](../../GIT_SERVER_FEATURE_PLAN.md) - Feature plan

### External Documentation

- [GitLab CE Documentation](https://docs.gitlab.com/ce/)
- [GitLab Installation](https://docs.gitlab.com/ce/install/)
- [GitLab Docker Installation](https://docs.gitlab.com/ce/install/docker.html)
- [GitLab Configuration](https://docs.gitlab.com/omnibus/settings/)

______________________________________________________________________

**Status**: ✅ Complete **Last Updated**: 2025-12-22 **Maintained By**: DevOps Engineer Agent
**Review Status**: Pending Evaluator review
