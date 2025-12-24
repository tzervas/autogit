# AutoGit Dynamic Runner System - Complete Guide

## 🎯 Overview

AutoGit provides **fully autonomous, zero-footprint CI/CD runners** that:
- ✅ **Spawn automatically** when GitLab jobs are queued
- ✅ **Register themselves** with GitLab without manual intervention
- ✅ **Execute jobs** in isolated containers
- ✅ **Clean up automatically** after a cooldown period
- ✅ **Zero footprint** when idle - only the coordinator runs

## 🔑 First-Time Login Information

### GitLab Web UI

```
URL:      http://192.168.1.170:3000
Username: root
Password: CHANGE_ME_SECURE_PASSWORD (from GITLAB_ROOT_PASSWORD env var)
```

**Important Links:**
- Projects: http://192.168.1.170:3000/dashboard/projects
- Admin Area: http://192.168.1.170:3000/admin
- CI/CD Runners: http://192.168.1.170:3000/admin/runners
- Access Tokens: http://192.168.1.170:3000/-/user_settings/personal_access_tokens

### Runner Coordinator API

```
Health:   http://192.168.1.170:8080/health
Status:   http://192.168.1.170:8080/status
Runners:  http://192.168.1.170:8080/runners
```

## 📋 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         GitLab CE                            │
│  (Git Server + CI/CD Orchestrator + Job Queue)              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Polls for pending jobs every 10s
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Runner Coordinator (Always On)                  │
│  • Monitors GitLab for pending jobs                         │
│  • Spawns runners on-demand                                 │
│  • Registers runners with GitLab                            │
│  • Monitors runner health                                   │
│  • Cleans up idle runners after cooldown                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Spawns/manages as needed
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           Dynamic Runners (Created on Demand)                │
│  • runner-abc123 (AMD64, no GPU)                            │
│  • runner-def456 (ARM64, no GPU)                            │
│  • runner-xyz789 (AMD64, NVIDIA GPU)                        │
│  [... spawned as jobs arrive ...]                           │
│  [... cleaned up after cooldown ...]                        │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Automated Setup

```bash
# Run first-time setup (provides login info and configures system)
bash scripts/first-time-setup.sh

# This will:
# - Show GitLab login credentials
# - Create personal access token
# - Configure runner registration
# - Save all config to files
```

### 2. Manual Verification

```bash
# Check services are running
bash scripts/check-homelab-status.sh

# Verify coordinator is healthy
curl http://192.168.1.170:8080/health

# Check current runners (should be empty when idle)
curl http://192.168.1.170:8080/runners | jq

# View system status
curl http://192.168.1.170:8080/status | jq
```

### 3. Test Dynamic Runners

```bash
# Load helper functions
source scripts/gitlab-helpers.sh

# Trigger a test pipeline
gitlab-trigger

# Watch runners spawn in real-time
watch -n 2 'curl -s http://192.168.1.170:8080/runners | jq'

# In another terminal, watch containers
watch -n 2 'ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter name=autogit-runner"'
```

## 🔧 Configuration

### Environment Variables

The runner coordinator accepts these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `GITLAB_URL` | `http://autogit-git-server:3000` | GitLab instance URL |
| `GITLAB_TOKEN` | (none) | Personal access token for API access |
| `GITLAB_RUNNER_REGISTRATION_TOKEN` | (none) | Token for registering new runners |
| `RUNNER_COOLDOWN_MINUTES` | `5` | Minutes to wait before cleaning up idle runners |
| `MAX_IDLE_RUNNERS` | `0` | Number of runners to keep warm (0 = pure zero-footprint) |

### Configuration Files

After setup, these files contain your configuration:

- **`.env.gitlab`** - GitLab API credentials
- **`.env.runner`** - Runner registration token
- **`.autogit_login_info`** - WebUI login credentials
- **`~/.autogit_gitlab_token`** - Personal access token (keep secure!)

### Customizing Behavior

Edit `docker-compose.yml` to change coordinator settings:

```yaml
services:
  runner-coordinator:
    environment:
      - RUNNER_COOLDOWN_MINUTES=10  # Wait 10 minutes before cleanup
      - MAX_IDLE_RUNNERS=2          # Keep 2 runners warm for faster response
```

Then restart:
```bash
docker compose up -d runner-coordinator
```

## 📊 Monitoring

### Real-Time Monitoring

```bash
# Watch runner lifecycle
watch -n 2 'curl -s http://192.168.1.170:8080/runners | jq'

# Watch containers
watch -n 2 'ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter name=autogit"'

# Follow coordinator logs
ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker logs -f autogit-runner-coordinator'
```

### Status Checks

```bash
# Coordinator health
curl http://192.168.1.170:8080/health

# System status
curl http://192.168.1.170:8080/status | jq

# Active runners
curl http://192.168.1.170:8080/runners | jq

# GitLab pipelines
source .env.gitlab
curl --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "http://192.168.1.170:3000/api/v4/projects/1/pipelines" | jq
```

## 🔄 Lifecycle Explained

### 1. Idle State (Zero Footprint)
```
Only running: autogit-git-server, autogit-runner-coordinator
Runners: 0
Containers: 2
```

