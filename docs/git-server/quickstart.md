# Git Server Quick Start Guide

Get up and running with the AutoGit Git Server in 5 minutes.

## Prerequisites

- Docker and Docker Compose installed
- At least 4 GB of RAM available
- 10 GB of disk space
- AMD64 (x86_64) architecture

## Step 1: Configure Environment

1. Navigate to the git-server service directory:

   ```bash
   cd services/git-server
   ```

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

1. Edit the `.env` file and set a secure root password:

   ```bash
   # Open .env in your editor
   vim .env

   # Change this line:
   GITLAB_ROOT_PASSWORD=your_secure_password_here
   ```

## Step 2: Start GitLab

1. Start the Git Server:

   ```bash
   # From the repository root
   docker-compose up -d git-server
   ```

1. Monitor the startup process (first start takes 3-5 minutes):

   ```bash
   docker-compose logs -f git-server
   ```

   Wait until you see:

   ```
   gitlab Reconfigured!
   ```

1. Verify the service is healthy:

   ```bash
   docker-compose ps git-server
   ```

   You should see "healthy" in the status.

## Step 3: Access GitLab

1. Open your browser and navigate to:

   ```
   http://localhost:3000
   ```

1. Login with:

   - **Username**: `root`
   - **Password**: The value you set in `GITLAB_ROOT_PASSWORD`

## Step 4: Create Your First Repository

### Via Web UI

1. Click "New project" or "Create a project"
1. Choose "Create blank project"
1. Fill in:
   - **Project name**: `my-first-project`
   - **Visibility**: Private
1. Click "Create project"

### Via API

```bash
# Get your personal access token from GitLab UI:
# User Settings > Access Tokens > Create token

# Create project
curl --request POST \
  --header "PRIVATE-TOKEN: your_token_here" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "my-first-project",
    "visibility": "private"
  }' \
  "http://localhost:3000/api/v4/projects"
```

## Step 5: Clone Your Repository

### Via HTTP

```bash
git clone http://localhost:3000/root/my-first-project.git
cd my-first-project
```

When prompted for credentials:

- **Username**: `root`
- **Password**: Your GitLab password

### Via SSH

1. Generate SSH key (if you don't have one):

   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

1. Copy your public key:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

1. Add SSH key to GitLab:

   - Login to GitLab
   - Go to User Settings > SSH Keys
   - Paste your public key
   - Click "Add key"

1. Clone via SSH:

   ```bash
   git clone ssh://git@localhost:2222/root/my-first-project.git
   cd my-first-project
   ```

## Step 6: Make Your First Commit

```bash
# Create a README
echo "# My First Project" > README.md

# Add and commit
git add README.md
git commit -m "Initial commit: Add README"

# Push to GitLab
git push origin main
```

## Verify Everything Works

1. **Check web UI**: Refresh your browser and verify the README appears
1. **Check API**:
   ```bash
   curl --header "PRIVATE-TOKEN: your_token" \
     "http://localhost:3000/api/v4/projects/1"
   ```
1. **Check health**:
   ```bash
   curl http://localhost:3000/-/health
   ```

## Common First-Time Tasks

### Create a Personal Access Token

1. Login to GitLab
1. Go to User Settings > Access Tokens
1. Enter:
   - **Token name**: `api-access`
   - **Expiration**: Choose a date
   - **Scopes**: Select `api`
1. Click "Create personal access token"
1. Copy the token (you won't see it again!)

### Create a New User

1. Login as root
1. Go to Admin Area > Users
1. Click "New user"
1. Fill in user details
1. Click "Create user"
1. Set password for the user

### Setup CI/CD Runner

See [Runner Integration Guide](runner-integration.md) for detailed instructions.

## Stopping the Service

```bash
# Stop GitLab
docker-compose stop git-server

# Stop and remove (keeps data)
docker-compose down

# Stop, remove, and delete all data (⚠️ WARNING: Destructive!)
docker-compose down -v
```

## Next Steps

- [Configure HTTPS](configuration.md#https) *(coming soon)*
- [Setup automated backups](backup-recovery.md#automated-backups) *(coming soon)*
- [Integrate with runners](runner-integration.md) *(coming soon)*
- [Setup webhooks](webhooks.md) *(coming soon)*
- [Configure external authentication](external-auth.md) *(coming soon)*

## Troubleshooting

### GitLab won't start

- Check Docker resources (at least 4 GB RAM)
- Review logs: `docker-compose logs git-server`
- Ensure ports 2222, 3000, and 3443 are available

### Can't login

- Verify you're using the correct password from `.env`
- Try resetting the password:
  ```bash
  docker-compose exec git-server gitlab-rake "gitlab:password:reset[root]"
  ```

### Slow performance

- First startup is always slow (3-5 minutes)
- Increase Docker resources if available
- Check system load: `docker stats autogit-git-server`

## Support

- [Full Documentation](README.md)
- [Troubleshooting Guide](#troubleshooting) *(section above)*
- [GitLab Community Forum](https://forum.gitlab.com/)

## Success! 🎉

You now have a fully functional Git server running. Start creating repositories, setting up CI/CD
pipelines, and integrating with your AutoGit runners!
