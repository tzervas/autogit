# Installation Guide

This guide covers installation of AutoGit across different deployment methods.

## Overview

AutoGit can be deployed using:
- Docker Compose (recommended for development)
- Kubernetes with Helm (recommended for production)
- Manual installation (advanced users)

## Quick Start with Docker Compose

```bash
git clone https://github.com/yourusername/autogit.git
cd autogit
cp .env.example .env
# Edit .env with your configuration
docker compose up -d
```

## Prerequisites

### System Requirements
- **OS**: Debian 12+, Ubuntu 22.04+, or equivalent
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 50GB free space minimum
- **CPU**: 4 cores minimum

### Software Requirements
- Docker 24.0+ or Kubernetes 1.28+
- Docker Compose 2.20+ (for Docker deployments)
- Helm 3.12+ (for Kubernetes deployments)
- kubectl (for Kubernetes deployments)

## Detailed Installation

See the following guides for detailed installation instructions:
- [Docker Compose Installation](docker-compose.md) - For development and testing
- [Kubernetes Installation](kubernetes.md) - For production deployments
- [Configuration](../configuration/README.md) - Post-installation configuration

## Next Steps

After installation:
1. Configure your environment - see [Configuration Guide](../configuration/README.md)
2. Set up runners - see [Runner Management](../runners/README.md)
3. Configure SSO (optional) - see [Security Guide](../security/README.md)

## Troubleshooting

For installation issues, see [Installation Troubleshooting](../troubleshooting/installation.md).
