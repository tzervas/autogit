# Git Server User Guide

**Component**: Git Server (GitLab CE) **Focus**: Developer Workflow and Usage **Last Updated**:
2025-12-23

## Getting Started

Welcome to the AutoGit Git Server. This guide will help you get started with managing your code.

## 1. Setting Up Your Profile

### SSH Keys

To push and pull code securely, you must add your SSH public key to your profile.

1. Go to **User Settings** > **SSH Keys**.
1. Paste your public key and click **Add key**.
1. See the [SSH Access Guide](ssh-access.md) for detailed instructions.

### Personal Access Tokens

For API access or using Git over HTTP, create a Personal Access Token (PAT).

1. Go to **User Settings** > **Access Tokens**.
1. Select scopes (e.g., `api`, `read_repository`, `write_repository`).
1. Click **Create personal access token**.

## 2. Working with Projects

### Creating a Project

1. Click the **+** icon in the top navigation bar and select **New project/repository**.
1. Choose **Create blank project**.
1. Set the visibility to **Private** (recommended).

### Cloning a Project

```bash
# Via SSH (Port 2222)
git clone ssh://git@localhost:2222/username/project.git

# Via HTTP (Port 3000)
git clone http://localhost:3000/username/project.git
```

## 3. Collaboration

### Merge Requests

1. Push your feature branch to the server.
1. Go to the project page and click **Create merge request**.
1. Assign reviewers and describe your changes.

### Issues and Labels

Use the **Issues** sidebar to track tasks, bugs, and feature requests. Use **Labels** to categorize
and prioritize work.

## 4. CI/CD Integration

AutoGit uses GitLab CI/CD. To enable it, add a `.gitlab-ci.yml` file to your repository root.

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "Building..."
```

## Support

For issues or questions, please contact your system administrator or refer to the
[official GitLab documentation](https://docs.gitlab.com/).