### 2. Job Arrives
```
GitLab: Job queued → pending
Coordinator: Detects pending job (within 10 seconds)
Action: Spawns runner container
Time: ~5-15 seconds
```

### 3. Runner Registration
```
Coordinator: Registers runner with GitLab
Runner: Starts gitlab-runner service
GitLab: Marks runner as available
Status: Runner shows as "idle"
```

### 4. Job Execution
```
GitLab: Assigns job to runner
Runner: Executes job in isolated container
Status: Runner shows as "busy"
Duration: Varies by job
```

### 5. Job Complete
```
Runner: Reports completion to GitLab
Status: Runner transitions to "idle"
Cooldown: Timer starts (default: 5 minutes)
```

### 6. Cleanup
```
Coordinator: Detects runner idle past cooldown
Action:
  1. Unregisters runner from GitLab
  2. Stops container
  3. Removes container
  4. Removes database entry
Result: Zero footprint restored
```

## 🛠️ Troubleshooting

### No Runners Spawning

**Check coordinator logs:**
```bash
ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker logs autogit-runner-coordinator' | grep -i error
```

**Common issues:**
- `GITLAB_TOKEN` not set → No API access to poll for jobs
- `GITLAB_RUNNER_REGISTRATION_TOKEN` not set → Can't register new runners
- Network issues → Check `docker network ls` includes `autogit-network`

**Fix:**
```bash
# Regenerate tokens and reconfigure
bash scripts/setup-gitlab-automation.sh
bash scripts/first-time-setup.sh
```

### Runners Not Cleaning Up

**Check cooldown setting:**
```bash
curl http://192.168.1.170:8080/status | jq .cooldown_minutes
```

**Force cleanup manually:**
```bash
ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps -a --filter "name=autogit-runner" -q | xargs docker rm -f'
```

### GitLab Jobs Stay Pending

**Verify runner registration token:**
1. Login to GitLab: http://192.168.1.170:3000
2. Go to Admin Area → CI/CD → Runners
3. Check if runners appear (even if offline)
4. Copy the registration token
5. Update environment:
```bash
echo "GITLAB_RUNNER_REGISTRATION_TOKEN=your_token_here" >> .env.runner
```

### Database Issues

**Reset coordinator database:**
```bash
ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec autogit-runner-coordinator rm /app/runner_coordinator.db'
ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker restart autogit-runner-coordinator'
```

## 📚 Advanced Usage

### Warm Runner Pool

Keep runners ready for instant job pickup:

```yaml
# docker-compose.yml
environment:
  - MAX_IDLE_RUNNERS=2  # Keep 2 runners warm
```

Trade-off: Faster job start vs. higher resource usage

### Architecture-Specific Runners

Coordinator automatically spawns runners matching job requirements:

```yaml
# .gitlab-ci.yml
job:amd64:
  script: echo "Running on AMD64"
  tags: [docker, amd64]

job:arm64:
  script: echo "Running on ARM64"
  tags: [docker, arm64]
```

### GPU-Accelerated Runners

```yaml
job:gpu:
  script: nvidia-smi
  tags: [docker, gpu, nvidia]
```

Coordinator detects GPU requirement and spawns runner with GPU access.

## 🔐 Security Considerations

### Tokens

- **Personal Access Token** (`.env.gitlab`) - API access, keep secure
- **Runner Registration Token** (`.env.runner`) - Register new runners, rotate periodically
- **Files** - All credential files have `chmod 600` (owner read/write only)

### Runner Isolation

- Runners execute in isolated Docker containers
- Network: `autogit-network` (isolated bridge network)
- Capabilities: Minimal (`CAP_CHOWN`, `CAP_SETUID`, `CAP_SETGID` only)
- Security options: `no-new-privileges:true`

### Best Practices

1. **Change default password** immediately after first login
2. **Enable 2FA** for root account in GitLab
3. **Rotate tokens** regularly (every 90 days)
4. **Monitor logs** for suspicious activity
5. **Keep system updated** - rebuild images periodically

## 📖 Additional Resources

- **Dynamic Runner Testing:** `docs/runners/dynamic-runner-testing.md`
- **Example CI Config:** `.gitlab-ci.example.yml`
- **GitLab API Docs:** https://docs.gitlab.com/ee/api/
- **GitLab Runner Docs:** https://docs.gitlab.com/runner/

## ✅ Success Criteria

Your dynamic runner system is working correctly when:

- ✅ Zero runners exist when no jobs are queued
- ✅ Runners spawn within 30 seconds of job trigger
- ✅ Jobs execute successfully
- ✅ Runners clean up after cooldown period
- ✅ No manual intervention required
- ✅ System recovers from failures automatically

## 🎉 You're All Set!

Your AutoGit instance now has:
- ✅ Fully autonomous runner management
- ✅ Zero-footprint when idle
- ✅ Automatic spawning and cleanup
- ✅ Complete lifecycle management
- ✅ No manual runner registration needed

**Start using it:**
```bash
# Login and create your first project
open http://192.168.1.170:3000

# Or trigger a test
source scripts/gitlab-helpers.sh
gitlab-trigger
```

Happy automating! 🚀
