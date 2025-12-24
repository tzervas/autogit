# Dynamic Runner Testing Guide

This guide walks through testing the AutoGit dynamic runner system that automatically spawns and culls runners based on demand.

## System Overview

The AutoGit dynamic runner system consists of:

1. **GitLab CE** - Git server and CI/CD orchestrator
2. **Runner Coordinator** - FastAPI service that manages runner lifecycle
3. **Dynamic Runners** - Docker containers spawned on-demand for CI/CD jobs

## How Dynamic Runners Work

### Automatic Spawning

When a GitLab CI/CD pipeline is triggered:

1. GitLab webhook notifies the Runner Coordinator
2. Coordinator checks for available idle runners
3. If no suitable runner exists, a new one is spawned
4. Runner registers with GitLab and picks up the job
5. Job executes in an isolated container

### Automatic Cleanup

After job completion:

1. Runner reports completion to Coordinator
2. Runner enters "idle" state with cooldown timer
3. After cooldown period (default: 5 minutes), runner is terminated
4. Container is removed to free resources

## Testing Prerequisites

### 1. Verify Services Are Running

```bash
# Check homelab status
bash scripts/check-homelab-status.sh

# Verify containers
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter 'name=autogit'"
```

Expected output:
- `autogit-git-server` - Up and healthy
- `autogit-runner-coordinator` - Up and healthy

### 2. Access GitLab Web UI

1. Navigate to: `http://192.168.1.170:3000`
2. Login as `root` with your configured password
3. If first login, check environment variable: `GITLAB_ROOT_PASSWORD`

### 3. Create Personal Access Token

1. In GitLab: **User Settings** → **Access Tokens**
2. Create token with scopes:
   - `api`
   - `read_api`
   - `write_repository`
3. Save the token securely

## Test Scenario 1: Simple CI Pipeline

### Step 1: Create Test Project

```bash
# Using GitLab API
export GITLAB_URL="http://192.168.1.170:3000"
export GITLAB_TOKEN="your_token_here"

curl --request POST \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "runner-test",
    "visibility": "private",
    "initialize_with_readme": true
  }' \
  "${GITLAB_URL}/api/v4/projects"
```

### Step 2: Add CI Configuration

Create `.gitlab-ci.yml`:

```yaml
stages:
  - test
  - build

# Simple test job
test:hello:
  stage: test
  script:
    - echo "Hello from AutoGit dynamic runner!"
    - echo "Runner: ${CI_RUNNER_DESCRIPTION}"
    - echo "Job ID: ${CI_JOB_ID}"
    - echo "Pipeline ID: ${CI_PIPELINE_ID}"
  tags:
    - autogit
    - docker

# CPU-intensive job
test:load:
  stage: test
  script:
    - echo "Testing CPU load..."
    - dd if=/dev/zero of=/dev/null bs=1M count=1000
    - echo "Load test complete"
  tags:
    - autogit
    - docker

# Parallel jobs to test multiple runners
test:parallel:1:
  stage: build
  script:
    - echo "Parallel job 1 running"
    - sleep 30
  tags:
    - autogit

test:parallel:2:
  stage: build
  script:
    - echo "Parallel job 2 running"
    - sleep 30
  tags:
    - autogit

test:parallel:3:
  stage: build
  script:
    - echo "Parallel job 3 running"
    - sleep 30
  tags:
    - autogit
```

### Step 3: Monitor Runner Creation

In one terminal, watch runners:

```bash
# Monitor runners in real-time
watch -n 2 'curl -s http://192.168.1.170:8080/runners | jq'

# Or monitor Docker containers
watch -n 2 'ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter name=autogit-runner"'
```

### Step 4: Trigger Pipeline

```bash
# Push a commit to trigger CI
cd runner-test
git add .gitlab-ci.yml
git commit -m "Add CI configuration"
git push origin main

# Or trigger via API
curl --request POST \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "${GITLAB_URL}/api/v4/projects/<project_id>/trigger/pipeline" \
  --form ref=main
```

### Step 5: Observe Dynamic Behavior

You should see:

1. **Spawning Phase** (within 10-30 seconds)
   - New `autogit-runner-*` containers appear
   - Coordinator logs show runner registration
   - Runners appear in `curl http://192.168.1.170:8080/runners`

2. **Execution Phase**
   - Jobs execute in parallel across multiple runners
   - Each runner handles one job at a time
   - GitLab UI shows job progress

3. **Cooldown Phase** (after jobs complete)
   - Runners enter "idle" state
   - Cooldown timer starts (5 minutes default)

4. **Cleanup Phase** (after cooldown)
   - Idle runners are terminated
   - Containers are removed
   - Only coordinator remains running

## Test Scenario 2: Architecture-Specific Runners

Test spawning runners for different architectures:

