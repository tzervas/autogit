import os
import urllib.parse

import requests


class GitLabApiError(Exception):
    """Raised when a GitLab API request returns an error response."""

    def __init__(self, status_code, message, method=None, endpoint=None):
        self.status_code = status_code
        self.message = message
        self.method = method
        self.endpoint = endpoint
        super().__init__(f"GitLab API Error ({status_code}): {message} [{method} {endpoint}]")


class GitLabClient:
    """
    A lightweight Python client for the GitLab REST API v4.
    """

    def __init__(self, base_url=None, token=None, timeout=10):
        self.base_url = base_url or os.getenv("GITLAB_URL", "http://localhost:3000")
        self.api_url = f"{self.base_url.rstrip('/')}/api/v4"
        self.token = token or os.getenv("GITLAB_TOKEN")
        self.timeout = timeout

        if not self.token:
            raise ValueError(
                "GitLab API token is required. Set GITLAB_TOKEN env var or pass it to the constructor."
            )

        self.headers = {"PRIVATE-TOKEN": self.token, "Content-Type": "application/json"}

    def _request(self, method, endpoint, data=None, params=None):
        url = f"{self.api_url}/{endpoint.lstrip('/')}"
        try:
            response = requests.request(
                method, url, headers=self.headers, json=data, params=params, timeout=self.timeout
            )

            if response.status_code >= 400:
                try:
                    error_msg = response.json().get("message", response.text)
                except ValueError:
                    error_msg = response.text
                raise GitLabApiError(response.status_code, error_msg, method, endpoint)

            return response.json() if response.content else None
        except requests.exceptions.RequestException as e:
            if isinstance(e, GitLabApiError):
                raise e
            # Wrap transport-level errors in GitLabApiError for uniformity
            status_code = getattr(getattr(e, "response", None), "status_code", 0)
            message = f"Request to GitLab failed: {e}"
            raise GitLabApiError(status_code, message, method, endpoint) from e

    # User Operations
    def get_users(self):
        return self._request("GET", "users")

    def get_current_user(self):
        return self._request("GET", "user")

    # Project Operations
    def get_projects(self, owned=True):
        params = {"owned": "true"} if owned else {}
        return self._request("GET", "projects", params=params)

    def create_project(self, name, path=None, namespace_id=None, visibility="private"):
        data = {
            "name": name,
            "path": path or name.lower().replace(" ", "-"),
            "visibility": visibility,
        }
        if namespace_id:
            data["namespace_id"] = namespace_id
        return self._request("POST", "projects", data=data)

    def delete_project(self, project_id):
        return self._request("DELETE", f"projects/{project_id}")

    # SSH Key Operations
    def get_ssh_keys(self):
        return self._request("GET", "user/keys")

    def add_ssh_key(self, title, key):
        data = {"title": title, "key": key}
        return self._request("POST", "user/keys", data=data)

    # Group Operations
    def get_groups(self):
        return self._request("GET", "groups")

    def create_group(self, name, path, visibility="private"):
        data = {"name": name, "path": path, "visibility": visibility}
        return self._request("POST", "groups", data=data)

    # Branch Protection Operations
    def protect_branch(self, project_id, branch_name, push_access_level=40, merge_access_level=40):
        """
        Protect a branch.
        Access levels: 0 (No access), 30 (Developer), 40 (Maintainer), 60 (Admin)
        """
        data = {
            "name": branch_name,
            "push_access_level": push_access_level,
            "merge_access_level": merge_access_level,
        }
        return self._request("POST", f"projects/{project_id}/protected_branches", data=data)

    def unprotect_branch(self, project_id, branch_name):
        encoded_branch = urllib.parse.quote(branch_name, safe="")
        return self._request("DELETE", f"projects/{project_id}/protected_branches/{encoded_branch}")

    # Webhook Operations
    def add_project_webhook(self, project_id, url, push_events=True, merge_requests_events=True):
        data = {
            "url": url,
            "push_events": push_events,
            "merge_requests_events": merge_requests_events,
        }
        return self._request("POST", f"projects/{project_id}/hooks", data=data)

    # Repository File Operations
    def create_file(self, project_id, file_path, branch, content, commit_message):
        data = {"branch": branch, "content": content, "commit_message": commit_message}
        encoded_path = urllib.parse.quote(file_path, safe="")
        return self._request(
            "POST", f"projects/{project_id}/repository/files/{encoded_path}", data=data
        )
