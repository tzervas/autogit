# Git Server Administration Guide

**Component**: Git Server (GitLab CE) **Focus**: System Administration and Maintenance **Last
Updated**: 2025-12-23

## Overview

This guide provides instructions for administrators to manage the AutoGit Git Server (GitLab CE). It
covers user management, system maintenance, and monitoring.

## User Management

### Creating Users

While users can sign up (if enabled), administrators can create users via the Web UI or API.

**Via Web UI**:

1. Go to **Admin Area** > **Overview** > **Users**.
1. Click **New user**.
1. Fill in the details and click **Create user**.

**Via API**:

```bash
curl --request POST --header "PRIVATE-TOKEN: <admin_token>" \
     --data "email=user@example.com&name=New User&username=newuser&password=SecurePassword123" \
     "http://localhost:3000/api/v4/users"
```

### Managing Permissions

GitLab uses Role-Based Access Control (RBAC). Roles include:

- **Guest**: Can view projects but not code.
- **Reporter**: Can view code and issues.
- **Developer**: Can push to non-protected branches.
- **Maintainer**: Can push to protected branches and manage settings.
- **Owner**: Full control over the project/group.

## System Maintenance

### Updating GitLab

To update the Git Server to a newer version:

1. Update the version in `services/git-server/Dockerfile` or `.env`.
1. Pull the new image: `docker compose pull git-server`.
1. Restart the service: `docker compose up -d git-server`.

### Monitoring

- **Health Check**: `http://localhost:3000/-/health`
- **Logs**: `docker compose logs -f git-server`
- **Internal Stats**: Access the **Admin Area** > **Monitoring** in the Web UI.

## Troubleshooting

### Reconfiguring GitLab

If configuration changes in `gitlab.rb` are not taking effect:

```bash
docker exec -it git-server gitlab-ctl reconfigure
```

### Resetting Root Password

If you lose the root password:

```bash
docker exec -it git-server gitlab-rake "gitlab:password:reset[root]"
```

## Security Audits

Regularly check the **Admin Area** > **Monitoring** > **Audit Events** to track sensitive actions
across the platform.
