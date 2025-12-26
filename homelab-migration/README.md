# Homelab GitLab Configuration

This directory contains scripts to configure and manage a self-hosted GitLab instance
programmatically.

## Quick Start - Fresh Deployment

For a completely fresh GitLab setup with automatic repository mirroring:

### Option 1: Automated (Recommended)

```bash
# Configure your tokens in .env file, then:
./setup-optimized.sh
```

### Option 2: Manual Configuration

```bash
# 1. Deploy fresh GitLab instance
export GITLAB_URL="https://gitlab.vectorweight.com"
./deploy-fresh.sh

# 2. Configure users and tokens (after GitLab is ready)
export GITLAB_ROOT_TOKEN="your-initial-root-token"
uv run python configure-gitlab-fresh.py

# 3. Set up repository mirroring
export GITHUB_PAT_MIRROR="your-github-token"
export GITLAB_PAT_MIRROR="your-gitlab-token"
uv run python setup-mirroring.py

# 4. Configure CLI authentication
./setup-cli-auth.sh
```

## Environment Configuration

### `.env` File Setup

Create a `.env` file in the project root with your configuration:

```bash
# Copy and edit the template
cp .env.example .env

# Edit with your values
nano .env
```

**Required Variables:**

```bash
# GitLab Configuration
GITLAB_URL=https://gitlab.vectorweight.com

# API Tokens for Repository Mirroring
GITHUB_PAT_MIRROR=your_github_token_here
GITLAB_PAT_MIRROR=your_gitlab_token_here

# GitLab Root Token (obtained during initial setup)
GITLAB_ROOT_TOKEN=your_root_token_here
```

**Optional Variables:**

```bash
# Deployment Configuration
DOCKER_COMPOSE_COMMAND="sudo docker compose"
SSL_CERT_DIR="./data/gitlab/ssl"
DATA_DIR="./data"

# Performance Settings
GITLAB_WORKER_PROCESSES=2
GITLAB_SIDEKIQ_CONCURRENCY=5
```

### Automatic Environment Loading

All setup scripts automatically load the `.env` file if present, eliminating the need for manual
token entry.

### Security Features

- **Token Sanitization:** All logs and output automatically mask sensitive tokens
- **No Token Storage:** Scripts never write tokens to log files
- **Environment Isolation:** Tokens only exist in memory during execution
- **Safe Logging:** Monitoring outputs are sanitized before logging

**Example Output:**

```
🌐 GitLab URL: https://gitlab.vectorweight.com
🐙 GitHub Token: github_pat_1...***
🦊 GitLab Token: glpat-***...***
```

## Performance Monitoring & Optimization

### `monitor-deployment.sh`

Comprehensive deployment monitoring script that captures logs, metrics, and timing data.

**Captures:**

- System resources (CPU, memory, disk I/O, network)
- Docker container logs in real-time
- Deployment phase timings
- GitLab health status

**Usage:**

```bash
# Run in parallel with deployment
./monitor-deployment.sh
```

**Output:**

- `deployment-logs/deployment_monitor_TIMESTAMP.log`: Detailed logs
- `deployment-logs/deployment_metrics_TIMESTAMP.csv`: CSV metrics data

### `analyze-deployment.sh`

Analyzes monitoring data to identify bottlenecks and suggest optimizations.

**Features:**

- Phase timing analysis
- Resource usage patterns
- Error detection
- Optimization recommendations

**Usage:**

```bash
./analyze-deployment.sh
```

### `setup-optimized.sh`

Performance-optimized deployment script with parallel processing and pre-optimizations.

**Optimizations:**

- Pre-pulls Docker images
- Parallel task execution
- Pre-generates SSL certificates
- Enhanced progress reporting
- Reduced deployment time

**Usage:**

```bash
export GITHUB_PAT_MIRROR="your-github-token"
export GITLAB_PAT_MIRROR="your-gitlab-token"
./setup-optimized.sh
```

## Performance Optimization Strategies

### Common Bottlenecks & Solutions

1. **Docker Image Downloads (5-10 minutes)**

   - **Solution:** Pre-pull images: `sudo docker pull gitlab/gitlab-ce:latest`
   - **Impact:** Saves 5-8 minutes on first deployment

1. **SSL Certificate Generation (10-30 seconds)**

   - **Solution:** Pre-generate certificates before deployment
   - **Impact:** Saves 20-30 seconds per deployment

1. **GitLab Initialization (3-8 minutes)**

   - **Solution:** Optimize GitLab configuration for faster startup
   - **Impact:** Can reduce initialization time by 50%

1. **Repository Mirroring (2-5 minutes)**

   - **Solution:** Parallel processing of mirror setup
   - **Impact:** Reduces setup time by 60%

### Monitoring Best Practices

1. **Always monitor deployments** to identify new bottlenecks
1. **Compare metrics** between deployments to measure improvements
1. **Focus on the slowest phases** for maximum impact
1. **Test optimizations** in a staging environment first

### Expected Performance Targets

- **Total deployment time:** < 10 minutes (optimized)
- **SSL generation:** < 5 seconds
- **Container startup:** < 30 seconds
- **GitLab health check:** < 3 minutes
- **Repository mirroring:** < 2 minutes

### `deploy-fresh.sh`

Deploys a fresh, optimized GitLab CE instance with Docker Compose.

**Features:**

- Optimized for homelab use (reduced resource usage)
- Automatic health checks
- GitLab Runner included
- Persistent data storage
- Initial root password retrieval

**Usage:**

```bash
export GITLAB_URL="http://homelab:8080"  # Optional
./deploy-fresh.sh
```

### `configure-gitlab-fresh.py`

