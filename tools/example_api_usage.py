import os
import sys

from gitlab_client import GitLabApiError, GitLabClient


def main():
    # Configuration
    url = os.getenv("GITLAB_URL", "http://localhost:3000")
    token = os.getenv("GITLAB_TOKEN")

    if not token:
        print("Error: GITLAB_TOKEN environment variable not set.")
        print("Usage: GITLAB_TOKEN=your_token python3 example_api_usage.py")
        sys.exit(1)

    try:
        client = GitLabClient(base_url=url, token=token)

        # 1. Get current user
        user = client.get_current_user()
        print(f"--- Authenticated as: {user['username']} ({user['name']}) ---")

        # 2. List projects
        print("\n--- Your Projects ---")
        projects = client.get_projects()
        if not projects:
            print("No projects found.")
        for p in projects:
            print(f"- {p['name']} (ID: {p['id']})")

        # 3. List SSH keys
        print("\n--- Your SSH Keys ---")
        keys = client.get_ssh_keys()
        if not keys:
            print("No SSH keys found.")
        for k in keys:
            print(f"- {k['title']} (Fingerprint: {k['fingerprint']})")

    except GitLabApiError as e:
        print(f"GitLab API Error: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")


if __name__ == "__main__":
    main()
