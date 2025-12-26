import os
import sys

from tools.gitlab_client import GitLabClient


def main():
    # Configuration
    url = os.getenv("GITLAB_URL", "http://localhost:3000")
    token = os.getenv("GITLAB_TOKEN")

    if not token:
        print("Error: GITLAB_TOKEN environment variable not set.")
        sys.exit(1)

    client = GitLabClient(base_url=url, token=token)

    try:
        # 1. Create a new project
        project_name = "AutoGit Test Project"
        print(f"Creating project: {project_name}...")
        project = client.create_project(name=project_name)
        project_id = project["id"]
        print(f"✅ Project created with ID: {project_id}")

        # 2. Create a README file
        print("Creating README.md...")
        client.create_file(
            project_id=project_id,
            file_path="README.md",
            branch="main",
            content="# AutoGit Test Project\n\nThis project was created via the AutoGit API client.",
            commit_message="Initial commit",
        )
        print("✅ README.md created.")

        # 3. Protect the main branch
        print("Protecting 'main' branch...")
        client.protect_branch(project_id=project_id, branch_name="main")
        print("✅ 'main' branch protected (Maintainers only).")

        # 4. Add a webhook (example)
        print("Adding webhook...")
        client.add_project_webhook(
            project_id=project_id, url="http://runner-coordinator:8080/webhook"
        )
        print("✅ Webhook added.")

    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
