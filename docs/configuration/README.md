# Configuration Guide

This guide covers configuration options for AutoGit.

## Overview

AutoGit uses a combination of:
- Environment variables for secrets and deployment-specific settings
- YAML configuration files for structural configuration
- Runtime configuration through the web interface

## Configuration Files

### Environment Variables

Key environment variables (set in `.env` file):

```bash
# GitLab Configuration
GITLAB_ROOT_PASSWORD=<secure-password>
GITLAB_EXTERNAL_URL=https://gitlab.yourdomain.com

# Runner Configuration
RUNNER_REGISTRATION_TOKEN=<token-from-gitlab>
RUNNER_EXECUTOR=docker

# SSO Configuration (optional)
AUTHELIA_JWT_SECRET=<secure-secret>
AUTHELIA_SESSION_SECRET=<secure-secret>

# Database Configuration
POSTGRES_PASSWORD=<secure-password>
REDIS_PASSWORD=<secure-password>
```

### YAML Configuration

Main configuration file: `config/config.yml`

See [config.yml reference](config-yml.md) for detailed options.

## Component Configuration

- [Git Server Configuration](git-server.md)
- [Runner Configuration](runners.md)
- [GPU Configuration](gpu.md)
- [SSO Configuration](sso.md)
- [Network Configuration](network.md)

## Security Considerations

See [Security Configuration](../security/README.md) for security-related configuration.

## Next Steps

- [Operations Guide](../operations/README.md) - Day-to-day operations
- [Monitoring Setup](../operations/monitoring.md) - Set up monitoring