```yaml
# .gitlab-ci.yml
test:amd64:
  stage: test
  script:
    - uname -m
    - echo "Running on AMD64 architecture"
  tags:
    - autogit
    - amd64

test:arm64:
  stage: test
  script:
    - uname -m
    - echo "Running on ARM64 architecture"
  tags:
    - autogit
    - arm64
```

## Test Scenario 3: GPU-Accelerated Jobs

Test GPU runner spawning (requires NVIDIA GPU):

```yaml
# .gitlab-ci.yml
test:gpu:
  stage: test
  script:
    - nvidia-smi
    - python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
  tags:
    - autogit
    - gpu
    - nvidia
```

## Monitoring and Debugging

### Check Runner Coordinator Logs

```bash
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker logs -f autogit-runner-coordinator"
```

Look for:
- `Dispatching job X for project Y`
- `Runner registered successfully`
- `Runner X finished, tearing down`
- `Job X assigned to runner Y`

### Check Runner Logs

```bash
# List active runners
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter 'name=autogit-runner'"

# View specific runner logs
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker logs autogit-runner-<id>"
```

### API Endpoints

```bash
# Health check
curl http://192.168.1.170:8080/health

# List active runners
curl http://192.168.1.170:8080/runners | jq

# System status
curl http://192.168.1.170:8080/status | jq
```

### Database Inspection

The coordinator uses SQLite to track jobs and runners:

```bash
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec autogit-runner-coordinator sqlite3 /app/runner_coordinator.db 'SELECT * FROM runners;'"

ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec autogit-runner-coordinator sqlite3 /app/runner_coordinator.db 'SELECT * FROM jobs;'"
```

## Expected Behavior

### ✅ Successful Dynamic Runner Operation

- Runners spawn within 10-30 seconds of job trigger
- Multiple runners spawn for parallel jobs
- Jobs execute successfully
- Runners remain idle for cooldown period
- Runners are cleaned up after cooldown
- No orphaned containers remain

### ❌ Common Issues

**Problem**: Runners don't spawn
- Check coordinator logs for errors
- Verify Docker socket is accessible
- Check network connectivity

**Problem**: Runners spawn but don't pick up jobs
- Verify runner registration with GitLab
- Check runner tags match job requirements
- Ensure GitLab can reach runners

**Problem**: Runners never cleanup
- Check coordinator background task is running
- Verify cleanup logic in `job_manager.py`
- Check Docker API connectivity

## Performance Metrics

Track these metrics during testing:

- **Spawn Time**: Time from job trigger to runner ready (target: <30s)
- **Cleanup Time**: Time from idle to removed (default: 5 minutes)
- **Concurrent Runners**: Number of runners active simultaneously
- **Resource Usage**: CPU, memory, disk per runner
- **Success Rate**: Percentage of successful job executions

## Configuration Tuning

### Adjust Cooldown Period

Edit `services/runner-coordinator/app/job_manager.py`:

```python
# Change cooldown check logic
COOLDOWN_SECONDS = 300  # 5 minutes default
```

### Adjust Resource Limits

Edit `services/runner-coordinator/app/driver.py`:

```python
# Modify spawn_runner() parameters
cpu_limit=2.0,      # CPU cores
mem_limit="2g",     # Memory limit
```

### Adjust Polling Frequency

Edit `services/runner-coordinator/app/job_manager.py`:

```python
# In process_queue()
await asyncio.sleep(5)  # Poll every 5 seconds
```

## Next Steps

After successful testing:

1. **Monitor production workloads**
   - Track runner creation patterns
   - Optimize cooldown periods
   - Adjust resource limits

2. **Add metrics and alerting**
   - Prometheus/Grafana integration
   - Alert on spawn failures
   - Track resource utilization

3. **Implement advanced features**
   - Runner pooling (keep N idle runners warm)
   - Priority queues
   - Cost optimization
   - Multi-architecture support

## Troubleshooting Commands

```bash
# Full system check
bash scripts/check-homelab-status.sh

# Restart coordinator
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker restart autogit-runner-coordinator"

# View coordinator health
curl http://192.168.1.170:8080/health

# Clean up orphaned runners manually
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps -a --filter 'name=autogit-runner' --filter 'status=exited' -q | xargs docker rm"

# Reset coordinator database
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker exec autogit-runner-coordinator rm /app/runner_coordinator.db"
ssh homelab "DOCKER_HOST=unix:///run/user/1000/docker.sock docker restart autogit-runner-coordinator"
```

## Success Criteria

The dynamic runner system is working correctly when:

✅ Runners automatically spawn when jobs are queued
✅ Multiple runners spawn for parallel jobs
✅ Runners execute jobs successfully
✅ Runners automatically cleanup after cooldown
✅ No manual intervention required
✅ System recovers from failures gracefully
✅ Resource usage is optimized (no idle runners consuming resources)

## Additional Resources

- [Runner Coordinator API Documentation](../api/runner-coordinator.md)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Docker SDK for Python](https://docker-py.readthedocs.io/)
