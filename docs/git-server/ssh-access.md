# SSH Access Configuration Guide

**Component**: Git Server (GitLab CE) - SSH Access
**Status**: Implementation
**Last Updated**: 2025-12-23

## Overview

AutoGit uses SSH for secure Git operations (clone, push, pull). To avoid conflicts with the host's SSH service, AutoGit's Git Server listens on port **2222**.

## 1. Generate an SSH Key

If you don't already have an SSH key, generate one:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

## 2. Add SSH Key to AutoGit

### Option 1: Via Web UI (Recommended)
1. Log in to AutoGit: http://localhost:3000
2. Click on your avatar in the top-right corner and select **Settings**.
3. In the left sidebar, select **SSH Keys**.
4. Click **Add new key**.
5. Paste your **public** key (usually `~/.ssh/id_ed25519.pub`) into the **Key** field.
6. Give it a descriptive title and click **Add key**.

### Option 2: Via Management Script (Admin only)
Admins can add keys for any user using the management script:

```bash
./services/git-server/scripts/manage-ssh-keys.sh add <username> "My Laptop" "$(cat ~/.ssh/id_ed25519.pub)"
```

## 3. Configure Local SSH Client

Since AutoGit uses port **2222**, you should configure your local SSH client to automatically use the correct port and key for the AutoGit host.

Add the following to your `~/.ssh/config` file:

```text
Host gitlab.autogit.local localhost
    HostName localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/id_ed25519
```

## 4. Test Connection

Test your connection to the Git Server:

```bash
ssh -T git@localhost -p 2222
```

If successful, you should see a welcome message:
`Welcome to GitLab, @username!`

## 5. Cloning Repositories

When cloning via SSH, use the following format:

```bash
# If you configured ~/.ssh/config:
git clone git@localhost:group/project.git

# If you did NOT configure ~/.ssh/config:
git clone ssh://git@localhost:2222/group/project.git
```

## Troubleshooting

### Host Key Verification Failed
If you see an error about host key verification, it might be because the container was recreated and generated new host keys.

**Solution**:
Remove the old entry from your `known_hosts` file:
```bash
ssh-keygen -f "~/.ssh/known_hosts" -R "[localhost]:2222"
```

### Permission Denied (publickey)
1. Ensure your public key is added to your GitLab profile.
2. Ensure your private key is loaded in your SSH agent: `ssh-add ~/.ssh/id_ed25519`.
3. Verify you are using the correct port (2222).
4. Check that the `User` is `git`.

### Connection Refused
1. Ensure the `git-server` container is running: `docker compose ps`.
2. Check if port 2222 is correctly mapped in `docker-compose.yml`.
