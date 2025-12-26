# Rootless Docker Port Fix - Two Options

**Problem:** Rootless Docker cannot bind to privileged ports (80, 443) without special
configuration.

**Error:** `cannot expose privileged port 80... currently 1024`

______________________________________________________________________

## Option 1: System-Wide Fix (Recommended for Permanent Setup)

Allow rootless Docker to bind to ports 80 and 443:

```bash
ssh kang@192.168.1.170
cd /home/kang/autogit-homelab
chmod +x fix-rootless-ports.sh
./fix-rootless-ports.sh
```

This will:

1. Add `net.ipv4.ip_unprivileged_port_start=80` to `/etc/sysctl.conf`
1. Apply immediately with `sysctl -p`
1. Allow original `./deploy.sh` to work with ports 80/443

**Then run:**

```bash
./deploy.sh
```

______________________________________________________________________

## Option 2: Use Non-Privileged Ports (Quick Test)

Use ports 8080/8443 instead of 80/443:

```bash
ssh kang@192.168.1.170
cd /home/kang/autogit-homelab
chmod +x deploy-rootless.sh
./deploy-rootless.sh
```

**Access GitLab at:**

- HTTP: `http://192.168.1.170:8080`
- SSH: `ssh://git@192.168.1.170:2222`

______________________________________________________________________

## Recommendation

**For smoke test:** Use **Option 2** (quick, no system changes)

- Tests DB tuning fixes
- Validates configuration
- No sudo required

**For production:** Apply **Option 1** (standard ports)

- Better for HTTPS/SSL
- Standard ports (80/443)
- Cleaner URLs

______________________________________________________________________

## Next Steps

### Option 2 (Rootless Ports) - Quick Test

```bash
ssh kang@192.168.1.170
cd /home/kang/autogit-homelab

# Deploy with non-privileged ports
./deploy-rootless.sh

# Monitor logs
docker compose logs -f gitlab

# Test health (wait ~8-10 min)
curl http://localhost:8080/-/health

# Check container status
docker compose ps
```

**Access from your machine:**

```bash
# From volk, access homelab GitLab
curl http://192.168.1.170:8080/-/health

# Or use SSH tunnel
ssh -L 8080:localhost:8080 kang@192.168.1.170
# Then access: http://localhost:8080
```

______________________________________________________________________

## Files Deployed

✅ `docker-compose.rootless.yml` - Config with ports 8080/8443/2222 ✅ `deploy-rootless.sh` -
Deployment script for rootless Docker ✅ `fix-rootless-ports.sh` - System-wide fix for Option 1

______________________________________________________________________

## What Changed

**docker-compose.rootless.yml:**

- Ports: `80→8080`, `443→8443`, `22→2222`
- External URL: `http://gitlab.vectorweight.com:8080`
- Health check: `http://localhost/-/health` (port 80 internal)
- All PostgreSQL tuning preserved
- All other configs identical

______________________________________________________________________

**Ready to test!** Use Option 2 for the smoke test. 🚀
