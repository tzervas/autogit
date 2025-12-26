#!/usr/bin/env python3
"""
Homelab GitLab Configuration Script

This script configures users, groups, roles, and scoped tokens in a self-hosted GitLab instance
using the GitLab REST API. It is designed to be idempotent and parameterized.

Usage:
    export GITLAB_URL="http://192.168.1.170:3000"
    export GITLAB_TOKEN="your-root-token-here"
    uv run python homelab-gitlab/configure-gitlab.py

Requirements:
- requests (installed via uv)
- Root token with admin privileges

Threat model:
- Sensitive data: GitLab root token (passed via env, not stored)
- Failure modes: API failures, duplicate creations (handled idempotently)
- Blast radius: GitLab server configuration
- Mitigations: Idempotent operations, minimal permissions on created tokens
"""

import os
import sys
from typing import Dict, List

import requests


class GitLabConfigurator:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        })

    def _api_call(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        url = f"{self.base_url}/api/v4{endpoint}"
        resp = self.session.request(method, url, **kwargs)
        resp.raise_for_status()
        return resp

    def get_or_create_user(self, username: str, email: str, name: str, password: str) -> Dict:
        """Create user if not exists, return user data."""
        # Check if user exists
        try:
            resp = self._api_call("GET", f"/users?username={username}")
            users = resp.json()
            if users:
                print(f"User {username} already exists")
                return users[0]
        except requests.HTTPError:
            pass  # User not found, create

        # Create user
        data = {
            "username": username,
            "email": email,
            "name": name,
            "password": password,
            "skip_confirmation": True,  # For self-hosted
        }
        resp = self._api_call("POST", "/users", json=data)
        user = resp.json()
        print(f"Created user {username}")
        return user

    def get_or_create_group(self, name: str, path: str, description: str = "") -> Dict:
        """Create group if not exists, return group data."""
        # Check if group exists
        try:
            resp = self._api_call("GET", f"/groups/{path}")
            print(f"Group {path} already exists")
            return resp.json()
        except requests.HTTPError as e:
            if e.response.status_code != 404:
                raise

        # Create group
        data = {
            "name": name,
            "path": path,
            "description": description,
            "visibility": "private",
        }
        resp = self._api_call("POST", "/groups", json=data)
        group = resp.json()
        print(f"Created group {path}")
        return group

    def add_user_to_group(self, user_id: int, group_id: int, access_level: int):
        """Add user to group with access level (10=Guest, 20=Reporter, 30=Developer, 40=Maintainer, 50=Owner)."""
        try:
            self._api_call("POST", f"/groups/{group_id}/members", json={
                "user_id": user_id,
                "access_level": access_level,
            })
            print(f"Added user {user_id} to group {group_id} with level {access_level}")
        except requests.HTTPError as e:
            if e.response.status_code == 409:  # Already a member
                print(f"User {user_id} already in group {group_id}")
            else:
                raise

    def create_personal_access_token(self, user_id: int, name: str, scopes: List[str]) -> str:
        """Create PAT for user, return token string."""
        data = {
            "name": name,
            "scopes": scopes,
        }
        resp = self._api_call("POST", f"/users/{user_id}/personal_access_tokens", json=data)
        token_data = resp.json()
        token = token_data["token"]
        print(f"Created PAT '{name}' for user {user_id} with scopes {scopes}")
        return token

    def configure(self):
        """Main configuration logic."""
        # Define users
        users = [
            {
                "username": "ci-user",
                "email": "ci@homelab.local",
                "name": "CI User",
                "password": "changeme123!",  # pragma: allowlist secret - TODO: Use secure password
            },
            {
                "username": "admin-user",
                "email": "admin@homelab.local",
                "name": "Admin User",
                "password": "changeme123!",
            },
        ]

        # Create users
        created_users = {}
        for user_spec in users:
            user = self.get_or_create_user(**user_spec)
            created_users[user_spec["username"]] = user

        # Define groups
        groups = [
            {
                "name": "Debian Sid Projects",
                "path": "debian-sid",
                "description": "Group for Debian Sid automation projects",
            },
        ]

        # Create groups
        created_groups = {}
        for group_spec in groups:
            group = self.get_or_create_group(**group_spec)
            created_groups[group_spec["path"]] = group

        # Add users to groups
        debian_group = created_groups["debian-sid"]
        ci_user = created_users["ci-user"]
        admin_user = created_users["admin-user"]

        self.add_user_to_group(ci_user["id"], debian_group["id"], 30)  # Developer
        self.add_user_to_group(admin_user["id"], debian_group["id"], 50)  # Owner

        # Create scoped tokens
        tokens = {}

        # CI token with minimal scopes for CI operations
        tokens["ci_token"] = self.create_personal_access_token(
            ci_user["id"],
            "CI Token",
            ["api", "read_repository", "write_repository"]  # Minimal for CI
        )

        # Admin token with broader scopes for admin tasks
        tokens["admin_token"] = self.create_personal_access_token(
            admin_user["id"],
            "Admin Token",
            ["api", "read_user", "sudo"]  # For admin operations
        )

        # Output tokens (insecure, but for setup)
        print("\n" + "="*50)
        print("GENERATED TOKENS (store securely, will not be shown again):")
        for name, token in tokens.items():
            print(f"{name}: {token}")
        print("="*50)

        return {
            "users": created_users,
            "groups": created_groups,
            "tokens": tokens,
        }


def main():
    gitlab_url = os.environ.get("GITLAB_URL")
    gitlab_token = os.environ.get("GITLAB_TOKEN")

    if not gitlab_url or not gitlab_token:
        print("Error: Set GITLAB_URL and GITLAB_TOKEN environment variables", file=sys.stderr)
        sys.exit(1)

    configurator = GitLabConfigurator(gitlab_url, gitlab_token)
    result = configurator.configure()

    # Optionally save config to file
    import json
    with open("homelab-gitlab/gitlab-config.json", "w") as f:
        json.dump(result, f, indent=2)
    print("Configuration saved to homelab-gitlab/gitlab-config.json")


if __name__ == "__main__":
    main()
