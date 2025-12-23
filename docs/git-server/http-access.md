# HTTP/HTTPS Access Configuration Guide

**Component**: Git Server (GitLab CE) - HTTP/HTTPS Access
**Status**: Implementation
**Last Updated**: 2025-12-23

## Overview

AutoGit provides access to the Git Server via HTTP (port 3000) and HTTPS (port 3443).

## 1. HTTP Access (Default)

By default, AutoGit is configured to use HTTP on port 3000.

- **URL**: `http://localhost:3000`
- **Git Clone**: `git clone http://localhost:3000/group/project.git`

## 2. HTTPS Access (Optional)

To enable HTTPS, you need to generate SSL certificates and update the configuration.

### Step 1: Generate Self-Signed Certificates

```bash
./services/git-server/scripts/generate-ssl.sh gitlab.autogit.local
```

### Step 2: Update Configuration

Edit `services/git-server/config/gitlab.rb.template` (or the active `gitlab.rb` in the volume):

```ruby
external_url 'https://gitlab.autogit.local'
nginx['listen_port'] = 443
nginx['listen_https'] = true
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.autogit.local.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.autogit.local.key"
```

### Step 3: Update Docker Compose

Ensure the SSL directory is mounted in `docker-compose.yml`:

```yaml
services:
  git-server:
    # ...
    volumes:
      - ./services/git-server/config/ssl:/etc/gitlab/ssl
    # ...
```

## 3. Reverse Proxy Configuration

If you are running AutoGit behind a reverse proxy (like Nginx or Traefik), ensure you pass the correct headers:

```nginx
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

## Troubleshooting

### SSL Certificate Warning
Since we use self-signed certificates, your browser and Git client will show a warning.

> **Security Warning**: Disabling SSL verification globally is highly discouraged as it exposes you to man-in-the-middle attacks. Only use the following commands for local development and with full awareness of the risks.

**For Git (Per-Repository - Recommended)**:
```bash
git config http.sslVerify false
```

**For Git (Global - Use with Caution)**:
```bash
git config --global http.sslVerify false
```

### Port Conflicts
If port 3000 or 3443 is already in use, change the mapping in your `.env` file:

```bash
GITLAB_HTTP_PORT=3001
GITLAB_HTTPS_PORT=3444
```
