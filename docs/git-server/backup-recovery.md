# Backup and Recovery Guide

**Component**: Git Server (GitLab CE) - Backup & Recovery **Status**: Implementation **Last
Updated**: 2025-12-23

## Overview

AutoGit provides automated scripts for backing up and restoring the Git Server (GitLab CE). This
ensures data persistence and disaster recovery capabilities.

## 1. Backup Procedure

The backup process captures two main components:

1. **Application Data**: Repositories, database, uploads, etc. (handled by `gitlab-backup`).
1. **Configuration**: `gitlab.rb`, SSL certificates, and secrets (handled by file copy).

### Running a Backup

```bash
./services/git-server/scripts/backup.sh
```

- **Application Backups**: Stored inside the container at `/var/opt/gitlab/backups/`.
- **Configuration Backups**: Stored on the host in `./backups/config_<timestamp>/`.

## 2. Recovery Procedure

To restore GitLab, you need the backup timestamp name.

### Running a Restore

```bash
./services/git-server/scripts/restore.sh <backup_timestamp_name>
```

**Example**:

```bash
./services/git-server/scripts/restore.sh 1703325600_2025_12_23_16.11.0
```

> **Warning**: Restoring a backup will overwrite existing data. Ensure you have a recent backup
> before proceeding.

## 3. Automated Backups (Cron)

To automate backups, add a cron job to the host:

```cron
# Run backup every day at 2 AM
0 2 * * * cd /path/to/autogit && ./services/git-server/scripts/backup.sh
```

## 4. Best Practices

- **Store backups off-site**: Regularly move the `./backups/` directory to a secure remote location.
- **Test restores**: Periodically perform a restore on a test environment to verify backup
  integrity.
- **Keep secrets safe**: The `gitlab-secrets.json` file is critical for decrypting database data.
  Ensure it is included in your configuration backups.