Sets up users, groups, and access tokens for repository mirroring.

**Creates:**

- `ci-user`: For automated repository operations
- `admin`: For administrative tasks
- `projects` group: Container for mirrored repositories
- Scoped access tokens with minimal permissions

**Usage:**

```bash
export GITLAB_ROOT_TOKEN="initial-root-token"
uv run python configure-gitlab-fresh.py
```

**Outputs:**

- `gitlab-fresh-config.json`: Complete configuration with tokens
- Prints access tokens (save securely!)

### `setup-mirroring.py`

Automatically creates mirrors of all your public repositories.

**Mirrors:**

- All public GitHub repositories from `tzervas`
- All GitLab repositories from `vector_weight`
- Creates projects in the `projects` group

**Requirements:**

- GitHub personal access token with `repo` scope
- GitLab personal access token with `read_repository` scope

**Usage:**

```bash
export GITHUB_TOKEN="github-token"
export GITLAB_MIRROR_TOKEN="gitlab-token"
uv run python setup-mirroring.py
```

**Outputs:**

- `repository-mirrors.json`: Mirror configuration and status

### `setup-cli-auth.sh`

Configures local CLI tools to authenticate with GitLab.

**Configures:**

- Git credential helper
- GitLab CLI (glab) if installed
- Tests authentication

**Usage:**

```bash
./setup-cli-auth.sh
```

## Legacy Scripts (Backup/Restore)

### `configure-gitlab.py`

Configures users, groups, roles, and scoped tokens in GitLab.

**Usage:**

```bash
export GITLAB_URL="http://192.168.1.170:3000"
export GITLAB_TOKEN="your-root-token"
uv run python homelab-gitlab/configure-gitlab.py
```

**What it does:**

- Creates users: `ci-user`, `admin-user`
- Creates groups: `debian-sid`
- Assigns roles
- Generates scoped PATs for CI and admin operations
- Saves config to `gitlab-config.json`

**Security Notes:**

- Uses root token for initial setup
- Creates minimal-scoped tokens for operations
- Outputs tokens once (store securely)

### `backup-gitlab.sh`

Creates full GitLab backup including configuration and data.

**Usage (on GitLab server):**

```bash
export GITLAB_TOKEN="admin-token"
export GPG_PASSPHRASE="your-secure-passphrase"
sudo ./backup-gitlab.sh [backup-name]
```

**Features:**

- Exports configuration via API
- Creates GitLab data backup
- **Secure backup of sensitive files** (gitlab.rb, gitlab-secrets.json) with GPG encryption
- Compresses for efficient storage
- Maintains backup registry
- Auto-cleans old backups (keeps last 5)

**Security Features:**

- Sensitive configuration files are encrypted with AES256
- Encryption passphrase required via `GPG_PASSPHRASE` environment variable
- Encrypted files stored as `.gpg` files in config directory

### `run-gitlab-backup.sh`

Orchestrates backup from local machine via SSH.

**Usage:**

```bash
export GITLAB_TOKEN="admin-token"
export GPG_PASSPHRASE="your-secure-passphrase"  # Optional: enables secure backup of sensitive files
export GITLAB_SERVER="homelab"  # optional
export SSH_USER="spooky"        # optional
./run-gitlab-backup.sh [backup-name]
```

### `decrypt-sensitive-files.sh`

Decrypts sensitive GitLab configuration files from encrypted backup.

**Usage (on GitLab server):**

```bash
export GPG_PASSPHRASE="your-secure-passphrase"
./decrypt-sensitive-files.sh <backup-name> <output-dir>
```

**Example:**

```bash
export GPG_PASSPHRASE="my-secret-passphrase"
./decrypt-sensitive-files.sh 20231225_143022 /tmp/gitlab-restore
```

**Features:**

- Decrypts gitlab.rb and gitlab-secrets.json from GPG-encrypted backups
- Sets secure permissions (600) on decrypted files
- Warns about secure deletion after use

## Backup Strategy

**Naming Convention:**

- Automatic: `YYYYMMDD_HHMMSS` (e.g., `20231225_143022`)
- Custom: Any string (e.g., `pre-upgrade`, `v1.0`)

**Storage:**

- Config exports: `/var/opt/gitlab/backups/config/`
- Data backups: `/var/opt/gitlab/backups/` (compressed)
- Registry: `/var/opt/gitlab/backups/backups.json`

**Retention:**

- Keeps last 5 backups automatically
- Compressed for efficiency
- Includes metadata for restore verification

## Workflow

1. **Initial Setup:** Run `configure-gitlab.py` with root token to create users/tokens
1. **Switch to Scoped Tokens:** Use generated tokens for future operations
1. **Regular Backups:** Run `run-gitlab-backup.sh` weekly/monthly
1. **Export Config:** Run `export-gitlab-config.py` for config-only backup
1. **Restore if Needed:** Use `restore-gitlab.sh` with backup name

## Threat Model

- **Root Token:** Used only for initial setup, then discarded
- **Scoped Tokens:** Minimal permissions per operation
- **Sensitive Files:** Encrypted with GPG AES256 during backup
- **Auditability:** All operations logged in GitLab
- **Idempotent:** Scripts can be run multiple times safely

## Files

- `configure-gitlab.py`: Setup script
- `export-gitlab-config.py`: Config export
- `backup-gitlab.sh`: Full backup (server-side)
- `run-gitlab-backup.sh`: Backup orchestrator (local)
- `restore-gitlab.sh`: Restore script
- `decrypt-sensitive-files.sh`: Decrypt sensitive files from backup
- `README.md`: This documentation
- `gitlab-config.json`: Generated user/group config
- `gitlab-*.json`: Exported configuration files
