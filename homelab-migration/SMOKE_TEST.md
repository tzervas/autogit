# Homelab Deployment Smoke Test

**Purpose:** Verify DB tuning fixes resolve initialization hanging

## Pre-Test Changes Applied

✅ **PostgreSQL Performance Tuning Added:**
```yaml
postgresql['shared_buffers'] = "256MB"
postgresql['effective_cache_size'] = "1GB"
postgresql['work_mem'] = "16MB"
postgresql['maintenance_work_mem'] = "64MB"
postgresql['checkpoint_completion_target'] = 0.9
postgresql['wal_buffers'] = "16MB"
postgresql['max_wal_size'] = "1GB"
postgresql['min_wal_size'] = "80MB"
postgresql['random_page_cost'] = 1.1
```

✅ **Healthcheck Start Period Extended:**
- Before: `300s` (5 minutes)
- After: `600s` (10 minutes)

## Test Procedure

### 1. Pre-Flight Checks
```bash
cd homelab-migration/
docker --version
docker compose version
```

### 2. Clean Start
```bash
# Remove old data if exists
rm -rf data/gitlab/

# Pull latest image
docker compose -f docker-compose.homelab.yml pull
```

### 3. Deployment
```bash
# Start with monitoring
docker compose -f docker-compose.homelab.yml up -d

# Monitor logs in real-time
docker compose -f docker-compose.homelab.yml logs -f gitlab
```

### 4. Monitor Key Milestones
Watch logs for these events (record timestamps):

- [ ] **PostgreSQL Init Start** - Look for: "Database cluster initialized"
- [ ] **PostgreSQL Config Applied** - Look for: "shared_buffers = 256MB"
- [ ] **PostgreSQL Ready** - Look for: "database system is ready to accept connections"
- [ ] **GitLab DB Migration Start** - Look for: "Migrating to"
- [ ] **GitLab Services Ready** - Look for: "Gitlab Workhorse successfully started"
- [ ] **Health Check Pass** - Check: `curl -k https://localhost/-/health`

### 5. Success Criteria
- [ ] GitLab container stays running (no restarts)
- [ ] PostgreSQL initializes within 10 minutes
- [ ] Health endpoint responds with 200 OK
- [ ] Root login accessible at https://localhost
- [ ] No database timeout errors in logs

### 6. Metrics to Record
- **Total init time:** _________ minutes
- **PostgreSQL ready time:** _________ minutes
- **First health check success:** _________ minutes
- **Container restarts:** _________
- **Memory usage:** _________ GB

## Test Results

**Date:** _________________  
**Tester:** _________________  
**Status:** [ ] PASS [ ] FAIL

### Observations:
```
[Record any issues, timing anomalies, or unexpected behavior]
```

### Next Steps:
- [ ] If PASS: Proceed to task #5 (stage & commit)
- [ ] If FAIL: Analyze logs, adjust tuning, re-test

## Troubleshooting

### If DB Still Hangs:
1. Check available memory: `free -h`
2. Check logs: `docker compose -f docker-compose.homelab.yml logs gitlab | grep -i postgres`
3. Try increasing shared_buffers to 512MB
4. Consider external PostgreSQL container

### Quick Restart:
```bash
docker compose -f docker-compose.homelab.yml down
docker compose -f docker-compose.homelab.yml up -d
```

### Full Reset:
```bash
docker compose -f docker-compose.homelab.yml down -v
rm -rf data/gitlab/
docker compose -f docker-compose.homelab.yml up -d
```
