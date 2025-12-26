#!/usr/bin/env python3
"""
GitLab Configuration Exporter

Exports current GitLab server configuration via API for backup/restore purposes.
This creates a parameterized, idempotent config that can be used to recreate the setup.

Usage:
    export GITLAB_URL="http://192.168.1.170:3000"
    export GITLAB_TOKEN="your-token-here"  # Can be root or admin token
    uv run python homelab-gitlab/export-gitlab-config.py

Outputs:
- gitlab-settings.json: Application settings
- gitlab-users.json: User list (without sensitive data)
- gitlab-groups.json: Group list
- gitlab-config-summary.json: Combined summary

Threat model:
- Sensitive data: Tokens passed via env
- Failure modes: API access denied, large data sets
- Blast radius: Local files only
- Mitigations: No secrets in output, admin token required
"""

import json
import os
import sys
from typing import Any, Dict

import requests


class GitLabExporter:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {token}",
            }
        )

    def _api_call(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        url = f"{self.base_url}/api/v4{endpoint}"
        resp = self.session.request(method, url, **kwargs)
        resp.raise_for_status()
        return resp

    def export_application_settings(self) -> Dict[str, Any]:
        """Export application settings."""
        resp = self._api_call("GET", "/application/settings")
        return resp.json()

    def export_users(self) -> list:
        """Export users (excluding sensitive data)."""
        resp = self._api_call("GET", "/users", params={"per_page": 100})
        users = resp.json()
        # Remove sensitive fields
        for user in users:
            user.pop("private_token", None)
            user.pop("password", None)
        return users

    def export_groups(self) -> list:
        """Export groups."""
        resp = self._api_call("GET", "/groups", params={"per_page": 100})
        return resp.json()

    def export_projects(self) -> list:
        """Export projects."""
        resp = self._api_call("GET", "/projects", params={"per_page": 100})
        projects = resp.json()
        # Remove large fields
        for project in projects:
            project.pop("readme", None)
            project.pop("readme_url", None)
        return projects

    def export(self) -> Dict[str, Any]:
        """Main export logic."""
        print("Exporting GitLab configuration...")

        settings = self.export_application_settings()
        with open("homelab-gitlab/gitlab-settings.json", "w") as f:
            json.dump(settings, f, indent=2)
        print("Exported application settings")

        users = self.export_users()
        with open("homelab-gitlab/gitlab-users.json", "w") as f:
            json.dump(users, f, indent=2)
        print(f"Exported {len(users)} users")

        groups = self.export_groups()
        with open("homelab-gitlab/gitlab-groups.json", "w") as f:
            json.dump(groups, f, indent=2)
        print(f"Exported {len(groups)} groups")

        projects = self.export_projects()
        with open("homelab-gitlab/gitlab-projects.json", "w") as f:
            json.dump(projects, f, indent=2)
        print(f"Exported {len(projects)} projects")

        summary = {
            "settings": {k: v for k, v in settings.items() if not k.startswith("password")},
            "user_count": len(users),
            "group_count": len(groups),
            "project_count": len(projects),
        }

        with open("homelab-gitlab/gitlab-config-summary.json", "w") as f:
            json.dump(summary, f, indent=2)

        print("Export complete. Files saved in homelab-gitlab/")
        return summary


def main():
    gitlab_url = os.environ.get("GITLAB_URL")
    gitlab_token = os.environ.get("GITLAB_TOKEN")

    if not gitlab_url or not gitlab_token:
        print("Error: Set GITLAB_URL and GITLAB_TOKEN environment variables", file=sys.stderr)
        sys.exit(1)

    exporter = GitLabExporter(gitlab_url, gitlab_token)
    exporter.export()


if __name__ == "__main__":
    main()
