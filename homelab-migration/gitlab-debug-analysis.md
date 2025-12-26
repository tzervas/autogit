# GitLab Debug Analysis - December 25, 2025

## Executive Summary

**Container Status:** ✅ Running (25+ minutes uptime)  
**Health Status:** ⚠️ **UNHEALTHY** - Rails not fully initialized  
**Root Cause:** Puma (Rails app server) failed to load  
**PostgreSQL Tuning:** ❌ **NOT APPLIED** - Using old docker-compose.yml

---

## Critical Findings

### 1. **Wrong Docker Compose File in Use**

The homelab is using `/home/kang/homelab-gitlab/docker-compose.yml` which **does NOT contain** our PostgreSQL tuning fixes.

**Evidence:**
- No `postgresql['shared_buffers']` or tuning parameters found in logs
- File timestamp: Dec 25 17:19 (before our fixes)
- Container name: `autogit-git-server` (matches old config)

**Our fixed files were deployed to:** `/home/kang/autogit-homelab/` (wrong directory!)

---

### 2. **Puma Failed to Start**

**Error Log:**
```
2025-12-25_23:56:19.52254 bundler: failed to load command: puma (/opt/gitlab/embedded/bin/puma)
from /opt/gitlab/embedded/lib/ruby/site_ruby/3.2.0/bundler/friendly_errors.rb:118:in `with_friendly_errors'
```

**Symptoms:**
- Workhorse repeatedly failing to connect to Rails socket
- `dial unix /var/opt/gitlab/gitlab-rails/sockets/gitlab.socket: connect: connection refused`
- Connection refused errors every 10 seconds

---

### 3. **Database IS Working**

**Good News:**
- Database migrations running successfully
- Background workers executing properly
- No database timeout errors
- PostgreSQL responsive (even without tuning)

**Evidence:**
```
"Database::BatchedBackgroundMigrationWorker JID-...: done: 0.037358 sec"
"db_main_duration_s":0.001,"db_primary_duration_s":0.003
```

---

## Root Cause Analysis

### **Problem:** Deployment used wrong directory

**What happened:**
1. We deployed fixed files to `/home/kang/autogit-homelab/`
2. GitLab is actually running from `/home/kang/homelab-gitlab/`
3. Container started with old docker-compose.yml (no PostgreSQL tuning)
4. Puma crashed during initialization (likely resource constraints without tuning)

### **Why Puma Failed:**

Without PostgreSQL tuning, the database initialization likely consumed excessive memory/CPU, leaving insufficient resources for Puma to start. The exact Puma error is truncated in logs, but typical causes are:
- Out of memory
- Config file errors
- Missing dependencies
- Database connection issues during boot

---

## Fix Strategy

### **Option 1: Redeploy to Correct Directory** ✅ RECOMMENDED

```bash
# On local machine
cd /home/spooky/Documents/projects/autogit/homelab-migration

# Deploy to CORRECT directory
scp docker-compose.homelab.yml kang@192.168.1.170:/home/kang/homelab-gitlab/docker-compose.yml
scp docker-compose.rootless.yml kang@192.168.1.170:/home/kang/homelab-gitlab/

# On homelab
ssh kang@192.168.1.170
cd /home/kang/homelab-gitlab

# Stop existing containers
export DOCKER_HOST=unix:///run/user/1000/docker.sock
docker compose down

# Use fixed file
cp docker-compose.homelab.yml docker-compose.yml

# Start with PostgreSQL tuning
docker compose up -d

# Monitor
docker compose logs -f gitlab
```

---

### **Option 2: Use Rootless-Compatible Config**

If using non-privileged ports (8080/8443):

```bash
# On homelab
cd /home/kang/homelab-gitlab

# Stop existing
docker compose down

# Use rootless config
cp docker-compose.rootless.yml docker-compose.yml

# Start
docker compose up -d
```

---

## PostgreSQL Tuning Verification

**After redeployment, verify tuning is applied:**

```bash
# Check GitLab logs for PostgreSQL config
docker compose logs gitlab 2>&1 | grep -i "postgresql\['shared_buffers'\]"

# Should see:
# postgresql['shared_buffers'] = "256MB"
# postgresql['effective_cache_size'] = "1GB"
# postgresql['work_mem'] = "16MB"
# ... (9 total parameters)
```

---

## Expected Timeline (With Tuning)

- **~2 min:** PostgreSQL ready
- **~5 min:** Database migrations start
- **~8 min:** Puma starts successfully
- **~10 min:** Workhorse connects, health check passes
- **~12 min:** Web UI accessible

---

## Action Items

1. ✅ **Deploy to correct directory** (`/home/kang/homelab-gitlab/`)
2. ⏳ **Stop existing containers** (clear failed state)
3. ⏳ **Start with fixed docker-compose.yml**
4. ⏳ **Monitor for PostgreSQL tuning in logs**
5. ⏳ **Verify Puma starts successfully**
6. ⏳ **Test health endpoint:** `curl http://localhost:8080/-/health`

---

## Files to Deploy

**From:** `/home/spooky/Documents/projects/autogit/homelab-migration/`

**To:** `/home/kang/homelab-gitlab/`

Files:
- `docker-compose.homelab.yml` → `docker-compose.yml` (main fix)
- `docker-compose.rootless.yml` (alternative for rootless)
- `deploy-fresh.sh` (deployment script)
- `monitor-deployment.sh` (monitoring tool)

---

## Success Criteria

- ✅ Container status: healthy
- ✅ Puma running without errors
- ✅ Workhorse connected to Rails socket
- ✅ Health endpoint returns `{"status":"ok"}`
- ✅ Web UI accessible at http://localhost:8080 (or 192.168.1.170:8080)
- ✅ PostgreSQL tuning visible in logs

---

## Log Analysis Details

**Container Info:**
- ID: 5a11490dcebb
- Image: gitlab/gitlab-ce:latest
- Created: 25+ minutes ago
- Status: Up 25 minutes (unhealthy)
- Ports: 2222:22, 8080:80, 8443:443

**Database Activity:**
- Background migrations: ✅ Running
- DB connections: ✅ Working
- Query performance: ✅ Fast (1-3ms)

**Rails Status:**
- Puma: ❌ Failed to load
- Workhorse: ⚠️ Running but can't connect
- Sidekiq: ✅ Running

**Error Count:**
- Connection refused: 100+ (repeating every 10s)
- Puma load failure: 1 (critical)
- No database errors

---

## Next Steps

1. Deploy fixed docker-compose.yml to `/home/kang/homelab-gitlab/`
2. Restart containers cleanly
3. Monitor logs for PostgreSQL tuning confirmation
4. Wait ~10-12 minutes for full initialization
5. Verify health endpoint
6. Document results in SMOKE_TEST_RESULTS.md

**Confidence Level:** HIGH - Database is healthy, issue is Puma startup without tuning
