# GitLab API Integration Guide

**Component**: Git Server (GitLab CE) - API Integration
**Status**: Implementation
**Last Updated**: 2025-12-23

## Overview

AutoGit interacts with the GitLab Git Server via the GitLab REST API v4. This document outlines the key endpoints and authentication methods used by the AutoGit platform.

## Authentication

### Personal Access Tokens (PAT)
The primary method for API authentication is to use Personal Access Tokens.

- **Header**: `PRIVATE-TOKEN: <your_access_token>`
- **Scopes Required**: `api`, `read_user`, `read_repository`, `write_repository`

### Creating a PAT
1. Log in to GitLab.
2. Go to **User Settings** → **Access Tokens**.
3. Click **Add new token**.
4. Select the required scopes and click **Create personal access token**.

## Key API Endpoints

### 1. Users
- **List Users**: `GET /api/v4/users`
- **Get Single User**: `GET /api/v4/users/:id`
- **Create User**: `POST /api/v4/users`
- **Delete User**: `DELETE /api/v4/users/:id`

### 2. Projects (Repositories)
- **List Projects**: `GET /api/v4/projects`
- **Get Single Project**: `GET /api/v4/projects/:id`
- **Create Project**: `POST /api/v4/projects`
- **Delete Project**: `DELETE /api/v4/projects/:id`
- **Star Project**: `POST /api/v4/projects/:id/star`

### 3. Groups
- **List Groups**: `GET /api/v4/groups`
- **Create Group**: `POST /api/v4/groups`
- **Add Member to Group**: `POST /api/v4/groups/:id/members`

### 4. SSH Keys
- **List SSH Keys**: `GET /api/v4/user/keys`
- **Add SSH Key**: `POST /api/v4/user/keys`
- **Delete SSH Key**: `DELETE /api/v4/user/keys/:key_id`

### 5. Webhooks
- **List Project Hooks**: `GET /api/v4/projects/:id/hooks`
- **Add Project Hook**: `POST /api/v4/projects/:id/hooks`

## API Client Library

AutoGit provides a lightweight Python client located at `tools/gitlab_client.py`.

### Basic Usage

```python
from tools.gitlab_client import GitLabClient

client = GitLabClient(base_url="http://localhost:3000", token="your_pat_here")

# List projects
projects = client.get_projects()
for project in projects:
    print(f"Project: {project['name']}")
```

## Rate Limiting

GitLab API has built-in rate limiting. Ensure your scripts handle `429 Too Many Requests` responses gracefully.
