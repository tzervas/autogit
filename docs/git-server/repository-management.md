# Repository Management Guide

**Component**: Git Server (GitLab CE) - Repository Management
**Status**: Implementation
**Last Updated**: 2025-12-23

## Overview

AutoGit automates the lifecycle of Git repositories, including creation, configuration, and protection. This is primarily handled via the `GitLabClient` in `tools/gitlab_client.py`.

## Core Operations

### 1. Repository Creation
Repositories can be created for users or within groups.

```python
project = client.create_project(name="My Project", visibility="private")
```

### 2. Branch Protection
To ensure stability, the `main` and `dev` branches should be protected. By default, AutoGit protects these branches so only Maintainers can push or merge.

```python
client.protect_branch(project_id=123, branch_name="main")
```

### 3. Webhooks
Webhooks are used to notify the `runner-coordinator` of new commits or merge requests.

```python
client.add_project_webhook(project_id=123, url="http://runner-coordinator:8080/webhook")
```

### 4. Initializing Content
You can initialize a repository with a `README.md` or other template files directly via the API.

```python
client.create_file(project_id=123, file_path="README.md", branch="main", content="# Hello", commit_message="Init")
```

## Automation Script

The `tools/manage_repositories.py` script provides a reference implementation for these operations.

```bash
GITLAB_TOKEN=your_token python3 tools/manage_repositories.py
```

## Best Practices
- **Always protect the default branch**.
- **Use groups** to organize related projects.
- **Configure webhooks** early to enable CI/CD automation.
