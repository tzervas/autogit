# Git Server Service - GitLab CE

GitLab Community Edition (CE) integration for AutoGit platform, providing comprehensive version control and CI/CD capabilities.

## Architecture

This service runs GitLab CE 16.11.0 in a Docker container with AMD64 native support (MVP focus).

## Features

- **Repository Management**: Create, delete, and manage Git repositories
- **Git Protocol Support**: SSH (port 2222) and HTTP/HTTPS (ports 3000/3443)
- **Authentication**: Built-in user management and access control
- **CI/CD Integration**: GitLab CI/CD pipelines
- **API Access**: RESTful API for automation
- **Webhooks**: Event notifications for repository changes
- **Web UI**: Full-featured web interface

## Quick Start

1. **Copy environment configuration**:
   ```bash
   cp .env.example .env
   ```

2. **Edit .env and set secure passwords**:
   ```bash
   # Change GITLAB_ROOT_PASSWORD to a secure value
   vi .env
   ```

3. **Start the service**:
   ```bash
   docker-compose up -d git-server
   ```

4. **Wait for GitLab to initialize** (first start takes 3-5 minutes):
   ```bash
   docker-compose logs -f git-server
   ```

5. **Access GitLab**:
   - Web UI: http://localhost:3000
   - Username: `root`
   - Password: Value from `GITLAB_ROOT_PASSWORD` in .env

## Configuration

### Environment Variables

See `.env.example` for all available configuration options:

- `ARCH`: Architecture (amd64 for MVP)
- `GITLAB_ROOT_PASSWORD`: Root admin password (required)
- `GITLAB_SSH_PORT`: SSH access port (default: 2222)
- `GITLAB_HTTP_PORT`: HTTP access port (default: 3000)
- `GITLAB_HTTPS_PORT`: HTTPS access port (default: 3443)

### Volumes

GitLab data is persisted in three Docker volumes:

- `git-config`: GitLab configuration (/etc/gitlab)
- `git-logs`: GitLab logs (/var/log/gitlab)
- `git-data`: Repository data and databases (/var/opt/gitlab)

## API Endpoints

GitLab provides a comprehensive REST API. Key endpoints:

### Health Check
```bash
GET http://localhost:3000/-/health
```

### Repository Management
```bash
# List projects
GET /api/v4/projects

# Create project
POST /api/v4/projects
{
  "name": "my-project",
  "visibility": "private"
}

# Get project details
GET /api/v4/projects/:id
```

### User Management
```bash
# List users
GET /api/v4/users

# Create user
POST /api/v4/users
```

See [GitLab API Documentation](https://docs.gitlab.com/ce/api/) for complete reference.

## SSH Access

Configure SSH access for Git operations:

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Add SSH key to GitLab**:
   - Login to GitLab web UI
   - Go to User Settings > SSH Keys
   - Paste your public key (~/.ssh/id_ed25519.pub)

3. **Clone repository via SSH**:
   ```bash
   git clone ssh://git@localhost:2222/username/project.git
   ```

## HTTP/HTTPS Access

Clone repositories via HTTP:

```bash
git clone http://localhost:3000/username/project.git
```

## Resource Requirements

Minimum recommended resources:

- **CPU**: 2 cores
- **Memory**: 4 GB RAM
- **Disk**: 10 GB for application, additional space for repositories
- **Architecture**: AMD64 (x86_64)

## Health Checks

GitLab includes built-in health checks:

```bash
# Check if GitLab is ready
curl http://localhost:3000/-/health

# Check readiness
curl http://localhost:3000/-/readiness

# Check liveness
curl http://localhost:3000/-/liveness
```

## Backup and Recovery

### Manual Backup
```bash
docker exec -it autogit-git-server gitlab-backup create
```

### Restore Backup
```bash
# Stop GitLab services
docker exec -it autogit-git-server gitlab-ctl stop puma
docker exec -it autogit-git-server gitlab-ctl stop sidekiq

# Restore from backup
docker exec -it autogit-git-server gitlab-backup restore BACKUP=<timestamp>

# Restart services
docker exec -it autogit-git-server gitlab-ctl restart
```

## Troubleshooting

### GitLab is slow to start
- First startup takes 3-5 minutes to initialize databases
- Check logs: `docker-compose logs -f git-server`
- Monitor CPU and memory usage

### Cannot access web UI
- Verify port mapping: `docker-compose ps`
- Check if GitLab is healthy: `docker-compose exec git-server gitlab-ctl status`
- Review logs: `docker-compose logs git-server`

### SSH connection refused
- Verify SSH port is exposed: `docker-compose ps git-server`
- Check SSH is listening: `docker-compose exec git-server netstat -tlnp | grep 22`
- Ensure SSH key is added to your GitLab profile

### Out of memory errors
- Increase Docker memory limit
- Adjust `GITLAB_MEMORY_LIMIT` in .env
- Monitor with: `docker stats autogit-git-server`

## Security Considerations

1. **Change default passwords**: Always set a strong `GITLAB_ROOT_PASSWORD`
2. **Enable HTTPS**: Configure SSL certificates for production
3. **Disable signup**: Set `GITLAB_SIGNUP_ENABLED=false` to prevent unauthorized registrations
4. **Regular updates**: Keep GitLab CE up to date with security patches
5. **Network isolation**: Use Docker networks to isolate services
6. **Backup regularly**: Configure automated backups

## Runner Integration

To integrate with AutoGit runners:

1. **Get runner registration token**:
   - Login as admin
   - Go to Admin Area > CI/CD > Runners
   - Copy registration token

2. **Configure runner** (see runner-coordinator service)

3. **Register runner**:
   ```bash
   # This will be handled by runner-coordinator service
   ```

## Multi-Architecture Support (Future)

Current MVP focuses on AMD64 native support. Future phases will add:

- **ARM64 native**: For ARM64 hosts/runners (Phase 2)
- **ARM64 QEMU**: Emulation fallback on AMD64 hosts (Phase 2)
- **RISC-V QEMU**: Experimental support (Phase 3)

## Further Documentation

- [GitLab CE Documentation](https://docs.gitlab.com/ce/)
- [GitLab API Documentation](https://docs.gitlab.com/ce/api/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ce/ci/)
- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)

## Version

- **GitLab CE**: 16.11.0-ce.0
- **Architecture**: AMD64 native
- **Status**: Production ready (MVP)
