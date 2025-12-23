import requests
import os

class GitLabClient:
    """
    A lightweight Python client for the GitLab REST API v4.
    """

    def __init__(self, base_url=None, token=None):
        self.base_url = base_url or os.getenv("GITLAB_URL", "http://localhost:3000")
        self.api_url = f"{self.base_url.rstrip('/')}/api/v4"
        self.token = token or os.getenv("GITLAB_TOKEN")

        if not self.token:
            raise ValueError("GitLab API token is required. Set GITLAB_TOKEN env var or pass it to the constructor.")

        self.headers = {
            "PRIVATE-TOKEN": self.token,
            "Content-Type": "application/json"
        }

    def _request(self, method, endpoint, data=None, params=None):
        url = f"{self.api_url}/{endpoint.lstrip('/')}"
        response = requests.request(method, url, headers=self.headers, json=data, params=params)

        if response.status_code >= 400:
            try:
                error_msg = response.json().get("message", response.text)
            except:
                error_msg = response.text
            raise Exception(f"GitLab API Error ({response.status_code}): {error_msg}")

        return response.json() if response.content else None

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
            "visibility": visibility
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
