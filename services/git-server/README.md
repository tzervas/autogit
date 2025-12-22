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

- `GITLAB_ROOT_PASSWORD`: Root admin password (required)
- `GITLAB_SSH_PORT`: SSH access port (default: 2222)
- `GITLAB_HTTP_PORT`: HTTP access port (default: 3000)
- `GITLAB_HTTPS_PORT`: HTTPS access port (default: 3443)
- `GITLAB_CONFIG_VOLUME`: Custom path for config volume (optional, for bind mounts)
- `GITLAB_LOGS_VOLUME`: Custom path for logs volume (optional, for bind mounts)
- `GITLAB_DATA_VOLUME`: Custom path for data volume (optional, for bind mounts)

### Volumes and Data Persistence

GitLab data is persisted in three separate Docker named volumes, enabling easy version updates and container swapping:

- **git-config** (`autogit-git-config`): GitLab configuration files (/etc/gitlab)
  - Recommended size: 1 GB
  - Contains: gitlab.rb, SSL certificates, GitLab secrets
  
- **git-logs** (`autogit-git-logs`): Application and access logs (/var/log/gitlab)
  - Recommended size: 5 GB minimum
  - Contains: nginx logs, GitLab Rails logs, Sidekiq logs, PostgreSQL logs
  
- **git-data** (`autogit-git-data`): Primary storage for all repository content (/var/opt/gitlab)
  - **Recommended size: 50 GB minimum** (100+ GB for active teams, 500+ GB for large orgs)
  - Contains:
    - Git repositories and repository data
    - CI/CD artifacts and job logs
    - Container registry images
    - Package registry data
    - File uploads and attachments
    - GitLab Pages content
    - LFS (Large File Storage) objects
    - Database files (PostgreSQL)
    - Redis persistence

#### Volume Configuration Options

**Option 1: Named Volumes (Default, Recommended)**
Named volumes provide the best persistence and version update compatibility. Data persists independently of the container:
```bash
# Uses Docker-managed named volumes (default)
docker-compose up -d
```

**Option 2: Bind Mounts (Advanced)**
For direct filesystem access, set volume paths in `.env`:
```bash
GITLAB_CONFIG_VOLUME=./data/gitlab/config
GITLAB_LOGS_VOLUME=./data/gitlab/logs
GITLAB_DATA_VOLUME=./data/gitlab/data
```

#### Upgrading GitLab Versions

The separate volume design enables zero-data-loss version updates:

1. Stop current GitLab container:
   ```bash
   docker-compose stop git-server
   ```

2. Update GitLab version in Dockerfile:
   ```dockerfile
   FROM gitlab/gitlab-ce:16.12.0-ce.0  # Update version
   ```

3. Rebuild and start with existing volumes:
   ```bash
   docker-compose up -d --build git-server
   ```

All data (repositories, artifacts, configuration) persists across version updates.

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

- **CPU**: 2 cores (4+ cores recommended for production)
- **Memory**: 4 GB RAM minimum (8+ GB recommended for production)
- **Disk Space**:
  - **GitLab Application**: 2.5 GB for GitLab binaries and dependencies
  - **Configuration Volume**: 1 GB for config files and secrets
  - **Logs Volume**: 5 GB minimum for application logs with rotation
  - **Data Volume**: **50 GB minimum** for repositories and artifacts
    - 100+ GB recommended for active development teams
    - 500+ GB recommended for large organizations with extensive CI/CD, container registry, and package registry usage
  - **Total Minimum**: ~60 GB (10 GB comfortable padding for system overhead)
  - **Production Recommended**: 120+ GB total
- **Architecture**: AMD64 (x86_64)

### Storage Growth Planning

The data volume (`git-data`) will grow based on:
- Number and size of Git repositories
- CI/CD artifacts and job logs retention
- Container registry images
- Package registry usage
- File uploads and LFS objects

**Rule of thumb**: Plan for 3-5x your current repository size to account for CI/CD artifacts, registry data, and growth over 12 months.

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

## Monitoring Volume Usage

Monitor disk space usage to prevent storage issues:

### Check Docker Volume Usage
```bash
# List all volumes with sizes
docker system df -v

# Inspect specific volume
docker volume inspect autogit-git-data

# Check volume usage from within container
docker exec -it autogit-git-server df -h /var/opt/gitlab
docker exec -it autogit-git-server df -h /etc/gitlab
docker exec -it autogit-git-server df -h /var/log/gitlab
```

### Monitor Storage from GitLab Admin
1. Login as admin
2. Go to **Admin Area > Monitoring > System Info**
3. View disk space usage by component

### Disk Usage Breakdown
Check what's consuming space in the data volume:
```bash
docker exec -it autogit-git-server du -sh /var/opt/gitlab/*
```

Common space consumers:
- `/var/opt/gitlab/git-data/repositories` - Git repositories
- `/var/opt/gitlab/gitlab-rails/shared/artifacts` - CI/CD artifacts
- `/var/opt/gitlab/gitlab-rails/shared/lfs-objects` - LFS objects
- `/var/opt/gitlab/gitlab-rails/shared/packages` - Package registry
- `/var/opt/gitlab/gitlab-rails/shared/registry` - Container registry

### Storage Cleanup

Clean up old artifacts and reduce storage:
```bash
# Clean up old CI artifacts (older than 30 days)
docker exec -it autogit-git-server gitlab-rake gitlab:cleanup:orphan_job_artifact_files

# Clean up orphaned LFS files
docker exec -it autogit-git-server gitlab-rake gitlab:cleanup:orphan_lfs_files

# Prune old container logs
docker exec -it autogit-git-server gitlab-ctl registry-garbage-collect
```

### Extending Volume Storage

If you need more space:

**Option 1: Extend underlying disk** (if using bind mounts)
Expand the host filesystem where volumes are stored.

**Option 2: Migrate to larger volume**
```bash
# Create new larger volume
docker volume create --name autogit-git-data-new

# Stop GitLab
docker-compose stop git-server

# Copy data to new volume
docker run --rm -v autogit-git-data:/from -v autogit-git-data-new:/to alpine sh -c "cd /from && cp -av . /to"

# Update docker-compose.yml to use new volume
# Restart GitLab
docker-compose up -d git-server
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
