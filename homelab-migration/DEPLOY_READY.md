# Smoke Test Deployment - Ready to Execute

**Status:** ✅ All pre-flight checks PASSED
**Date:** December 25, 2025
**Target:** kang@192.168.1.170

---

## Pre-Flight Validation Results

✅ **Docker Compose v2 Syntax:** Valid
✅ **PostgreSQL Tuning:** Present (shared_buffers=256MB + 8 other params)
✅ **Healthcheck Period:** 600s (10 minutes)
✅ **Homelab Connectivity:** Reachable
✅ **SSH Access:** Configured
✅ **Required Files:** All present

---

## Deployment Command

From your current directory:
```bash
cd /home/spooky/Documents/projects/autogit/homelab-migration
./run-smoke-test.sh
```

This will:
1. Create remote directory on homelab
2. Copy `docker-compose.homelab.yml` → `docker-compose.yml`
3. Copy SSL certs (if available)
4. Copy smoke test checklist
5. Verify Docker Compose v2 on homelab
6. Create remote deployment script

---

## What Happens on Homelab

The script creates `deploy.sh` on homelab that:
- Pulls latest GitLab CE image
- Starts services with `docker compose up -d`
- Provides monitoring commands

---

## Monitoring Steps (After Deployment)

**Terminal 1:** Main deployment
```bash
ssh kang@192.168.1.170
cd /home/kang/autogit-homelab
./deploy.sh
```

**Terminal 2:** Live log monitoring
```bash
ssh kang@192.168.1.170
cd /home/kang/autogit-homelab
docker compose logs -f gitlab
```

---

## Key Milestones to Watch

1. **PostgreSQL Init** (~2-3 min)
   - Look for: `database system is ready to accept connections`
   - Verify tuning: `shared_buffers = 256MB` in logs

2. **GitLab DB Migration** (~3-5 min)
   - Look for: `Migrating to ...` (multiple lines)
   - Should complete without timeouts

3. **Services Ready** (~5-8 min)
   - Look for: `Gitlab Workhorse successfully started`
   - Look for: `gitlab Listening on`

4. **Health Check** (~8-10 min)
   ```bash
   curl -k https://localhost/-/health
   # Expected: {"status":"ok"}
   ```

5. **Container Stability**
   ```bash
   docker compose ps
   # Expected: gitlab status "healthy", no restarts
   ```

---

## Success Criteria

- [ ] GitLab container runs without restarts
- [ ] PostgreSQL initializes within 10 minutes
- [ ] No database timeout errors
- [ ] Health endpoint returns 200 OK
- [ ] Web UI accessible at https://gitlab.vectorweight.com
- [ ] No memory/resource exhaustion

---

## If Issues Occur

### DB Still Hangs:
```bash
# Check logs for DB errors
docker compose logs gitlab | grep -i "postgres\|database"

# Check available memory
free -h

# If needed, increase shared_buffers in docker-compose.yml
# then: docker compose down && docker compose up -d
```

### Container Restarts:
```bash
# Check restart count
docker compose ps

# View recent events
docker compose events --since 10m
```

### Health Check Fails:
```bash
# Exec into container
docker compose exec gitlab bash

# Check internal health
gitlab-rake gitlab:check

# Check PostgreSQL connection
gitlab-psql -c "SELECT 1;"
```

---

## Expected Timeline

| Time | Event |
|------|-------|
| 0:00 | Container start |
| 0:30 | PostgreSQL initialization begins |
| 2:00 | PostgreSQL ready (with tuning) |
| 2:30 | GitLab Rails DB setup begins |
| 5:00 | DB migrations running |
| 8:00 | Services starting |
| 10:00 | Health checks passing |

**With DB fixes, should complete in 8-12 minutes total.**

---

## Reporting Results

After test completion, document:

1. **Total init time:** _______ minutes
2. **PostgreSQL ready:** _______ minutes
3. **Container restarts:** _______
4. **Health check status:** [ ] PASS [ ] FAIL
5. **Memory usage:** _______ GB
6. **Any errors:** _______________________

**Report results back before proceeding to task #5 (stage & commit)!**

---

## Quick Commands Reference

```bash
# Start
./deploy.sh

# Monitor
docker compose logs -f gitlab

# Check status
docker compose ps

# Test health
curl -k https://localhost/-/health

# Stop
docker compose down

# Full reset (if needed)
docker compose down -v
rm -rf data/gitlab/
```

---

**Ready to execute:** Run `./run-smoke-test.sh` now! 🚀
